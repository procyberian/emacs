;;; mm-decode.el --- Functions for decoding MIME things  -*- lexical-binding:t -*-

;; Copyright (C) 1998-2025 Free Software Foundation, Inc.

;; Author: Lars Magne Ingebrigtsen <larsi@gnus.org>
;;	MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'mail-parse)
(require 'mm-bodies)
(eval-when-compile (require 'cl-lib))

(autoload 'gnus-map-function "gnus-util")

(autoload 'mm-inline-partial "mm-partial")
(autoload 'mm-inline-external-body "mm-extern")
(autoload 'mm-extern-cache-contents "mm-extern")
(autoload 'mm-insert-inline "mm-view")

(autoload 'mm-archive-decoders "mm-archive")
(autoload 'mm-archive-dissect-and-inline "mm-archive")
(autoload 'mm-dissect-archive "mm-archive")

(defvar gnus-current-window-configuration)

(add-hook 'gnus-exit-gnus-hook #'mm-destroy-postponed-undisplay-list)
(add-hook 'gnus-exit-gnus-hook #'mm-temp-files-delete)

(defgroup mime-display ()
  "Display of MIME in mail and news articles."
  :link '(custom-manual "(emacs-mime)Display Customization")
  :version "21.1"
  :group 'mail
  :group 'news
  :group 'multimedia)

(defgroup mime-security ()
  "MIME security in mail and news articles."
  :link '(custom-manual "(emacs-mime)Display Customization")
  :group 'mail
  :group 'news
  :group 'multimedia)

(defface mm-command-output
  '((((class color)
      (background dark))
     (:foreground "ForestGreen"))
    (((class color)
      (background light))
     (:foreground "red3"))
    (t
     (:slant italic)))
  "Face used for displaying output from commands."
  :group 'mime-display)

;;; Convenience macros.

(defmacro mm-handle-buffer (handle)
  `(nth 0 ,handle))
(defmacro mm-handle-type (handle)
  `(nth 1 ,handle))
(defsubst mm-handle-media-type (handle)
  (if (stringp (car handle))
      (car handle)
    (car (mm-handle-type handle))))
(defsubst mm-handle-media-supertype (handle)
  (car (split-string (mm-handle-media-type handle) "/")))
(defsubst mm-handle-media-subtype (handle)
  (cadr (split-string (mm-handle-media-type handle) "/")))
(defmacro mm-handle-encoding (handle)
  `(nth 2 ,handle))
(defmacro mm-handle-undisplayer (handle)
  `(nth 3 ,handle))
(defmacro mm-handle-set-undisplayer (handle function)
  `(setcar (nthcdr 3 ,handle) ,function))
(defmacro mm-handle-disposition (handle)
  `(nth 4 ,handle))
(defmacro mm-handle-description (handle)
  `(nth 5 ,handle))
(defmacro mm-handle-cache (handle)
  `(nth 6 ,handle))
(defmacro mm-handle-set-cache (handle contents)
  `(setcar (nthcdr 6 ,handle) ,contents))
(defmacro mm-handle-id (handle)
  `(nth 7 ,handle))
(defmacro mm-handle-multipart-original-buffer (handle)
  `(get-text-property 0 'buffer (car ,handle)))
(defmacro mm-handle-multipart-from (handle)
  `(get-text-property 0 'from (car ,handle)))
(defmacro mm-handle-multipart-ctl-parameter (handle parameter)
  `(get-text-property 0 ,parameter (car ,handle)))

(defmacro mm-make-handle (&optional buffer type encoding undisplayer
				    disposition description cache
				    id)
  `(list ,buffer ,type ,encoding ,undisplayer
	 ,disposition ,description ,cache ,id))

(defcustom mm-text-html-renderer
  (cond ((fboundp 'libxml-parse-html-region) 'shr)
	((executable-find "w3m") 'gnus-w3m)
	((executable-find "links") 'links)
        ((executable-find "lynx") 'lynx)
        (t 'shr))
  "Renderer of HTML contents.
It is one of defined renderer types, or a rendering function.
The defined renderer types are:
`shr': use the built-in Gnus HTML renderer;
`gnus-w3m': use Gnus renderer based on w3m;
`w3m': use emacs-w3m;
`w3m-standalone': use plain w3m;
`links': use links;
`lynx': use lynx."
  :version "29.1"
  :type '(choice (const shr)
                 (const gnus-w3m)
                 (const :tag "emacs-w3m" w3m)
                 (const :tag "standalone w3m" w3m-standalone)
		 (const links)
		 (const lynx)
		 (function))
  :group 'mime-display)

(defcustom mm-html-inhibit-images nil
  "Non-nil means inhibit displaying of images inline in the article body."
  :version "25.1"
  :type 'boolean
  :group 'mime-display)

(defcustom mm-html-blocked-images ""
  "Regexp matching image URLs to be blocked, or nil meaning not to block.
Note that cid images that are embedded in a message won't be blocked."
  :version "25.1"
  :type '(choice (const :tag "Allow all" nil)
		 (regexp :tag "Regular expression"))
  :group 'mime-display)

(defcustom mm-w3m-safe-url-regexp "\\`cid:"
  "Regexp matching URLs which are considered to be safe.
Some HTML mails might contain a nasty trick used by spammers, using
the <img> tag which is far more evil than the [Click Here!] button.
It is most likely intended to check whether the ominous spam mail has
reached your eyes or not, in which case the spammer knows for sure
that your email address is valid.  It is done by embedding an
identifier string into a URL that you might automatically retrieve
when displaying the image.  The default value is \"\\\\`cid:\" which only
matches parts embedded to the Multipart/Related type MIME contents and
Gnus will never connect to the spammer's site arbitrarily.  You may
set this variable to nil if you consider all urls to be safe."
  :version "22.1"
  :type '(choice (regexp :tag "Regexp")
		 (const :tag "All URLs are safe" nil))
  :group 'mime-display)

(defcustom mm-inline-text-html-with-w3m-keymap t
  "If non-nil, use emacs-w3m command keys in the article buffer."
  :version "22.1"
  :type 'boolean
  :group 'mime-display)

(defcustom mm-enable-external t
  "Indicate whether external MIME handlers should be used.

If t, all defined external MIME handlers are used.  If nil, files are saved by
`mailcap-save-binary-file'.  If it is the symbol `ask', you are prompted
before the external MIME handler is invoked."
  :version "22.1"
  :type '(choice (const :tag "Always" t)
		 (const :tag "Never" nil)
		 (const :tag "Ask" ask))
  :group 'mime-display)

(defcustom mm-inline-media-tests
  `(("image/p?jpeg"
     mm-inline-image
     ,(lambda (handle)
        (mm-valid-and-fit-image-p 'jpeg handle)))
    ("image/webp"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'webp handle)))
    ("image/png"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'png handle)))
    ("image/gif"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'gif handle)))
    ("image/tiff"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'tiff handle)))
    ("image/xbm"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'xbm handle)))
    ("image/x-xbitmap"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'xbm handle)))
    ("image/xpm"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'xpm handle)))
    ("image/x-xpixmap"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'xpm handle)))
    ("image/bmp"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'bmp handle)))
    ("image/x-portable-bitmap"
     mm-inline-image
     ,(lambda (handle)
       (mm-valid-and-fit-image-p 'pbm handle)))
    ("image/svg\\+xml"
     mm-inline-image
     ,(lambda (handle)
        (mm-valid-and-fit-image-p 'svg handle)))
    ("text/plain" mm-inline-text identity)
    ("text/enriched" mm-inline-text identity)
    ("text/richtext" mm-inline-text identity)
    ("text/x-patch" mm-display-patch-inline identity)
    ;; In case mime.types uses x-diff (as does Debian's mime-support-3.40).
    ("text/x-diff" mm-display-patch-inline identity)
    ("application/x-patch" mm-display-patch-inline identity)
    ("application/emacs-lisp" mm-display-elisp-inline identity)
    ("application/x-emacs-lisp" mm-display-elisp-inline identity)
    ("application/x-shellscript" mm-display-shell-script-inline identity)
    ("application/x-sh" mm-display-shell-script-inline identity)
    ("text/x-sh" mm-display-shell-script-inline identity)
    ("application/javascript" mm-display-javascript-inline identity)
    ("text/dns" mm-display-dns-inline identity)
    ("text/x-org" mm-display-org-inline identity)
    ("text/html"
     mm-inline-text-html
     ,(lambda (_handle)
       mm-text-html-renderer))
    ("text/x-vcard"
     mm-inline-text-vcard
     ,(lambda (_handle)
       (or (featurep 'vcard)
	   (locate-library "vcard"))))
    ("text/calendar" gnus-icalendar-mm-inline identity)
    ("message/delivery-status" mm-inline-text identity)
    ("message/rfc822" mm-inline-message identity)
    ("message/partial" mm-inline-partial identity)
    ("message/external-body" mm-inline-external-body identity)
    ("text/.*" mm-inline-text identity)
    ("application/x-.?tar\\(-.*\\)?" mm-archive-dissect-and-inline identity)
    ("application/zip" mm-archive-dissect-and-inline identity)
    ("application/pgp-signature" ignore identity)
    ("application/x-pkcs7-signature" ignore identity)
    ("application/pkcs7-signature" ignore identity)
    ("application/x-pkcs7-mime" ignore identity)
    ("application/pkcs7-mime" ignore identity)
    ("multipart/alternative" ignore identity)
    ("multipart/mixed" ignore identity)
    ("multipart/related" ignore identity)
    ("image/.*"
     mm-inline-image
     ,(lambda (handle)
       (and (mm-valid-image-format-p 'imagemagick)
	    (mm-with-unibyte-buffer
	      (mm-insert-part handle)
	      (let ((image
		     (ignore-errors
		       (create-image (buffer-string) 'imagemagick 'data-p))))
		(when image
		  (setcar (cdr handle) (list "image/imagemagick"))
		  (mm-image-fit-p handle)))))))
    ;; Disable audio and image
    ("audio/.*" ignore ignore)
    ("image/.*" ignore ignore)
    ;; Default to displaying as text
    (".*" mm-inline-text mm-readable-p))
  "Alist of media types/tests saying whether types can be displayed inline."
  :type '(repeat (list (regexp :tag "MIME type")
		       (function :tag "Display function")
		       (function :tag "Display test")))
  :group 'mime-display)

(defcustom mm-inlined-types
  '("image/.*" "text/.*" "message/delivery-status" "message/rfc822"
    "message/partial" "message/external-body"
    "application/x-patch"
    "application/emacs-lisp" "application/x-emacs-lisp"
    "application/pgp-signature" "application/x-pkcs7-signature"
    "application/pkcs7-signature" "application/x-pkcs7-mime"
    "application/pkcs7-mime"
    "application/x-gtar-compressed"
    "application/x-tar"
    "application/zip"
    ;; Mutt still uses this even though it has already been withdrawn.
    "application/pgp")
  "List of media types that are to be displayed inline.
See also `mm-inline-media-tests', which says how to display a media
type inline."
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-keep-viewer-alive-types
  '("application/postscript" "application/msword" "application/vnd.ms-excel"
    "application/pdf" "application/x-dvi"
    "application/vnd.*")
  "Media types for viewers not to be killed when selecting a different article.
Instead the viewers will be killed on Gnus exit instead.  This is
a list of regexps."
  :version "27.1"
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-automatic-display
  '("text/plain" "text/enriched" "text/richtext" "text/html" "text/x-verbatim"
    "text/calendar"
    "text/x-vcard" "image/.*" "message/delivery-status" "multipart/.*"
    "message/rfc822" "text/x-patch" "text/dns" "application/pgp-signature"
    "application/emacs-lisp" "application/x-emacs-lisp"
    "application/x-pkcs7-signature"
    "application/pkcs7-signature" "application/x-pkcs7-mime"
    "application/pkcs7-mime"
    ;; Mutt still uses this even though it has already been withdrawn.
    "application/pgp\\'"
     "text/x-org")
  "A list of MIME types to be displayed automatically."
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-attachment-override-types '("text/x-vcard"
					  "application/pkcs7-mime"
					  "application/x-pkcs7-mime"
					  "application/pkcs7-signature"
					  "application/x-pkcs7-signature")
  "Types to have \"attachment\" ignored if they can be displayed inline."
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-inline-override-types nil
  "Types to be treated as attachments even if they can be displayed inline."
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-automatic-external-display nil
  "List of MIME type regexps that will be displayed externally automatically."
  :type '(repeat regexp)
  :group 'mime-display)

(defcustom mm-discouraged-alternatives nil
  "List of MIME types that are discouraged when viewing multipart/alternative.
Viewing agents are supposed to view the last possible part of a message,
as that is supposed to be the richest.  However, users may prefer other
types instead, and this list says what types are most unwanted.  If,
for instance, text/html parts are very unwanted, and text/richtext are
somewhat unwanted, then the value of this variable should be set
to:

 (\"text/html\" \"text/richtext\")

Adding \"image/.*\" might also be useful.  Spammers use it as the
preferred part of multipart/alternative messages.  See also
`gnus-buttonized-mime-types', to which adding \"multipart/alternative\"
enables you to choose manually one of two types those mails include."
  :type '(repeat regexp) ;; See `mm-preferred-alternative-precedence'.
  :group 'mime-display)

(defcustom mm-tmp-directory temporary-file-directory
  "Where mm will store its temporary files."
  :type 'directory
  :group 'mime-display)

(defcustom mm-inline-large-images 'resize
  "If nil, images larger than the window aren't displayed in the buffer.
If `resize', try to resize the images so they fit in the buffer.
If t, show the images as they are without resizing."
  :version "27.1"
  :type '(radio
          (const :tag "Inline large images as they are." t)
          (const :tag "Resize large images." resize)
          (const :tag "Do not inline large images." nil))
  :group 'mime-display)

(defcustom mm-file-name-rewrite-functions
  '(mm-file-name-delete-control mm-file-name-delete-gotchas)
  "List of functions used for rewriting file names of MIME parts.
Each function takes a file name as input and returns a file name.

Ready-made functions include `mm-file-name-delete-control',
`mm-file-name-delete-gotchas' (you should not remove these two
functions), `mm-file-name-delete-whitespace',
`mm-file-name-trim-whitespace', `mm-file-name-collapse-whitespace',
`mm-file-name-replace-whitespace', `capitalize', `downcase',
`upcase', and `upcase-initials'."
  :type '(list (set :inline t
		    (const mm-file-name-delete-control)
		    (const mm-file-name-delete-gotchas)
		    (const mm-file-name-delete-whitespace)
		    (const mm-file-name-trim-whitespace)
		    (const mm-file-name-collapse-whitespace)
		    (const mm-file-name-replace-whitespace)
		    (const capitalize)
		    (const downcase)
		    (const upcase)
		    (const upcase-initials)
	       (repeat :inline t
		       :tag "Function"
		       function)))
  :version "23.1" ;; No Gnus
  :group 'mime-display)


(defcustom mm-path-name-rewrite-functions nil
  "List of functions for rewriting the full file names of MIME parts.
This is used when viewing parts externally, and is meant for
transforming the absolute name so that non-compliant programs can find
the file where it's saved.

Each function takes a file name as input and returns a file name."
  :type '(repeat function)
  :group 'mime-display)

(defvar mm-file-name-replace-whitespace nil
  "String used for replacing whitespace characters; default is `\"_\"'.")

(defcustom mm-default-directory nil
  "The default directory where mm will save files.
If not set, `default-directory' will be used."
  :type '(choice directory (const :tag "Default" nil))
  :group 'mime-display)

(defcustom mm-attachment-file-modes #o600
  "Set the mode bits of saved attachments to this integer.
This is decimal, not octal.  The default is 384 (0600 in octal)."
  :version "22.1"
  :type 'integer
  :group 'mime-display)

(defcustom mm-external-terminal-program '("xterm" "-e")
  "The program to start an external terminal.
This should be a list of strings."
  :version "29.1"
  :type '(choice string (repeat string))
  :group 'mime-display)

;;; Internal variables.

(defvar mm-last-shell-command "")
(defvar mm-content-id-alist nil)
(defvar mm-postponed-undisplay-list nil)
(defvar mm-inhibit-auto-detect-attachment nil)
(defvar mm-temp-files-to-be-deleted nil
  "List of temporary files scheduled to be deleted.")
(defvar mm-temp-files-cache-file (concat ".mm-temp-files-" (user-login-name))
  "Name of a file that caches a list of temporary files to be deleted.
The file will be saved in the directory `mm-tmp-directory'.")

;; According to RFC2046, in particular, in a digest, the default
;; Content-Type value for a body part is changed from "text/plain" to
;; "message/rfc822".
(defvar mm-dissect-default-type "text/plain")

(autoload 'mml2015-verify "mml2015")
(autoload 'mml2015-verify-test "mml2015")
(autoload 'mml-smime-verify "mml-smime")
(autoload 'mml-smime-verify-test "mml-smime")
(autoload 'mm-view-pkcs7-verify "mm-view")

(defvar mm-verify-function-alist
  '(("application/pgp-signature" mml2015-verify "PGP" mml2015-verify-test)
    ("application/x-gnus-pgp-signature" mm-uu-pgp-signed-extract-1 "PGP"
     mm-uu-pgp-signed-test)
    ("application/pkcs7-signature" mml-smime-verify "S/MIME"
     mml-smime-verify-test)
    ("application/x-pkcs7-signature" mml-smime-verify "S/MIME"
     mml-smime-verify-test)
    ("application/x-pkcs7-signature" mml-smime-verify "S/MIME"
     mml-smime-verify-test)
    ;; these are only used for security-buttons and contain the
    ;; smime-type after the underscore
    ("application/pkcs7-mime_signed-data" mm-view-pkcs7-verify "S/MIME"
     nil)
    ("application/x-pkcs7-mime_signed-data" mml-view-pkcs7-verify "S/MIME"
     nil)))

(defcustom mm-verify-option 'never
  "Option of verifying signed parts.
`never', not verify; `always', always verify;
`known', only verify known protocols.  Otherwise, ask user.

When set to `always' or `known', you should add
\"multipart/signed\" to `gnus-buttonized-mime-types' to see
result of the verification."
  :version "22.1"
  :type '(choice (item always)
		 (item never)
		 (item :tag "only known protocols" known)
		 (item :tag "ask" nil))
  :group 'mime-security)

(autoload 'mml2015-decrypt "mml2015")
(autoload 'mml2015-decrypt-test "mml2015")
(autoload 'mm-view-pkcs7-decrypt "mm-view")

(defvar mm-decrypt-function-alist
  '(("application/pgp-encrypted" mml2015-decrypt "PGP" mml2015-decrypt-test)
    ("application/x-gnus-pgp-encrypted" mm-uu-pgp-encrypted-extract-1 "PGP"
     mm-uu-pgp-encrypted-test)
    ;; these are only used for security-buttons and contain the
    ;; smime-type after the underscore
    ("application/pkcs7-mime_enveloped-data" mm-view-pkcs7-decrypt "S/MIME" nil)
    ("application/x-pkcs7-mime_enveloped-data"
     mm-view-pkcs7-decrypt "S/MIME" nil)))

(defcustom mm-decrypt-option nil
  "Option of decrypting encrypted parts.
`never', not decrypt; `always', always decrypt;
`known', only decrypt known protocols.  Otherwise, ask user."
  :version "22.1"
  :type '(choice (item always)
		 (item never)
		 (item :tag "only known protocols" known)
		 (item :tag "ask" nil))
  :group 'mime-security)

(defvar-keymap mm-viewer-completion-map
  :doc "Keymap for input viewer with completion."
  :parent minibuffer-local-completion-map
  ;; Should we bind other key to minibuffer-complete-word?
  "SPC" #'self-insert-command)

;;; The functions.

(defun mm-alist-to-plist (alist)
  "Convert association list ALIST into the equivalent property-list form.
The plist is returned.  This converts from

\((a . 1) (b . 2) (c . 3))

into

\(a 1 b 2 c 3)

The original alist is not modified."
  (let (plist)
    (while alist
      (let ((el (car alist)))
	(setq plist (cons (cdr el) (cons (car el) plist))))
      (setq alist (cdr alist)))
    (nreverse plist)))

(defun mm-keep-viewer-alive-p (handle)
  "Say whether external viewer for HANDLE should stay alive."
  (let ((types mm-keep-viewer-alive-types)
	(type (mm-handle-media-type handle))
	ty)
    (catch 'found
      (while (setq ty (pop types))
	(when (string-match ty type)
	  (throw 'found t))))))

(defun mm-handle-set-external-undisplayer (handle function)
  "Set the undisplayer for HANDLE to FUNCTION.
Postpone undisplaying of viewers for types in
`mm-keep-viewer-alive-types'."
  (if (mm-keep-viewer-alive-p handle)
      (let ((new-handle (copy-sequence handle)))
	(mm-handle-set-undisplayer new-handle function)
	(mm-handle-set-undisplayer handle nil)
	(push new-handle mm-postponed-undisplay-list))
    (mm-handle-set-undisplayer handle function)))

(defun mm-destroy-postponed-undisplay-list ()
  (when mm-postponed-undisplay-list
    (message "Destroying external MIME viewers")
    (mm-destroy-parts mm-postponed-undisplay-list)))

(defun mm-temp-files-delete ()
  "Delete temporary files and those parent directories.
Note that the deletion may fail if a program is catching hold of a file
under Windows or Cygwin.  In that case, it schedules the deletion of
files left at the next time."
  (let* ((coding-system-for-read mm-universal-coding-system)
	 (coding-system-for-write mm-universal-coding-system)
	 (cache-file (expand-file-name mm-temp-files-cache-file
				       mm-tmp-directory))
	 (cache (when (file-exists-p cache-file)
		  (mm-with-multibyte-buffer
		    (insert-file-contents cache-file)
		    (split-string (buffer-string) "\n" t))))
	 fails)
    (dolist (temp (append cache mm-temp-files-to-be-deleted))
      (when (and (file-exists-p temp)
		 (if (file-directory-p temp)
		     ;; A parent directory left at the previous time.
		     (progn
		       (ignore-errors (delete-directory temp))
		       (file-exists-p temp))
		   ;; Delete a temporary file and its parent directory.
		   (ignore-errors (delete-file temp))
		   (or (file-exists-p temp)
		       (progn
			 (setq temp (file-name-directory temp))
			 (ignore-errors (delete-directory temp))
			 (file-exists-p temp)))))
	(push temp fails)))
    (if fails
	;; Schedule the deletion of the files left at the next time.
	(with-file-modes #o600
	  (write-region (concat (mapconcat #'identity (nreverse fails) "\n")
				"\n")
			nil cache-file nil 'silent))
      (when (file-exists-p cache-file)
	(ignore-errors (delete-file cache-file))))
    (setq mm-temp-files-to-be-deleted nil)))

(autoload 'message-fetch-field "message")

(defun mm-dissect-buffer (&optional no-strict-mime loose-mime from)
  "Dissect the current buffer and return a list of MIME handles.
If NO-STRICT-MIME, don't require the message to have a
MIME-Version header before proceeding."
  (save-excursion
    (let (ct ctl type subtype cte cd description id result)
      (save-restriction
	(mail-narrow-to-head)
	(when (or no-strict-mime
		  loose-mime
		  (mail-fetch-field "mime-version"))
	  (setq ct (mail-fetch-field "content-type")
		ctl (and ct (mail-header-parse-content-type ct))
		cte (mail-fetch-field "content-transfer-encoding")
                cd (or (mail-fetch-field "content-disposition")
                       (when (and ctl
                                  (eq 'mm-inline-text
                                      (cadr (mm-assoc-string-match
                                             mm-inline-media-tests
                                             (car ctl)))))
                         "inline"))
		;; Newlines in description should be stripped so as
		;; not to break the MIME tag into two or more lines.
		description (message-fetch-field "content-description")
		id (mail-fetch-field "content-id"))
	  (unless from
	    (setq from (mail-fetch-field "from")))
	  ;; FIXME: In some circumstances, this code is running within
	  ;; a unibyte macro.  mail-extract-address-components
	  ;; creates unibyte buffers. This `if', though not a perfect
	  ;; solution, avoids most of them.
	  (if from
	      (setq from (cadr (mail-extract-address-components from))))
	  (if description
	      (setq description (mail-decode-encoded-word-string
				 description)))))
      (if (or (not ctl)
	      (not (string-search "/" (car ctl))))
	  (mm-dissect-singlepart
	   (list mm-dissect-default-type)
	   (and cte (intern (downcase (mail-header-strip-cte cte))))
	   no-strict-mime
	   (and cd (mail-header-parse-content-disposition cd))
	   description)
	(setq type (split-string (car ctl) "/"))
	(setq subtype (cadr type)
	      type (car type))
	(setq
	 result
	 (cond
	  ((equal type "multipart")
	   (let ((mm-dissect-default-type (if (equal subtype "digest")
					      "message/rfc822"
					    "text/plain"))
		 (start (cdr (assq 'start (cdr ctl)))))
	     (add-text-properties 0 (length (car ctl))
				  (mm-alist-to-plist (cdr ctl)) (car ctl))

	     ;; what really needs to be done here is a way to link a
	     ;; MIME handle back to its parent MIME handle (in a multilevel
	     ;; MIME article).  That would probably require changing
	     ;; the mm-handle API so we simply store the multipart buffer
	     ;; name as a text property of the "multipart/whatever" string.
	     (add-text-properties 0 (length (car ctl))
				  (list 'buffer (mm-copy-to-buffer)
					'from from
					'start start)
				  (car ctl))
	     (cons (car ctl) (mm-dissect-multipart ctl from))))
          (t
           (let* ((handle
                   (mm-dissect-singlepart
                    ctl
                    (and cte (intern (downcase (mail-header-strip-cte cte))))
                    no-strict-mime
                    (and cd (mail-header-parse-content-disposition cd))
                    description id))
                  (intermediate-result
                   (mm-possibly-verify-or-decrypt handle ctl from)))
             (when (and (equal type "application")
                        (or (equal subtype "pkcs7-mime")
                            (equal subtype "x-pkcs7-mime")))
               (add-text-properties
                0 (length (car ctl))
                (list 'protocol
                      (concat (substring-no-properties (car ctl))
                              "_"
                              (cdr (assoc 'smime-type ctl))))
                (car ctl))
               ;; If this is a pkcs7-mime lets treat this special and
               ;; more like multipart so the pkcs7-mime part does not
               ;; get ignored.
               (setq intermediate-result
                     (cons (car ctl) (list intermediate-result))))
             intermediate-result))))
        (when id
          (when (string-match " *<\\(.*\\)> *" id)
            (setq id (match-string 1 id)))
	  (push (cons id result) mm-content-id-alist))
	result))))

(defun mm-dissect-singlepart (ctl cte &optional force cdl description id)
  (when (or force
	    (if (equal "text/plain" (car ctl))
		(assoc 'format ctl)
	      t))
    ;; Guess what the type of application/octet-stream parts should
    ;; really be.
    (let ((filename (cdr (assq 'filename (cdr cdl)))))
      (when (and (not mm-inhibit-auto-detect-attachment)
		 (equal (car ctl) "application/octet-stream")
		 filename
		 (string-match "\\.\\([^.]+\\)$" filename))
	(let ((new-type (mailcap-extension-to-mime (match-string 1 filename))))
	  (when new-type
	    (setcar ctl new-type)))))
    (let ((handle
	   (mm-make-handle
	    (mm-copy-to-buffer) ctl cte nil cdl description nil id))
	  (decoder (assoc (car ctl) (mm-archive-decoders))))
      (if (and decoder
	       ;; Do automatic decoding
	       (cadr decoder)
	       (executable-find (caddr decoder)))
	  (mm-dissect-archive handle)
	handle))))

(defun mm-dissect-multipart (ctl from)
  (goto-char (point-min))
  (let* ((boundary (concat "\n--" (mail-content-type-get ctl 'boundary)))
	 (close-delimiter (concat (regexp-quote boundary) "--[ \t]*$"))
	 start parts
	 (end (save-excursion
		(goto-char (point-max))
		(if (re-search-backward close-delimiter nil t)
		    (match-beginning 0)
		  (point-max))))
	 (mm-inhibit-auto-detect-attachment
	  (equal (car ctl) "multipart/encrypted")))
    (setq boundary (concat (regexp-quote boundary) "[ \t]*$"))
    (while (and (< (point) end) (re-search-forward boundary end t))
      (goto-char (match-beginning 0))
      (when start
	(save-excursion
	  (save-restriction
	    (narrow-to-region start (point))
	    (setq parts (nconc (list (mm-dissect-buffer t nil from)) parts)))))
      (end-of-line 2)
      (or (looking-at boundary)
	  (forward-line 1))
      (setq start (point)))
    (when (and start (< start end))
      (save-excursion
	(save-restriction
	  (narrow-to-region start end)
	  (setq parts (nconc (list (mm-dissect-buffer t nil from)) parts)))))
    (mm-possibly-verify-or-decrypt (nreverse parts) ctl from)))

(defun mm-copy-to-buffer ()
  "Copy the contents of the current buffer to a fresh buffer."
  (let ((obuf (current-buffer))
        (mb enable-multibyte-characters)
        beg)
    (goto-char (point-min))
    (search-forward-regexp "^\n" nil 'move) ;; There might be no body.
    (setq beg (point))
    (with-current-buffer
          (generate-new-buffer " *mm*")
      ;; Preserve the data's unibyteness (for url-insert-file-contents).
      (set-buffer-multibyte mb)
      (insert-buffer-substring obuf beg)
      (current-buffer))))

(defun mm-display-parts (handle)
  (cond
   ((stringp (car handle)) (mapcar #'mm-display-parts (cdr handle)))
   ((bufferp (car handle))
    (save-restriction
      (narrow-to-region (point) (point))
      (mm-display-part handle)
      (goto-char (point-max))))
   (t
    (mapcar #'mm-display-parts handle))))

(autoload 'mailcap-parse-mailcaps "mailcap")
(autoload 'mailcap-mime-info "mailcap")

(defun mm-head-p (&optional point)
  "Return non-nil if point is in the article header."
  (let ((point (or point (point))))
    (save-excursion
      (goto-char point)
      (and (not (re-search-backward "^$" nil t))
	   (re-search-forward "^$" nil t)))))

(defun mm-display-part (handle &optional no-default force)
  "Display the MIME part represented by HANDLE.
Returns nil if the part is removed; inline if displayed inline;
external if displayed external."
  (save-excursion
    (mailcap-parse-mailcaps)
    (if (and (not force)
	     (mm-handle-displayed-p handle))
	(mm-remove-part handle)
      (let* ((ehandle (if (equal (mm-handle-media-type handle)
				 "message/external-body")
			  (progn
			    (unless (mm-handle-cache handle)
			      (mm-extern-cache-contents handle))
			    (mm-handle-cache handle))
			handle))
	     (type (mm-handle-media-type ehandle))
	     (method (mailcap-mime-info type))
	     (filename (or (mail-content-type-get
			    (mm-handle-disposition handle) 'filename)
			   (mail-content-type-get
			    (mm-handle-type handle) 'name)
			   "<file>"))
	     (external mm-enable-external)
	     (decoder (assoc (car (mm-handle-type handle))
			     (mm-archive-decoders))))
	(cond
	 ((and decoder
	       (executable-find (caddr decoder)))
	  (mm-archive-dissect-and-inline handle)
	  'inline)
	 ((and (mm-inlinable-p ehandle)
	       (mm-inlined-p ehandle))
	  (when force
	    (if (mm-head-p)
		(re-search-forward "^$" nil t)
	      (forward-line 1)))
	  (mm-display-inline handle)
	  'inline)
	 ((or method
	      (not no-default))
	  (if (and (not method)
		   (equal "text" (car (split-string type "/"))))
	      (progn
		(forward-line 1)
		(mm-insert-inline handle (mm-get-part handle))
		'inline)
	    (setq external
		  (and method	      ;; If nil, we always use "save".
		       (or (eq mm-enable-external t)
			   (and (eq mm-enable-external 'ask)
				(y-or-n-p
				 (concat
				  "Display part (" type
				  ") "
				  (if (stringp method)
				      (concat
				       "using external program \""
				       (format method filename) "\"")
				    (format-message
				     "by calling `%s' on the contents)" method))
				  "? "))))))
	    (if external
		(mm-display-external
		 handle (or method 'mailcap-save-binary-file))
	      (mm-display-external
	       handle 'mailcap-save-binary-file)))))))))

(declare-function gnus-configure-windows "gnus-win" (setting &optional force))
(defvar mailcap-mime-extensions)	; mailcap-mime-info autoloads
(declare-function term-mode "term" ())
(declare-function term-char-mode "term" ())

(defun mm-display-external (handle method)
  "Display HANDLE using METHOD."
  (let ((outbuf (current-buffer)))
    (mm-with-unibyte-buffer
      (if (functionp method)
	  (let ((cur (current-buffer)))
	    (if (eq method 'mailcap-save-binary-file)
		(progn
		  (set-buffer (generate-new-buffer " *mm*"))
		  (setq method nil))
	      (mm-insert-part handle)
	      (mm-add-meta-html-tag handle)
	      (let ((win (get-buffer-window cur t)))
		(when win
		  (select-window win)))
	      (switch-to-buffer (generate-new-buffer " *mm*")))
	    (buffer-disable-undo)
	    (set-buffer-file-coding-system mm-binary-coding-system)
	    (insert-buffer-substring cur)
	    (goto-char (point-min))
	    (when method
	      (message "Viewing with %s" method))
	    (let ((mm (current-buffer))
		  (attachment-filename (mm-handle-filename handle))
		  (non-viewer (assq 'non-viewer
				    (mailcap-mime-info
				     (mm-handle-media-type handle) t))))
	      (unwind-protect
		  (if method
		      (progn
			(when (and (boundp 'gnus-summary-buffer)
                                   (buffer-live-p gnus-summary-buffer))
			  (when attachment-filename
			    (with-current-buffer mm
			      (rename-buffer
			       (format "*mm* %s" attachment-filename) t)))
			  ;; So that we pop back to the right place, sort of.
			  (switch-to-buffer gnus-summary-buffer)
			  (switch-to-buffer mm))
			(funcall method))
		    (mm-save-part handle))
		(when (and (not non-viewer)
			   method)
		  (mm-handle-set-undisplayer handle mm)))))
	;; The function is a string to be executed.
	(mm-insert-part handle)
	(mm-add-meta-html-tag handle)
	;; We create a private sub-directory where we store our files.
	(let* ((dir (with-file-modes #o700
		      (make-temp-file
		       (expand-file-name "emm." mm-tmp-directory) 'dir)))
	       (filename (or
			  (mail-content-type-get
			   (mm-handle-disposition handle) 'filename)
			  (mail-content-type-get
			   (mm-handle-type handle) 'name)))
	       (mime-info (mailcap-mime-info
			   (mm-handle-media-type handle) t))
	       (needsterm (or (assoc "needsterm" mime-info)
			      (assoc "needsterminal" mime-info)))
	       (copiousoutput (assoc "copiousoutput" mime-info))
	       file buffer)
	  (if filename
	      (setq file (expand-file-name
			  (gnus-map-function mm-file-name-rewrite-functions
					     (file-name-nondirectory filename))
			  dir))
	    ;; Use nametemplate (defined in RFC1524) if it is specified
	    ;; in mailcap.
	    (let ((suffix (cdr (assoc "nametemplate" mime-info))))
	      (if (and suffix
		       (string-match "\\`%s\\(\\..+\\)\\'" suffix))
		  (setq suffix (match-string 1 suffix))
		;; Otherwise, use a suffix according to
		;; `mailcap-mime-extensions'.
		(setq suffix (car (rassoc (mm-handle-media-type handle)
					  mailcap-mime-extensions))))
	      (setq file (with-file-modes #o600
			   (make-temp-file (expand-file-name "mm." dir)
					   nil suffix)))))
	  (let ((coding-system-for-write mm-binary-coding-system))
	    (write-region (point-min) (point-max) file nil 'nomesg))
	  ;; The file is deleted after the viewer exists.  If the users edits
	  ;; the file, changes will be lost.  Set file to read-only to make it
	  ;; clear.
	  (set-file-modes file #o400 'nofollow)
	  (message "Viewing with %s" method)
	  (cond
	   (needsterm
	    (let ((command (mm-mailcap-command
			    method file (mm-handle-type handle))))
	      (unwind-protect
		  (if window-system
		      (set-process-sentinel
		       (apply #'start-process "*display*" nil
                              (append
                               (if (listp mm-external-terminal-program)
                                   mm-external-terminal-program
                                 ;; Be backwards-compatible.
                                 (list mm-external-terminal-program
                                       "-e"))
                               (list shell-file-name
				     shell-command-switch
                                     command)))
		       (lambda (process _state)
			 (if (eq 'exit (process-status process))
			     (run-at-time
			      60.0 nil
			      (lambda ()
				(ignore-errors (delete-file file))
				(ignore-errors (delete-directory
						(file-name-directory
						 file))))))))
		    (require 'term)
		    (require 'gnus-win)
		    (set-buffer
		     (setq buffer
			   (make-term "display"
				      shell-file-name
				      nil
				      shell-command-switch command)))
		    (term-mode)
		    (term-char-mode)
		    (set-process-sentinel
		     (get-buffer-process buffer)
                     (let ((wc gnus-current-window-configuration))
		       (lambda (process _state)
			 (when (eq 'exit (process-status process))
			   (ignore-errors (delete-file file))
			   (ignore-errors
			     (delete-directory (file-name-directory file)))
			   (gnus-configure-windows wc)))))
		    (gnus-configure-windows 'display-term))
		(mm-handle-set-external-undisplayer handle (cons file buffer))
		(add-to-list 'mm-temp-files-to-be-deleted file t))
	      (message "Displaying %s..." command))
	    'external)
	   (copiousoutput
	    (with-current-buffer outbuf
	      (forward-line 1)
	      (mm-insert-inline
	       handle
	       (unwind-protect
		   (progn
		     (call-process shell-file-name nil
				   (setq buffer
					 (generate-new-buffer " *mm*"))
				   nil
				   shell-command-switch
				   (mm-mailcap-command
				    method file (mm-handle-type handle)))
		     (if (buffer-live-p buffer)
			 (with-current-buffer buffer
			   (buffer-string))))
		 (progn
		   (ignore-errors (delete-file file))
		   (ignore-errors (delete-directory
				   (file-name-directory file)))
		   (ignore-errors (kill-buffer buffer))))))
	    'inline)
	   (t
	    ;; Deleting the temp file should be postponed for some wrappers,
	    ;; shell scripts, and so on, which might exit right after having
	    ;; started a viewer command as a background job.
	    (let ((command (mm-mailcap-command
			    method file (mm-handle-type handle))))
	      (unwind-protect
		  (let ((process-connection-type nil))
		    (start-process "*display*"
				   (setq buffer
					 (generate-new-buffer " *mm*"))
				   shell-file-name
				   shell-command-switch command)
		    (set-process-sentinel
		     (get-buffer-process buffer)
		     (lambda (process _state)
		       (when (eq (process-status process) 'exit)
			 (run-at-time
			  60.0 nil
			  (lambda ()
			    (ignore-errors (delete-file file))
			    (ignore-errors (delete-directory
					    (file-name-directory file)))))
			 (when (buffer-live-p outbuf)
			   (with-current-buffer outbuf
			     (let ((buffer-read-only nil)
				   (point (point)))
			       (forward-line 2)
			       (let ((start (point)))
				 (mm-insert-inline
				  handle (with-current-buffer buffer
					   (buffer-string)))
				 (put-text-property start (point)
						    'face 'mm-command-output))
			       (goto-char point))))
			 (when (buffer-live-p buffer)
			   (kill-buffer buffer)))
		       (message "Displaying %s...done" command))))
		(mm-handle-set-external-undisplayer
		 handle (cons file buffer))
		(add-to-list 'mm-temp-files-to-be-deleted file t))
	      (message "Displaying %s..." command))
	    'external)))))))

(defun mm-mailcap-command (method file type-list)
  (let ((ctl (cdr type-list))
	(beg 0)
	(uses-stdin t)
	out sub total)
    (while (string-match "%{\\([^}]+\\)}\\|'%s'\\|\"%s\"\\|%s\\|%t\\|%%"
			 method beg)
      (push (substring method beg (match-beginning 0)) out)
      (setq beg (match-end 0)
	    total (match-string 0 method)
	    sub (match-string 1 method))
      (cond
       ((string= total "%%")
	(push "%" out))
       ((or (string= total "%s")
	    ;; We do our own quoting.
	    (string= total "'%s'")
	    (string= total "\"%s\""))
	(setq uses-stdin nil)
	(push (shell-quote-argument
	       (gnus-map-function mm-path-name-rewrite-functions file))
	      out))
       ((string= total "%t")
	(push (shell-quote-argument (car type-list)) out))
       (t
	(push (shell-quote-argument (or (cdr (assq (intern sub) ctl)) "")) out))))
    (push (substring method beg (length method)) out)
    (when uses-stdin
      (push "<" out)
      (push (shell-quote-argument
	     (gnus-map-function mm-path-name-rewrite-functions file))
	    out))
    (mapconcat #'identity (nreverse out) "")))

(defun mm-remove-parts (handles)
  "Remove the displayed MIME parts represented by HANDLES."
  (if (and (listp handles)
	   (bufferp (car handles)))
      (mm-remove-part handles)
    (let (handle)
      (while (setq handle (pop handles))
	(cond
	 ((stringp handle)
	  (when (buffer-live-p (get-text-property 0 'buffer handle))
	    (kill-buffer (get-text-property 0 'buffer handle))))
	 ((and (listp handle)
	       (stringp (car handle)))
	  (mm-remove-parts (cdr handle)))
	 (t
	  (mm-remove-part handle)))))))

(defun mm-destroy-parts (handles)
  "Destroy the displayed MIME parts represented by HANDLES."
  (if (and (listp handles)
	   (bufferp (car handles)))
      (mm-destroy-part handles)
    (let (handle)
      (while (setq handle (pop handles))
	(cond
	 ((stringp handle)
	  (when (buffer-live-p (get-text-property 0 'buffer handle))
	    (kill-buffer (get-text-property 0 'buffer handle))))
	 ((and (listp handle)
	       (stringp (car handle)))
	  (mm-destroy-parts handle))
	 (t
	  (mm-destroy-part handle)))))))

(defun mm-remove-part (handle)
  "Remove the displayed MIME part represented by HANDLE."
  (when (listp handle)
    (let ((object (mm-handle-undisplayer handle)))
      (ignore-errors
	(cond
	 ;; Internally displayed part.
	 ((or (functionp object)
	      (and (listp object)
		   (eq (car object) 'lambda)))
	  (funcall object))
	 ;; Externally displayed part.
	 ((consp object)
	  (condition-case ()
	      (while (get-buffer-process (cdr object))
		(interrupt-process (get-buffer-process (cdr object)))
		(message "Waiting for external displayer to die...")
		(sit-for 1))
	    (quit)
	    (error))
	  (ignore-errors (and (cdr object) (kill-buffer (cdr object))))
	  (message "Waiting for external displayer to die...done")
	  (ignore-errors (delete-file (car object)))
	  (ignore-errors (delete-directory (file-name-directory
					    (car object)))))
         ((buffer-live-p object)
          (kill-buffer object))))
      (mm-handle-set-undisplayer handle nil))))

(defun mm-display-inline (handle)
  (let* ((type (mm-handle-media-type handle))
	 (function (cadr (mm-assoc-string-match mm-inline-media-tests type))))
    (funcall function handle)
    (goto-char (point-min))))

(defun mm-assoc-string-match (alist type)
  (cl-dolist (elem alist)
    (when (string-match (car elem) type)
      (cl-return elem))))

(defun mm-automatic-display-p (handle)
  "Say whether the user wants HANDLE to be displayed automatically."
  (let ((methods mm-automatic-display)
	(type (mm-handle-media-type handle))
	method result)
    (while (setq method (pop methods))
      (when (and (not (mm-inline-override-p handle))
		 (string-match method type))
	(setq result t
	      methods nil)))
    result))

(defun mm-inlinable-p (handle &optional type)
  "Say whether HANDLE can be displayed inline.
TYPE is the mime-type of the object; it defaults to the one given
in HANDLE."
  (unless type (setq type (mm-handle-media-type handle)))
  (let ((alist mm-inline-media-tests)
	test)
    (while alist
      (when (string-match (caar alist) type)
	(setq test (caddar alist)
	      alist nil)
	(setq test (funcall test handle)))
      (pop alist))
    test))

(defun mm-inlined-p (handle)
  "Say whether the user wants HANDLE to be displayed inline."
  (let ((methods mm-inlined-types)
	(type (mm-handle-media-type handle))
	method result)
    (while (setq method (pop methods))
      (when (and (not (mm-inline-override-p handle))
		 (string-match method type))
	(setq result t
	      methods nil)))
    result))

(defun mm-attachment-override-p (handle)
  "Say whether HANDLE should have attachment behavior overridden."
  (let ((types mm-attachment-override-types)
	(type (mm-handle-media-type handle))
	ty)
    (catch 'found
      (while (setq ty (pop types))
	(when (and (string-match ty type)
		   (mm-inlinable-p handle))
	  (throw 'found t))))))

(defun mm-inline-override-p (handle)
  "Say whether HANDLE should have inline behavior overridden."
  (let ((types mm-inline-override-types)
	(type (mm-handle-media-type handle))
	ty)
    (catch 'found
      (while (setq ty (pop types))
	(when (string-match ty type)
	  (throw 'found t))))))

(defun mm-automatic-external-display-p (type)
  "Return the user-defined method for TYPE."
  (let ((methods mm-automatic-external-display)
	method result)
    (while (setq method (pop methods))
      (when (string-match method type)
	(setq result t
	      methods nil)))
    result))

(defun mm-destroy-part (handle)
  "Destroy the data structures connected to HANDLE."
  (when (listp handle)
    (mm-remove-part handle)
    (when (buffer-live-p (mm-handle-buffer handle))
      (kill-buffer (mm-handle-buffer handle)))))

(defun mm-handle-displayed-p (handle)
  "Say whether HANDLE is displayed or not."
  (mm-handle-undisplayer handle))

;;;
;;; Functions for outputting parts
;;;

(defmacro mm-with-part (handle &rest forms)
  "Run FORMS in the temp buffer containing the contents of HANDLE."
  (declare (indent 1) (debug t))
  ;; The handle-buffer's content is a sequence of bytes, not a sequence of
  ;; chars, so the buffer should be unibyte.  It may happen that the
  ;; handle-buffer is multibyte for some reason, in which case now is a good
  ;; time to adjust it, since we know at this point that it should
  ;; be unibyte.
  `(let* ((handle ,handle))
     (when (and (mm-handle-buffer handle)
		(buffer-name (mm-handle-buffer handle)))
       (with-temp-buffer
	 (mm-disable-multibyte)
	 (insert-buffer-substring (mm-handle-buffer handle))
	 (mm-decode-content-transfer-encoding
	  (mm-handle-encoding handle)
	  (mm-handle-media-type handle))
	 ,@forms))))

(defun mm-get-part (handle &optional no-cache)
  "Return the contents of HANDLE as a string.
If NO-CACHE is non-nil, cached contents of a message/external-body part
are ignored."
  (if (and (not no-cache)
	   (equal (mm-handle-media-type handle) "message/external-body"))
      (progn
	(unless (mm-handle-cache handle)
	  (mm-extern-cache-contents handle))
	(with-current-buffer (mm-handle-buffer (mm-handle-cache handle))
	  (buffer-string)))
    (mm-with-part handle
      (buffer-string))))

(defun mm-insert-part (handle &optional no-cache)
  "Insert the contents of HANDLE in the current buffer.
If NO-CACHE is non-nil, cached contents of a message/external-body part
are ignored."
  (let ((text (cond ((eq (mail-content-type-get (mm-handle-type handle)
						'charset)
			 'gnus-decoded)
		     (with-current-buffer (mm-handle-buffer handle)
		       (buffer-string)))
		    (t
		     (mm-get-part handle no-cache)))))
    (save-restriction
      (widen)
      (goto-char
       (prog1
	   (point)
	 (if (and (eq (get-char-property (max (point-min) (1- (point))) 'face)
		      'mm-uu-extract)
		  (eq (get-char-property 0 'face text) 'mm-uu-extract))
	     ;; Separate the extracted parts that have the same faces.
	     (insert "\n" text)
	   (insert text)))))))

(defun mm-file-name-delete-whitespace (file-name)
  "Remove all whitespace characters from FILE-NAME."
  (while (string-match "\\s-+" file-name)
    (setq file-name (replace-match "" t t file-name)))
  file-name)

(defun mm-file-name-trim-whitespace (file-name)
  "Remove leading and trailing whitespace characters from FILE-NAME."
  (when (string-match "\\`\\s-+" file-name)
    (setq file-name (substring file-name (match-end 0))))
  (when (string-match "\\s-+\\'" file-name)
    (setq file-name (substring file-name 0 (match-beginning 0))))
  file-name)

(defun mm-file-name-collapse-whitespace (file-name)
  "Collapse multiple whitespace characters in FILE-NAME."
  (while (string-match "\\s-\\s-+" file-name)
    (setq file-name (replace-match " " t t file-name)))
  file-name)

(defun mm-file-name-replace-whitespace (file-name)
  "Replace whitespace characters in FILE-NAME with underscores.
Set the option `mm-file-name-replace-whitespace' to any other
string if you do not like underscores."
  (let ((s (or mm-file-name-replace-whitespace "_")))
    (while (string-match "\\s-" file-name)
      (setq file-name (replace-match s t t file-name))))
  file-name)

(defun mm-file-name-delete-control (filename)
  "Delete control characters from FILENAME."
  (replace-regexp-in-string "[\x00-\x1f\x7f]" "" filename))

(defun mm-file-name-delete-gotchas (filename)
  "Delete shell gotchas from FILENAME."
  (setq filename (replace-regexp-in-string "[<>|]" "" filename))
  (replace-regexp-in-string "^[.-]+" "" filename))

(defun mm-save-part (handle &optional prompt)
  "Write HANDLE to a file.
PROMPT overrides the default one used to ask user for a file name."
  (let ((filename (or (mail-content-type-get
		       (mm-handle-disposition handle) 'filename)
		      (mail-content-type-get
		       (mm-handle-type handle) 'name)))
	file directory)
    (when filename
      (setq filename (gnus-map-function mm-file-name-rewrite-functions
					(file-name-nondirectory filename))))
    (while
	(progn
	  (setq file
		(read-file-name
		 (or prompt
		     (format-prompt "Save MIME part to" filename))
		 (or directory mm-default-directory default-directory)
		 (expand-file-name
		  (or filename "")
		  (or directory mm-default-directory default-directory))))
	  (cond ((or (not file) (equal file ""))
		 (message "Please enter a file name")
		 t)
		((and (file-directory-p file)
		      (not filename))
		 (setq directory file)
		 (message "Please enter a non-directory file name")
		 t)
		(t nil)))
      (sit-for 2)
      (discard-input))
    (if (file-directory-p file)
	(setq file (expand-file-name filename file))
      (setq file (expand-file-name
		  file (or mm-default-directory default-directory))))
    (setq mm-default-directory (file-name-directory file))
    (and (or (not (file-exists-p file))
	     (yes-or-no-p (format "File %s already exists; overwrite? "
				  file)))
	 (progn
	   (mm-save-part-to-file handle file)
	   file))))

(defun mm-add-meta-html-tag (handle &optional charset force-charset)
  "Add meta html tag to specify CHARSET of HANDLE in the current buffer.
CHARSET defaults to the one HANDLE specifies.  Existing meta tag that
specifies charset will not be modified unless FORCE-CHARSET is non-nil.
Return t if meta tag is added or replaced."
  (when (equal (mm-handle-media-type handle) "text/html")
    (when (or charset
	      (setq charset (mail-content-type-get (mm-handle-type handle)
						   'charset)))
      (setq charset (format "\
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=%s\">" charset))
      (let ((case-fold-search t))
	(goto-char (point-min))
	(if (re-search-forward "\
<meta\\s-+http-equiv=[\"']?content-type[\"']?\\s-+content=[\"']?\
text/html\\(?:;\\s-*charset=\\([^\t\n\r \"'>]+\\)\\)?[^>]*>" nil t)
	    (if (and (not force-charset)
		     (match-beginning 1))
		;; Don't modify existing meta tag.
		nil
	      ;; Replace it with the one specifying charset.
	      (replace-match charset)
	      t)
	  (if (re-search-forward "<head>\\s-*" nil t)
	      (insert charset "\n")
	    (re-search-forward "<html\\(?:\\s-+[^>]+\\|\\s-*\\)>\\s-*" nil t)
	    (insert "<head>\n" charset "\n</head>\n"))
	  t)))))

(defun mm-save-part-to-file (handle file)
  (mm-with-unibyte-buffer
    (mm-insert-part handle)
    (mm-add-meta-html-tag handle)
    (let ((current-file-modes (default-file-modes)))
      (set-default-file-modes mm-attachment-file-modes)
      (unwind-protect
	  ;; Don't re-compress .gz & al.  Arguably we should make
	  ;; `file-name-handler-alist' nil, but that would chop
	  ;; ange-ftp, which is reasonable to use here.
	  (mm-write-region (point-min) (point-max) file nil nil nil 'binary t)
	(set-default-file-modes current-file-modes)))))

(defun mm-pipe-part (handle &optional cmd)
  "Pipe HANDLE to a process.
Use CMD as the process."
  (let ((command (or cmd
		     (read-shell-command
		      "Shell command on MIME part: " mm-last-shell-command))))
    (mm-with-unibyte-buffer
      (mm-insert-part handle)
      (mm-add-meta-html-tag handle)
      (let ((coding-system-for-write 'binary))
	(shell-command-on-region (point-min) (point-max) command nil)))))

(autoload 'gnus-completing-read "gnus-util")

(defun mm-interactively-view-part (handle)
  "Display HANDLE using METHOD."
  (let* ((type (mm-handle-media-type handle))
	 (methods
	  (mapcar (lambda (i) (cdr (assoc 'viewer i)))
		  (mailcap-mime-info type 'all)))
	 (method (let ((minibuffer-local-completion-map
			mm-viewer-completion-map))
		   (completing-read "Viewer: " methods))))
    (when (string= method "")
      (error "No method given"))
    (if (string-match "^[^% \t]+$" method)
	(setq method (concat method " %s")))
    (mm-display-external handle method)))

(defun mm-preferred-alternative (handles &optional preferred)
  "Say which of HANDLES are preferred."
  (let ((prec (if preferred (list preferred)
		(mm-preferred-alternative-precedence handles)))
	p h result type handle)
    (while (setq p (pop prec))
      (setq h handles)
      (while h
	(setq handle (car h))
	(setq type (mm-handle-media-type handle))
	(when (and (equal p type)
		   (mm-automatic-display-p handle)
		   (or (stringp (car handle))
		       (not (mm-handle-disposition handle))
		       (equal (car (mm-handle-disposition handle))
			      "inline")))
	  (setq result handle
		h nil
		prec nil))
	(pop h)))
    result))

(defun mm-preferred-alternative-precedence (handles)
  "Return the precedence based on HANDLES and `mm-discouraged-alternatives'."
  (setq handles (reverse handles))
  (dolist (disc (reverse mm-discouraged-alternatives))
    (dolist (handle (copy-sequence handles))
      (when (string-match disc (mm-handle-media-type handle))
	(setq handles (nconc (delete handle handles) (list handle))))))
  ;; Remove empty parts.
  (dolist (handle (copy-sequence handles))
    (when (and (bufferp (mm-handle-buffer handle))
	       (not (with-current-buffer (mm-handle-buffer handle)
		      (goto-char (point-min))
		      (re-search-forward "[^ \t\n]" nil t))))
      (setq handles (nconc (delete handle handles) (list handle)))))
  (mapcar #'mm-handle-media-type handles))

(defun mm-get-content-id (id)
  "Return the handle(s) referred to by ID."
  (cdr (assoc id mm-content-id-alist)))

(defconst mm-image-type-regexps
  '(("/\\*.*XPM.\\*/" . xpm)
    ("P[1-6]" . pbm)
    ("GIF8" . gif)
    ("\377\330" . jpeg)
    ("\211PNG\r\n" . png)
    ("#define" . xbm)
    ("\\(MM\0\\*\\)\\|\\(II\\*\0\\)" . tiff)
    ("%!PS" . postscript))
  "Alist of (REGEXP . IMAGE-TYPE) pairs used to auto-detect image types.
When the first bytes of an image file match REGEXP, it is assumed to
be of image type IMAGE-TYPE.")

;; Steal from image.el. image-type-from-data suffers multi-line matching bug.
(defun mm-image-type-from-buffer ()
  "Determine the image type from data in the current buffer.
Value is a symbol specifying the image type or nil if type cannot
be determined."
  (let ((types mm-image-type-regexps)
	type)
    (goto-char (point-min))
    (while (and types (null type))
      (let ((regexp (car (car types)))
	    (image-type (cdr (car types))))
	(when (looking-at regexp)
	  (setq type image-type))
	(setq types (cdr types))))
    type))

(defun mm-get-image (handle)
  "Return an image instance based on HANDLE."
  (let ((type (mm-handle-media-subtype handle))
	spec)
    ;; Allow some common translations.
    (setq type
	  (cond
	   ((equal type "x-pixmap")
	    "xpm")
	   ((equal type "x-xbitmap")
	    "xbm")
	   ((equal type "x-portable-bitmap")
	    "pbm")
	   ((equal type "svg+xml")
	    "svg")
	   (t type)))
    (or (mm-handle-cache handle)
	(mm-with-unibyte-buffer
	  (mm-insert-part handle)
	  (prog1
	      (setq spec
		    (ignore-errors
		      (create-image (buffer-string)
				    (or (mm-image-type-from-buffer)
					(intern type))
				    'data-p)))
	    (mm-handle-set-cache handle spec))))))

(declare-function image-size "image.c" (spec &optional pixels frame))

(defun mm-image-fit-p (handle)
  "Say whether the image in HANDLE will fit the current window."
  (let ((image (mm-get-image handle)))
    (or (not image)
	(let* ((size (image-size image))
	       (w (car size))
	       (h (cdr size)))
	  (or mm-inline-large-images
	      (and (<= h (1- (window-height))) ; Don't include mode line.
		   (<= w (window-width))))))))

(defun mm-valid-image-format-p (format)
  "Say whether FORMAT can be displayed natively by Emacs."
  (and (display-graphic-p)
       (image-type-available-p format)))

(defun mm-valid-and-fit-image-p (format handle)
  "Say whether FORMAT can be displayed natively and HANDLE fits the window."
  (and (mm-valid-image-format-p format)
       (mm-image-fit-p handle)))

(defun mm-find-part-by-type (handles type &optional notp recursive)
  "Search in HANDLES for part with TYPE.
If NOTP, returns first non-matching part.
If RECURSIVE, search recursively."
  (let (handle)
    (while handles
      (if (and recursive (stringp (caar handles)))
	  (if (setq handle (mm-find-part-by-type (cdar handles) type
						 notp recursive))
	      (setq handles nil))
	(if (if notp
		(not (equal (mm-handle-media-type (car handles)) type))
	      (equal (mm-handle-media-type (car handles)) type))
	    (setq handle (car handles)
		  handles nil)))
      (setq handles (cdr handles)))
    handle))

(defun mm-find-raw-part-by-type (ctl type &optional notp)
  (goto-char (point-min))
  (let* ((boundary (concat "--" (mm-handle-multipart-ctl-parameter ctl
								   'boundary)))
	 (close-delimiter (concat "^" (regexp-quote boundary) "--[ \t]*$"))
	 start
	 (end (save-excursion
		(goto-char (point-max))
		(if (re-search-backward close-delimiter nil t)
		    (match-beginning 0)
		  (point-max))))
	 result)
    (setq boundary (concat "^" (regexp-quote boundary) "[ \t]*$"))
    (while (and (not result)
		(re-search-forward boundary end t))
      (goto-char (match-beginning 0))
      (when start
	(save-excursion
	  (save-restriction
	    (narrow-to-region start (1- (point)))
	    (when (let* ((ct (mail-fetch-field "content-type"))
			 (ctl (and ct (mail-header-parse-content-type ct))))
		    (if notp
			(not (equal (car ctl) type))
		      (equal (car ctl) type)))
	      (setq result (buffer-string))))))
      (forward-line 1)
      (setq start (point)))
    (when (and (not result) start)
      (save-excursion
	(save-restriction
	  (narrow-to-region start end)
	  (when (let* ((ct (mail-fetch-field "content-type"))
		       (ctl (and ct (mail-header-parse-content-type ct))))
		  (if notp
		      (not (equal (car ctl) type))
		    (equal (car ctl) type)))
	    (setq result (buffer-string))))))
    result))

(defsubst mm-set-handle-multipart-parameter (handle parameter value)
  ;; HANDLE could be a CTL.
  (when handle
    (put-text-property 0 (length (car handle)) parameter value
		       (car handle))))

;; Interface functions and variables for the decryption/verification
;; functions.
(defvar mm-security-handle nil)
(defun mm-sec-status (&rest keys)
  (cl-loop for (key val) on keys by #'cddr
	   do (mm-set-handle-multipart-parameter mm-security-handle key val)))

(defun mm-sec-error (&rest keys)
  (apply #'mm-sec-status (append '(sec-error t) keys)))

(autoload 'mm-view-pkcs7 "mm-view")

(defun mm-possibly-verify-or-decrypt (parts ctl &optional from)
  (let ((type (car ctl))
	(subtype (cadr (split-string (car ctl) "/")))
	(mm-security-handle ctl) ;; (car CTL) is the type.
	(smime-type (cdr (assq 'smime-type (mm-handle-type parts))))
	protocol func functest)
    (cond
     ((or (equal type "application/x-pkcs7-mime")
	  (equal type "application/pkcs7-mime"))
      (add-text-properties 0 (length (car ctl))
                           (list 'buffer (car parts))
                           (car ctl))
      (let* ((envelope-p (string= smime-type "enveloped-data"))
             (decrypt-or-verify-option (if envelope-p
                                           mm-decrypt-option
                                         mm-verify-option))
             (question (if envelope-p
                           "Decrypt (S/MIME) part? "
                         "Verify signed (S/MIME) part? ")))
        (with-temp-buffer
	  (when (and (cond
		      ((equal smime-type "signed-data") t)
		      ((eq decrypt-or-verify-option 'never) nil)
		      ((eq decrypt-or-verify-option 'always) t)
		      ((eq decrypt-or-verify-option 'known) t)
		      (t (y-or-n-p (format question))))
                     (mm-view-pkcs7 parts from))

	    (goto-char (point-min))
	    ;; The encrypted document is a MIME part, and may use either
	    ;; CRLF (Outlook and the like) or newlines for end-of-line
	    ;; markers.  Translate from CRLF.
	    (while (search-forward "\r\n" nil t)
	      (replace-match "\n"))
	    ;; Normally there will be a Content-type header here, but
	    ;; some mailers don't add that to the encrypted part, which
	    ;; makes the subsequent re-dissection fail here.
	    (save-restriction
	      (mail-narrow-to-head)
	      (unless (mail-fetch-field "content-type")
	        (goto-char (point-max))
	        (insert "Content-type: text/plain\n\n")))
	    (setq parts (mm-dissect-buffer t))))))
     ((equal subtype "signed")
      (unless (and (setq protocol
			 (mm-handle-multipart-ctl-parameter ctl 'protocol))
		   (not (equal protocol "multipart/mixed")))
	;; The message is broken or draft-ietf-openpgp-multsig-01.
	(let ((protocols mm-verify-function-alist))
	  (while protocols
	    (if (and (or (not (setq functest (nth 3 (car protocols))))
			 (funcall functest parts ctl))
		     (mm-find-part-by-type parts (caar protocols) nil t))
		(setq protocol (caar protocols)
		      protocols nil)
	      (setq protocols (cdr protocols))))))
      (setq func (nth 1 (assoc protocol mm-verify-function-alist)))
      (when (cond
	     ((eq mm-verify-option 'never) nil)
	     ((eq mm-verify-option 'always) t)
	     ((eq mm-verify-option 'known)
	      (and func
		   (or (not (setq functest
				  (nth 3 (assoc protocol
						mm-verify-function-alist))))
		       (funcall functest parts ctl))))
	     (t
	      (y-or-n-p
	       (format "Verify signed (%s) part? "
		       (or (nth 2 (assoc protocol mm-verify-function-alist))
			   (format "protocol=%s" protocol))))))
	(save-excursion
	  (if func
	      (setq parts (funcall func parts ctl))
	    (mm-sec-error 'gnus-details
			  (format "Unknown sign protocol (%s)" protocol))))))
     ((equal subtype "encrypted")
      (unless (setq protocol
		    (mm-handle-multipart-ctl-parameter ctl 'protocol))
	;; The message is broken.
	(let ((parts parts))
	  (while parts
	    (if (assoc (mm-handle-media-type (car parts))
		       mm-decrypt-function-alist)
		(setq protocol (mm-handle-media-type (car parts))
		      parts nil)
	      (setq parts (cdr parts))))))
      (setq func (nth 1 (assoc protocol mm-decrypt-function-alist)))
      (when (cond
	     ((eq mm-decrypt-option 'never) nil)
	     ((eq mm-decrypt-option 'always) t)
	     ((eq mm-decrypt-option 'known)
	      (and func
		   (or (not (setq functest
				  (nth 3 (assoc protocol
						mm-decrypt-function-alist))))
		       (funcall functest parts ctl))))
	     (t
	      (y-or-n-p
	       (format "Decrypt (%s) part? "
		       (or (nth 2 (assoc protocol mm-decrypt-function-alist))
			   (format "protocol=%s" protocol))))))
	(save-excursion
	  (if func
	      (setq parts (funcall func parts ctl))
	    (mm-sec-error
	     'gnus-details
	     (format "Unknown encrypt protocol (%s)" protocol)))))))
    ;; Check the results (which are now in `parts').
    (let ((err (get-text-property 0 'sec-error (car mm-security-handle))))
      (if (or (not err)
	      (not (equal subtype "encrypted")))
	  parts
	;; We had an error during decryption.  Report what it is.
	(list
	 (mm-make-handle
	  (with-current-buffer (generate-new-buffer " *mm*")
	    (insert "Error!  Result from decryption:\n\n"
		    (or (get-text-property 0 'gnus-details
					   (car mm-security-handle))
			"")
		    "\n\n"
		    (or (get-text-property 0 'gnus-details
					   (car mm-security-handle))
			""))
	    (current-buffer))
	  '("text/plain")))))))

(defun mm-multiple-handles (handles)
  (and (listp handles)
       (> (length handles) 1)
       (or (listp (car handles))
	   (stringp (car handles)))))

(defun mm-complicated-handles (handles)
  (and (listp (car handles))
       (> (length handles) 1)))

(defun mm-merge-handles (handles1 handles2)
  (append
   (if (listp (car handles1))
       handles1
     (list handles1))
   (if (listp (car handles2))
       handles2
     (list handles2))))

(defun mm-readable-p (handle)
  "Say whether the content of HANDLE is readable."
  (and (< (with-current-buffer (mm-handle-buffer handle)
	    (buffer-size)) 10000)
       (mm-with-unibyte-buffer
	 (mm-insert-part handle)
	 (and (eq (mm-body-7-or-8) '7bit)
	      (not (mm-long-lines-p 76))))))

(declare-function libxml-parse-html-region "xml.c"
		  (start end &optional base-url discard-comments))
(declare-function shr-insert-document "shr" (dom))
(defvar shr-blocked-images)
(defvar shr-use-fonts)
(defvar shr-width)
(defvar shr-content-function)
(defvar shr-inhibit-images)

(defun mm-shr (handle)
  ;; Require since we bind its variables.
  (require 'shr)
  (let ((shr-width (if shr-use-fonts
		       shr-width
		     fill-column))
	(shr-content-function (lambda (id)
				(let ((handle (mm-get-content-id id)))
				  (when handle
				    (mm-with-part handle
				      (buffer-string))))))
	(shr-inhibit-images mm-html-inhibit-images)
	(shr-blocked-images mm-html-blocked-images)
	charset coding char document)
    (mm-with-part (or handle (setq handle (mm-dissect-buffer t)))
      (setq case-fold-search t)
      (or (setq charset
		(mail-content-type-get (mm-handle-type handle) 'charset))
	  (progn
	    (goto-char (point-min))
	    (and (re-search-forward "\
<meta\\s-+http-equiv=[\"']?content-type[\"']?\\s-+content=[\"']?\
text/html;\\s-*charset=\\([^\t\n\r \"'>]+\\)[^>]*>" nil t)
		 (setq coding (mm-charset-to-coding-system (match-string 1)
							   nil t))))
	  (setq charset mail-parse-charset))
      (when (and (or coding
		     (setq coding (mm-charset-to-coding-system charset nil t)))
		 (not (eq coding 'ascii)))
	(insert (prog1
		    (decode-coding-string (buffer-string) coding)
		  (erase-buffer)
		  (set-buffer-multibyte t))))
      (goto-char (point-min))
      (while (re-search-forward
	      "&#\\(?:x\\([89][0-9a-f]\\)\\|\\(1[2-5][0-9]\\)\\);" nil t)
	(when (setq char
		    (cdr (assq (if (match-beginning 1)
				   (string-to-number (match-string 1) 16)
				 (string-to-number (match-string 2)))
			       mm-extra-numeric-entities)))
	  (replace-match (char-to-string char))))
      ;; Remove "soft hyphens".
      (goto-char (point-min))
      (while (search-forward "­" nil t)
	(replace-match "" t t))
      (setq document (libxml-parse-html-region (point-min) (point-max))))
    (save-restriction
      (narrow-to-region (point) (point))
      (shr-insert-document document)
      (unless (bobp)
	(insert "\n"))
      (mm-handle-set-undisplayer
       handle
       (let ((min (point-min-marker))
             (max (point-max-marker)))
         (lambda ()
	   (let ((inhibit-read-only t))
	     (delete-region min max))))))))

(defun mm-handle-filename (handle)
  "Return filename of HANDLE if any."
  (or (mail-content-type-get (mm-handle-type handle)
                             'name)
      (mail-content-type-get (mm-handle-disposition handle)
                             'filename)))

(provide 'mm-decode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; mm-decode.el ends here
