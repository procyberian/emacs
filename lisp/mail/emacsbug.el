;;; emacsbug.el --- command to report Emacs bugs to appropriate mailing list  -*- lexical-binding: t; -*-

;; Copyright (C) 1985-2025 Free Software Foundation, Inc.

;; Author: K. Shane Hartman
;; Maintainer: emacs-devel@gnu.org
;; Keywords: maint mail
;; Package: emacs

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

;; `M-x report-emacs-bug' starts an email note to the Emacs maintainers
;; describing a problem.  You need to be able to send mail from Emacs
;; to complete the process.  Alternatively, compose the bug report in
;; Emacs then paste it into your normal mail client.

;; `M-x submit-emacs-patch' can be used to send a patch to the Emacs
;; maintainers.

;;; Code:

(require 'sendmail)
(require 'message)
(require 'lisp-mnt)

(defgroup emacsbug nil
  "Sending Emacs bug reports."
  :group 'maint
  :group 'mail)

(defcustom report-emacs-bug-no-confirmation nil
  "If non-nil, suppress the confirmations asked for the sake of novice users."
  :type 'boolean)

(defcustom report-emacs-bug-no-explanations nil
  "If non-nil, suppress the explanations given for the sake of novice users."
  :type 'boolean)

;; User options end here.

(defvar report-emacs-bug-orig-text nil
  "The automatically-created initial text of the bug report.")

(defvar-local report-emacs-bug-send-command nil
  "Name of the command to send the bug report, as a string.")

(defvar-local report-emacs-bug-send-hook nil
  "Hook run before sending the bug report.")

(declare-function x-server-vendor "xfns.c" (&optional terminal))
(declare-function x-server-version "xfns.c" (&optional terminal))
(declare-function message-sort-headers "message" ())
(declare-function w32--os-description "w32-fns" ())
(defvar message-strip-special-text-properties)

(defun report-emacs-bug-can-use-osx-open ()
  "Return non-nil if the macOS \"open\" command is available for mailing."
  (and (featurep 'ns)
       (equal (executable-find "open") "/usr/bin/open")
       (memq system-type '(darwin))))

(defun report-emacs-bug-can-use-xdg-email ()
  "Return non-nil if the \"xdg-email\" command can be used.
xdg-email is a desktop utility that calls your preferred mail client."
  (and ;; See browse-url-can-use-xdg-open.
       (or (getenv "DISPLAY") (getenv "WAYLAND_DISPLAY"))
       (executable-find "xdg-email")))

(defun report-emacs-bug-insert-to-mailer ()
  "Send the message to your preferred mail client.
This requires either the macOS \"open\" command, or the freedesktop
\"xdg-email\" command to be available."
  (interactive)
  (save-excursion
    ;; FIXME? use mail-fetch-field?
    (let* ((to (progn
		 (goto-char (point-min))
		 (forward-line)
		 (and (looking-at "^To: \\(.*\\)")
		      (match-string-no-properties 1))))
	   (subject (progn
		      (forward-line)
		      (and (looking-at "^Subject: \\(.*\\)")
			   (match-string-no-properties 1))))
	   (body (progn
		   (forward-line 2)
		   (if (> (point-max) (point))
		       (buffer-substring-no-properties (point) (point-max))))))
      (if (and to subject body)
	  (if (report-emacs-bug-can-use-osx-open)
	      (start-process "/usr/bin/open" nil "open"
			     (concat "mailto:" to
				     "?subject=" (url-hexify-string subject)
				     "&body=" (url-hexify-string body)))
	    (start-process "xdg-email" nil "xdg-email"
			   "--subject" subject
			   "--body" body
			   (concat "mailto:" to)))
	(error "Subject, To or body not found")))))

(defvar report-emacs-bug--os-description nil
  "Cached value of operating system description.")

(defun report-emacs-bug--os-description ()
  "Return a string describing the operating system, or nil."
  (cond ((eq system-type 'darwin)
         (let (os)
           (with-temp-buffer
             (when (eq 0 (ignore-errors
                           (call-process "sw_vers" nil '(t nil) nil)))
               (dolist (s '("ProductName" "ProductVersion"))
                 (goto-char (point-min))
                 (if (re-search-forward (format "^%s\\s-*:\\s-+\\(.*\\)$" s)
                                        nil t)
                     (setq os (concat os " " (match-string 1)))))))
           os))
        ((eq system-type 'windows-nt)
         (or report-emacs-bug--os-description
             (setq report-emacs-bug--os-description (w32--os-description))))
        ((eq system-type 'berkeley-unix)
         (with-temp-buffer
           (when
               (or (eq 0 (ignore-errors (call-process "freebsd-version" nil
                                                      '(t nil) nil "-u")))
                   (progn (erase-buffer)
                          (eq 0 (ignore-errors
                                  (call-process "uname" nil
                                                '(t nil) nil "-a")))))
             (unless (zerop (buffer-size))
               (goto-char (point-min))
               (buffer-substring (line-beginning-position)
                                 (line-end-position))))))
        ((eq system-type 'android)
         ;; This is a short string containing the Android version,
         ;; build number, and window system distributor.
         (symbol-value 'android-build-fingerprint))
        ;; TODO Cygwin, Solaris (usg-unix-v).
        (t
         (or (let ((file "/etc/os-release"))
               (and (file-readable-p file)
                    (with-temp-buffer
                      (insert-file-contents file)
                      (if (re-search-forward
                           "^\\sw*PRETTY_NAME=\"?\\(.+?\\)\"?$" nil t)
                          (match-string 1)
                        (let (os)
                          (when (re-search-forward
                                 "^\\sw*NAME=\"?\\(.+?\\)\"?$" nil t)
                            (setq os (match-string 1))
                            (if (re-search-forward
                                 "^\\sw*VERSION=\"?\\(.+?\\)\"?$" nil t)
                                (setq os (concat os " " (match-string 1))))
                            os))))))
             (with-temp-buffer
               (when (eq 0 (ignore-errors
                             (call-process "lsb_release" nil '(t nil)
                                           nil "-d")))
                 (goto-char (point-min))
                 (if (looking-at "^\\sw+:\\s-+")
                     (goto-char (match-end 0)))
                 (buffer-substring (point) (line-end-position))))
             (let ((file "/etc/lsb-release"))
               (and (file-readable-p file)
                    (with-temp-buffer
                      (insert-file-contents file)
                      (if (re-search-forward
                           "^\\sw*DISTRIB_DESCRIPTION=\"?\\(.*release.*?\\)\"?$" nil t)
                          (match-string 1)))))
             (catch 'found
               (dolist (f (append (file-expand-wildcards "/etc/*-release")
                                  '("/etc/debian_version")))
                 (and (not (member (file-name-nondirectory f)
                                   '("lsb-release" "os-release")))
                      (file-readable-p f)
                      (with-temp-buffer
                        (insert-file-contents f)
                        (if (not (zerop (buffer-size)))
                            (throw 'found
                                   (format "%s%s"
                                           (if (equal (file-name-nondirectory f)
                                                      "debian_version")
                                               "Debian " "")
                                           (buffer-substring
                                            (line-beginning-position)
                                            (line-end-position)))))))))))))

;; It's the default mail mode, so it seems OK to use its features.
(autoload 'message-bogus-recipient-p "message")
(autoload 'message-make-address "message")
(defvar message-send-mail-function)
(defvar message-sendmail-envelope-from)

;;;###autoload
(defun report-emacs-bug (topic &optional _unused)
  "Report a bug in GNU Emacs.
Prompts for bug subject.  Leaves you in a mail buffer.

Already submitted bugs can be found in the Emacs bug tracker:

  https://debbugs.gnu.org/cgi/pkgreport.cgi?package=emacs;max-bugs=100;base-order=1;bug-rev=1"
  (declare (advertised-calling-convention (topic) "24.5"))
  (interactive "sBug Subject: ")
  ;; The syntax `version;' is preferred to `[version]' because the
  ;; latter could be mistakenly stripped by mailing software.
  (setq topic (concat emacs-version "; " topic))
  (let ((from-buffer (current-buffer))
	(can-insert-mail (or (report-emacs-bug-can-use-xdg-email)
			     (report-emacs-bug-can-use-osx-open)))
        user-point) ;; message-end-point
    ;; (setq message-end-point
    ;;       (with-current-buffer (messages-buffer)
    ;;         (point-max-marker)))
    (condition-case nil
        ;; For the novice user make sure there's always enough space for
        ;; the mail and the warnings buffer on this frame (Bug#10873).
        (unless report-emacs-bug-no-explanations
          (delete-other-windows)
          (set-window-dedicated-p nil nil)
          (set-frame-parameter nil 'unsplittable nil))
      (error nil))
    (compose-mail report-emacs-bug-address topic)
    (rfc822-goto-eoh)
    (insert "X-Debbugs-Cc: \n")
    ;; The rest of this does not execute if the user was asked to
    ;; confirm and said no.
    (when (derived-mode-p 'message-mode)
      ;; Message-mode sorts the headers before sending.  We sort now so
      ;; that report-emacs-bug-orig-text remains valid.  (Bug#5178)
      (message-sort-headers)
      ;; Stop message-mode stealing the properties we will add.
      (setq-local message-strip-special-text-properties nil)
      ;; Make sure we default to the From: address as envelope when sending
      ;; through sendmail.  FIXME: Why?
      (when (and (not (message--sendmail-envelope-from))
		 (message-bogus-recipient-p (message-make-address)))
        (setq-local message-sendmail-envelope-from 'header)))
    (rfc822-goto-eoh)
    (forward-line 1)
    ;; Move the mail signature to the proper place.
    (let ((signature (buffer-substring (point) (point-max)))
	  (inhibit-read-only t))
      (delete-region (point) (point-max))
      (insert signature)
      (backward-char (length signature)))
    (unless report-emacs-bug-no-explanations
      ;; Insert warnings for novice users.
      (if (not (equal "bug-gnu-emacs@gnu.org" report-emacs-bug-address))
	  (insert (format "The report will be sent to %s.\n\n"
			  report-emacs-bug-address))
	(insert "This bug report will be sent to the ")
	(insert-text-button
	 "Bug-GNU-Emacs"
	 'face 'link
	 'help-echo (concat "mouse-2, RET: Follow this link")
	 'action (lambda (_button)
		   (browse-url "https://lists.gnu.org/r/bug-gnu-emacs/"))
	 'follow-link t)
	(insert " mailing list\nand the GNU bug tracker at ")
	(insert-text-button
	 "debbugs.gnu.org"
	 'face 'link
	 'help-echo (concat "mouse-2, RET: Follow this link")
	 'action (lambda (_button)
		   (browse-url "https://debbugs.gnu.org/cgi/pkgreport.cgi?package=emacs;max-bugs=100;base-order=1;bug-rev=1"))
	 'follow-link t)

	(insert ".  Please check that
the From: line contains a valid email address.  After a delay of up
to one day, you should receive an acknowledgment at that address.

Please write in English if possible, as the Emacs maintainers
usually do not have translators for other languages.\n\n")))

    (insert "Please describe exactly what actions triggered the bug, and\n"
	    "the precise symptoms of the bug.  If you can, give a recipe\n"
	    "starting from 'emacs -Q':\n\n")
    (let ((txt (delete-and-extract-region
                (save-excursion (rfc822-goto-eoh) (line-beginning-position 2))
                (point))))
      (insert (propertize "\n" 'display txt)))
    (setq user-point (point))
    (insert "\n\n")

    (insert "If Emacs crashed, and you have the Emacs process in the gdb debugger,\n"
	    "please include the output from the following gdb commands:\n"
	    "    'bt full' and 'xbacktrace'.\n")

    (let ((debug-file (expand-file-name "DEBUG" data-directory)))
      (if (file-readable-p debug-file)
	  (insert "For information about debugging Emacs, please read the file\n"
		  debug-file ".\n")))
    (let ((txt (delete-and-extract-region (1+ user-point) (point))))
      (insert (propertize "\n" 'display txt)))

    (emacs-build-description)
    (insert "Configured features:\n" system-configuration-features "\n\n")
    (fill-region (line-beginning-position -1) (point))
    (when (and (featurep 'native-compile)
               (null (native-comp-available-p)))
      (insert "(NATIVE_COMP present but libgccjit not available)\n\n"))
    (insert "Important settings:\n")
    (mapc
     (lambda (var)
       (let ((val (getenv var)))
	 (if val (insert (format "  value of $%s: %s\n" var val)))))
     '("EMACSDATA" "EMACSDOC" "EMACSLOADPATH" "EMACSNATIVELOADPATH" "EMACSPATH"
       "LC_ALL" "LC_COLLATE" "LC_CTYPE" "LC_MESSAGES"
       "LC_MONETARY" "LC_NUMERIC" "LC_TIME" "LANG" "XMODIFIERS"))
    (insert (format "  locale-coding-system: %s\n" locale-coding-system))
    (insert "\n")
    (insert (format "Major mode: %s\n"
		    (format-mode-line
                     (buffer-local-value 'mode-name from-buffer)
                     nil nil from-buffer)))
    (insert "\n")
    (insert "Minor modes in effect:\n")
    (dolist (mode minor-mode-list)
      (and (boundp mode) (buffer-local-value mode from-buffer)
	   (insert (format "  %s: %s\n" mode
			   (buffer-local-value mode from-buffer)))))
    (insert "\n")
    (insert "Load-path shadows:\n")
    (let* ((msg "Checking for load-path shadows...")
	   (result "done")
	   (shadows (progn (message "%s" msg)
			   (condition-case nil (list-load-path-shadows t)
			     (error
			      (setq result "error")
			      "Error during checking")))))
      (message "%s%s" msg result)
      (insert (if (zerop (length shadows))
                  "None found.\n"
                shadows)))
    (insert (format "\nFeatures:\n%s\n" features))
    (fill-region (line-beginning-position 0) (point))

    (insert "\nMemory information:\n")
    (pp (garbage-collect) (current-buffer))

    ;; This is so the user has to type something in order to send easily.
    (use-local-map (nconc (make-sparse-keymap) (current-local-map)))
    (keymap-set (current-local-map) "C-c C-i" #'info-emacs-bug)
    (if can-insert-mail
        (keymap-set (current-local-map) "C-c M-i"
                    #'report-emacs-bug-insert-to-mailer))
    (setq report-emacs-bug-send-command (get mail-user-agent 'sendfunc)
	  report-emacs-bug-send-hook (get mail-user-agent 'hookvar))
    (if report-emacs-bug-send-command
	(setq report-emacs-bug-send-command
	      (symbol-name report-emacs-bug-send-command)))
    (unless report-emacs-bug-no-explanations
      (with-output-to-temp-buffer "*Bug Help*"
	(princ "While in the mail buffer:\n\n")
        (let ((help
               (substitute-command-keys
                (format "%s%s%s%s"
                        (if report-emacs-bug-send-command
                            (format "  Type \\[%s] to send the bug report.\n"
                                    report-emacs-bug-send-command)
                          "")
                        "  Type \\[kill-buffer] \\`RET' to cancel (don't send it).\n"
                        (if can-insert-mail
                            "  Type \\[report-emacs-bug-insert-to-mailer] to \
copy text to your preferred mail program.\n"
                          "")
                        "  Type \\[info-emacs-bug] to visit in Info the Emacs Manual section
    about when and how to write a bug report, and what
    information you should include to help fix the bug."))))
          (with-current-buffer "*Bug Help*"
            (insert help))))
      (shrink-window-if-larger-than-buffer (get-buffer-window "*Bug Help*")))
    ;; Make it less likely people will send empty messages.
    (if report-emacs-bug-send-hook
        (add-hook report-emacs-bug-send-hook #'report-emacs-bug-hook nil t))
    (goto-char (point-max))
    (skip-chars-backward " \t\n")
    (setq-local report-emacs-bug-orig-text
                (buffer-substring-no-properties (point-min) (point)))
    (goto-char user-point)))

;;;###autoload
(defun emacs-build-description ()
  "Insert a description of the current Emacs build in the current buffer."
  (interactive)
  (let ((start (point)))
    (insert "\nIn " (emacs-version))
    (if emacs-build-system
        (insert " built on " emacs-build-system))
    (insert "\n")
    (fill-region-as-paragraph start (point)))

  (if (stringp emacs-repository-version)
      (insert "Repository revision: " emacs-repository-version "\n"))
  (if (stringp emacs-repository-branch)
      (insert "Repository branch: " emacs-repository-branch "\n"))
  (if (fboundp 'x-server-vendor)
      (condition-case nil
          ;; This is used not only for X11 but also W32 and others.
	  (insert "Windowing system distributor '" (x-server-vendor)
                  "', version "
		  (mapconcat #'number-to-string (x-server-version) ".") "\n")
	(error t)))
  (let ((os (ignore-errors (report-emacs-bug--os-description))))
    (if (stringp os)
        (insert "System Description: " os "\n\n")))
  (when (and system-configuration-options
	     (not (equal system-configuration-options "")))
    (insert "Configured using:\n 'configure "
	    system-configuration-options "'\n\n")
    (fill-region (line-beginning-position -1) (point))))

(defun report-emacs-bug-check-org ()
  "Warn the user if the bug report mentions org-mode."
  (unless report-emacs-bug-no-confirmation
    (goto-char (point-max))
    (skip-chars-backward " \t\n")
    (let* ((text (buffer-substring-no-properties (point-min) (point)))
           (l (length report-emacs-bug-orig-text))
           (text (substring text 0 l))
           (org-regex "\\b[Oo]rg\\(-mode\\)?\\b"))
      (when (string-match-p org-regex text)
        (when (yes-or-no-p "Is this bug about org-mode?")
          (error (substitute-command-keys "\
Not sending, use \\[org-submit-bug-report] to report an Org-mode bug.")))))))

(defun report-emacs-bug-hook ()
  "Do some checking before sending a bug report."
  (goto-char (point-max))
  (skip-chars-backward " \t\n")
  (and (= (- (point) (point-min))
          (length report-emacs-bug-orig-text))
       (string-equal (buffer-substring-no-properties (point-min) (point))
                     report-emacs-bug-orig-text)
       (error "No text entered in bug report"))
  ;; Warning for novice users.
  (when (and (string-match "bug-gnu-emacs@gnu\\.org" (mail-fetch-field "to"))
             (not report-emacs-bug-no-confirmation)
	     (not (yes-or-no-p
		   "Send this bug report to the Emacs maintainers? ")))
    (with-output-to-temp-buffer "*Bug Help*"
      (princ (substitute-command-keys
              (format "\
You invoked the command \\[report-emacs-bug],
but you decided not to mail the bug report to the Emacs maintainers.

If you want to mail it to someone else instead,
please insert the proper e-mail address after \"To: \",
and send the mail again%s."
                      (if report-emacs-bug-send-command
                          (format " using \\[%s]"
                                  report-emacs-bug-send-command)
                        "")))))
    (error "M-x report-emacs-bug was canceled, please read *Bug Help* buffer"))
  ;; Query the user for the SMTP method, so that we can skip
  ;; questions about From header validity if the user is going to
  ;; use mailclient, anyway.
  (when (or (and (derived-mode-p 'message-mode)
		 (eq (message-default-send-mail-function) 'sendmail-query-once))
	    (and (not (derived-mode-p 'message-mode))
		 (eq send-mail-function 'sendmail-query-once)))
    (setq send-mail-function (sendmail-query-user-about-smtp))
    (when (derived-mode-p 'message-mode)
      (setq message-send-mail-function (message-default-send-mail-function))
      ;; Don't ask the question below if we are going to ignore it in
      ;; 'customize-save-variable' anyway.
      (unless (or (null user-init-file)
                  (and (null custom-file) init-file-had-error))
        (add-hook 'message-sent-hook
                  (lambda ()
                    (when (y-or-n-p "Save this mail sending choice?")
                      (customize-save-variable 'send-mail-function
                                               send-mail-function)))
                  nil t))))
  (or report-emacs-bug-no-confirmation
      ;; mailclient.el does not need a valid From
      (eq send-mail-function 'mailclient-send-it)
      ;; Not narrowing to the headers, but that's OK.
      (let ((from (mail-fetch-field "From")))
	(when (and (or (not from)
		       (message-bogus-recipient-p from)
		       ;; This is the default user-mail-address.  On
		       ;; today's systems, it seems more likely to
		       ;; be wrong than right, since most people
		       ;; don't run their own mail server.
		       (string-match (format "\\<%s@%s\\>"
					     (regexp-quote (user-login-name))
					     (regexp-quote (system-name)))
				     from))
	           (not (yes-or-no-p
		         (format-message "Is `%s' really your email address? "
                                         from))))
          (goto-char (point-min))
          (re-search-forward "^From: " nil t)
	  (error "Please edit the From address and try again"))))
  (report-emacs-bug-check-org)
  ;; Bury the help buffer (if it's shown).
  (when-let* ((help (get-buffer "*Bug Help*")))
    (when (get-buffer-window help)
      (quit-window nil (get-buffer-window help)))))

(defconst submit-emacs-patch-excluded-maintainers
  '("emacs-devel@gnu.org")
  "List of maintainer addresses for `submit-emacs-patch' to ignore.")

;;;###autoload
(defun submit-emacs-patch (subject file)
  "Send an Emacs patch to the Emacs maintainers.
Interactively, you will be prompted for SUBJECT and a patch FILE
name (which will be attached to the mail).  You will end up in a
Message buffer where you can explain more about the patch."
  (interactive
   (let* ((file (read-file-name "Patch file name: "))
          (guess (with-temp-buffer
                   (insert-file-contents file)
                   (mail-fetch-field "Subject"))))
     (list (read-string (format-prompt "This patch is about" guess)
                        nil nil guess)
           file)))
  (pop-to-buffer-same-window "*Patch Help*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert "Thank you for considering submitting a patch to the Emacs project.\n\n"
            "Please describe what the patch fixes (or, if it's a new feature, what it\n"
            "implements) in the mail buffer below.  When done, use the "
            (substitute-command-keys "\\<message-mode-map>\\[message-send-and-exit] command\n")
            "to send the patch as an email to the Emacs issue tracker.\n\n"
            "If this is the first time you're submitting an Emacs patch, please\n"
            "read the ")
    (insert-text-button
     "CONTRIBUTE"
     'action (lambda (_)
               (view-buffer
                (find-file-noselect
                 (expand-file-name "CONTRIBUTE" installation-directory)))))
    (insert " file first.\n")
    (goto-char (point-min))
    (view-mode 1)
    (button-mode 1))
  (compose-mail-other-window report-emacs-bug-address subject)
  (rfc822-goto-eoh)
  (insert "X-Debbugs-Cc: ")
  (let ((maint (let (files)
                 (with-temp-buffer
                   (insert-file-contents file)
                   (while (search-forward-regexp "^\\+\\{3\\} ./\\(.*\\)" nil t)
                     (let ((file (expand-file-name
                                  (match-string-no-properties 1)
                                  source-directory)))
                       (when (file-readable-p file)
                         (push file files)))))
                 (mapcan
                  (lambda (patch)
                    (seq-remove
                     (pcase-lambda (`(,_name . ,addr))
                       (member addr submit-emacs-patch-excluded-maintainers))
                     ;; TODO: Consult admin/MAINTAINERS for additional
                     ;; information.  This either requires some
                     ;; heuristics to parse the existing file or to
                     ;; adjust the file format to make it more machine
                     ;; readable (bug#69646).
                     (lm-maintainers patch)))
                  files))))
    (when maint
      (insert (mapconcat
               (pcase-lambda (`(,name . ,addr))
                 (format "%s <%s>" name addr))
               maint ", "))))
  (insert "\n")
  (message-goto-body)
  (insert "\n\n\n")
  (emacs-build-description)
  (mml-attach-file file "text/patch" nil "attachment")
  (message-goto-body)
  (message "Write a description of the patch and use %s to send it"
           (substitute-command-keys "\\[message-send-and-exit]"))
  (add-hook 'message-send-hook
            (lambda ()
              (message-goto-body)
              (insert "Tags: patch\n\n"))
            nil t)
  (message-add-action
   (lambda ()
     ;; Bury the help buffer (if it's shown).
     (when-let* ((help (get-buffer "*Patch Help*")))
       (when (get-buffer-window help)
         (quit-window nil (get-buffer-window help)))))
   'send))

(provide 'emacsbug)

;;; emacsbug.el ends here
