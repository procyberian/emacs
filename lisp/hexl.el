;;; hexl.el --- edit a file in a hex dump format using the hexl filter -*- lexical-binding: t -*-

;; Copyright (C) 1989, 1994, 1998, 2001-2025 Free Software Foundation,
;; Inc.

;; Author: Keith Gabryelski <ag@wheaties.ai.mit.edu>
;; Maintainer: emacs-devel@gnu.org
;; Keywords: data

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

;; This package implements a major mode for editing binary files.  It uses
;; a program called hexl, supplied with the GNU Emacs distribution, that
;; can filter a binary into an editable format or from the format back into
;; binary.  For full instructions, invoke `hexl-mode' on an empty buffer and
;; do M-x `describe-mode'.
;;
;; NOTE: Remember to change `hexl-program' or `hexl-options' if needed.
;;
;; Currently hexl only supports big endian hex output with 16 bit
;; grouping.
;;
;; -iso in `hexl-options' will allow iso characters to display in the
;; ASCII region of the screen (if your Emacs supports this) instead of
;; changing them to dots.

;;; Code:

(require 'eldoc)
(eval-when-compile (require 'cl-lib))

;;
;; vars here
;;

(defgroup hexl nil
  "Edit a file in a hex dump format using the hexl filter."
  :group 'data)

(defcustom hexl-bits 16
  "The bit grouping that hexl will use."
  :type '(choice (const 8 )
                 (const 16)
                 (const 32)
                 (const 64))
  :version "24.3")

(defcustom hexl-program hexl-program-name
  "The program that will hexlify and dehexlify its stdin.
`hexl-program' will always be concatenated with `hexl-options'
and \"-de\" when dehexlifying a buffer."
  :type 'string)

(defcustom hexl-iso ""
  "If your Emacs can handle ISO characters, this should be set to
\"-iso\" otherwise it should be \"\"."
  :type 'string)

(defcustom hexl-options (format "-hex %s" hexl-iso)
  "Space separated options to `hexl-program' that suit your needs.
Quoting cannot be used, so the arguments cannot themselves contain spaces.
If you wish to set the `-group-by-X-bits' options, set `hexl-bits' instead,
as that will override any bit grouping options set here."
  :type 'string)

(defcustom hexl-follow-ascii t
  "If non-nil then highlight the ASCII character corresponding to point."
  :type 'boolean
  :version "20.3")

(defcustom hexl-mode-hook '(hexl-follow-line hexl-activate-ruler)
  "Normal hook run when entering Hexl mode."
  :type 'hook
  :options '(hexl-follow-line hexl-activate-ruler eldoc-mode))

(defface hexl-address-region
  '((t (:inherit header-line)))
  "Face used in address area of Hexl mode buffer.")

(defface hexl-ascii-region
  ;; Copied from 'header-line'.  We used to inherit from it, but that
  ;; looks awful when the headerline is given a variable-pitch font or
  ;; (even worse) a 3D look.
  '((((class color grayscale) (background light))
     :background "grey90" :foreground "grey20"
     :box nil)
    (((class color grayscale) (background dark))
     :background "grey20" :foreground "grey90"
     :box nil))
  "Face used in ASCII area of Hexl mode buffer.")

(defvar-local hexl-max-address 0
  "Maximum offset into hexl buffer.")

(defvar hexl-mode-map
  (let ((map (make-keymap)))
    ;; Make all self-inserting keys go through hexl-self-insert-command,
    ;; because we need to convert them to unibyte characters before
    ;; inserting them into the buffer.
    (define-key map [remap self-insert-command] 'hexl-self-insert-command)

    (define-key map "\C-m" 'hexl-self-insert-command)
    (define-key map [left] 'hexl-backward-char)
    (define-key map [right] 'hexl-forward-char)
    (define-key map [up] 'hexl-previous-line)
    (define-key map [down] 'hexl-next-line)
    (define-key map [M-left] 'hexl-backward-short)
    (define-key map [?\e left] 'hexl-backward-short)
    (define-key map [M-right] 'hexl-forward-short)
    (define-key map [?\e right] 'hexl-forward-short)
    (define-key map [next] 'hexl-scroll-up)
    (define-key map [prior] 'hexl-scroll-down)
    (define-key map [home] 'hexl-beginning-of-line)
    (define-key map [end] 'hexl-end-of-line)
    (define-key map [C-home] 'hexl-beginning-of-buffer)
    (define-key map [C-end] 'hexl-end-of-buffer)
    (define-key map [deletechar] 'undefined)
    (define-key map [deleteline] 'undefined)
    (define-key map [insertline] 'undefined)
    (define-key map [S-delete] 'undefined)
    (define-key map "\177" 'undefined)

    (define-key map "\C-a" 'hexl-beginning-of-line)
    (define-key map "\C-b" 'hexl-backward-char)
    (define-key map "\C-d" 'undefined)
    (define-key map "\C-e" 'hexl-end-of-line)
    (define-key map "\C-f" 'hexl-forward-char)

    (if (not (memq (key-binding (char-to-string help-char))
		   '(help-command ehelp-command)))
	(define-key map (char-to-string help-char) 'undefined))

    (define-key map "\C-k" 'undefined)
    (define-key map "\C-n" 'hexl-next-line)
    (define-key map "\C-o" 'undefined)
    (define-key map "\C-p" 'hexl-previous-line)
    (define-key map "\C-q" 'hexl-quoted-insert)
    (define-key map "\C-t" 'undefined)
    (define-key map "\C-v" 'hexl-scroll-up)
    (define-key map "\C-w" 'undefined)
    (define-key map "\C-y" 'undefined)

    (fset 'hexl-ESC-prefix (copy-keymap 'ESC-prefix))
    (define-key map "\e" 'hexl-ESC-prefix)
    (define-key map "\e\C-a" 'hexl-beginning-of-512b-page)
    (define-key map "\e\C-b" 'hexl-backward-short)
    (define-key map "\e\C-d" 'hexl-insert-decimal-char)
    (define-key map "\e\C-e" 'hexl-end-of-512b-page)
    (define-key map "\e\C-f" 'hexl-forward-short)
    (define-key map "\e\C-i" 'undefined)
    (define-key map "\e\C-j" 'undefined)
    (define-key map "\e\C-k" 'undefined)
    (define-key map "\e\C-o" 'hexl-insert-octal-char)
    (define-key map "\e\C-q" 'undefined)
    (define-key map "\e\C-t" 'undefined)
    (define-key map "\e\C-x" 'hexl-insert-hex-char)
    (define-key map "\eb" 'hexl-backward-word)
    (define-key map "\ec" 'undefined)
    (define-key map "\ed" 'undefined)
    (define-key map "\ef" 'hexl-forward-word)
    (define-key map "\eg" 'hexl-goto-hex-address)
    (define-key map "\ei" 'undefined)
    (define-key map "\ej" 'hexl-goto-address)
    (define-key map "\ek" 'undefined)
    (define-key map "\el" 'undefined)
    (define-key map "\eq" 'undefined)
    (define-key map "\es" 'undefined)
    (define-key map "\et" 'undefined)
    (define-key map "\eu" 'undefined)
    (define-key map "\ev" 'hexl-scroll-down)
    (define-key map "\ey" 'undefined)
    (define-key map "\ez" 'undefined)
    (define-key map "\e<" 'hexl-beginning-of-buffer)
    (define-key map "\e>" 'hexl-end-of-buffer)

    (fset 'hexl-C-c-prefix (copy-keymap mode-specific-map))
    (define-key map "\C-c" 'hexl-C-c-prefix)
    (define-key map "\C-c\C-c" 'hexl-mode-exit)

    (fset 'hexl-C-x-prefix (copy-keymap 'Control-X-prefix))
    (define-key map "\C-x" 'hexl-C-x-prefix)
    (define-key map "\C-x[" 'hexl-beginning-of-1k-page)
    (define-key map "\C-x]" 'hexl-end-of-1k-page)
    (define-key map "\C-x\C-p" 'undefined)
    (define-key map "\C-x\C-s" 'hexl-save-buffer)
    (define-key map "\C-x\C-t" 'undefined)
    map))

;; Variable declarations for suppressing warnings from the byte-compiler.
(defvar ruler-mode)
(defvar ruler-mode-ruler-function)
(defvar hl-line-mode)
(defvar hl-line-range-function)
(defvar hl-line-face)

;; Variables where the original values are stored to.
(defvar-local hexl-mode--old-var-vals ())

(defvar-local hexl-ascii-overlay nil
  "Overlay used to highlight ASCII element corresponding to current point.")

(defvar hexl-font-lock-keywords
  '(("^\\([0-9a-f]+:\\)\\( \\).\\{39\\}\\(  \\)\\(.+$\\)"
     ;; "^\\([0-9a-f]+:\\).+  \\(.+$\\)"v
     (1 'hexl-address-region t t)
     ;; If `hexl-address-region' is using a variable-pitch font, the
     ;; rest of the line isn't naturally aligned, so align them by hand.
     (2 '(face nil display (space :align-to 10)))
     (3 '(face nil display (space :align-to 51)))
     (4 'hexl-ascii-region t t)))
  "Font lock keywords used in `hexl-mode'.")

(defun hexl-rulerize (string bits)
  (let ((size (/ bits 4)) (strlen (length string)) (pos 0) (ruler ""))
    (while (< pos strlen)
      (setq ruler (concat ruler " " (substring string pos (+ pos size))))
      (setq pos (+ pos size)))
    (substring ruler 1) ))

(defvar hexl-rulers
  (mapcar
   (lambda (bits)
     (cons bits
           (concat " 87654321  "
                   (hexl-rulerize "00112233445566778899aabbccddeeff" bits)
                   "  0123456789abcdef")))
   '(8 16 32 64)))
;; routines

(put 'hexl-mode 'mode-class 'special)

;; 10 chars for the "address: "
;; 32 chars for the hexlified bytes
;; 1 char for the space
;; 16 chars for the character display
;; X chars for the spaces (128 bits divided by the hexl-bits)
;; 1 char for the newline.
(defun hexl-line-displen ()
  "The length of a hexl display line (varies with `hexl-bits')."
  (+ 60 (/ 128 (or hexl-bits 16))))

;;;###autoload
(defun hexl-mode (&optional arg)
  "A mode for editing binary files in hex dump format.
\\<hexl-mode-map>This is not an ordinary major mode; it alters some aspects
of the current mode's behavior, but not all; also, you can exit
Hexl mode and return to the previous mode using \\[hexl-mode-exit].

This function automatically converts a buffer into the hexl format
using the function `hexlify-buffer'.

Each line in the buffer has an \"address\" (displayed in hexadecimal)
representing the offset into the file that the characters on this line
are at and 16 characters from the file (displayed as hexadecimal
values grouped every `hexl-bits' bits, and as their ASCII values).

If any of the characters (displayed as ASCII characters) are
unprintable (control or meta characters) they will be replaced by
periods.

If `hexl-mode' is invoked with an argument the buffer is assumed to be
in hexl format.

A sample format:

  HEX ADDR: 0011 2233 4455 6677 8899 aabb ccdd eeff     ASCII-TEXT
  --------  ---- ---- ---- ---- ---- ---- ---- ----  ----------------
  00000000: 5468 6973 2069 7320 6865 786c 2d6d 6f64  This is hexl-mod
  00000010: 652e 2020 4561 6368 206c 696e 6520 7265  e.  Each line re
  00000020: 7072 6573 656e 7473 2031 3620 6279 7465  presents 16 byte
  00000030: 7320 6173 2068 6578 6164 6563 696d 616c  s as hexadecimal
  00000040: 2041 5343 4949 0a61 6e64 2070 7269 6e74   ASCII.and print
  00000050: 6162 6c65 2041 5343 4949 2063 6861 7261  able ASCII chara
  00000060: 6374 6572 732e 2020 416e 7920 636f 6e74  cters.  Any cont
  00000070: 726f 6c20 6f72 206e 6f6e 2d41 5343 4949  rol or non-ASCII
  00000080: 2063 6861 7261 6374 6572 730a 6172 6520   characters.are
  00000090: 6469 7370 6c61 7965 6420 6173 2070 6572  displayed as per
  000000a0: 696f 6473 2069 6e20 7468 6520 7072 696e  iods in the prin
  000000b0: 7461 626c 6520 6368 6172 6163 7465 7220  table character
  000000c0: 7265 6769 6f6e 2e0a                      region..

Movement is as simple as movement in a normal Emacs text buffer.
Most cursor movement bindings are the same: use \\[hexl-backward-char], \\[hexl-forward-char], \\[hexl-next-line], and \\[hexl-previous-line]
to move the cursor left, right, down, and up.

Advanced cursor movement commands (ala \\[hexl-beginning-of-line], \\[hexl-end-of-line], \\[hexl-beginning-of-buffer], and \\[hexl-end-of-buffer]) are
also supported.

There are several ways to change text in hexl mode:

Self-inserting characters are bound to `hexl-self-insert' so you
can simply type the character and it will insert itself (actually
overstrike) into the buffer.  However, inserting non-ASCII characters
requires caution: the buffer's coding-system should correspond to
the encoding on disk, and multibyte characters should be inserted
with cursor on the first byte of a multibyte sequence whose length
is identical to the length of the multibyte sequence to be inserted,
otherwise this could produce invalid multibyte sequences.  Non-ASCII
characters in ISO-2022 encodings should preferably inserted byte by
byte, to avoid problems caused by the designation sequences before
the actual characters.

\\[hexl-quoted-insert] followed by another keystroke allows you to insert the key even if
it isn't bound to self-insert.  An octal number can be supplied in place
of another key to insert the octal number's ASCII representation.

\\[hexl-insert-hex-char] will insert a given hexadecimal value
into the buffer at the current address.

\\[hexl-insert-octal-char] will insert a given octal value
into the buffer at the current address.

\\[hexl-insert-decimal-char] will insert a given decimal value
into the buffer at the current address..

\\[hexl-mode-exit] will exit `hexl-mode'.

Note: saving the file with any of the usual Emacs commands
will actually convert it back to binary format while saving.

You can use \\[hexl-find-file] to visit a file in Hexl mode.

\\[describe-bindings] for advanced commands."
  (interactive "p")
  (unless (eq major-mode 'hexl-mode)
    (let ((modified (buffer-modified-p))
	  (inhibit-read-only t)
          (point-offset (bufferpos-to-filepos (point) 'exact)))
      ;; If `hexl-mode' is invoked with an argument the buffer is assumed to
      ;; be in hexl format.
      (when (memq arg '(1 nil))
        (hexlify-buffer)
        (restore-buffer-modified-p modified))
      (setq hexl-max-address
            (+ (* (/ (1- (buffer-size)) (hexl-line-displen)) 16) 15))
      (condition-case nil
	  (hexl-goto-address point-offset)
	(error nil)))

    (let ((max-address hexl-max-address))
      (major-mode-suspend)
      (setq hexl-max-address max-address))

    (use-local-map hexl-mode-map)

    (setq-local mode-name "Hexl")
    (setq-local isearch-search-fun-function #'hexl-isearch-search-function)
    (setq-local major-mode 'hexl-mode)

    ;; (set-syntax-table (standard-syntax-table))

    (add-hook 'write-contents-functions #'hexl-save-buffer nil t)

    (setq-local require-final-newline nil)


    (setq-local font-lock-defaults '(hexl-font-lock-keywords t))
    (setq-local font-lock-extra-managed-props '(display))

    (setq-local revert-buffer-function #'hexl-revert-buffer-function)
    (add-hook 'change-major-mode-hook #'hexl-maybe-dehexlify-buffer nil t)

    ;; Set a callback function for eldoc.
    (add-hook 'eldoc-documentation-functions
              #'hexl-print-current-point-info nil t)
    (eldoc-add-command-completions "hexl-")
    (eldoc-remove-command "hexl-save-buffer"
			  "hexl-current-address")

    (if hexl-follow-ascii (hexl-follow-ascii-mode 1)))
  (run-mode-hooks 'hexl-mode-hook))


(defun hexl-isearch-search-function ()
  (if (and (not isearch-regexp) (not isearch-regexp-function))
      (lambda (string &optional bound noerror count)
	(funcall
	 (if isearch-forward 're-search-forward 're-search-backward)
         (let ((textre
                (if (> (length string) 80)
                    (regexp-quote string)
                  (mapconcat (lambda (c) (regexp-quote (string c))) string
                             "\\(?:\n\\(?:[:a-f0-9]+ \\)+ \\)?"))))
           (if (string-match "\\` ?\\([a-f0-9]+ \\)*[a-f0-9]+ ?\\'" string)
               (concat textre "\\|"
                       (mapconcat 'regexp-quote (split-string string " ")
                                  " \\(?: .+\n[a-f0-9]+: \\)?"))
             textre))
	 bound noerror count))
    (isearch-search-fun-default)))

(defvar hexl-in-save-buffer nil)

(defun hexl-save-buffer ()
  "Save a hexl format buffer as binary in visited file if modified."
  (interactive)
  (if hexl-in-save-buffer nil
    (restore-buffer-modified-p
     (if (buffer-modified-p)
         (let ((buf (generate-new-buffer " hexl"))
               (name (buffer-name))
               (start (point-min))
               (end (point-max))
               modified)
           (with-current-buffer buf
             (insert-buffer-substring name start end)
             (set-buffer name)
             (dehexlify-buffer)
             ;; Prevent infinite recursion.
             (let ((hexl-in-save-buffer t))
               (save-buffer))
             (setq modified (buffer-modified-p))
             (delete-region (point-min) (point-max))
             (insert-buffer-substring buf start end)
             (kill-buffer buf)
             modified))
       (message "(No changes need to be saved)")
       nil))
    ;; Return t to indicate we have saved t
    t))

;;;###autoload
(defun hexl-find-file (filename)
  "Edit file FILENAME as a binary file in hex dump format.
Switch to a buffer visiting file FILENAME, creating one if none exists,
and edit the file in `hexl-mode'.  The buffer's coding-system will be
no-conversion, unlike if you visit it normally and then invoke `hexl-mode'."
  (interactive
   (list
    (let ((completion-ignored-extensions nil))
      (read-file-name "Filename: " nil nil 'ret-must-match))))
  ;; Ignore the user's setting of default major-mode.
  (cl-letf (((default-value 'major-mode) 'fundamental-mode))
    (find-file-literally filename))
  (if (not (eq major-mode 'hexl-mode))
      (hexl-mode)))

(defun hexl-revert-buffer-function (_ignore-auto _noconfirm)
  ;; FIXME: We don't obey revert-buffer-preserve-modes!
  (let ((coding-system-for-read 'no-conversion)
	revert-buffer-function)
    ;; Call the original `revert-buffer' without code conversion; also
    ;; prevent it from changing the major mode to normal-mode, which
    ;; calls `set-auto-mode'.
    (revert-buffer nil nil t)
    ;; A couple of hacks are necessary here:
    ;; 1. change the major-mode to one other than hexl-mode since the
    ;; function `hexl-mode' does nothing if the current major-mode is
    ;; already hexl-mode.
    ;; 2. reset change-major-mode-hook in case that `hexl-mode'
    ;; previously added hexl-maybe-dehexlify-buffer to it.
    (remove-hook 'change-major-mode-hook #'hexl-maybe-dehexlify-buffer t)
    (remove-hook 'eldoc-documentation-functions
                 #'hexl-print-current-point-info t)
    (setq major-mode 'fundamental-mode)
    (hexl-mode)))

(defun hexl-mode-exit (&optional arg)
  "Exit Hexl mode, returning to previous mode.
With arg, don't unhexlify buffer."
  (interactive "p")
  (if (or (eq arg 1) (not arg))
      (let ((modified (buffer-modified-p))
	    (inhibit-read-only t)
            (point-offset (hexl-current-address)))
	(dehexlify-buffer)
	(remove-hook 'write-contents-functions #'hexl-save-buffer t)
	(restore-buffer-modified-p modified)
	(goto-char (filepos-to-bufferpos point-offset 'exact))))

  (remove-hook 'change-major-mode-hook #'hexl-maybe-dehexlify-buffer t)
  (major-mode-restore))

(defun hexl-maybe-dehexlify-buffer ()
  "Convert a hexl format buffer to binary.
Ask the user for confirmation."
  (if (y-or-n-p "Convert contents back to binary format? ")
      (let ((modified (buffer-modified-p))
	    (inhibit-read-only t)
            (point-offset (hexl-current-address)))
	(dehexlify-buffer)
	(remove-hook 'write-contents-functions #'hexl-save-buffer t)
	(restore-buffer-modified-p modified)
	(goto-char (filepos-to-bufferpos point-offset 'exact)))))

(defun hexl-current-address (&optional validate)
  "Return current hexl-address."
  (interactive)
  (let ((current-column
         (- (% (- (point) (point-min) -1) (hexl-line-displen)) 11))
	(hexl-address 0))
    (if (< current-column 0)
	(if validate
	    (error "Point is not on a character in the file")
	  (setq current-column 0)))
    (setq hexl-address
          (+ (* (/ (- (point) (point-min) -1)
                   (hexl-line-displen)) 16)
	     (if (>= current-column (- (hexl-ascii-start-column) 10))
		 (- current-column (- (hexl-ascii-start-column) 10))
               (/ (- current-column
                     (/ current-column (1+ (/ hexl-bits 4)))) 2))))
    (when (called-interactively-p 'interactive)
      (message "Current address is %d/0x%08x" hexl-address hexl-address))
    hexl-address))

(defun hexl-print-current-point-info (&rest _ignored)
  "Return current hexl-address in string.
This function is intended to be used as eldoc callback."
  (let ((addr (hexl-current-address)))
    (format "Current address is %d/0x%08x" addr addr)))

(defun hexl-ascii-start-column ()
  "Column at which the ASCII portion of the hexl display starts."
  (+ 43 (/ 128 hexl-bits)))

(defun hexl-address-to-marker (address)
  "Return buffer position for ADDRESS."
  (interactive "nAddress: ")
  (let ((N (* (% address 16) 2)))
    (+ (* (/ address 16) (hexl-line-displen)) ; hexl line no * display length
       10                      ; 10 chars for the "address: " prefix
       (point-min)             ; base offset (point usually starts at 1, not 0)
       (+ N (/ N (/ hexl-bits 4))) )) ) ; char offset into hexl display line

(defun hexl-goto-address (address)
  "Go to `hexl-mode' (decimal) address ADDRESS.
Signal error if ADDRESS is out of range."
  (interactive "nAddress: ")
  (if (or (< address 0) (> address hexl-max-address))
      (error "Out of hexl region"))
  (goto-char (hexl-address-to-marker address)))

(defun hexl-goto-hex-address (hex-address)
  "Go to Hexl mode address (hex string) HEX-ADDRESS.
Signal error if HEX-ADDRESS is out of range."
  (interactive "sHex Address: ")
  (hexl-goto-address (hexl-hex-string-to-integer hex-address)))

(defun hexl-hex-string-to-integer (hex-string)
  "Return decimal integer for HEX-STRING."
  (interactive "sHex number: ")
  (let ((hex-num 0))
    (while (not (equal hex-string ""))
      (setq hex-num (+ (* hex-num 16)
		       (hexl-hex-char-to-integer (string-to-char hex-string))))
      (setq hex-string (substring hex-string 1)))
    hex-num))

(defun hexl-octal-string-to-integer (octal-string)
  "Return decimal integer for OCTAL-STRING."
  (interactive "sOctal number: ")
  (let ((oct-num 0))
    (while (not (equal octal-string ""))
      (setq oct-num (+ (* oct-num 8)
		       (hexl-oct-char-to-integer
			(string-to-char octal-string))))
      (setq octal-string (substring octal-string 1)))
    oct-num))

;; move point functions

(defun hexl-backward-char (arg)
  "Move to left ARG bytes (right if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-goto-address (- (hexl-current-address) arg)))

(defun hexl-forward-char (arg)
  "Move to right ARG bytes (left if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-goto-address (+ (hexl-current-address) arg)))

(defun hexl-backward-short (arg)
  "Move to left ARG shorts (right if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-goto-address (let ((address (hexl-current-address)))
		       (if (< arg 0)
			   (progn
			     (setq arg (- arg))
			     (while (> arg 0)
                               (setq address
                                     (if (> address hexl-max-address)
                                         (progn
                                           (message "End of buffer.")
                                           hexl-max-address)
                                       (if (equal address (logior address 3))
                                           (+ address 4)
                                         (logior address 3))))
			       (setq arg (1- arg)))
                             (setq address
                                   (if (> address hexl-max-address)
                                       (progn
                                         (message "End of buffer.")
                                         hexl-max-address)
                                     (logior address 3))))
			 (while (> arg 0)
			   (if (not (equal address (logand address -4)))
			       (setq address (logand address -4))
			     (if (not (equal address 0))
				 (setq address (- address 4))
			       (message "Beginning of buffer.")))
			   (setq arg (1- arg))))
		       address)))

(defun hexl-forward-short (arg)
  "Move to right ARG shorts (left if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-backward-short (- arg)))

(defun hexl-backward-word (arg)
  "Move to left ARG words (right if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-goto-address (let ((address (hexl-current-address)))
		       (if (< arg 0)
			   (progn
			     (setq arg (- arg))
			     (while (> arg 0)
                               (setq address
                                     (if (> address hexl-max-address)
                                         (progn
                                           (message "End of buffer.")
                                           hexl-max-address)
                                       (if (equal address (logior address 7))
                                           (+ address 8)
                                         (logior address 7))))
			       (setq arg (1- arg)))
                             (setq address
                                   (if (> address hexl-max-address)
                                       (progn
                                         (message "End of buffer.")
                                         hexl-max-address)
                                     (logior address 7))))
			 (while (> arg 0)
			   (if (not (equal address (logand address -8)))
			       (setq address (logand address -8))
			     (if (not (equal address 0))
				 (setq address (- address 8))
			       (message "Beginning of buffer.")))
			   (setq arg (1- arg))))
		       address)))

(defun hexl-forward-word (arg)
  "Move to right ARG words (left if ARG negative) in Hexl mode."
  (interactive "p")
  (hexl-backward-word (- arg)))

(defun hexl-previous-line (arg)
  "Move vertically up ARG lines [16 bytes] (down if ARG negative) in Hexl mode.
If there is no byte at the target address move to the last byte in that line."
  (interactive "p")
  (hexl-next-line (- arg)))

(defun hexl-next-line (arg)
  "Move vertically down ARG lines [16 bytes] (up if ARG negative) in Hexl mode.
If there is no byte at the target address move to the last byte in that line."
  (interactive "p")
  (hexl-goto-address (let ((address (+ (hexl-current-address) (* arg 16))))
		       (if (and (< arg 0) (< address 0))
				(progn (message "Out of hexl region.")
				       (setq address
					     (% (hexl-current-address) 16)))
			 (if (and (> address hexl-max-address)
				  (< (% hexl-max-address 16) (% address 16)))
			     (setq address hexl-max-address)
			   (if (> address hexl-max-address)
			       (progn (message "Out of hexl region.")
				      (setq
				       address
				       (+ (logand hexl-max-address -16)
					  (% (hexl-current-address) 16)))))))
		       address)))

(defun hexl-beginning-of-buffer (arg)
  "Move to the beginning of the hexl buffer.
Leaves mark at previous position.
With prefix arg N, puts point N bytes of the way from the true beginning."
  (interactive "p")
  (push-mark)
  (hexl-goto-address (+ 0 (1- arg))))

(defun hexl-end-of-buffer (arg)
  "Go to `hexl-max-address' minus ARG."
  (interactive "p")
  (push-mark)
  (hexl-goto-address (- hexl-max-address (1- arg))))

(defun hexl-beginning-of-line ()
  "Goto beginning of line in Hexl mode."
  (interactive)
  (goto-char (+ (* (/ (point) (hexl-line-displen)) (hexl-line-displen)) 11)))

(defun hexl-end-of-line ()
  "Goto end of line in Hexl mode."
  (interactive)
  (hexl-goto-address (min hexl-max-address (logior (hexl-current-address) 15))))

(defun hexl-scroll-down (arg)
  "Scroll hexl buffer window upward ARG lines; or near full window if no ARG."
  (interactive "P")
  (setq arg (if (null arg)
                (- (window-height)
                   1
                   (if ruler-mode 1 0)
                   next-screen-context-lines)
              (prefix-numeric-value arg)))
  (hexl-scroll-up (- arg)))

(defun hexl-scroll-up (arg)
  "Scroll hexl buffer window upward ARG lines; or near full window if no ARG.
If there's no byte at the target address, move to the first or last line."
  (interactive "P")
  (setq arg (if (null arg)
                (- (window-height)
                   1
                   (if ruler-mode 1 0)
                   next-screen-context-lines)
              (prefix-numeric-value arg)))
  (let* ((movement (* arg 16))
	 (address (hexl-current-address))
	 (dest (+ address movement)))
    (cond
     ;; If possible, try to stay at the same offset from the beginning
     ;; of the 16-byte group, even if we move to the first or last
     ;; group.
     ((and (> dest hexl-max-address)
	   (>= (% hexl-max-address 16) (% address 16)))
      (setq dest (+ (logand hexl-max-address -16) (% address 16))))
     ((> dest hexl-max-address)
      (setq dest hexl-max-address))
     ((< dest 0)
      (setq dest (% address 16))))
    (if (/= dest (+ address movement))
	(message "Out of hexl region."))
    (hexl-goto-address dest)
    (recenter 0)))

(defun hexl-beginning-of-1k-page ()
  "Go to beginning of 1KB boundary."
  (interactive)
  (hexl-goto-address (logand (hexl-current-address) -1024)))

(defun hexl-end-of-1k-page ()
  "Go to end of 1KB boundary."
  (interactive)
  (hexl-goto-address
   (min hexl-max-address (logior (hexl-current-address) 1023))))

(defun hexl-beginning-of-512b-page ()
  "Go to beginning of 512 byte boundary."
  (interactive)
  (hexl-goto-address (logand (hexl-current-address) -512)))

(defun hexl-end-of-512b-page ()
  "Go to end of 512 byte boundary."
  (interactive)
  (hexl-goto-address
   (min hexl-max-address (logior (hexl-current-address) 511))))

(defun hexl-quoted-insert (arg)
  "Read next input character and insert it.
Useful for inserting control characters and non-ASCII characters given their
numerical code.
You may also type octal digits, to insert a character with that code."
  (interactive "p")
  (hexl-insert-multibyte-char (read-quoted-char) arg))

;00000000: 0011 2233 4455 6677 8899 aabb ccdd eeff  0123456789ABCDEF

(defun hexl-options (&optional test)
  "Combine `hexl-bits' with `hexl-options', altering `hexl-options' as needed
to produce the command line options to pass to the hexl command."
  (let ((opts (or test hexl-options)))
    (when (memq hexl-bits '(8 16 32 64))
      (when (string-match "\\(.*\\)-group-by-[0-9]+-bits\\(.*\\)" opts)
        (setq opts (concat (match-string 1 opts)
                           (match-string 2 opts))))
      (setq opts (format "%s -group-by-%d-bits " opts hexl-bits)) )
    opts))

;;;###autoload
(defun hexlify-buffer ()
  "Convert a binary buffer to hexl format.
This discards the buffer's undo information."
  (interactive)
  (and (consp buffer-undo-list)
       (or (y-or-n-p "Converting to hexl format discards undo info; ok? ")
	   (error "Aborted"))
       (setq buffer-undo-list nil))
  ;; Don't decode text in the ASCII part of `hexl' program output.
  (let ((coding-system-for-read 'raw-text)
	(coding-system-for-write buffer-file-coding-system)
	(buffer-undo-list t))
    (apply 'call-process-region (point-min) (point-max)
	   (expand-file-name hexl-program exec-directory)
	   t t nil
           ;; Manually encode the args, otherwise they're encoded using
           ;; coding-system-for-write (i.e. buffer-file-coding-system) which
           ;; may not be what we want (e.g. utf-16 on a non-utf-16 system).
           (mapcar (lambda (s)
                     (if (not (multibyte-string-p s)) s
                       (encode-coding-string s locale-coding-system)))
                   (split-string (hexl-options))))
    (if (> (point) (hexl-address-to-marker hexl-max-address))
	(hexl-goto-address hexl-max-address))))

(defun dehexlify-buffer ()
  "Convert a hexl format buffer to binary.
This discards the buffer's undo information."
  (interactive)
  (and (consp buffer-undo-list)
       (or (y-or-n-p "Converting from hexl format discards undo info; ok? ")
	   (error "Aborted"))
       (setq buffer-undo-list nil))
  (let ((coding-system-for-write 'raw-text)
	(coding-system-for-read buffer-file-coding-system)
	(buffer-undo-list t))
    (apply 'call-process-region (point-min) (point-max)
	   (expand-file-name hexl-program exec-directory)
	   t t nil "-de" (split-string (hexl-options)))))

(defun hexl-char-after-point ()
  "Return char for ASCII hex digits at point."
  (hexl-htoi (char-after (point))
	     (char-after (1+ (point)))))

(defun hexl-htoi (lh rh)
  "Hex (char) LH (char) RH to integer."
    (+ (* (hexl-hex-char-to-integer lh) 16)
       (hexl-hex-char-to-integer rh)))

(defun hexl-hex-char-to-integer (character)
  "Take a char and return its value as if it was a hex digit."
  (if (and (>= character ?0) (<= character ?9))
      (- character ?0)
    (let ((ch (logior character 32)))
      (if (and (>= ch ?a) (<= ch ?f))
	  (- ch (- ?a 10))
	(error "Invalid hex digit `%c'" ch)))))

(defun hexl-oct-char-to-integer (character)
  "Take a char and return its value as if it was an octal digit."
  (if (and (>= character ?0) (<= character ?7))
      (- character ?0)
    (error "Invalid octal digit `%c'" character)))

(defun hexl-printable-character (ch)
  "Return a displayable string for character CH."
  (format "%c" (if (equal hexl-iso "")
		   (if (or (< ch 32) (>= ch 127))
		       46
		     ch)
		 (if (or (< ch 32) (and (>= ch 127) (< ch 160)))
		     46
		   ch))))

(defun hexl-insert-multibyte-char (ch num)
  "Insert a possibly multibyte character CH NUM times.

Non-ASCII characters are first encoded with `buffer-file-coding-system',
and their encoded form is inserted byte by byte.  Note that if the
hexl buffer was produced by `hexl-find-file', its coding-system
is no-conversion.

Inserting non-ASCII characters requires caution: the buffer's
coding-system should correspond to the encoding on disk, and
multibyte characters should be inserted with cursor on the first
byte of a multibyte sequence whose length is identical to the
length of the multibyte sequence to be inserted, otherwise this
could produce invalid multibyte sequences.  Non-ASCII characters
in ISO-2022 encodings should preferably inserted byte by byte, to
avoid problems caused by the designation sequences before the
actual characters."
  (let ((charset (char-charset ch))
	(coding (if (or (null buffer-file-coding-system)
			;; coding-system-type equals t means undecided.
			(eq (coding-system-type buffer-file-coding-system) t))
		    (default-value 'buffer-file-coding-system)
		  buffer-file-coding-system)))
    (cond ((and (>= ch 0) (< ch 256)
                (coding-system-get coding :ascii-compatible-p))
	   (hexl-insert-char ch num))
	  ((eq charset 'unknown)
	   (error
	    "0x%x -- invalid character code; use \\[hexl-insert-hex-string]"
	    ch))
	  (t
           (let ((encoded (encode-coding-char ch coding))
	         (internal (char-to-string ch))
	         internal-hex)
             ;; If encode-coding-char returns nil, it means our character
             ;; cannot be safely encoded with buffer-file-coding-system.
             ;; In that case, we offer to insert the internal representation
             ;; of that character, byte by byte.
             (when (null encoded)
	       (setq internal (encode-coding-string internal 'utf-8-emacs)
	             internal-hex
                     (mapconcat (lambda (c) (format "%x" c))
			        internal " "))
	       (if (yes-or-no-p
		    (format-message
		     "Insert char 0x%x's internal representation \"%s\"? "
		     ch internal-hex))
		   (setq encoded internal)
		 (error
		  "Can't encode `0x%x' with this buffer's coding system; %s"
		  ch
		  (substitute-command-keys "try \\[hexl-insert-hex-string]"))))
	     (while (> num 0)
	       (mapc
                (lambda (c) (hexl-insert-char c 1)) encoded)
	       (setq num (1- num))))))))

(defun hexl-self-insert-command (arg)
  "Insert this character.
Interactively, with a numeric argument, insert this character that many times.

Non-ASCII characters are first encoded with `buffer-file-coding-system',
and their encoded form is inserted byte by byte.  Note that if the
hexl buffer was produced by `hexl-find-file', its coding-system
is no-conversion.

Inserting non-ASCII characters requires caution: the buffer's
coding-system should correspond to the encoding on disk, and
multibyte characters should be inserted with cursor on the first
byte of a multibyte sequence whose length is identical to the
length of the multibyte sequence to be inserted, otherwise this
could produce invalid multibyte sequences.  Non-ASCII characters
in ISO-2022 encodings should preferably inserted byte by byte, to
avoid problems caused by the designation sequences before the
actual characters."
  (interactive "p")
  (hexl-insert-multibyte-char last-command-event arg))

(defun hexl-insert-char (ch num)
  "Insert the character CH NUM times in a hexl buffer.

CH must be a unibyte character whose value is between 0 and 255."
  (if (or (< ch 0) (> ch 255))
      (error "Invalid character 0x%x -- must be in the range [0..255]" ch))
  (let ((address (hexl-current-address t)))
    (while (> num 0)
      (let ((hex-position (hexl-address-to-marker address))
	    (ascii-position
	     (+ (* (/ address 16) (hexl-line-displen))
                (hexl-ascii-start-column)
                (point-min)
                (% address 16)))
	    at-ascii-position)
	(if (= (point) ascii-position)
	    (setq at-ascii-position t))
	(goto-char hex-position)
	(delete-char 2)
	(insert (format "%02x" ch))
	(goto-char ascii-position)
	(delete-char 1)
	(insert (hexl-printable-character ch))
	(or (= address hexl-max-address)
	    (setq address (1+ address)))
	(hexl-goto-address address)
	(if at-ascii-position
	    (progn
	      (beginning-of-line)
	      (forward-char (hexl-ascii-start-column))
	      (forward-char (% address 16)))))
      (setq num (1- num)))))

;; hex conversion

(defun hexl-insert-hex-char (arg)
  "Insert a character given by its hexadecimal code ARG times at point.

Values above 0xFF are treated as multibyte characters, and first encoded
using `buffer-file-coding-system'.  Note that if the hexl buffer was
produced by `hexl-find-file', its coding-system is no-conversion.

Inserting non-ASCII characters requires caution: the buffer's
coding-system should correspond to the encoding on disk, and
multibyte characters should be inserted with cursor on the first
byte of a multibyte sequence whose length is identical to the
length of the multibyte sequence to be inserted, otherwise this
could produce invalid multibyte sequences.  Non-ASCII characters
in ISO-2022 encodings should preferably inserted byte by byte, to
avoid problems caused by the designation sequences before the
actual characters."
  (interactive "p")
  (let ((num (hexl-hex-string-to-integer (read-string "Hex number: "))))
    (if (< num 0)
	(error "Hex number out of range")
      (hexl-insert-multibyte-char num arg))))

(defun hexl-insert-hex-string (str arg)
  "Insert hexadecimal string STR at point ARG times.
Embedded whitespace, dashes, and periods in the string are ignored."
  (interactive "sHex string: \np")
  (setq str (replace-regexp-in-string "[- \t.]" "" str))
  (let ((chars '()))
    (let ((len (length str))
	  (idx 0))
      (if (oddp len)
	  (let ((num (hexl-hex-string-to-integer (substring str 0 1))))
	    (setq chars (cons num chars))
	    (setq idx 1)))
      (while (< idx len)
	(let* ((nidx (+ idx 2))
	       (num (hexl-hex-string-to-integer (substring str idx nidx))))
	  (setq chars (cons num chars))
	  (setq idx nidx))))
    (setq chars (nreverse chars))
    (while (> arg 0)
      (let ((chars chars))
	(while chars
	  (hexl-insert-char (car chars) 1)
	  (setq chars (cdr chars))))
      (setq arg (- arg 1)))))

(defun hexl-insert-decimal-char (arg)
  "Insert a character given by its decimal code ARG times at point.

Values above 256 are treated as multibyte characters, and first encoded
using `buffer-file-coding-system'.  Note that if the hexl buffer was
produced by `hexl-find-file', its coding-system is no-conversion.

Inserting non-ASCII characters requires caution: the buffer's
coding-system should correspond to the encoding on disk, and
multibyte characters should be inserted with cursor on the first
byte of a multibyte sequence whose length is identical to the
length of the multibyte sequence to be inserted, otherwise this
could produce invalid multibyte sequences.  Non-ASCII characters
in ISO-2022 encodings should preferably inserted byte by byte, to
avoid problems caused by the designation sequences before the
actual characters."
  (interactive "p")
  (let ((num (string-to-number (read-string "Decimal Number: "))))
    (if (< num 0)
	(error "Decimal number out of range")
      (hexl-insert-multibyte-char num arg))))

(defun hexl-insert-octal-char (arg)
  "Insert a character given by its octal code ARG times at point.

Values above \377 are treated as multibyte characters, and first encoded
using `buffer-file-coding-system'.  Note that if the hexl buffer was
produced by `hexl-find-file', its coding-system is no-conversion.

Inserting non-ASCII characters requires caution: the buffer's
coding-system should correspond to the encoding on disk, and
multibyte characters should be inserted with cursor on the first
byte of a multibyte sequence whose length is identical to the
length of the multibyte sequence to be inserted, otherwise this
could produce invalid multibyte sequences.  Non-ASCII characters
in ISO-2022 encodings should preferably inserted byte by byte, to
avoid problems caused by the designation sequences before the
actual characters."
  (interactive "p")
  (let ((num (hexl-octal-string-to-integer (read-string "Octal Number: "))))
    (if (< num 0)
	(error "Decimal number out of range")
      (hexl-insert-multibyte-char num arg))))

(define-minor-mode hexl-follow-ascii-mode
  "Minor mode to follow ASCII in current Hexl buffer.

When following is enabled, the ASCII character corresponding to the
element under the point is highlighted.
The default activation is controlled by `hexl-follow-ascii'."
  :global nil
  (if hexl-follow-ascii-mode
      ;; turn it on
      (progn
        (unless hexl-ascii-overlay
	  (setq hexl-ascii-overlay (make-overlay (point) (point)))
	  (overlay-put hexl-ascii-overlay 'face 'highlight))
        (add-hook 'post-command-hook #'hexl-follow-ascii-find nil t))
      ;; turn it off
      (when hexl-ascii-overlay
        (delete-overlay hexl-ascii-overlay)
        (setq hexl-ascii-overlay nil))
      (remove-hook 'post-command-hook #'hexl-follow-ascii-find t)))

(define-minor-mode hexl-follow-ascii
  "Toggle following ASCII in Hexl buffers.
Like `hexl-follow-ascii-mode' but remembers the choice globally."
  :global t
  (let ((on-p (if arg
		  (> (prefix-numeric-value arg) 0)
	       (not hexl-ascii-overlay))))
    (hexl-follow-ascii-mode (if on-p 1 -1))
    ;; Remember this choice globally for later use.
    (setq hexl-follow-ascii hexl-follow-ascii-mode)))

(defun hexl-activate-ruler ()
  "Activate `ruler-mode'."
  (require 'ruler-mode)
  (setq-local ruler-mode-ruler-function #'hexl-mode-ruler)
  (ruler-mode 1))

(defun hexl-follow-line ()
  "Activate `hl-line-mode'."
  (require 'hl-line)
  (setq-local hl-line-range-function #'hexl-highlight-line-range)
  (setq-local hl-line-face 'highlight)  ;FIXME: Why?
  (hl-line-mode 1))

(defun hexl-highlight-line-range ()
  "Return the range of address region for the point.
This function is assumed to be used as callback function for `hl-line-mode'."
  (cons
   (line-beginning-position)
   ;; 9 stands for (length "87654321:")
   (+ (line-beginning-position) 9)))

(defun hexl-follow-ascii-find ()
  "Find and highlight the ASCII element corresponding to current point."
  (let ((pos (+ (hexl-ascii-start-column)
		(- (point) (current-column))
		(mod (hexl-current-address) 16))))
    (move-overlay hexl-ascii-overlay pos (1+ pos))
    ))

(defun hexl-mode-ruler ()
  "Return a string ruler for Hexl mode."
  (let* ((highlight (mod (hexl-current-address) 16))
	 (s (cdr (assq hexl-bits hexl-rulers)))
	 (pos 0)
         (lnum-width
          (if display-line-numbers
              (round (line-number-display-width 'columns))
            0)))
    (set-text-properties 0 (length s) nil s)
    (when (> lnum-width 0)
      (setq s (concat (make-string lnum-width ?  ) s))
      (setq pos (+ pos lnum-width)))
    ;; Turn spaces in the header into stretch specs so they work
    ;; regardless of the header-line face.
    (while (string-match "[ \t]+" s pos)
      (setq pos (match-end 0))
      (put-text-property (match-beginning 0) pos 'display
			 ;; Assume fixed-size chars
			 `(space :align-to ,(1- pos))
			 s))
    ;; Highlight the current column.
    (let ( (offset (+ (* 2 highlight) (/ (* 8 highlight) hexl-bits))) )
      (if (> lnum-width 0) (setq offset (+ offset lnum-width)))
      (put-text-property (+ 11 offset) (+ 13 offset) 'face 'highlight s))
    ;; Highlight the current ascii column
    (put-text-property (+ (hexl-ascii-start-column) lnum-width highlight 1)
                       (+ (hexl-ascii-start-column) lnum-width highlight 2)
                       'face 'highlight s)
    s))

;; startup stuff.

(easy-menu-define hexl-menu hexl-mode-map "Hexl Mode menu."
  '("Hexl"
    :help "Hexl-specific Features"

    ["Backward short" hexl-backward-short
     :help "Move to left a short"]
    ["Forward short" hexl-forward-short
     :help "Move to right a short"]
    ["Backward word" hexl-backward-short
     :help "Move to left a word"]
    ["Forward word" hexl-forward-short
     :help "Move to right a word"]
    "-"
    ["Beginning of 512b page" hexl-beginning-of-512b-page
     :help "Go to beginning of 512 byte boundary"]
    ["End of 512b page" hexl-end-of-512b-page
     :help "Go to end of 512 byte boundary"]
    ["Beginning of 1K page" hexl-beginning-of-1k-page
     :help "Go to beginning of 1KB boundary"]
    ["End of 1K page" hexl-end-of-1k-page
     :help "Go to end of 1KB boundary"]
    "-"
    ["Go to address" hexl-goto-address
     :help "Go to hexl-mode (decimal) address"]
    ["Go to address" hexl-goto-hex-address
     :help "Go to hexl-mode (hex string) address"]
    "-"
    ["Insert decimal char" hexl-insert-decimal-char
     :help "Insert a character given by its decimal code"]
    ["Insert hex char" hexl-insert-hex-char
     :help "Insert a character given by its hexadecimal code"]
    ["Insert octal char" hexl-insert-octal-char
     :help "Insert a character given by its octal code"]
    "-"
    ["Exit hexl mode" hexl-mode-exit
     :help "Exit hexl mode returning to previous mode"]))

(provide 'hexl)

;;; hexl.el ends here
