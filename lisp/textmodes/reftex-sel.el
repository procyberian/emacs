;;; reftex-sel.el --- the selection modes for RefTeX  -*- lexical-binding: t; -*-

;; Copyright (C) 1997-2025 Free Software Foundation, Inc.

;; Author: Carsten Dominik <carsten.dominik@gmail.com>
;; Maintainer: auctex-devel@gnu.org

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

(eval-when-compile (require 'cl-lib))

(require 'reftex)

;; Common bindings in reftex-select-label-mode-map
;; and reftex-select-bib-mode-map.
(defvar reftex-select-shared-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map [remap next-line] #'reftex-select-next)
    (define-key map [remap previous-line] #'reftex-select-previous)
    (define-key map [remap keyboard-quit] #'reftex-select-keyboard-quit)
    (define-key map [remap newline] #'reftex-select-accept)

    (define-key map " " #'reftex-select-callback)
    (define-key map "n" #'reftex-select-next)
    (define-key map [(down)] #'reftex-select-next)
    (define-key map "p" #'reftex-select-previous)
    (define-key map [(up)] #'reftex-select-previous)
    (define-key map "f" #'reftex-select-toggle-follow)
    (define-key map "\C-m" #'reftex-select-accept)
    (define-key map [(return)] #'reftex-select-accept)
    (define-key map "q" #'reftex-select-quit)
    (define-key map "." #'reftex-select-show-insertion-point)
    (define-key map "?" #'reftex-select-help)

    ;; The mouse-2 binding
    (define-key map [(mouse-2)] #'reftex-select-mouse-accept)
    (define-key map [follow-link] 'mouse-face)
    map))

(defvar reftex-select-label-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map reftex-select-shared-map)

    (mapc (lambda (key)
            (define-key map (vector (list key))
              (lambda ()
                "Press `?' during selection to find out about this key."
                (interactive) (throw 'myexit key))))
          "aAcgFlrRstx#%")

    (define-key map "b" #'reftex-select-jump-to-previous)
    (define-key map "z" #'reftex-select-jump)
    (define-key map "v" #'reftex-select-cycle-ref-style-forward)
    (define-key map "V" #'reftex-select-cycle-ref-style-backward)
    (define-key map "m" #'reftex-select-mark)
    (define-key map "u" #'reftex-select-unmark)
    (define-key map "," #'reftex-select-mark-comma)
    (define-key map "-" #'reftex-select-mark-to)
    (define-key map "+" #'reftex-select-mark-and)
    (define-key map [(tab)] #'reftex-select-read-label)
    (define-key map "\C-i" #'reftex-select-read-label)
    (define-key map "\C-c\C-n" #'reftex-select-next-heading)
    (define-key map "\C-c\C-p" #'reftex-select-previous-heading)

    map)
  "Keymap used for *RefTeX Select* buffer, when selecting a label.
This keymap can be used to configure the label selection process which is
started with the command \\[reftex-reference].")

;;;###autoload
(define-derived-mode reftex-select-label-mode special-mode "LSelect"
  "Major mode for selecting a label in a LaTeX document.
This buffer was created with RefTeX.
It only has a meaningful keymap when you are in the middle of a
selection process.
To select a label, move the cursor to it and press RET.
Press `?' for a summary of important key bindings.

During a selection process, these are the local bindings.

\\{reftex-select-label-mode-map}"
  (setq-local reftex-select-marked nil)
  (setq truncate-lines t)
  (setq mode-line-format
        (list "----  " 'mode-line-buffer-identification
              "  " 'global-mode-string "   (" mode-name ")"
              "  S<" 'reftex-refstyle ">"
              " -%-"))
  (when (syntax-table-p reftex-latex-syntax-table)
    (set-syntax-table reftex-latex-syntax-table))
  ;; We do not set a local map - reftex-select-item does this.
  )

(defvar reftex-select-bib-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map reftex-select-shared-map)

    (mapc (lambda (key)
            (define-key map (vector (list key))
              (lambda ()
                "Press `?' during selection to find out about this key."
                (interactive) (throw 'myexit key))))
          "grRaAeE")

    (define-key map "\C-i" #'reftex-select-read-cite)
    (define-key map [(tab)] #'reftex-select-read-cite)
    (define-key map "m" #'reftex-select-mark)
    (define-key map "u" #'reftex-select-unmark)

    map)
  "Keymap used for *RefTeX Select* buffer, when selecting a BibTeX entry.
This keymap can be used to configure the BibTeX selection process which is
started with the command \\[reftex-citation].")

;;;###autoload
(define-derived-mode reftex-select-bib-mode special-mode "BSelect"
  "Major mode for selecting a citation key in a LaTeX document.
This buffer was created with RefTeX.
It only has a meaningful keymap when you are in the middle of a
selection process.
In order to select a citation, move the cursor to it and press RET.
Press `?' for a summary of important key bindings.

During a selection process, these are the local bindings.

\\{reftex-select-label-mode-map}"
  (setq-local reftex-select-marked nil)
  ;; We do not set a local map - reftex-select-item does this.
  )

;; (defun reftex-get-offset (buf here-am-I &optional typekey toc index file)
;;   ;; Find the correct offset data, like insert-docstruct would, but faster.
;;   ;; Buffer BUF knows the correct docstruct to use.
;;   ;; Basically this finds the first docstruct entry after HERE-I-AM which
;;   ;; is of allowed type.  The optional arguments specify what is allowed.
;;   (catch 'exit
;;     (with-current-buffer buf
;;       (reftex-access-scan-info)
;;       (let* ((rest (memq here-am-I (symbol-value reftex-docstruct-symbol)))
;;          entry)
;;     (while (setq entry (pop rest))
;;       (if (or (and typekey
;;                    (stringp (car entry))
;;                    (or (equal typekey " ")
;;                        (equal typekey (nth 1 entry))))
;;               (and toc (eq (car entry) 'toc))
;;               (and index (eq (car entry) 'index))
;;               (and file
;;                    (memq (car entry) '(bof eof file-error))))
;;           (throw 'exit entry)))
;;     nil))))

;;;###autoload
(defun reftex-get-offset (buf here-am-I &optional typekey toc index file)
  ;; Find the correct offset data, like insert-docstruct would, but faster.
  ;; Buffer BUF knows the correct docstruct to use.
  ;; Basically this finds the first docstruct entry before HERE-I-AM which
  ;; is of allowed type.  The optional arguments specify what is allowed.
  (catch 'exit
    (with-current-buffer buf
      (reftex-access-scan-info)
      (let* ((rest (symbol-value reftex-docstruct-symbol))
             lastentry entry)
        (while (setq entry (pop rest))
          (if (or (and typekey
                       (stringp (car entry))
                       (or (equal typekey " ")
                           (equal typekey (nth 1 entry))))
                  (and toc (eq (car entry) 'toc))
                  (and index (eq (car entry) 'index))
                  (and file
                       (memq (car entry) '(bof eof file-error))))
              (setq lastentry entry))
          (if (eq entry here-am-I)
              (throw 'exit (or lastentry entry))))
        nil))))

;;;###autoload
(defun reftex-insert-docstruct
  (buf toc labels index-entries files context counter show-commented
            here-I-am xr-prefix toc-buffer)
  ;; Insert an excerpt of the docstruct list.
  ;; Return the data property of the entry corresponding to HERE-I-AM.
  ;; BUF is the buffer which has the correct docstruct-symbol.
  ;; LABELS non-nil means to include labels into the list.
  ;;        When a string, indicates the label type to include
  ;; FILES non-nil means to display file boundaries.
  ;; CONTEXT non-nil means to include label context.
  ;; COUNTER means to count the labels.
  ;; SHOW-COMMENTED means to include also labels which are commented out.
  ;; HERE-I-AM is a member of the docstruct list.  The function will return
  ;;           a used member near to this one, as a possible starting point.
  ;; XR-PREFIX is the prefix to put in front of labels.
  ;; TOC-BUFFER means this is to fill the toc buffer.
  (let* ((font reftex-use-fonts)
         (cnt 0)
         (index -1)
         (toc-indent " ")
         (label-indent
          (concat "> "
                  (if toc (make-string (* 7 reftex-level-indent) ?\ ) "")))
         (context-indent
          (concat ".   "
                  (if toc (make-string (* 7 reftex-level-indent) ?\ ) "")))
         (mouse-face
          (if (memq reftex-highlight-selection '(mouse both))
              reftex-mouse-selected-face
            nil))
         (label-face reftex-label-face)
         (index-face reftex-index-face)
         all cell text label typekey note comment master-dir-re
         prev-inserted offset from to index-tag docstruct-symbol)

    ;; Pop to buffer buf to get the correct buffer-local variables
    (with-current-buffer buf

      ;; Ensure access to scanning info
      (reftex-access-scan-info)

      (setq docstruct-symbol reftex-docstruct-symbol
            all (symbol-value reftex-docstruct-symbol)
            reftex-active-toc nil
            master-dir-re
            (concat "\\`" (regexp-quote
                           (reftex--get-directory (reftex-TeX-master-file))))))

    (setq-local reftex-docstruct-symbol docstruct-symbol)
    (setq-local reftex-prefix
                (cdr (assoc labels reftex-typekey-to-prefix-alist)))
    (if (equal reftex-prefix " ") (setq reftex-prefix nil))

    ;; Walk the docstruct and insert the appropriate stuff
    (while (setq cell (pop all))

      (incf index)
      (setq from (point))

      (cond

       ((memq (car cell) '(bib thebib label-numbers appendix
                               master-dir bibview-cache is-multi xr xr-doc)))
       ;; These are currently ignored

       ((memq (car cell) '(bof eof file-error))
        ;; Beginning or end of a file
        (when files
          (setq prev-inserted cell)
;         (if (eq offset 'attention) (setq offset cell))
          (insert
           " File " (if (string-match master-dir-re (nth 1 cell))
                   (substring (nth 1 cell) (match-end 0))
                 (nth 1 cell))
           (cond ((eq (car cell) 'bof) " starts here\n")
                 ((eq (car cell) 'eof) " ends here\n")
                 ((eq (car cell) 'file-error) " was not found\n")))
          (setq to (point))
          (when font
            (put-text-property from to
                               'font-lock-face reftex-file-boundary-face))
          (when toc-buffer
            (if mouse-face
                (put-text-property from (1- to)
                                   'mouse-face mouse-face))
            (put-text-property from to :data cell))))

       ((eq (car cell) 'toc)
        ;; a table of contents entry
        (when (and toc
                   (<= (nth 5 cell) reftex-toc-max-level))
          (setq prev-inserted cell)
;         (if (eq offset 'attention) (setq offset cell))
          (setq reftex-active-toc cell)
          (insert (concat toc-indent (nth 2 cell) "\n"))
          (setq to (point))
          (when font
            (put-text-property from to
                               'font-lock-face reftex-section-heading-face))
          (when toc-buffer
            (if mouse-face
                (put-text-property from (1- to)
                                   'mouse-face mouse-face))
            (put-text-property from to :data cell))
          (goto-char to)))

       ((stringp (car cell))
        ;; a label
        (when (null (nth 2 cell))
          ;; No context yet.  Quick update.
          (setcdr cell (cdr (reftex-label-info-update cell)))
          (put docstruct-symbol 'modified t))

        (setq label   (car cell)
              typekey (nth 1 cell)
              text    (nth 2 cell)
              comment (nth 4 cell)
              note    (nth 5 cell))

        (when (and labels
                   (or (eq labels t)
                       (string= typekey labels)
                       (string= labels " "))
                   (or show-commented (null comment)))

          ;; Yes we want this one
          (incf cnt)
          (setq prev-inserted cell)
;         (if (eq offset 'attention) (setq offset cell))

          (setq label (concat xr-prefix label))
          (when comment (setq label (concat "% " label)))
          (insert label-indent label)
          (when font
            (setq to (point))
            (put-text-property
             (- (point) (length label)) to
             'font-lock-face (if comment
                       'font-lock-comment-face
                     label-face))
            (goto-char to))

          (insert (if counter (format " (%d) " cnt) "")
                  (if comment " LABEL IS COMMENTED OUT " "")
                  (if (stringp note) (concat "  " note) "")
                  "\n")
          (setq to (point))

          (when context
            (insert context-indent text "\n")
            (setq to (point)))
          (put-text-property from to :data cell)
          (when mouse-face
            (put-text-property from (1- to)
                               'mouse-face mouse-face))
          (goto-char to)))

       ((eq (car cell) 'index)
        ;; index entry
        (when (and index-entries
                   (or (eq t index-entries)
                       (string= index-entries (nth 1 cell))))
          (setq prev-inserted cell)
;         (if (eq offset 'attention) (setq offset cell))
          (setq index-tag (format "<%s>" (nth 1 cell)))
          (and font
               (put-text-property 0 (length index-tag)
                                  'font-lock-face reftex-index-tag-face index-tag))
          (insert label-indent index-tag " " (nth 7 cell))

          (when font
            (setq to (point))
            (put-text-property
             (- (point) (length (nth 7 cell))) to
             'font-lock-face index-face)
            (goto-char to))
          (insert "\n")
          (setq to (point))

          (when context
            (insert context-indent (nth 2 cell) "\n")
            (setq to (point)))
          (put-text-property from to :data cell)
          (when mouse-face
            (put-text-property from (1- to)
                               'mouse-face mouse-face))
          (goto-char to))))

      (if (eq cell here-I-am)
          (setq offset 'attention))
      (if (and prev-inserted (eq offset 'attention))
          (setq offset prev-inserted))
      )

    (when (reftex-refontify)
      ;; we need to fontify the buffer
      (reftex-fontify-select-label-buffer buf))
    (run-hooks 'reftex-display-copied-context-hook)
    offset))

;;;###autoload
(defun reftex-find-start-point (fallback &rest locations)
  ;; Set point to the first available LOCATION.  When a LOCATION is a list,
  ;; search for such a :data text property.  When it is an integer,
  ;; use is as line number.  FALLBACK is a buffer position used if everything
  ;; else  fails.
  (catch 'exit
    (goto-char (point-min))
    (let (loc pos)
      (while locations
        (setq loc (pop locations))
        (cond
         ((null loc))
         ((listp loc)
          (setq pos (text-property-any (point-min) (point-max) :data loc))
          (when pos
            (goto-char pos)
            (throw 'exit t)))
         ((integerp loc)
          (when (<= loc (count-lines (point-min) (point-max)))
            (goto-char (point-min))
            (forward-line (1- loc))
            (throw 'exit t)))))
      (goto-char fallback))))

(defvar reftex-last-data nil)
(defvar reftex-last-line nil)
(defvar reftex-select-marked nil)
(defvar reftex-refstyle)

;; The following variables are all bound dynamically in `reftex-select-item'.

(defvar reftex-select-data)
(defvar reftex-select-prompt)
(defvar reftex--cb-flag)
(defvar reftex--last-data)
(defvar reftex--call-back)
(defvar reftex--help-string)

;;;###autoload
(defun reftex-select-item ( prompt help-string keymap
                            &optional offset call-back cb-flag)
  ;; Select an item, using PROMPT.
  ;; The function returns a key indicating an exit status, along with a
  ;; data structure indicating which item was selected.
  ;; HELP-STRING contains help.  KEYMAP is a keymap with the available
  ;; selection commands.
  ;; OFFSET can be a label list item which will be selected at start.
  ;; When it is t, point will start out at the beginning of the buffer.
  ;; Any other value will cause restart where last selection left off.
  ;; When CALL-BACK is given, it is a function which is called with the index
  ;; of the element.
  ;; CB-FLAG is the initial value of that flag.
  (let ((reftex-select-prompt prompt)
        (reftex--help-string help-string)
        (reftex--call-back call-back)
        (reftex--cb-flag cb-flag)
        ev reftex-select-data reftex--last-data
        (selection-buffer (current-buffer)))

    (setq reftex-select-marked nil)

    (setq ev
          (catch 'myexit
            (save-window-excursion
              (setq truncate-lines t)

              ;; Find a good starting point
              (reftex-find-start-point
               (point-min) offset reftex-last-data reftex-last-line)
              (beginning-of-line 1)
              (setq-local reftex-last-follow-point (point))

      (unwind-protect
          (progn
            (use-local-map keymap)
            (add-hook 'pre-command-hook #'reftex-select-pre-command-hook nil t)
            (add-hook 'post-command-hook #'reftex-select-post-command-hook nil t)
            (princ reftex-select-prompt)
            (set-marker reftex-recursive-edit-marker (point))
            (recursive-edit))

        (set-marker reftex-recursive-edit-marker nil)
        (with-current-buffer selection-buffer
          (use-local-map nil)
          (remove-hook 'pre-command-hook #'reftex-select-pre-command-hook t)
          (remove-hook 'post-command-hook
                       #'reftex-select-post-command-hook t))
        ;; Kill the mark overlays
        (mapc (lambda (c) (delete-overlay (nth 1 c)))
              reftex-select-marked)))))

    (setq-local reftex-last-line
                (+ (count-lines (point-min) (point)) (if (bolp) 1 0)))
    (setq-local reftex-last-data reftex--last-data)
    (reftex-kill-buffer "*RefTeX Help*")
    (setq reftex-callback-fwd (not reftex-callback-fwd)) ;; ;-)))
    (message "")
    (list ev reftex-select-data reftex--last-data)))

;; The selection commands

(defun reftex-select-pre-command-hook ()
  (reftex-unhighlight 1)
  (reftex-unhighlight 0))

(defun reftex-select-post-command-hook ()
  (let (b e)
    (setq reftex-select-data (get-text-property (point) :data))
    (setq reftex--last-data (or reftex-select-data reftex--last-data))

    (when (and reftex-select-data reftex--cb-flag
               (not (equal reftex-last-follow-point (point))))
      (setq reftex-last-follow-point (point))
      (funcall reftex--call-back reftex-select-data reftex-callback-fwd
               (not reftex-revisit-to-follow)))
    (if reftex-select-data
        (setq b (or (previous-single-property-change
                     (1+ (point)) :data)
                    (point-min))
              e (or (next-single-property-change
                     (point) :data)
                    (point-max)))
      (setq b (point) e (point)))
    (and (memq reftex-highlight-selection '(cursor both))
         (reftex-highlight 1 b e))
    (if (or (not (pos-visible-in-window-p b))
            (not (pos-visible-in-window-p e)))
        (recenter '(4)))
    (unless (current-message)
      (princ reftex-select-prompt))))

(defun reftex-select-next (&optional arg)
  "Move to next selectable item."
  (interactive "p")
  (setq reftex-callback-fwd t)
  (or (eobp) (forward-char 1))
  (re-search-forward "^[^. \t\n\r]" nil t arg)
  (beginning-of-line 1))
(defun reftex-select-previous (&optional arg)
  "Move to previous selectable item."
  (interactive "p")
  (setq reftex-callback-fwd nil)
  (re-search-backward "^[^. \t\n\r]" nil t arg))
(defun reftex-select-jump (arg)
  "Jump to a specific section.  E.g. '3 z' jumps to section 3.
Useful for large TOC's."
  (interactive "P")
  (goto-char (point-min))
  (re-search-forward
   (concat "^ *" (number-to-string (if (numberp arg) arg 1)) " ")
   nil t)
  (beginning-of-line))
(defun reftex-select-next-heading (&optional arg)
  "Move to next table of contents line."
  (interactive "p")
  (end-of-line)
  (re-search-forward "^ " nil t arg)
  (beginning-of-line))
(defun reftex-select-previous-heading (&optional arg)
  "Move to previous table of contents line."
  (interactive "p")
  (re-search-backward "^ " nil t arg))
(defun reftex-select-quit ()
  "Abort selection process."
  (interactive)
  (throw 'myexit nil))
(defun reftex-select-keyboard-quit ()
  "Abort selection process."
  (interactive)
  (throw 'exit t))
(defun reftex-select-jump-to-previous ()
  "Jump back to where previous selection process left off."
  (interactive)
  (let (pos)
    (cond
     ((and (local-variable-p 'reftex-last-data (current-buffer))
           reftex-last-data
           (setq pos (text-property-any (point-min) (point-max)
                                        :data reftex-last-data)))
      (goto-char pos))
     ((and (local-variable-p 'reftex-last-line (current-buffer))
           (integerp reftex-last-line))
      (goto-char (point-min))
      (forward-line (1- reftex-last-line)))
     (t (ding)))))
(defun reftex-select-toggle-follow ()
  "Toggle follow mode:  Other window follows with full context."
  (interactive)
  (setq reftex-last-follow-point -1)
  (setq reftex--cb-flag (not reftex--cb-flag)))

(defun reftex-select-cycle-ref-style-internal (&optional reverse)
  "Cycle through macros used for referencing.
Cycle in reverse order if optional argument REVERSE is non-nil."
  (let (list)
    (dolist (style (reftex-ref-style-list))
      (mapc (lambda (x) (add-to-list 'list (car x) t))
	    (nth 2 (assoc style reftex-ref-style-alist))))
    (when reverse
      (setq list (reverse list)))
    (setq reftex-refstyle (or (cadr (member reftex-refstyle list)) (car list))))
  (force-mode-line-update))

(defun reftex-select-cycle-ref-style-forward ()
  "Cycle forward through macros used for referencing."
  (interactive)
  (reftex-select-cycle-ref-style-internal))

(defun reftex-select-cycle-ref-style-backward ()
  "Cycle backward through macros used for referencing."
  (interactive)
  (reftex-select-cycle-ref-style-internal t))

(defun reftex-select-show-insertion-point ()
  "Show the point from where selection was started in another window."
  (interactive)
  (let ((this-window (selected-window)))
    (unwind-protect
        (progn
          (switch-to-buffer-other-window
           (marker-buffer reftex-select-return-marker))
          (goto-char (marker-position reftex-select-return-marker))
          (recenter '(4)))
      (select-window this-window))))
(defun reftex-select-callback ()
  "Show full context in another window."
  (interactive)
  (if reftex-select-data
      (funcall reftex--call-back reftex-select-data reftex-callback-fwd nil)
    (ding)))
(defun reftex-select-accept ()
  "Accept the currently selected item."
  (interactive)
  (throw 'myexit 'return))
(defun reftex-select-mouse-accept (ev)
  "Accept the item at the mouse click."
  (interactive "e")
  (mouse-set-point ev)
  (setq reftex-select-data (get-text-property (point) :data))
  (setq reftex--last-data (or reftex-select-data reftex--last-data))
  (throw 'myexit 'return))
(defun reftex-select-read-label ()
  "Use minibuffer to read a label to reference, with completion."
  (interactive)
  (let ((label (completing-read
                "Label: " (symbol-value reftex-docstruct-symbol)
                nil nil reftex-prefix)))
    (unless (or (equal label "") (equal label reftex-prefix))
      (throw 'myexit label))))

(defvar reftex--found-list)

(defun reftex-select-read-cite ()
  "Use minibuffer to read a citation key with completion."
  (interactive)
  (let* ((key (completing-read "Citation key: " reftex--found-list))
         (entry (assoc key reftex--found-list)))
    (cond
     ((or (null key) (equal key "")))
     (entry
      (setq reftex-select-data entry)
      (setq reftex--last-data reftex-select-data)
      (throw 'myexit 'return))
     (t (throw 'myexit key)))))

(defun reftex-select-mark (&optional separator)
  "Mark the entry."
  (interactive)
  (let* ((data (get-text-property (point) :data))
         boe eoe ovl)
    (or data (error "No entry to mark at point"))
    (if (assq data reftex-select-marked)
        (error "Entry is already marked"))
    (setq boe (or (previous-single-property-change (1+ (point)) :data)
                  (point-min))
          eoe (or (next-single-property-change (point) :data) (point-max)))
    (setq ovl (make-overlay boe eoe))
    (push (list data ovl separator) reftex-select-marked)
    (overlay-put ovl 'font-lock-face reftex-select-mark-face)
    (overlay-put ovl 'before-string
                 (if separator
                     (format "*%c%d* " separator
                             (length reftex-select-marked))
                   (format "*%d*  " (length reftex-select-marked))))
    (message "Entry has mark no. %d" (length reftex-select-marked))))

(defun reftex-select-mark-comma ()
  "Mark the entry and store the `comma' separator."
  (interactive)
  (reftex-select-mark ?,))
(defun reftex-select-mark-to ()
  "Mark the entry and store the `to' separator."
  (interactive)
  (reftex-select-mark ?-))
(defun reftex-select-mark-and ()
  "Mark the entry and store `and' to separator."
  (interactive)
  (reftex-select-mark ?+))

(defun reftex-select-unmark ()
  "Unmark the entry."
  (interactive)
  (let* ((data (get-text-property (point) :data))
         (cell (assq data reftex-select-marked))
         (ovl (nth 1 cell))
         (cnt 0)
         sep)
    (unless cell
      (error "No marked entry at point"))
    (and ovl (delete-overlay ovl))
    (setq reftex-select-marked (delq cell reftex-select-marked))
    (setq cnt (1+ (length reftex-select-marked)))
    (mapc (lambda (c)
            (setq sep (nth 2 c))
            (overlay-put (nth 1 c) 'before-string
                         (if sep
                             (format "*%c%d* " sep (decf cnt))
                           (format "*%d*  " (decf cnt)))))
          reftex-select-marked)
    (message "Entry no longer marked")))

(defun reftex-select-help ()
  "Display a summary of the special key bindings."
  (interactive)
  (with-output-to-temp-buffer "*RefTeX Help*"
    (princ reftex--help-string))
  (reftex-enlarge-to-fit "*RefTeX Help*" t))

(provide 'reftex-sel)

;;; reftex-sel.el ends here

;; Local Variables:
;; generated-autoload-file: "reftex-loaddefs.el"
;; End:
