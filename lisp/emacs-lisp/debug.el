;;; debug.el --- debuggers and related commands for Emacs  -*- lexical-binding: t -*-

;; Copyright (C) 1985-1986, 1994, 2001-2025 Free Software Foundation,
;; Inc.

;; Maintainer: emacs-devel@gnu.org
;; Keywords: lisp, tools, maint

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

;; This is a major mode documented in the Emacs Lisp manual.

;;; Code:

(require 'cl-lib)
(require 'backtrace)

(defgroup debugger nil
  "Debuggers and related commands for Emacs."
  :prefix "debugger-"
  :group 'debug)

(defcustom debugger-mode-hook nil
  "Hooks run when `debugger-mode' is turned on."
  :type 'hook
  :group 'debugger
  :version "20.3")

(defcustom debugger-batch-max-lines 40
  "Maximum lines to show in debugger buffer in a noninteractive Emacs.
When the debugger is entered and Emacs is running in batch mode,
if the backtrace text has more than this many lines,
the middle is discarded, and just the beginning and end are displayed."
  :type 'integer
  :group 'debugger
  :version "21.1")

(defcustom debugger-print-function #'cl-prin1
  "Function used to print values in the debugger backtraces."
  :type '(choice (const cl-prin1)
                 (const prin1)
                 function)
  :version "26.1")

(defcustom debugger-bury-or-kill 'bury
  "What to do with the debugger buffer when exiting `debug'.
The value affects the behavior of operations on any window
previously showing the debugger buffer.

nil means that if its window is not deleted when exiting the
  debugger, invoking `switch-to-prev-buffer' will usually show
  the debugger buffer again.

`append' means that if the window is not deleted, the debugger
  buffer moves to the end of the window's previous buffers so
  it's less likely that a future invocation of
  `switch-to-prev-buffer' will switch to it.  Also, it moves the
  buffer to the end of the frame's buffer list.

`bury' means that if the window is not deleted, its buffer is
  removed from the window's list of previous buffers.  Also, it
  moves the buffer to the end of the frame's buffer list.  This
  value provides the most reliable remedy to not have
  `switch-to-prev-buffer' switch to the debugger buffer again
  without killing the buffer.

`kill' means to kill the debugger buffer.

The value used here is passed to `quit-restore-window'."
  :type '(choice
	  (const :tag "Keep alive" nil)
	  (const :tag "Append" append)
	  (const :tag "Bury" bury)
	  (const :tag "Kill" kill))
  :group 'debugger
  :version "24.3")

(defcustom debug-allow-recursive-debug nil
  "If non-nil, erroring in debug and edebug won't recursively debug."
  :type 'boolean
  :version "29.1")

(defvar debugger-step-after-exit nil
  "Non-nil means \"single-step\" after the debugger exits.")

(defvar debugger-value nil
  "This is the value for the debugger to return, when it returns.")

(defvar debugger-old-buffer nil
  "This is the buffer that was current when the debugger was entered.")

(defvar debugger-previous-window nil
  "This is the window last showing the debugger buffer.")

(defvar debugger-previous-window-height nil
  "The last recorded height of `debugger-previous-window'.")

(defvar debugger-outer-match-data)
(defvar debugger-will-be-back nil
  "Non-nil if we expect to get back in the debugger soon.")

(defvar inhibit-debug-on-entry nil
  "Non-nil means that `debug-on-entry' is disabled.")

(defvar debugger-jumping-flag nil
  "Non-nil means that `debug-on-entry' is disabled.
This variable is used by `debugger-jump', `debugger-step-through',
and `debugger-reenable' to temporarily disable `debug-on-entry'.")

(defvar inhibit-trace)                  ;Not yet implemented.

(defvar debugger-args nil
  "Arguments with which the debugger was called.
It is a list expected to take the form (CAUSE . REST)
where CAUSE can be:
- debug: called for entry to a flagged function.
- t: called because of `debug-on-next-call'.
- lambda: same thing but via `funcall'.
- exit: called because of exit of a flagged function.
- error: called because of `debug-on-error'.")

(cl-defstruct (debugger--buffer-state
            (:constructor debugger--save-buffer-state
                          (&aux (mode     major-mode)
                                (header   backtrace-insert-header-function)
                                (frames   backtrace-frames)
                                (content  (buffer-string))
                                (pos      (point)))))
  mode header frames content pos)

(defun debugger--restore-buffer-state (state)
  (unless (derived-mode-p (debugger--buffer-state-mode state))
    (funcall (debugger--buffer-state-mode state)))
  (setq backtrace-insert-header-function (debugger--buffer-state-header state)
        backtrace-frames (debugger--buffer-state-frames state))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (debugger--buffer-state-content state)))
  (goto-char (debugger--buffer-state-pos state)))

(defun debugger--duplicate-p (args)
  (pcase args
    (`(error ,err . ,_) (and (consp err) (eq err debugger--last-error)))))

;;;###autoload
(setq debugger 'debug)
;;;###autoload
(defun debug (&rest args)
  "Enter debugger.  \\<debugger-mode-map>`\\[debugger-continue]' returns from the debugger.

In interactive sessions, this switches to a backtrace buffer and shows
the Lisp backtrace of function calls there.  In batch mode (more accurately,
when `noninteractive' is non-nil), it shows the Lisp backtrace on the
standard error stream (unless `backtrace-on-error-noninteractive' is nil),
and then kills Emacs, causing it to exit with a negative exit code.

Arguments are mainly for use when this is called from the internals
of the evaluator.

You may call with no args, or you may pass nil as the first arg and
any other args you like.  In that case, the list of args after the
first will be printed into the backtrace buffer.

If `inhibit-redisplay' is non-nil when this function is called,
the debugger will not be entered."
  (interactive)
  (if (or inhibit-redisplay
          (debugger--duplicate-p args))
      ;; Don't really try to enter debugger within an eval from redisplay
      ;; or if we already popper into the debugger for this error,
      ;; which can happen when we have several nested `handler-bind's that
      ;; want to invoke the debugger.
      debugger-value
    (setq debugger--last-error nil)
    (let ((non-interactive-frame
           (or noninteractive           ;FIXME: Presumably redundant.
               ;; If we're in the initial-frame (where `message' just
               ;; outputs to stdout) so there's no tty or GUI frame to
               ;; display the backtrace and interact with it: just dump a
               ;; backtrace to stdout.  This happens for example while
               ;; handling an error in code from early-init.el with
               ;; --debug-init.
               (and (eq t (framep (selected-frame)))
                    (equal "initial_terminal" (terminal-name)))))
          ;; Don't let `inhibit-message' get in our way (especially important if
          ;; `non-interactive-frame' evaluated to a non-nil value.
          (inhibit-message nil)
          ;; We may be entering the debugger from a context that has
          ;; let-bound `inhibit-read-only', which means that all
          ;; buffers would be read/write while the debugger is running.
          (inhibit-read-only nil))
      (unless non-interactive-frame
        (message "Entering debugger..."))
      (let (debugger-value
	    (debugger-previous-state
             (if (get-buffer "*Backtrace*")
                 (with-current-buffer "*Backtrace*"
                   (debugger--save-buffer-state))))
            (debugger-args args)
	    (debugger-buffer (get-buffer-create "*Backtrace*"))
	    (debugger-old-buffer (current-buffer))
	    (debugger-window nil)
	    (debugger-step-after-exit nil)
            (debugger-will-be-back nil)
	    ;; Don't keep reading from an executing kbd macro!
	    (executing-kbd-macro nil)
	    ;; Save the outer values of these vars for the `e' command
	    ;; before we replace the values.
	    (debugger-outer-match-data (match-data))
	    (debugger-with-timeout-suspend (with-timeout-suspend)))
        ;; Set this instead of binding it, so that `q'
        ;; will not restore it.
        (setq overriding-terminal-local-map nil)
        ;; Don't let these magic variables affect the debugger itself.
        (let ((last-command nil) this-command track-mouse
	      (inhibit-trace t)
	      unread-command-events
	      unread-post-input-method-events
	      last-input-event last-command-event last-nonmenu-event
	      last-event-frame
	      overriding-local-map
	      (load-read-function #'read)
	      ;; If we are inside a minibuffer, allow nesting
	      ;; so that we don't get an error from the `e' command.
	      (enable-recursive-minibuffers
	       (or enable-recursive-minibuffers (> (minibuffer-depth) 0)))
	      (standard-input t) (standard-output t)
	      inhibit-redisplay
	      (cursor-in-echo-area nil)
	      (window-configuration (current-window-configuration)))
	  (unwind-protect
	      (save-excursion
	        (when (eq (car debugger-args) 'debug)
		  (let ((base (debugger--backtrace-base)))
		    (backtrace-debug 1 t base) ;FIXME!
		    ;; Place an extra debug-on-exit for macro's.
		    (when (eq 'lambda (car-safe (cadr (backtrace-frame 1 base))))
		      (backtrace-debug 2 t base))))
                (set-buffer debugger-buffer)
                (unless (derived-mode-p 'debugger-mode)
	          (debugger-mode))
	        (debugger-setup-buffer debugger-args)
	        (if non-interactive-frame
		    ;; If the backtrace is long, save the beginning
		    ;; and the end, but discard the middle.
                    (let ((inhibit-read-only t))
		      (when (> (count-lines (point-min) (point-max))
			       debugger-batch-max-lines)
		        (goto-char (point-min))
		        (forward-line (/ debugger-batch-max-lines 2))
		        (let ((middlestart (point)))
		          (goto-char (point-max))
		          (forward-line (- (/ debugger-batch-max-lines 2)))
		          (delete-region middlestart (point)))
		        (insert "...\n"))
		      (message "%s" (buffer-string)))
	          (pop-to-buffer
	           debugger-buffer
	           `((display-buffer-reuse-window
		      display-buffer-in-previous-window
		      display-buffer-below-selected)
		     . ((window-min-height . 10)
		        (window-height . fit-window-to-buffer)
		        ,@(when (and (window-live-p debugger-previous-window)
				     (frame-visible-p
				      (window-frame debugger-previous-window)))
		            `((previous-window . ,debugger-previous-window))))))
	          (setq debugger-window (selected-window))
		  (when debugger-jumping-flag
		    ;; Try to restore previous height of debugger
		    ;; window.
		    (condition-case nil
		        (window-resize
		         debugger-window
		         (- debugger-previous-window-height
			    (window-total-height debugger-window)))
		      (error nil))
		    (setq debugger-previous-window debugger-window))
	          (message "")
	          (let ((standard-output nil)
		        (buffer-read-only t))
		    (message "")
		    ;; Make sure we unbind buffer-read-only in the right buffer.
		    (save-excursion
		      (recursive-edit)))))
	    (when (and (window-live-p debugger-window)
		       (eq (window-buffer debugger-window) debugger-buffer))
	      ;; Record height of debugger window.
	      (setq debugger-previous-window-height
		    (window-total-height debugger-window)))
	    (if debugger-will-be-back
	        ;; Restore previous window configuration (Bug#12623).
	        (set-window-configuration window-configuration)
	      (when (and (window-live-p debugger-window)
		         (eq (window-buffer debugger-window) debugger-buffer))
	        (progn
		  ;; Unshow debugger-buffer.
		  (quit-restore-window debugger-window debugger-bury-or-kill)
		  ;; Restore current buffer (Bug#12502).
		  (set-buffer debugger-old-buffer)))
              ;; Forget debugger window, it won't be back (Bug#17882).
              (setq debugger-previous-window nil))
            ;; Restore previous state of debugger-buffer in case we
            ;; were in a recursive invocation of the debugger,
            ;; otherwise just exit (after changing the mode, since we
            ;; can't interact with the buffer in the same way).
	    (when (buffer-live-p debugger-buffer)
	      (with-current-buffer debugger-buffer
	        (if debugger-previous-state
                    (debugger--restore-buffer-state debugger-previous-state)
                  (backtrace-mode))))
	    (with-timeout-unsuspend debugger-with-timeout-suspend)
	    (set-match-data debugger-outer-match-data)))
	(when (eq 'error (car-safe debugger-args))
	  ;; Remember the error we just debugged, to avoid re-entering
          ;; the debugger if some higher-up `handler-bind' invokes us
          ;; again, oblivious that the error was already debugged from
          ;; a more deeply nested `handler-bind'.
	  (setq debugger--last-error (nth 1 debugger-args)))
        (setq debug-on-next-call debugger-step-after-exit)
        debugger-value))))

(defun debugger--print (obj &optional stream)
  (condition-case err
      (funcall debugger-print-function obj stream)
    (error
     (message "Error in debug printer: %S" err)
     (prin1 obj stream))))

(make-obsolete 'debugger-insert-backtrace
               "use a `backtrace-mode' buffer or `backtrace-to-string'."
               "27.1")

(defun debugger-insert-backtrace (frames do-xrefs)
  "Format and insert the backtrace FRAMES at point.
Make functions into cross-reference buttons if DO-XREFS is non-nil."
  (insert (if do-xrefs
              (backtrace--to-string frames)
            (backtrace-to-string frames))))

(defun debugger-setup-buffer (args)
  "Initialize the `*Backtrace*' buffer for entry to the debugger.
That buffer should be current already and in `debugger-mode'."
  (setq backtrace-frames
        ;; The `base' frame is the one that gets index 0 and it is the entry to
        ;; the debugger, so drop it with `cdr'.
        (cdr (backtrace-get-frames (debugger--backtrace-base))))
  (when (eq (car-safe args) 'exit)
    (setq debugger-value (nth 1 args))
    (setf (cl-getf (backtrace-frame-flags (car backtrace-frames))
                   :debug-on-exit)
          nil))

  (setq backtrace-view (plist-put backtrace-view :show-flags t)
        backtrace-insert-header-function (lambda ()
                                           (debugger--insert-header args))
        backtrace-print-function debugger-print-function)
  (backtrace-print)
  ;; Place point on "stack frame 0" (bug#15101).
  (goto-char (point-min))
  (search-forward ":" (line-end-position) t)
  (when (and (< (point) (line-end-position))
             (= (char-after) ?\s))
    (forward-char)))

(defun debugger--insert-header (args)
  "Insert the header for the debugger's Backtrace buffer.
Include the reason for debugger entry from ARGS."
  (insert "Debugger entered")
  (pcase (car args)
    ;; lambda is for debug-on-call when a function call is next.
    ;; debug is for debug-on-entry function called.
    ((or 'lambda 'debug)
     (insert "--entering a function:\n"))
    ;; Exiting a function.
    ('exit
     (insert "--returning value: ")
     (insert (backtrace-print-to-string debugger-value))
     (insert ?\n))
    ;; Watchpoint triggered.
    ((and 'watchpoint (let `(,symbol ,newval . ,details) (cdr args)))
     (insert
      "--"
      (pcase details
        ('(makunbound nil) (format "making %s void" symbol))
        (`(makunbound ,buffer) (format "killing local value of %s in buffer %s"
                                       symbol buffer))
        (`(defvaralias ,_) (format "aliasing %s to %s" symbol newval))
        (`(let ,_) (format "let-binding %s to %s" symbol
                           (backtrace-print-to-string newval)))
        (`(unlet ,_) (format "ending let-binding of %s" symbol))
        ('(set nil) (format "setting %s to %s" symbol
                            (backtrace-print-to-string newval)))
        (`(set ,buffer) (format "setting %s in buffer %s to %s"
                                symbol buffer
                                (backtrace-print-to-string newval)))
        (_ (error "Unrecognized watchpoint triggered %S" (cdr args))))
      ": ")
     (insert ?\n))
    ;; Debugger entered for an error.
    ('error
     (insert "--Lisp error: ")
     (insert (backtrace-print-to-string (nth 1 args)))
     (insert ?\n))
    ;; debug-on-call, when the next thing is an eval.
    ('t
     (insert "--beginning evaluation of function call form:\n"))
    ;; User calls debug directly.
    (_
     (insert ": ")
     (insert (backtrace-print-to-string (if (eq (car args) 'nil)
                                            (cdr args) args)))
     (insert ?\n))))


(defun debugger-step-through ()
  "Proceed, stepping through subexpressions of this expression.
Enter another debugger on next entry to eval, apply or funcall."
  (interactive)
  (setq debugger-step-after-exit t)
  (setq debugger-jumping-flag t)
  (setq debugger-will-be-back t)
  (add-hook 'post-command-hook 'debugger-reenable)
  (message "Proceeding, will debug on next eval or call.")
  (exit-recursive-edit))

(defun debugger-continue ()
  "Continue, evaluating this expression without stopping."
  (interactive)
  (unless debugger-may-continue
    (error "Cannot continue"))
  (message "Continuing.")

  ;; Check to see if we've flagged some frame for debug-on-exit, in which
  ;; case we'll probably come back to the debugger soon.
  (dolist (frame backtrace-frames)
    (when (plist-get (backtrace-frame-flags frame) :debug-on-exit)
      (setq debugger-will-be-back t)))
  (exit-recursive-edit))

(defun debugger-return-value (val)
  "Continue, specifying value to return.
This is only useful when the value returned from the debugger
will be used, such as in a debug on exit from a frame."
  (interactive "XReturn value (evaluated): ")
  (when (memq (car debugger-args) '(t lambda error debug))
    (error "Cannot return a value %s"
           (if (eq (car debugger-args) 'error)
               "from an error" "at function entrance")))
  (setq debugger-value val)
  (princ "Returning " t)
  (debugger--print debugger-value)
    ;; Check to see if we've flagged some frame for debug-on-exit, in which
    ;; case we'll probably come back to the debugger soon.
  (dolist (frame backtrace-frames)
    (when (plist-get (backtrace-frame-flags frame) :debug-on-exit)
      (setq debugger-will-be-back t)))
  (exit-recursive-edit))

(defun debugger-jump ()
  "Continue to exit from this frame, with all `debug-on-entry' suspended."
  (interactive)
  (debugger-frame)
  (setq debugger-jumping-flag t)
  (add-hook 'post-command-hook 'debugger-reenable)
  (message "Continuing through this frame")
  (setq debugger-will-be-back t)
  (exit-recursive-edit))

(defun debugger-reenable ()
  "Turn all `debug-on-entry' functions back on.
This function is put on `post-command-hook' by `debugger-jump' and
removes itself from that hook."
  (setq debugger-jumping-flag nil)
  (remove-hook 'post-command-hook 'debugger-reenable))

(defun debugger-frame-number ()
  "Return number of frames in backtrace before the one point points at."
  (let ((index (backtrace-get-index)))
    (unless index
      (error "This line is not a function call"))
    ;; We have 3 representations of the backtrace: the real in C in `specpdl',
    ;; the one stored in `backtrace-frames' and the textual version in
    ;; the buffer.  Check here that the one from `backtrace-frames' is in sync
    ;; with the one from `specpdl'.
    (cl-assert (equal (backtrace-frame-fun (nth index backtrace-frames))
                      (nth 1 (backtrace-frame (1+ index)
                                              (debugger--backtrace-base)))))
    ;; The `base' frame is the one that gets index 0 and it is the entry to
    ;; the debugger, so the first non-debugger frame is 1.
    ;; This `+1' skips the same frame as the `cdr' in
    ;; `debugger-setup-buffer'.
    (1+ index)))

(defun debugger-frame ()
  "Request entry to debugger when this frame exits.
Applies to the frame whose line point is on in the backtrace."
  (interactive)
  (backtrace-debug (debugger-frame-number) t (debugger--backtrace-base))
  (setf
   (cl-getf (backtrace-frame-flags (nth (backtrace-get-index) backtrace-frames))
            :debug-on-exit)
   t)
  (backtrace-update-flags))

(defun debugger-frame-clear ()
  "Do not enter debugger when this frame exits.
Applies to the frame whose line point is on in the backtrace."
  (interactive)
  (backtrace-debug (debugger-frame-number) nil (debugger--backtrace-base))
  (setf
   (cl-getf (backtrace-frame-flags (nth (backtrace-get-index) backtrace-frames))
            :debug-on-exit)
   nil)
  (backtrace-update-flags))

(defmacro debugger-env-macro (&rest body)
  "Run BODY in original environment."
  (declare (indent 0))
  `(progn
    (set-match-data debugger-outer-match-data)
    (prog1
        (progn ,@body)
      (setq debugger-outer-match-data (match-data)))))

(defun debugger--backtrace-base ()
  "Return the function name that marks the top of the backtrace.
See `backtrace-frame'."
  (or (cadr (memq :backtrace-base debugger-args))
      #'debug))

(defun debugger-eval-expression (exp &optional nframe)
  "Eval an expression, in an environment like that outside the debugger.
The environment used is the one when entering the activation frame at point."
  (interactive
   (list (read--expression "Eval in stack frame: ")))
  (let ((nframe (or nframe
                    (condition-case nil (debugger-frame-number)
                      (error 0)))) ;; If on first line.
	(base (debugger--backtrace-base)))
    (debugger-env-macro
      (let* ((errored nil)
             (val (if debug-allow-recursive-debug
                      (backtrace-eval exp nframe base)
                    (condition-case err
                        (backtrace-eval exp nframe base)
                      (error (setq errored
                                   (format "%s: %s"
                                           (get (car err) 'error-message)
			                   (car (cdr err)))))))))
        (if errored
            (progn
              (message "Error: %s" errored)
              nil)
          (prog1
              (debugger--print val t)
            (let ((str (eval-expression-print-format val)))
              (if str (princ str t)))))))))

(define-obsolete-function-alias 'debugger-toggle-locals
  'backtrace-toggle-locals "28.1")


(defvar-keymap debugger-mode-map
  :full t
  :parent backtrace-mode-map
  "b" #'debugger-frame
  "c" #'debugger-continue
  "j" #'debugger-jump
  "r" #'debugger-return-value
  "u" #'debugger-frame-clear
  "d" #'debugger-step-through
  "l" #'debugger-list-functions
  "q" #'debugger-quit
  "e" #'debugger-eval-expression
  "R" #'debugger-record-expression

  "<mouse-2>" #'push-button

  :menu
  '("Debugger"
    ["Step through" debugger-step-through
     :help "Proceed, stepping through subexpressions of this expression"]
    ["Continue" debugger-continue
     :help "Continue, evaluating this expression without stopping"]
    ["Jump" debugger-jump
     :help "Continue to exit from this frame, with all debug-on-entry suspended"]
    ["Eval Expression..." debugger-eval-expression
     :help "Eval an expression, in an environment like that outside the debugger"]
    ["Display and Record Expression" debugger-record-expression
     :help "Display a variable's value and record it in `*Backtrace-record*' buffer"]
    ["Return value..." debugger-return-value
     :help "Continue, specifying value to return."]
    "--"
    ["Debug frame" debugger-frame
     :help "Request entry to debugger when this frame exits"]
    ["Cancel debug frame" debugger-frame-clear
     :help "Do not enter debugger when this frame exits"]
    ["List debug on entry functions" debugger-list-functions
     :help "Display a list of all the functions now set to debug on entry"]
    "--"
    ["Next Line" next-line
     :help "Move cursor down"]
    ["Help for Symbol" backtrace-help-follow-symbol
     :help "Show help for symbol at point"]
    ["Describe Debugger Mode" describe-mode
     :help "Display documentation for debugger-mode"]
    "--"
    ["Quit" debugger-quit
     :help "Quit debugging and return to top level"]))

(put 'debugger-mode 'mode-class 'special)

(define-derived-mode debugger-mode backtrace-mode "Debugger"
  "Mode for debugging Emacs Lisp using a backtrace.
\\<debugger-mode-map>
A frame marked with `*' in the backtrace means that exiting that
frame will enter the debugger.  You can flag frames to enter the
debugger when frame is exited with \\[debugger-frame], and remove
the flag with \\[debugger-frame-clear].

When in debugger invoked due to exiting a frame which was flagged
with a `*', you can use the \\[debugger-return-value] command to
override the value being returned from that frame when the debugger
exits.

Use \\[debug-on-entry] and \\[cancel-debug-on-entry] to control
which functions will enter the debugger when called.

Complete list of commands:
\\{debugger-mode-map}"
  (add-hook 'kill-buffer-hook
            (lambda () (if (> (recursion-depth) 0) (top-level)))
            nil t)
  (use-local-map debugger-mode-map))

(defcustom debugger-record-buffer "*Debugger-record*"
  "Buffer name for expression values, for \\[debugger-record-expression]."
  :type 'string
  :group 'debugger
  :version "20.3")

(defun debugger-record-expression  (exp)
  "Display a variable's value and record it in `*Backtrace-record*' buffer."
  (interactive
   (list (read--expression "Record Eval: ")))
  (let* ((buffer (get-buffer-create debugger-record-buffer))
	 (standard-output buffer))
    (princ (format "Debugger Eval (%s): " exp))
    (princ (debugger-eval-expression exp))
    (terpri))

  (with-current-buffer debugger-record-buffer
    (message "%s"
	     (buffer-substring (line-beginning-position 0)
			       (line-end-position 0)))))

(define-obsolete-function-alias 'debug-help-follow
  'backtrace-help-follow-symbol "28.1")


;; When you change this, you may also need to change the number of
;; frames that the debugger skips.
(defun debug--implement-debug-on-entry (&rest _ignore)
  "Conditionally call the debugger.
A call to this function is inserted by `debug-on-entry' to cause
functions to break on entry."
  (if (or inhibit-debug-on-entry debugger-jumping-flag)
      nil
    (let ((inhibit-debug-on-entry t))
      (funcall debugger 'debug :backtrace-base
               ;; An offset of 1 because we need to skip the advice
               ;; OClosure that called us.
               '(1 . debug--implement-debug-on-entry)))))

;;;###autoload
(defun debug-on-entry (function)
  "Request FUNCTION to invoke debugger each time it is called.

When called interactively, prompt for FUNCTION in the minibuffer.

This works by modifying the definition of FUNCTION.  If you tell the
debugger to continue, FUNCTION's execution proceeds.  If FUNCTION is a
normal function or a macro written in Lisp, you can also step through
its execution.  FUNCTION can also be a primitive that is not a special
form, in which case stepping is not possible.  Break-on-entry for
primitive functions only works when that function is called from Lisp.

Use \\[cancel-debug-on-entry] to cancel the effect of this command.
Redefining FUNCTION also cancels it."
  (interactive
   (let ((fn (function-called-at-point)) val)
     (when (special-form-p fn)
       (setq fn nil))
     (setq val (completing-read
                (format-prompt "Debug on entry to function" fn)
		obarray
		#'(lambda (symbol)
		    (and (fboundp symbol)
			 (not (special-form-p symbol))))
		'confirm nil nil (symbol-name fn)))
     (list (if (equal val "") fn (intern val)))))
  (advice-add function :before #'debug--implement-debug-on-entry
              '((depth . -100)))
  function)

(defun debug--function-list ()
  "List of functions currently set for debug on entry."
  (let ((funs '()))
    (mapatoms
     (lambda (s)
       (when (advice-member-p #'debug--implement-debug-on-entry s)
         (push s funs))))
    funs))

;;;###autoload
(defun cancel-debug-on-entry (&optional function)
  "Undo effect of \\[debug-on-entry] on FUNCTION.
If FUNCTION is nil, cancel `debug-on-entry' for all functions.
When called interactively, prompt for FUNCTION in the minibuffer.
To specify a nil argument interactively, exit with an empty minibuffer."
  (interactive
   (list (let ((name
		(completing-read
                 (format-prompt "Cancel debug on entry to function"
                                "all functions")
		 (mapcar #'symbol-name (debug--function-list)) nil t)))
	   (when name
	     (unless (string= name "")
	       (intern name))))))
  (if function
      (progn
        (advice-remove function #'debug--implement-debug-on-entry)
	function)
    (message "Canceling debug-on-entry for all functions")
    (mapcar #'cancel-debug-on-entry (debug--function-list))))

(defun debugger-list-functions ()
  "Display a list of all the functions now set to debug on entry."
  (interactive)
  (require 'help-mode)
  (help-setup-xref '(debugger-list-functions)
		   (called-interactively-p 'interactive))
  (with-output-to-temp-buffer (help-buffer)
    (with-current-buffer standard-output
      (let ((funs (debug--function-list)))
        (if (null funs)
            (princ "No debug-on-entry functions now\n")
          (princ "Functions set to debug on entry:\n\n")
          (dolist (fun funs)
            (make-text-button (point) (progn (prin1 fun) (point))
                              'type 'help-function
                              'help-args (list fun))
            (terpri))
          ;; Now that debug--function-list uses advice-member-p, its
          ;; output should be reliable (except for bugs and the exceptional
          ;; case where some other advice ends up overriding ours).
          ;;(terpri)
          ;;(princ "Note: if you have redefined a function, then it may no longer\n")
          ;;(princ "be set to debug on entry, even if it is in the list.")
          )))))

(defun debugger-quit ()
  "Quit debugging and return to the top level."
  (interactive)
  (if (= (recursion-depth) 0)
      (quit-window)
    (top-level)))

(defun debug--implement-debug-watch (symbol newval op where)
  "Conditionally call the debugger.
This function is called when SYMBOL's value is modified."
  (if (or inhibit-debug-on-entry debugger-jumping-flag)
      nil
    (let ((inhibit-debug-on-entry t))
      (funcall debugger 'watchpoint symbol newval op where))))

;;;###autoload
(defun debug-on-variable-change (variable)
  "Trigger a debugger invocation when VARIABLE is changed.

When called interactively, prompt for VARIABLE in the minibuffer.

This works by calling `add-variable-watcher' on VARIABLE.  If you
quit from the debugger, this will abort the change (unless the
change is caused by the termination of a let-binding).

The watchpoint may be circumvented by C code that changes the
variable directly (i.e., not via `set').  Changing the value of
the variable (e.g., `setcar' on a list variable) will not trigger
watchpoint.

Use \\[cancel-debug-on-variable-change] to cancel the effect of
this command.  Uninterning VARIABLE or making it an alias of
another symbol also cancels it."
  (interactive
   (let* ((var-at-point (variable-at-point))
          (var (and (symbolp var-at-point) var-at-point))
          (val (completing-read
                (format-prompt "Debug when setting variable" var)
                obarray #'boundp
                t nil nil (and var (symbol-name var)))))
     (list (if (equal val "") var (intern val)))))
  (add-variable-watcher variable #'debug--implement-debug-watch))

;;;###autoload
(defalias 'debug-watch #'debug-on-variable-change)


(defun debug--variable-list ()
  "List of variables currently set for debug on set."
  (let ((vars '()))
    (mapatoms
     (lambda (s)
       (when (memq #'debug--implement-debug-watch
                   (get s 'watchers))
         (push s vars))))
    vars))

;;;###autoload
(defun cancel-debug-on-variable-change (&optional variable)
  "Undo effect of \\[debug-on-variable-change] on VARIABLE.
If VARIABLE is nil, cancel `debug-on-variable-change' for all variables.
When called interactively, prompt for VARIABLE in the minibuffer.
To specify a nil argument interactively, exit with an empty minibuffer."
  (interactive
   (list (let ((name
                (completing-read
                 (format-prompt "Cancel debug on set for variable"
                                "all variables")
                 (mapcar #'symbol-name (debug--variable-list)) nil t)))
           (when name
             (unless (string= name "")
               (intern name))))))
  (if variable
      (remove-variable-watcher variable #'debug--implement-debug-watch)
    (message "Canceling debug-watch for all variables")
    (mapc #'cancel-debug-watch (debug--variable-list))))

;;;###autoload
(defalias 'cancel-debug-watch #'cancel-debug-on-variable-change)

(make-obsolete-variable 'debugger-previous-backtrace
                        "no longer used." "29.1")
(defvar debugger-previous-backtrace nil)

(provide 'debug)

;;; debug.el ends here
