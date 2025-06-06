;;; ert-tests.el --- ERT's self-tests  -*- lexical-binding: t -*-

;; Copyright (C) 2007-2025 Free Software Foundation, Inc.

;; Author: Christian Ohler <ohler@gnu.org>

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

;; This file is part of ERT, the Emacs Lisp Regression Testing tool.
;; See ert.el or the texinfo manual for more details.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'ert-x)

;;; Self-test that doesn't rely on ERT, for bootstrapping.

;; This is used to test that bodies actually run.
(defvar ert--test-body-was-run)
(ert-deftest ert-test-body-runs ()
  (setq ert--test-body-was-run t))

(defun ert-self-test ()
  "Run ERT's self-tests and make sure they actually ran."
  (let ((window-configuration (current-window-configuration)))
    (let ((ert--test-body-was-run nil)
          (ert--output-buffer-name " *ert self-tests*"))
      ;; The buffer name chosen here should not compete with the default
      ;; results buffer name for completion in `switch-to-buffer'.
      (let ((stats (ert-run-tests-interactively "^ert-")))
        (cl-assert ert--test-body-was-run)
        (if (zerop (ert-stats-completed-unexpected stats))
            ;; Hide results window only when everything went well.
            (set-window-configuration window-configuration)
          (error "ERT self-test failed"))))))

(defun ert-self-test-and-exit ()
  "Run ERT's self-tests and exit Emacs.

The exit code will be zero if the tests passed, nonzero if they
failed or if there was a problem."
  (unwind-protect
      (progn
        (ert-self-test)
        (kill-emacs 0))
    (unwind-protect
        (progn
          (message "Error running tests")
          (backtrace))
      (kill-emacs 1))))


;;; Further tests are defined using ERT.

(ert-deftest ert-test-nested-test-body-runs ()
  "Test that nested test bodies run."
  (let ((was-run nil))
    (let ((test (make-ert-test :body (lambda ()
                                       (setq was-run t)))))
      (cl-assert (not was-run))
      (ert-run-test test)
      (cl-assert was-run))))


;;; Test that pass/fail works.
(ert-deftest ert-test-pass ()
  (let ((test (make-ert-test :body (lambda ()))))
    (let ((result (ert-run-test test)))
      (cl-assert (ert-test-passed-p result)))))

(ert-deftest ert-test-fail ()
  (let ((test (make-ert-test :body (lambda () (ert-fail "failure message")))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (cl-assert (ert-test-failed-p result) t)
      (cl-assert (equal (ert-test-result-with-condition-condition result)
                     '(ert-test-failed "failure message"))
              t))))

(ert-deftest ert-test-fail-debug-with-debugger-1 ()
  (let ((test (make-ert-test :body (lambda () (ert-fail "failure message")))))
    (let ((debugger (lambda (&rest _args)
                      (cl-assert nil))))
      (let ((ert-debug-on-error nil))
        (ert-run-test test)))))

(ert-deftest ert-test-fail-debug-with-debugger-2 ()
  (let ((test (make-ert-test :body (lambda () (ert-fail "failure message")))))
    (cl-block nil
      (let ((debugger (lambda (&rest _args)
                        (cl-return-from nil nil))))
        (let ((ert-debug-on-error t))
          (ert-run-test test))
        (cl-assert nil)))))

(ert-deftest ert-test-fail-debug-nested-with-debugger ()
  (let ((test (make-ert-test :body (lambda ()
                                     (let ((ert-debug-on-error t))
                                       (ert-fail "failure message"))))))
    (let ((debugger (lambda (&rest _args)
                      (cl-assert nil nil "Assertion a"))))
      (let ((ert-debug-on-error nil))
        (ert-run-test test))))
  (let ((test (make-ert-test :body (lambda ()
                                     (let ((ert-debug-on-error nil))
                                       (ert-fail "failure message"))))))
    (cl-block nil
      (let ((debugger (lambda (&rest _args)
                        (cl-return-from nil nil))))
        (let ((ert-debug-on-error t))
          (ert-run-test test))
        (cl-assert nil nil "Assertion b")))))

(ert-deftest ert-test-error ()
  (let ((test (make-ert-test :body (lambda () (error "Error message")))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (cl-assert (ert-test-failed-p result) t)
      (cl-assert (equal (ert-test-result-with-condition-condition result)
                     '(error "Error message"))
              t))))


;;; Test that `should' works.
(ert-deftest ert-test-should ()
  (let ((test (make-ert-test :body (lambda () (should nil)))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (cl-assert (ert-test-failed-p result) t)
      (cl-assert (equal (ert-test-result-with-condition-condition result)
                     '(ert-test-failed ((should nil) :form nil :value nil)))
              t)))
  (let ((test (make-ert-test :body (lambda () (should t)))))
    (let ((result (ert-run-test test)))
      (cl-assert (ert-test-passed-p result) t))))

(ert-deftest ert-test-should-value ()
  (should (eql (should 'foo) 'foo))
  (should (eql (should 'bar) 'bar)))

(ert-deftest ert-test-should-not ()
  (let ((test (make-ert-test :body (lambda () (should-not t)))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (cl-assert (ert-test-failed-p result) t)
      (cl-assert (equal (ert-test-result-with-condition-condition result)
                     '(ert-test-failed ((should-not t) :form t :value t)))
              t)))
  (let ((test (make-ert-test :body (lambda () (should-not nil)))))
    (let ((result (ert-run-test test)))
      (cl-assert (ert-test-passed-p result)))))


(ert-deftest ert-test-should-with-macrolet ()
  (let ((test (make-ert-test :body (lambda ()
                                     (cl-macrolet ((foo () '(progn t nil)))
                                       (should (foo)))))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (should (ert-test-failed-p result))
      (should (equal
               (ert-test-result-with-condition-condition result)
               '(ert-test-failed ((should (foo))
                                  :form (progn t nil)
                                  :value nil)))))))

(ert-deftest ert-test-should-error ()
  ;; No error.
  (let ((test (make-ert-test :body (lambda () (should-error (progn))))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (should (ert-test-failed-p result))
      (should (equal (ert-test-result-with-condition-condition result)
                     '(ert-test-failed
                       ((should-error (progn))
                        :form (progn)
                        :value nil
                        :fail-reason "did not signal an error"))))))
  ;; A simple error.
  (should (equal (should-error (error "Foo"))
                 '(error "Foo")))
  ;; Error of unexpected type.
  (let ((test (make-ert-test :body (lambda ()
                                     (should-error (error "Foo")
                                                   :type 'singularity-error)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-failed-p result))
      (should (equal
               (ert-test-result-with-condition-condition result)
               '(ert-test-failed
                 ((should-error (error "Foo") :type 'singularity-error)
                  :form (error "Foo")
                  :condition (error "Foo")
                  :fail-reason
                  "the error signaled did not have the expected type"))))))
  ;; Error of the expected type.
  (let* ((error nil)
         (test (make-ert-test
                :body (lambda ()
                        (setq error
                              (should-error (signal 'singularity-error nil)
                                            :type 'singularity-error))))))
    (let ((result (ert-run-test test)))
      (should (ert-test-passed-p result))
      (should (equal error '(singularity-error))))))

(ert-deftest ert-test-should-error-subtypes ()
  (should-error (signal 'singularity-error nil)
                :type 'singularity-error
                :exclude-subtypes t)
  (let ((test (make-ert-test
               :body (lambda ()
                       (should-error (signal 'arith-error nil)
                                     :type 'singularity-error)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-failed-p result))
      (should (equal
               (ert-test-result-with-condition-condition result)
               '(ert-test-failed
                 ((should-error (signal 'arith-error nil)
                                :type 'singularity-error)
                  :form (signal arith-error nil)
                  :condition (arith-error)
                  :fail-reason
                  "the error signaled did not have the expected type"))))))
  (let ((test (make-ert-test
               :body (lambda ()
                       (should-error (signal 'arith-error nil)
                                     :type 'singularity-error
                                     :exclude-subtypes t)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-failed-p result))
      (should (equal
               (ert-test-result-with-condition-condition result)
               '(ert-test-failed
                 ((should-error (signal 'arith-error nil)
                                :type 'singularity-error
                                :exclude-subtypes t)
                  :form (signal arith-error nil)
                  :condition (arith-error)
                  :fail-reason
                  "the error signaled did not have the expected type"))))))
  (let ((test (make-ert-test
               :body (lambda ()
                       (should-error (signal 'singularity-error nil)
                                     :type 'arith-error
                                     :exclude-subtypes t)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-failed-p result))
      (should (equal
               (ert-test-result-with-condition-condition result)
               '(ert-test-failed
                 ((should-error (signal 'singularity-error nil)
                                :type 'arith-error
                                :exclude-subtypes t)
                  :form (signal singularity-error nil)
                  :condition (singularity-error)
                  :fail-reason
                  "the error signaled was a subtype of the expected type")))))
    ))

(ert-deftest ert-test-should-error-argument ()
  "Errors due to evaluating arguments should not break tests."
  (should-error (identity (/ 1 0))))

(ert-deftest ert-test-should-error-macroexpansion ()
  "Errors due to expanding macros should not break tests."
  (cl-macrolet ((test () (error "Foo")))
    (should-error (test))))

(ert-deftest ert-test-skip-when ()
  ;; Don't skip.
  (let ((test (make-ert-test :body (lambda () (skip-when nil)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-passed-p result))))
  ;; Skip.
  (let ((test (make-ert-test :body (lambda () (skip-when t)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-skipped-p result))))
  ;; Skip in case of error.
  (let ((test (make-ert-test :body (lambda () (skip-when (error "Foo"))))))
    (let ((result (ert-run-test test)))
      (should (ert-test-skipped-p result)))))

(ert-deftest ert-test-skip-unless ()
  ;; Don't skip.
  (let ((test (make-ert-test :body (lambda () (skip-unless t)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-passed-p result))))
  ;; Skip.
  (let ((test (make-ert-test :body (lambda () (skip-unless nil)))))
    (let ((result (ert-run-test test)))
      (should (ert-test-skipped-p result))))
  ;; Skip in case of error.
  (let ((test (make-ert-test :body (lambda () (skip-unless (error "Foo"))))))
    (let ((result (ert-run-test test)))
      (should (ert-test-skipped-p result)))))

(defmacro ert--test-my-list (&rest args)
  "Don't use this.  Instead, call `list' with ARGS, it does the same thing.

This macro is used to test if macroexpansion in `should' works."
  `(list ,@args))

(ert-deftest ert-test-should-failure-debugging ()
  "Test that `should' errors contain the information we expect them to."
  (cl-loop
   for (body expected-condition) in
   `((,(lambda () (let ((x nil)) (should x)))
      (ert-test-failed ((should x) :form x :value nil)))
     (,(lambda () (let ((x t)) (should-not x)))
      (ert-test-failed ((should-not x) :form x :value t)))
     (,(lambda () (let ((x t)) (should (not x))))
      (ert-test-failed ((should (not x)) :form (not t) :value nil)))
     (,(lambda () (let ((x nil)) (should-not (not x))))
      (ert-test-failed ((should-not (not x)) :form (not nil) :value t)))
     (,(lambda () (let ((x t) (y nil)) (should-not
                                   (ert--test-my-list x y))))
      (ert-test-failed
       ((should-not (ert--test-my-list x y))
        :form (list t nil)
        :value (t nil))))
     (,(lambda () (let ((_x t)) (should (error "Foo"))))
      (error "Foo")))
   do
   (let* ((test (make-ert-test :body body))
          (result (ert-run-test test)))
     (should (ert-test-failed-p result))
     (should (equal (ert-test-failed-condition result) expected-condition)))))

(defun ert-test--which-file ()
  "Dummy function to help test `symbol-file' for tests.")

(ert-deftest ert-test-deftest ()
  (ert-deftest ert-test-abc () "foo" :tags '(bar))
  (let ((abc (ert-get-test 'ert-test-abc)))
    (should (equal (ert-test-tags abc) '(bar)))
    (should (equal (ert-test-documentation abc) "foo")))
  (should (equal (symbol-file 'ert-test-deftest 'ert--test)
                 (symbol-file 'ert-test--which-file 'defun)))

  (ert-deftest ert-test-def () :expected-result ':passed)
  (let ((def (ert-get-test 'ert-test-def)))
    (should (equal (ert-test-expected-result-type def) :passed)))
  ;; :documentation keyword is forbidden
  (should-error (macroexpand '(ert-deftest ghi ()
                                :documentation "foo"))))

(ert-deftest ert-test-record-backtrace ()
  (let* ((test-body (lambda () (ert-fail "foo")))
         (test (make-ert-test :body test-body))
         (result (ert-run-test test)))
    (should (ert-test-failed-p result))
    (should (memq (backtrace-frame-fun (car (ert-test-failed-backtrace result)))
                  ;; This is `ert-fail' on nativecomp and `signal'
                  ;; otherwise.  It's not clear whether that's a bug
                  ;; or not (bug#51308).
                  '(ert-fail signal)))))

(ert-deftest ert-test-messages ()
  :tags '(:causes-redisplay)
  (let* ((message-string "Test message")
         (messages-buffer (get-buffer-create "*Messages*"))
         (test (make-ert-test :body (lambda () (message "%s" message-string)))))
    (with-current-buffer messages-buffer
      (let ((result (ert-run-test test)))
        (should (equal (concat message-string "\n")
                       (ert-test-result-messages result)))))))

(ert-deftest ert-test-running-tests ()
  (let ((outer-test (ert-get-test 'ert-test-running-tests)))
    (should (equal (ert-running-test) outer-test))
    (let (test1 test2 test3)
      (setq test1 (make-ert-test
                   :name "1"
                   :body (lambda ()
                           (should (equal (ert-running-test) outer-test))
                           (should (equal ert--running-tests
                                          (list test1 test2 test3
                                                outer-test)))))
            test2 (make-ert-test
                   :name "2"
                   :body (lambda ()
                           (should (equal (ert-running-test) outer-test))
                           (should (equal ert--running-tests
                                          (list test3 test2 outer-test)))
                           (ert-run-test test1)))
            test3 (make-ert-test
                   :name "3"
                   :body (lambda ()
                           (should (equal (ert-running-test) outer-test))
                           (should (equal ert--running-tests
                                          (list test3 outer-test)))
                           (ert-run-test test2))))
      (should (ert-test-passed-p (ert-run-test test3))))))

(ert-deftest ert-test-test-result-expected-p ()
  "Test `ert-test-result-expected-p' and (implicitly) `ert-test-result-type-p'."
  ;; passing test
  (let ((test (make-ert-test :body (lambda ()))))
    (should (ert-test-result-expected-p test (ert-run-test test))))
  ;; unexpected failure
  (let ((test (make-ert-test :body (lambda () (ert-fail "failed")))))
    (should-not (ert-test-result-expected-p test (ert-run-test test))))
  ;; expected failure
  (let ((test (make-ert-test :body (lambda () (ert-fail "failed"))
                             :expected-result-type ':failed)))
    (should (ert-test-result-expected-p test (ert-run-test test))))
  ;; `not' expected type
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(not :failed))))
    (should (ert-test-result-expected-p test (ert-run-test test))))
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(not :passed))))
    (should-not (ert-test-result-expected-p test (ert-run-test test))))
  ;; `and' expected type
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(and :passed :failed))))
    (should-not (ert-test-result-expected-p test (ert-run-test test))))
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(and :passed
                                                         (not :failed)))))
    (should (ert-test-result-expected-p test (ert-run-test test))))
  ;; `or' expected type
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(or (and :passed :failed)
                                                        :passed))))
    (should (ert-test-result-expected-p test (ert-run-test test))))
  (let ((test (make-ert-test :body (lambda ())
                             :expected-result-type '(or (and :passed :failed)
                                                        nil (not t)))))
    (should-not (ert-test-result-expected-p test (ert-run-test test)))))

;;; Test `ert-select-tests'.
(ert-deftest ert-test-select-regexp ()
  (should (equal (ert-select-tests "^ert-test-select-regexp$" t)
                 (list (ert-get-test 'ert-test-select-regexp)))))

(ert-deftest ert-test-test-boundp ()
  (should (ert-test-boundp 'ert-test-test-boundp))
  (should-not (ert-test-boundp (make-symbol "ert-not-a-test"))))

(ert-deftest ert-test-select-member ()
  (should (equal (ert-select-tests '(member ert-test-select-member) t)
                 (list (ert-get-test 'ert-test-select-member)))))

(ert-deftest ert-test-select-test ()
  (should (equal (ert-select-tests (ert-get-test 'ert-test-select-test) t)
                 (list (ert-get-test 'ert-test-select-test)))))

(ert-deftest ert-test-select-symbol ()
  (should (equal (ert-select-tests 'ert-test-select-symbol t)
                 (list (ert-get-test 'ert-test-select-symbol)))))

(ert-deftest ert-test-select-and ()
  (let ((test (make-ert-test
               :name nil
               :body nil
               :most-recent-result (make-ert-test-failed
                                    :condition nil
                                    :backtrace nil
                                    :infos nil))))
    (should (equal (ert-select-tests `(and (member ,test) :failed) t)
                   (list test)))))

(ert-deftest ert-test-select-tag ()
  (let ((test (make-ert-test
               :name nil
               :body nil
               :tags '(a b))))
    (should (equal (ert-select-tests '(tag a) (list test)) (list test)))
    (should (equal (ert-select-tests '(tag b) (list test)) (list test)))
    (should (equal (ert-select-tests '(tag c) (list test)) '()))))

(ert-deftest ert-test-select-undefined ()
  (let* ((symbol (make-symbol "ert-not-a-test"))
         (data (should-error (ert-select-tests symbol t)
                             :type 'ert-test-unbound)))
    (should (eq (cadr data) symbol))))


;;; Tests for utility functions.
(ert-deftest ert-test-parse-keys-and-body ()
  (should (equal (ert--parse-keys-and-body '(foo)) '(nil (foo))))
  (should (equal (ert--parse-keys-and-body '(:bar foo)) '((:bar foo) nil)))
  (should (equal (ert--parse-keys-and-body '(:bar foo a (b)))
                 '((:bar foo) (a (b)))))
  (should (equal (ert--parse-keys-and-body '(:bar foo :a (b)))
                 '((:bar foo :a (b)) nil)))
  (should (equal (ert--parse-keys-and-body '(bar foo :a (b)))
                 '(nil (bar foo :a (b)))))
  (should-error (ert--parse-keys-and-body '(:bar foo :a))))


(ert-deftest ert-test-run-tests-interactively ()
  :tags '(:causes-redisplay)
  (let ((passing-test (make-ert-test :name 'passing-test
                                     :body (lambda () (ert-pass))))
        (failing-test (make-ert-test :name 'failing-test
                                     :body (lambda () (ert-fail
                                                       "failure message"))))
        (skipped-test (make-ert-test :name 'skipped-test
                                     :body (lambda () (ert-skip
                                                       "skip message")))))
    (let ((ert-debug-on-error nil))
      (cl-letf* ((buffer-name (generate-new-buffer-name
                               " *ert-test-run-tests*"))
                 (ert--output-buffer-name buffer-name)
                 (messages nil)
                 ((symbol-function 'message)
                  (lambda (format-string &rest args)
                    (push (apply #'format format-string args) messages))))
        (save-window-excursion
          (unwind-protect
              (let ((case-fold-search nil))
                (ert-run-tests-interactively
                 `(member ,passing-test ,failing-test, skipped-test))
                (should (equal messages `(,(concat
                                            "Ran 3 tests, 1 results were "
                                            "as expected, 1 unexpected, "
					    "1 skipped"))))
                (with-current-buffer buffer-name
                  (goto-char (point-min))
                  (should (equal
                           (buffer-substring (point-min)
                                             (save-excursion
                                               (forward-line 5)
                                               (point)))
                           (concat
                            "Selector: (member <passing-test> <failing-test> "
			    "<skipped-test>)\n"
                            "Passed:  1\n"
                            "Failed:  1 (1 unexpected)\n"
			    "Skipped: 1\n"
                            "Total:   3/3\n")))))
            (when (get-buffer buffer-name)
              (kill-buffer buffer-name))))))))

(ert-deftest ert-test-run-tests-batch ()
  (let* ((complex-list '((:1 (:2 (:3 (:4 (:5 (:6 "abc"))))))))
	 (long-list (make-list 11 1))
	 (failing-test-1
          (make-ert-test :name 'failing-test-1
			 :body (lambda () (should (equal complex-list 1)))))
	 (failing-test-2
          (make-ert-test :name 'failing-test-2
			 :body (lambda () (should (equal long-list 1))))))
    (let ((ert-debug-on-error nil)
          messages)
      (cl-letf* (((symbol-function 'message)
                  (lambda (format-string &rest args)
                    (push (apply #'format format-string args) messages))))
        (save-window-excursion
          (let ((case-fold-search nil)
                (ert-batch-backtrace-right-margin nil)
		(ert-batch-print-level 10)
		(ert-batch-print-length 11))
            (ert-run-tests-batch
             `(member ,failing-test-1 ,failing-test-2)))))
      (let ((long-text "(different-types[ \t\n]+(1 1 1 1 1 1 1 1 1 1 1)[ \t\n]+1)))[ \t\n]*$")
	    (complex-text "(different-types[ \t\n]+((:1[ \t\n]+(:2[ \t\n]+(:3[ \t\n]+(:4[ \t\n]+(:5[ \t\n]+(:6[ \t\n]+\"abc\")))))))[ \t\n]+1)))[ \t\n]*$")
            found-long
	    found-complex)
	(cl-loop for msg in (reverse messages)
		 do
		 (unless found-long
		   (setq found-long (string-match long-text msg)))
		 (unless found-complex
		   (setq found-complex (string-match complex-text msg))))
	(should found-long)
	(should found-complex)))))

(ert-deftest ert-test-run-tests-batch-expensive ()
  :tags '(:unstable)
  (let* ((complex-list '((:1 (:2 (:3 (:4 (:5 (:6 "abc"))))))))
	 (failing-test-1
          (make-ert-test :name 'failing-test-1
			 :body (lambda () (should (equal complex-list 1))))))
    (let ((ert-debug-on-error nil)
          messages)
      (cl-letf* (((symbol-function 'message)
                  (lambda (format-string &rest args)
                    (push (apply #'format format-string args) messages))))
        (save-window-excursion
          (let ((case-fold-search nil)
                (ert-batch-backtrace-right-margin nil)
                (ert-batch-backtrace-line-length nil)
		(ert-batch-print-level 6)
		(ert-batch-print-length 11))
            (ert-run-tests-batch
             `(member ,failing-test-1)))))
      (let ((frame "ert-fail(((should (equal complex-list 1)) :form (equal ((:1 (:2 (:3 (:4 (:5 (:6 \"abc\"))))))) 1) :value nil :explanation (different-types ((:1 (:2 (:3 (:4 (:5 (:6 \"abc\"))))))) 1)))")
            found-frame)
	(cl-loop for msg in (reverse messages)
		 do
		 (unless found-frame
		   (setq found-frame (cl-search frame msg :test 'equal))))
        (should found-frame)))))

(ert-deftest ert-test-special-operator-p ()
  (should (ert--special-operator-p 'if))
  (should-not (ert--special-operator-p 'car))
  (should-not (ert--special-operator-p 'ert--special-operator-p))
  (cl-with-gensyms (b)
    (should-not (ert--special-operator-p b))
    (fset b 'if)
    (should (ert--special-operator-p b))))

(ert-deftest ert-test-list-of-should-forms ()
  (let ((test (make-ert-test :body (lambda ()
                                     (should t)
                                     (should (null '()))
                                     (should nil)
                                     (should t)))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (should (equal (ert-test-result-should-forms result)
                     '(((should t) :form t :value t)
                       ((should (null '())) :form (null nil) :value t)
                       ((should nil) :form nil :value nil)))))))

(ert-deftest ert-test-list-of-should-forms-observers-should-not-stack ()
  (let ((test (make-ert-test
               :body (lambda ()
                       (let ((test2 (make-ert-test
                                     :body (lambda ()
                                             (should t)))))
                         (let ((result (ert-run-test test2)))
                           (should (ert-test-passed-p result))))))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (should (ert-test-passed-p result))
      (should (eql (length (ert-test-result-should-forms result))
                   1)))))

(ert-deftest ert-test-list-of-should-forms-no-deep-copy ()
  (let ((test (make-ert-test :body (lambda ()
                                     (let ((obj (list 'a)))
                                       (should (equal obj '(a)))
                                       (setf (car obj) 'b)
                                       (should (equal obj '(b))))))))
    (let ((result (let ((ert-debug-on-error nil))
                    (ert-run-test test))))
      (should (ert-test-passed-p result))
      (should (equal (ert-test-result-should-forms result)
                     '(((should (equal obj '(a))) :form (equal (b) (a)) :value t
                        :explanation nil)
                       ((should (equal obj '(b))) :form (equal (b) (b)) :value t
                        :explanation nil)
                       ))))))

(ert-deftest ert-test-string-first-line ()
  (should (equal (ert--string-first-line "") ""))
  (should (equal (ert--string-first-line "abc") "abc"))
  (should (equal (ert--string-first-line "abc\n") "abc"))
  (should (equal (ert--string-first-line "foo\nbar") "foo"))
  (should (equal (ert--string-first-line " foo\nbar\nbaz\n") " foo")))

(ert-deftest ert-test-explain-equal ()
  (should (equal (ert--explain-equal nil 'foo)
                 '(different-atoms nil foo)))
  (should (equal (ert--explain-equal '(a a) '(a b))
                 '(list-elt 1 (different-atoms a b))))
  (should (equal (ert--explain-equal '(1 48) '(1 49))
                 '(list-elt 1 (different-atoms (48 "#x30" "?0")
                                               (49 "#x31" "?1")))))
  (should (equal (ert--explain-equal 'nil '(a))
                 '(different-types nil (a))))
  (should (equal (ert--explain-equal '(a b c) '(a b c d))
                 '(proper-lists-of-different-length 3 4 (a b c) (a b c d)
                                                    first-mismatch-at 3)))
  (let ((sym (make-symbol "a")))
    (should (equal (ert--explain-equal 'a sym)
                   `(different-symbols-with-the-same-name a ,sym)))))

(ert-deftest ert-test-explain-equal-strings ()
  (should (equal (ert--explain-equal "abc" "axc")
                 '(array-elt 1 (different-atoms
                                (?b "#x62" "?b")
                                (?x "#x78" "?x")))))
  (should (equal (ert--explain-equal "abc" "abxc")
                 '(arrays-of-different-length
                   3 4 "abc" "abxc" first-mismatch-at 2)))
  (should (equal (ert--explain-equal "xyA" "xyÅ")
                 '(array-elt 2 (different-atoms
                                (?A "#x41" "?A")
                                (?Å "#xc5" "?Å")))))
  (should (equal (ert--explain-equal "m\xff" "m\u00ff")
                 `(array-elt
                   1 (different-atoms
                      (#x3fffff "#x3fffff" ,(string-to-multibyte "?\xff"))
                      (#xff "#xff" "?ÿ")))))
  (should (equal (ert--explain-equal (string-to-multibyte "m\xff") "m\u00ff")
                 `(array-elt
                   1 (different-atoms
                      (#x3fffff "#x3fffff" ,(string-to-multibyte "?\xff"))
                      (#xff "#xff" "?ÿ"))))))

(ert-deftest ert-test-explain-equal-improper-list ()
  (should (equal (ert--explain-equal '(a . b) '(a . c))
                 '(cdr (different-atoms b c)))))

(ert-deftest ert-test-explain-equal-keymaps ()
  ;; This used to be very slow.
  (should (equal (make-keymap) (make-keymap)))
  (should (equal (make-sparse-keymap) (make-sparse-keymap))))

(ert-deftest ert-test-significant-plist-keys ()
  (should (equal (ert--significant-plist-keys '()) '()))
  (should (equal (ert--significant-plist-keys '(a b c d e f c g p q r nil s t))
                 '(a c e p s))))

(ert-deftest ert-test-plist-difference-explanation ()
  (should (equal (ert--plist-difference-explanation
                  '(a b c nil) '(a b))
                 nil))
  (should (equal (ert--plist-difference-explanation
                  '(a b c t) '(a b))
                 '(different-properties-for-key c (different-atoms t nil))))
  (should (equal (ert--plist-difference-explanation
                  '(a b c t) '(c nil a b))
                 '(different-properties-for-key c (different-atoms t nil))))
  (should (equal (ert--plist-difference-explanation
                  '(a b c (foo . bar)) '(c (foo . baz) a b))
                 '(different-properties-for-key c
                                                (cdr
                                                 (different-atoms bar baz))))))

(ert-deftest ert-test-abbreviate-string ()
  (should (equal (ert--abbreviate-string "foo" 4 nil) "foo"))
  (should (equal (ert--abbreviate-string "foo" 3 nil) "foo"))
  (should (equal (ert--abbreviate-string "foo" 3 nil) "foo"))
  (should (equal (ert--abbreviate-string "foo" 2 nil) "fo"))
  (should (equal (ert--abbreviate-string "foo" 1 nil) "f"))
  (should (equal (ert--abbreviate-string "foo" 0 nil) ""))
  (should (equal (ert--abbreviate-string "bar" 4 t) "bar"))
  (should (equal (ert--abbreviate-string "bar" 3 t) "bar"))
  (should (equal (ert--abbreviate-string "bar" 3 t) "bar"))
  (should (equal (ert--abbreviate-string "bar" 2 t) "ar"))
  (should (equal (ert--abbreviate-string "bar" 1 t) "r"))
  (should (equal (ert--abbreviate-string "bar" 0 t) "")))

(ert-deftest ert-test-explain-equal-string-properties ()
  (should-not (ert--explain-equal-including-properties-rec "foo" "foo"))
  (should-not (ert--explain-equal-including-properties-rec
               #("foo" 0 3 (a b))
               (propertize "foo" 'a 'b)))
  (should-not (ert--explain-equal-including-properties-rec
               #("foo" 0 3 (a b c d))
               (propertize "foo" 'a 'b 'c 'd)))
  (should-not (ert--explain-equal-including-properties-rec
               #("foo" 0 3 (a (t)))
               (propertize "foo" 'a (list t))))

  (should (equal (ert--explain-equal-including-properties-rec
                  #("foo" 0 3 (a b c e))
                  (propertize "foo" 'a 'b 'c 'd))
                 '(char 0 "f" (different-properties-for-key c (different-atoms e d))
                        context-before ""
                        context-after "oo")))
  (should (equal (ert--explain-equal-including-properties-rec
                  #("foo" 0 1 (a b))
                  "foo")
                 '(char 0 "f"
                        (different-properties-for-key a (different-atoms b nil))
                        context-before ""
                        context-after "oo")))
  (should (equal (ert--explain-equal-including-properties-rec
                  #("foo" 1 3 (a b))
                  #("goo" 0 1 (c d)))
                 '(array-elt 0 (different-atoms (?f "#x66" "?f")
                                                (?g "#x67" "?g")))))
  (should (equal (ert--explain-equal-including-properties-rec
                  #("foo" 0 1 (a b c d) 1 3 (a b))
                  #("foo" 0 1 (c d a b) 1 2 (a foo)))
                 '(char 1 "o" (different-properties-for-key a (different-atoms b foo))
                        context-before "f" context-after "o"))))

(ert-deftest ert-test-explain-time-equal-p ()
  (should-not (ert--explain-time-equal-p 123 '(0 123 0 0)))
  (should (equal (ert--explain-time-equal-p 123 '(0 120 0 0))
                 '(different-time-values
                   "1970-01-01 00:02:03.000000000+0000"
                   "1970-01-01 00:02:00.000000000+0000"
                   difference "3.000000000"))))

(ert-deftest ert-test-stats-set-test-and-result ()
  (let* ((test-1 (make-ert-test :name 'test-1
                                :body (lambda () nil)))
         (test-2 (make-ert-test :name 'test-2
                                :body (lambda () nil)))
         (test-3 (make-ert-test :name 'test-2
                                :body (lambda () nil)))
         (stats (ert--make-stats (list test-1 test-2) 't))
         (failed (make-ert-test-failed :condition nil
                                       :backtrace nil
                                       :infos nil))
         (skipped (make-ert-test-skipped :condition nil
					 :backtrace nil
					 :infos nil)))
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 0 (ert-stats-completed stats)))
    (should (eql 0 (ert-stats-completed-expected stats)))
    (should (eql 0 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-1 (make-ert-test-passed))
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 1 (ert-stats-completed stats)))
    (should (eql 1 (ert-stats-completed-expected stats)))
    (should (eql 0 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-1 failed)
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 1 (ert-stats-completed stats)))
    (should (eql 0 (ert-stats-completed-expected stats)))
    (should (eql 1 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-1 nil)
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 0 (ert-stats-completed stats)))
    (should (eql 0 (ert-stats-completed-expected stats)))
    (should (eql 0 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-3 failed)
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 1 (ert-stats-completed stats)))
    (should (eql 0 (ert-stats-completed-expected stats)))
    (should (eql 1 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 1 test-2 (make-ert-test-passed))
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 2 (ert-stats-completed stats)))
    (should (eql 1 (ert-stats-completed-expected stats)))
    (should (eql 1 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-1 (make-ert-test-passed))
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 2 (ert-stats-completed stats)))
    (should (eql 2 (ert-stats-completed-expected stats)))
    (should (eql 0 (ert-stats-completed-unexpected stats)))
    (should (eql 0 (ert-stats-skipped stats)))
    (ert--stats-set-test-and-result stats 0 test-1 skipped)
    (should (eql 2 (ert-stats-total stats)))
    (should (eql 2 (ert-stats-completed stats)))
    (should (eql 1 (ert-stats-completed-expected stats)))
    (should (eql 0 (ert-stats-completed-unexpected stats)))
    (should (eql 1 (ert-stats-skipped stats)))))

(ert-deftest ert-test-with-demoted-errors ()
  "Check that ERT correctly handles `with-demoted-errors'."
  (should-not (with-demoted-errors "FOO: %S" (error "Foo"))))

(ert-deftest ert-test-fail-inside-should ()
  "Check that `ert-fail' inside `should' works correctly."
  (let ((result (ert-run-test
                 (make-ert-test
                  :name 'test-1
                  :body (lambda () (should (integerp (ert-fail "Boo"))))))))
    (should (ert-test-failed-p result))
    (should (equal (ert-test-failed-condition result)
                   '(ert-test-failed "Boo")))))

(ert-deftest ert-test-deftest-lexical-binding-t ()
  "Check that `lexical-binding' in `ert-deftest' has the file value."
  (should (equal lexical-binding t)))

(ert-deftest ert-test-get-explainer ()
  (should (eq (ert--get-explainer 'string-equal) 'ert--explain-string-equal))
  (should (eq (ert--get-explainer 'string=) 'ert--explain-string-equal)))

(ert-deftest ert--pp-with-indentation-and-newline ()
  :tags '(:causes-redisplay)
  (let ((failing-test (make-ert-test
                       :name 'failing-test
                       :body (lambda ()
                               (should (equal '((:one "1" :three "3" :two "2"))
                                              '((:one "1")))))))
        (want-body "\
Selector: <failing-test>
Passed:  0
Failed:  1 (1 unexpected)
Skipped: 0
Total:   1/1

Started at:   @@TIMESTAMP@@
Finished.
Finished at:  @@TIMESTAMP@@

F

F failing-test
    (ert-test-failed
     ((should (equal '((:one \"1\" :three \"3\" :two \"2\")) '((:one \"1\"))))
      :form (equal ((:one \"1\" :three \"3\" :two \"2\")) ((:one \"1\"))) :value
      nil :explanation
      (list-elt 0
                (proper-lists-of-different-length 6 2
                                                  (:one \"1\" :three \"3\"
                                                        :two \"2\")
                                                  (:one \"1\")
                                                  first-mismatch-at 2))))
\n\n")
        (want-msg "Ran 1 tests, 0 results were as expected, 1 unexpected")
        (buffer-name (generate-new-buffer-name " *ert-test-run-tests*")))
    (cl-letf* ((ert-debug-on-error nil)
               (ert--output-buffer-name buffer-name)
               (messages nil)
               ((symbol-function 'message)
                (lambda (format-string &rest args)
                  (push (apply #'format format-string args) messages)))
               ((symbol-function 'ert--format-time-iso8601)
                (lambda (_) "@@TIMESTAMP@@")))
      (save-window-excursion
        (unwind-protect
            (let ((fill-column 70))
              (ert-run-tests-interactively failing-test)
              (should (equal (list want-msg) messages))
              (should (equal (string-replace "\t" "        "
                                             (with-current-buffer buffer-name
                                               (buffer-string)))
                             want-body)))
          (when noninteractive
            (kill-buffer buffer-name)))))))

(defun ert--hash-table-to-alist (table)
  (let ((accu nil))
    (maphash (lambda (key value)
               (push (cons key value) accu))
             table)
    (nreverse accu)))

(ert-deftest ert-test-test-buffers ()
  (let (buffer-1
        buffer-2)
    (let ((test-1
           (make-ert-test
            :name 'test-1
            :body (lambda ()
                    (ert-with-test-buffer (:name "foo")
                      (should (string-match
                               "[*]Test buffer (ert-test-test-buffers): foo[*]"
                               (buffer-name)))
                      (setq buffer-1 (current-buffer))))))
          (test-2
           (make-ert-test
            :name 'test-2
            :body (lambda ()
                    (ert-with-test-buffer (:name "bar")
                      (should (string-match
                               "[*]Test buffer (ert-test-test-buffers): bar[*]"
                               (buffer-name)))
                      (setq buffer-2 (current-buffer))
                      (ert-fail "fail for test"))))))
      (let ((ert--test-buffers (make-hash-table :weakness t)))
        (ert-run-tests `(member ,test-1 ,test-2) #'ignore)
        (should (equal (ert--hash-table-to-alist ert--test-buffers)
                       `((,buffer-2 . t))))
        (should-not (buffer-live-p buffer-1))
        (should (buffer-live-p buffer-2))))))

(ert-deftest ert-test-with-buffer-selected/current ()
  (let ((origbuf (current-buffer)))
    (ert-with-test-buffer ()
      (let ((buf (current-buffer)))
        (should (not (eq buf origbuf)))
        (with-current-buffer origbuf
          (ert-with-buffer-selected buf
            (should (eq (current-buffer) buf))))))))

(ert-deftest ert-test-with-buffer-selected/selected ()
  (ert-with-test-buffer ()
    (ert-with-buffer-selected (current-buffer)
      (should (eq (window-buffer) (current-buffer))))))

(ert-deftest ert-test-with-buffer-selected/nil-buffer ()
  (ert-with-test-buffer ()
    (let ((buf (current-buffer)))
      (ert-with-buffer-selected nil
        (should (eq (window-buffer) buf))))))

(ert-deftest ert-test-with-buffer-selected/modification-hooks ()
  (ert-with-test-buffer ()
    (ert-with-buffer-selected (current-buffer)
      (should (null inhibit-modification-hooks)))))

(ert-deftest ert-test-with-buffer-selected/read-only ()
  (ert-with-test-buffer ()
    (ert-with-buffer-selected (current-buffer)
      (should (null inhibit-read-only))
      (should (null buffer-read-only)))))

(ert-deftest ert-test-with-buffer-selected/return-value ()
  (should (equal (ert-with-buffer-selected nil "foo") "foo")))

(ert-deftest ert-test-with-test-buffer-selected/selected ()
  (ert-with-test-buffer (:selected t)
    (should (eq (window-buffer) (current-buffer)))))

(ert-deftest ert-test-with-test-buffer-selected/modification-hooks ()
  (ert-with-test-buffer (:selected t)
    (should (null inhibit-modification-hooks))))

(ert-deftest ert-test-with-test-buffer-selected/read-only ()
  (ert-with-test-buffer (:selected t)
    (should (null inhibit-read-only))
    (should (null buffer-read-only))))

(ert-deftest ert-test-with-test-buffer-selected/return-value ()
  (should (equal (ert-with-test-buffer (:selected t) "foo") "foo")))

(ert-deftest ert-test-with-test-buffer-selected/buffer-name ()
  (should (equal (ert-with-test-buffer (:name "foo") (buffer-name))
                 (ert-with-test-buffer (:name "foo" :selected t)
                   (buffer-name)))))

(ert-deftest ert-test-erts-pass ()
  "Test that `ert-test-erts-file' reports test case passed."
  (ert-test-erts-file (ert-resource-file "erts-pass.erts")
                      (lambda () ())))

(ert-deftest ert-test-erts-fail ()
  "Test that `ert-test-erts-file' reports test case failed."
  (should-error (ert-test-erts-file (ert-resource-file "erts-fail.erts")
                                    (lambda () ()))
                :type 'ert-test-failed))

(ert-deftest ert-test-erts-skip-one ()
  "Test that Skip does not affect subsequent test cases (Bug#76839)."
  (should-error (ert-test-erts-file (ert-resource-file "erts-skip-one.erts")
                                    (lambda () ()))
                :type 'ert-test-failed))

(ert-deftest ert-test-erts-skip-last ()
  "Test that Skip does not fail on last test case (Bug#76839)."
  (ert-test-erts-file (ert-resource-file "erts-skip-last.erts")
                      (lambda () ())))

(provide 'ert-tests)

;;; ert-tests.el ends here
