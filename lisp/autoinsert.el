;;; autoinsert.el --- automatic mode-dependent insertion of text into new files  -*- lexical-binding: t -*-

;; Copyright (C) 1985-2025 Free Software Foundation, Inc.

;; Author: Charlie Martin <crm@cs.duke.edu>
;; Adapted-By: Daniel Pfeiffer <occitan@esperanto.org>
;; Keywords: convenience
;; Maintainer: emacs-devel@gnu.org

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

;; The following defines an association list for text to be
;; automatically inserted when a new file is created, and a function
;; which automatically inserts these files; the idea is to insert
;; default text much as the mode is automatically set using
;; auto-mode-alist.
;;
;; To use, add this to your Init file:
;;
;;     (auto-insert-mode t)
;;     (setq auto-insert-directory "~/some-dir")
;;
;; You can also customize the variable `auto-insert-mode' to load the
;; package.
;;
;; Author:  Charlie Martin
;;          Department of Computer Science and
;;          National Biomedical Simulation Resource
;;          Box 3709
;;          Duke University Medical Center
;;          Durham, NC 27710
;;           (crm@cs.duke.edu,mcnc!duke!crm)

;;; Code:

(require 'seq)

(defgroup auto-insert nil
  "Automatic mode-dependent insertion of text into new files."
  :prefix "auto-insert-"
  :group 'files
  :group 'convenience
  :link '(custom-manual "(autotype) Autoinserting"))


(defcustom auto-insert 'not-modified
  "Controls automatic insertion into newly found empty files.
Possible values:
	nil	do nothing
	t	insert if possible
	other	insert if possible, but mark as unmodified.
Insertion is possible when something appropriate is found in
`auto-insert-alist'.  When the insertion is marked as unmodified, you can
save it with  \\[write-file] \\`RET'.
This variable is used when the function `auto-insert' is called, e.g.
when you do (add-hook \\='find-file-hook \\='auto-insert).
With \\[auto-insert], this is always treated as if it were t."
  :type '(choice (const :tag "Insert if possible" t)
                 (const :tag "Do nothing" nil)
                 (other :tag "insert if possible, mark as unmodified."
                        not-modified)))

;;;###autoload
(put 'auto-insert 'safe-local-variable #'null)

(defcustom auto-insert-query 'function
  "Non-nil means ask user before auto-inserting.
When this is `function', only ask when called non-interactively."
  :type '(choice (const :tag "Don't ask" nil)
                 (const :tag "Ask if called non-interactively" function)
                 (other :tag "Ask" t)))

(defcustom auto-insert-prompt "Perform %s auto-insertion?"
  "Prompt to use when querying whether to `auto-insert'.
If this contains a %s, that will be replaced by the matching rule."
  :type 'string
  :version "28.1")

(declare-function sgml-tag "textmodes/sgml-mode" (&optional str arg))

(defcustom auto-insert-alist
  `((("\\.\\([Hh]\\|hh\\|hpp\\|hxx\\|h\\+\\+\\)\\'" . "C / C++ header")
     (replace-regexp-in-string
      "[^A-Z0-9]" "_"
      (string-replace
       "+" "P"
       (upcase (file-name-nondirectory buffer-file-name))))
     "#ifndef " str \n
     "#define " str "\n\n"
     _ "\n\n#endif")

    (("\\.\\([Cc]\\|cc\\|cpp\\|cxx\\|c\\+\\+\\)\\'" . "C / C++ program")
     nil
     "#include \""
     (let ((stem (file-name-sans-extension buffer-file-name))
           ret)
       (dolist (ext '("H" "h" "hh" "hpp" "hxx" "h++") ret)
         (when (file-exists-p (concat stem "." ext))
           (setq ret (file-name-nondirectory (concat stem "." ext))))))
     & ?\" | -10)

    (("[Mm]akefile\\'" . "Makefile") . "makefile.inc")

    (html-mode . ,(lambda () (sgml-tag "html")))

    (plain-tex-mode . "tex-insert.tex")
    (bibtex-mode . "tex-insert.tex")
    (latex-mode
     ;; should try to offer completing read for these
     "options, RET: "
     "\\documentclass[" str & ?\] | -1
     ?{ (read-string "class: ") "}\n"
     ("package, %s: "
      "\\usepackage[" (read-string "options, RET: ") & ?\] | -1 ?{ str "}\n")
     _ "\n\\begin{document}\n" _
     "\n\\end{document}")

    (("/bin/.*[^/]\\'" . "Shell-Script mode magic number") .
     ,(lambda ()
	(if (eq major-mode (default-value 'major-mode))
	    (sh-mode))))

    (ada-mode . ada-skel-initial-string)

    (("\\.[1-9]\\'" . "Man page skeleton")
     "Short description: "
     ".\\\" Copyright (C), " (format-time-string "%Y") "  "
     (getenv "ORGANIZATION") | (progn user-full-name)
     "
.\\\" You may distribute this file under the terms of the GNU Free
.\\\" Documentation License.
.TH " (file-name-base (buffer-file-name))
     " " (file-name-extension (buffer-file-name))
     " " (format-time-string "%Y-%m-%d ")
     "\n.SH NAME\n"
     (file-name-base (buffer-file-name))
     " \\- " str
     "\n.SH SYNOPSIS
.B " (file-name-base (buffer-file-name))
     "\n"
     _
     "
.SH DESCRIPTION
.SH OPTIONS
.SH FILES
.SH \"SEE ALSO\"
.SH BUGS
.SH AUTHOR
" (user-full-name)
     '(if (search-backward "&" (line-beginning-position) t)
	  (replace-match (capitalize (user-login-name)) t t))
     '(end-of-line 1) " <" (progn user-mail-address) ">\n")

    ((,(rx ".dir-locals" (? "-2") ".el") . "Directory Local Variables")
     nil
     ";;; Directory Local Variables         -*- no-byte-compile: t; -*-\n"
     ";;; For more information see (info \"(emacs) Directory Variables\")\n\n"
     "(("
     '(setq v1 (let ((modes '("nil")))
                 (mapatoms (lambda (mode)
                             (let ((name (symbol-name mode)))
                               (when (string-match "-mode\\'" name)
                                 (push name modes)))))
                 (sort modes 'string<)))
     (completing-read "Local variables for mode: " v1 nil 'confirm)
     " . (("
     (let ((all-variables
            (apropos-internal ".*"
                              ,(lambda (symbol)
			         (and (boundp symbol)
				      (get symbol 'variable-documentation))))))
       (completing-read "Variable to set: " all-variables))
     " . "
     (completing-read "Value to set it to: " nil)
     "))))\n")

    (("\\.el\\'" . "Emacs Lisp header")
     "Short description: "
     ";;; " (file-name-nondirectory (buffer-file-name)) " --- " str
     (make-string (max 2 (- 80 (current-column) 27)) ?\s)
     "-*- lexical-binding: t; -*-" '(setq lexical-binding t)
     "

;; Copyright (C) " (format-time-string "%Y") "  "
 (getenv "ORGANIZATION") | (progn user-full-name) "

;; Author: " (user-full-name)
'(if (search-backward "&" (line-beginning-position) t)
     (replace-match (capitalize (user-login-name)) t t))
'(end-of-line 1) " <" (progn user-mail-address) ">
;; Keywords: "
 '(require 'finder)
 ;;'(setq v1 (apply 'vector (mapcar 'car finder-known-keywords)))
 '(setq v1 (mapcar ,(lambda (x) (list (symbol-name (car x))))
		   finder-known-keywords)
	v2 (mapconcat (lambda (x) (format "%12s:  %s" (car x) (cdr x)))
	              finder-known-keywords
	              "\n"))
 ((let ((minibuffer-help-form v2))
    (completing-read "Keyword, C-h: " v1 nil t))
    str ", ")
 & -2 "

\;; This program is free software; you can redistribute it and/or modify
\;; it under the terms of the GNU General Public License as published by
\;; the Free Software Foundation, either version 3 of the License, or
\;; (at your option) any later version.

\;; This program is distributed in the hope that it will be useful,
\;; but WITHOUT ANY WARRANTY; without even the implied warranty of
\;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\;; GNU General Public License for more details.

\;; You should have received a copy of the GNU General Public License
\;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

\;;; Commentary:

\;; " _ "

\;;; Code:



\(provide '"
       (file-name-base (buffer-file-name))
       ")
\;;; " (file-name-nondirectory (buffer-file-name)) " ends here\n")
    (("\\.texi\\(nfo\\)?\\'" . "Texinfo file skeleton")
     "Title: "
     "\\input texinfo   @c -*-texinfo-*-
@c %**start of header
@setfilename "
     (file-name-base (buffer-file-name)) ".info\n"
      "@settitle " str "
@c %**end of header
@copying\n"
      (setq short-description (read-string "Short description: "))
      ".\n\n"
      "Copyright @copyright{} " (format-time-string "%Y") "  "
      (getenv "ORGANIZATION") | (progn user-full-name) "

@quotation
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled ``GNU
Free Documentation License''.

A copy of the license is also available from the Free Software
Foundation Web site at @url{https://www.gnu.org/licenses/fdl.html}.

@end quotation

The document was typeset with
@uref{https://www.gnu.org/software/texinfo/, GNU Texinfo}.

@end copying

@titlepage
@title " str "
@subtitle " short-description "
@author " (getenv "ORGANIZATION") | (progn user-full-name)
     " <" (progn user-mail-address) ">
@page
@vskip 0pt plus 1filll
@insertcopying
@end titlepage

@c Output the table of the contents at the beginning.
@contents

@ifnottex
@node Top
@top " str "

@insertcopying
@end ifnottex

@c Generate the nodes for this menu with `C-c C-u C-m'.
@menu
@end menu

@c Update all node entries with `C-c C-u C-n'.
@c Insert new nodes with `C-c C-c n'.
@node Chapter One
@chapter Chapter One

" _ "

@node Copying This Manual
@appendix Copying This Manual

@menu
* GNU Free Documentation License::  License for copying this manual.
@end menu

@c Get fdl.texi from https://www.gnu.org/licenses/fdl.html
@include fdl.texi

@node Index
@unnumbered Index

@printindex cp

@bye
"))
  "A list specifying text to insert by default into a new file.
Elements look like (CONDITION . ACTION) or ((CONDITION . DESCRIPTION) . ACTION).
CONDITION may be a regexp that must match the new file's name, or it may be
a symbol that must match the major mode for this element to apply.
Only the first matching element is effective.
Optional DESCRIPTION is a string for filling `auto-insert-prompt'.
ACTION may be a skeleton to insert (see `skeleton-insert'), an absolute
file-name or one relative to `auto-insert-directory' or a function to call.
ACTION may also be a vector containing several successive single actions as
described above, e.g. [\"header.insert\" date-and-author-update]."
  :type '(alist :key-type
                (choice (regexp :tag "Regexp matching file name")
                        (symbol :tag "Major mode")
                        (cons :tag "Condition and description"
                              (choice :tag "Condition"
                               (regexp :tag "Regexp matching file name")
                               (symbol :tag "Major mode"))
                              (string :tag "Description")))
                ;; There's no custom equivalent of "repeat" for vectors.
                :value-type (choice file function
                                    (sexp :tag "Skeleton or vector")))
  :version "27.1")


;; Establish a default value for auto-insert-directory
(defcustom auto-insert-directory "~/insert/"
  "Directory from which auto-inserted files are taken."
  :type 'directory)


;;;###autoload
(defun auto-insert ()
  "Insert default contents into new files if variable `auto-insert' is non-nil.
Matches the visited file name against the elements of `auto-insert-alist'."
  (interactive)
  (and (not buffer-read-only)
       (or (eq this-command 'auto-insert)
	   (and auto-insert
		(bobp) (eobp)))
       (let* ((case-fold-search nil)
              (desc nil)
              ;; Find first matching alist entry.
              (action
               (seq-some
                (pcase-lambda (`(,cond . ,action))
                  (if (atom cond)
                      (setq desc cond)
                    (setq desc (cdr cond)
                          cond (car cond)))
                  (when (if (symbolp cond)
                            (derived-mode-p cond)
                          (and buffer-file-name
                               (string-match cond buffer-file-name)))
                    action))
                auto-insert-alist)))
         (goto-char 1)
	 ;; Now, if we found something, do it
	 (and action
	      (or (not (stringp action))
                  (file-readable-p (expand-file-name
                                    action auto-insert-directory)))
	      (or (not auto-insert-query)
                  (if (eq auto-insert-query 'function)
                      (eq this-command 'auto-insert))
                  (y-or-n-p (format auto-insert-prompt desc)))
	      (mapc
	       (lambda (action)
		 (if (stringp action)
		     (if (file-readable-p
			  (setq action (expand-file-name
                                        action auto-insert-directory)))
			 (insert-file-contents action))
		   (save-window-excursion
		     ;; make buffer visible before skeleton or function
		     ;; which might ask the user for something
		     (switch-to-buffer (current-buffer))
		     (if (and (consp action)
			      (not (functionp action)))
			 (skeleton-insert action)
		       (funcall action)))))
	       (if (vectorp action)
		   action
		 (vector action))))
	 (and (buffer-modified-p)
	      (not (eq this-command 'auto-insert))
	      (set-buffer-modified-p (eq auto-insert t)))))
  ;; Return nil so that it could be used in
  ;; `find-file-not-found-functions', though that's probably inadvisable.
  nil)


;;;###autoload
(defun define-auto-insert (condition action &optional after)
  "Associate CONDITION with (additional) ACTION in `auto-insert-alist'.
Optional AFTER means to insert action after all existing actions for CONDITION,
or if CONDITION had no actions, after all other CONDITIONs."
  (declare (indent defun))
  (let ((elt (assoc condition auto-insert-alist)))
    (if elt
	(setcdr elt
		(if (vectorp (cdr elt))
		    (vconcat (if after (cdr elt))
			     (if (vectorp action) action (vector action))
			     (if after () (cdr elt)))
		  (if after
		      (vector (cdr elt) action)
		    (vector action (cdr elt)))))
      (if after
	  (nconc auto-insert-alist (list (cons condition action)))
        (push (cons condition action) auto-insert-alist)))))

;;;###autoload
(define-minor-mode auto-insert-mode
  "Toggle Auto-insert mode, a global minor mode.

When Auto-insert mode is enabled, when new files are created you can
insert a template for the file depending on the mode of the buffer."
  :global t :group 'auto-insert
  (if auto-insert-mode
      (add-hook 'find-file-hook 'auto-insert)
    (remove-hook 'find-file-hook 'auto-insert)))

(provide 'autoinsert)

;;; autoinsert.el ends here
