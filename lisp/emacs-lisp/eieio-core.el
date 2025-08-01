;;; eieio-core.el --- Core implementation for eieio  -*- lexical-binding:t -*-

;; Copyright (C) 1995-1996, 1998-2025 Free Software Foundation, Inc.

;; Author: Eric M. Ludlam <zappo@gnu.org>
;; Version: 1.4
;; Keywords: OO, lisp

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
;;
;; The "core" part of EIEIO is the implementation for the object
;; system (such as eieio-defclass-internal, or cl-defmethod) but not
;; the base classes for the object system, which are defined in EIEIO.
;;
;; See the commentary for eieio.el for more about EIEIO itself.

;;; Code:

(require 'cl-lib)

;;;
;; A few functions that are better in the official EIEIO src, but
;; used from the core.
(declare-function slot-unbound "eieio")
(declare-function slot-missing "eieio")
(declare-function child-of-class-p "eieio")
(declare-function same-class-p "eieio")
(declare-function object-of-class-p "eieio")


;;;
;; Variable declarations.
;;
(defvar eieio-hook nil
  "This hook is executed, then cleared each time `defclass' is called.")

(defvar eieio-error-unsupported-class-tags nil
  "Non-nil to throw an error if an encountered tag is unsupported.
This may prevent classes from CLOS applications from being used with EIEIO
since EIEIO does not support all CLOS tags.")

(defvar eieio-skip-typecheck nil
  "If non-nil, skip all slot typechecking.
Set this to t permanently if a program is functioning well to get a
small speed increase.  This variable is also used internally to handle
default setting for optimization purposes.")

(defvar eieio-optimize-primary-methods-flag t
  "Non-nil means to optimize the method dispatch on primary methods.")

(defvar eieio-backward-compatibility 'warn
  "If nil, drop support for some behaviors of older versions of EIEIO.
Currently under control of this var:
- Define every class as a var whose value is the class symbol.
- Define <class>-child-p predicate.
- Allow object names in constructors.
When `warn', also emit warnings at run-time when code uses those
deprecated features.")

(define-obsolete-variable-alias 'eieio-unbound 'eieio--unbound "28.1")
(defvar eieio--unbound (make-symbol "eieio--unbound")
  "Uninterned symbol representing an unbound slot in an object.")
(defvar eieio--unbound-form (macroexp-quote eieio--unbound))

;; This is a bootstrap for eieio-default-superclass so it has a value
;; while it is being built itself.
(defvar eieio-default-superclass nil)

(progn
  ;; Arrange for field access not to bother checking if the access is indeed
  ;; made to an eieio--class object.
  (eval-when-compile (cl-declaim (optimize (safety 0))))

(cl-defstruct (eieio--class
               (:constructor nil)
               (:constructor eieio--class-make (name))
               (:include cl--class)
               (:copier nil))
  children
  initarg-tuples                  ;; initarg tuples list
  (class-slots nil :type (vector-of eieio--slot))
  class-allocation-values         ;; class allocated value vector
  default-object-cache ;; what a newly created object would look like.
                       ; This will speed up instantiation time as
                       ; only a `copy-sequence' will be needed, instead of
                       ; looping over all the values and setting them from
                       ; the default.
  options ;; storage location of tagged class option
          ; Stored outright without modifications or stripping
  )
  ;; Set it back to the default value.  NOTE: Using the default
  ;; `safety' value does NOT give the default
  ;; `byte-compile-delete-errors' value.  Therefore limit this (and
  ;; the above `cl-declaim') to compile time so that we don't affect
  ;; code which only loads this library.
  (eval-when-compile (cl-declaim (optimize (safety 1)))))


(eval-and-compile
  (defconst eieio--object-num-slots 1))

(defsubst eieio--object-class-tag (obj)
  (aref obj 0))


;;; Important macros used internally in eieio.

(require 'cl-macs)  ;For cl--find-class.

(defsubst eieio--class-object (class)
  "Return the class object."
  (if (symbolp class)
      ;; Return the symbol if the class object doesn't exist,
      ;; for better error messages.
      (or (cl--find-class class) class)
    class))

(defsubst eieio--object-class (obj)
  (eieio--class-object (eieio--object-class-tag obj)))

(defun class-p (x)
  "Return non-nil if X is a valid class vector.
X can also be is a symbol."
  (eieio--class-p (if (symbolp x) (cl--find-class x) x)))

(cl-deftype class () `(satisfies class-p))

(defun eieio--class-print-name (class)
  "Return a printed representation of CLASS."
  (format "#<class %s>" (eieio-class-name class)))

(defun eieio-class-name (class)
  "Return a Lisp like symbol name for CLASS."
  (setq class (eieio--class-object class))
  (cl-check-type class eieio--class)
  (eieio--class-name class))
(define-obsolete-function-alias 'class-name #'eieio-class-name "24.4")

(defalias 'eieio--class-constructor #'identity
  "Return the symbol representing the constructor of CLASS.")

(defmacro eieio--class-option-assoc (list option)
  "Return from LIST the found OPTION, or nil if it doesn't exist."
  `(car-safe (cdr (memq ,option ,list))))

(defsubst eieio--class-option (class option)
  "Return the value stored for CLASS' OPTION.
Return nil if that option doesn't exist."
  (eieio--class-option-assoc (eieio--class-options class) option))

(defun eieio-object-p (obj)
  "Return non-nil if OBJ is an EIEIO object."
  (and (recordp obj)
       (eieio--class-p (eieio--object-class obj))))

(cl-deftype eieio-object () `(satisfies eieio-object-p))

(define-obsolete-function-alias 'object-p #'eieio-object-p "25.1")

(defun class-abstract-p (class)
  "Return non-nil if CLASS is abstract.
Abstract classes cannot be instantiated."
  (eieio--class-option (cl--find-class class) :abstract))

(defsubst eieio--class-method-invocation-order (class)
  "Return the invocation order of CLASS.
Abstract classes cannot be instantiated."
  (or (eieio--class-option class :method-invocation-order)
      :breadth-first))



;;;
;; Class Creation

(defvar eieio-defclass-autoload-map (make-hash-table)
  "Symbol map of superclasses we find in autoloads.")

;; We autoload this because it's used in `make-autoload'.
;;;###autoload
(defun eieio-defclass-autoload (cname superclasses filename doc)
  "Create autoload symbols for the EIEIO class CNAME.
SUPERCLASSES are the superclasses that CNAME inherits from.
DOC is the docstring for CNAME.
This function creates a mock-class for CNAME and adds it into
SUPERCLASSES as children.
It creates an autoload function for CNAME's constructor."
  ;; Assume we've already debugged inputs.
  (let* ((oldc (cl--find-class cname))
	 (newc (eieio--class-make cname))
	 (parents (mapcar #'cl-find-class superclasses)))
    (if (eieio--class-p oldc)
	nil ;; Do nothing if we already have this class.

      ;; turn this into a usable self-pointing symbol
      (when eieio-backward-compatibility
        (set cname cname)
        (make-obsolete-variable cname (format "use '%s instead" cname) "25.1"))

      (when (memq nil parents)
        ;; If some parents aren't yet fully defined, just ignore them for now.
        (setq parents (delq nil parents)))
      (unless parents
       (setq parents (list (cl--find-class 'eieio-default-superclass))))
      (setf (cl--class-parents newc) parents)
      (setf (cl--find-class cname) newc)

      ;; Create an autoload on top of our constructor function.
      (autoload cname filename doc nil nil)
      (autoload (intern (format "%s-p" cname)) filename "" nil nil)
      (when eieio-backward-compatibility
        (autoload (intern (format "%s-child-p" cname)) filename "" nil nil)))))

(defun eieio--full-class-object (class)
  "Like `eieio--class-object' but loads the class if needed."
  (let ((c (eieio--class-object class)))
    (and (not (symbolp c))
         ;; If the default-object-cache slot is nil, the class object
         ;; is still a "dummy" setup by eieio-defclass-autoload.
         (not (eieio--class-default-object-cache c))
         ;; FIXME: We rely on the autoload setup for the "standard"
         ;; constructor, here!
         (autoload-do-load (symbol-function (eieio--class-name c))))
    c))

(cl-deftype list-of (elem-type)
  `(and list
        (satisfies ,(lambda (list)
                      (cl-every (lambda (elem) (cl-typep elem elem-type))
                                list)))))


(defun eieio-make-class-predicate (class)
  (lambda (obj)
    (:documentation
     (concat
      (internal--format-docstring-line
       "Return non-nil if OBJ is an object of type `%S'."
       class)
      "\n\n(fn OBJ)"))
    (and (eieio-object-p obj)
         (same-class-p obj class))))

(defun eieio-make-child-predicate (class)
  (lambda (obj)
    (:documentation
     (concat
      (internal--format-docstring-line
       "Return non-nil if OBJ is an object of type `%S' or a subclass."
       class)
      "\n\n(fn OBJ)"))
    (and (eieio-object-p obj)
         (object-of-class-p obj class))))

(defvar eieio--known-slot-names nil)
(defvar eieio--known-class-slot-names nil)

(defun eieio--known-slot-name-p (name)
  (or (memq name eieio--known-slot-names)
      (get name 'slot-name)))

(defun eieio-defclass-internal (cname superclasses slots options)
  "Define CNAME as a new subclass of SUPERCLASSES.
SLOTS are the slots residing in that class definition, and OPTIONS
holds the class options.
See `defclass' for more information."
  ;; Run our eieio-hook each time, and clear it when we are done.
  ;; This way people can add hooks safely if they want to modify eieio
  ;; or add definitions when eieio is loaded or something like that.
  (run-hooks 'eieio-hook)
  (setq eieio-hook nil)

  (let* ((oldc (let ((c (cl--find-class cname))) (if (eieio--class-p c) c)))
	 (newc (or oldc
                   ;; Reuse `oldc' instead of creating a new one, so that
                   ;; existing references stay valid.  E.g. when
                   ;; reloading the file that does the `defclass', we don't
                   ;; want to create a new class object.
                   (eieio--class-make cname)))
	 (groups nil)) ;; list of groups id'd from slots

    ;; If this class already existed, and we are updating its structure,
    ;; make sure we keep the old child list.  This can cause bugs, but
    ;; if no new slots are created, it also saves time, and prevents
    ;; method table breakage, particularly when the users is only
    ;; byte compiling an EIEIO file.
    (if oldc
        (progn
          (cl-assert (eq newc oldc))
          ;; Reset the fields.
          (setf (eieio--class-parents newc) nil)
          (setf (eieio--class-slots newc) nil)
          (setf (eieio--class-initarg-tuples newc) nil)
          (setf (eieio--class-class-slots newc) nil))
      ;; If the old class did not exist, but did exist in the autoload map,
      ;; then adopt those children.  This is like the above, but deals with
      ;; autoloads nicely.
      (let ((children (gethash cname eieio-defclass-autoload-map)))
	(when children
          (setf (eieio--class-children newc) children)
	  (remhash cname eieio-defclass-autoload-map))))

    (unless (or superclasses (eq cname 'eieio-default-superclass))
      (setq superclasses '(eieio-default-superclass)))

    (if superclasses
	(progn
	  (dolist (p superclasses)
	    (if (not (and p (symbolp p)))
		(error "Invalid parent class %S" p)
              (let ((c (cl--find-class p)))
                (if (not (eieio--class-p c))
		    ;; bad class
		    (error "Given parent class %S is not a class" p)
		  ;; good parent class...
		  ;; save new child in parent
                  (cl-pushnew cname (eieio--class-children c))
		  ;; Get custom groups, and store them into our local copy.
		  (mapc (lambda (g) (cl-pushnew g groups :test #'equal))
			(eieio--class-option c :custom-groups))
		  ;; Save parent in child.
                  (push c (eieio--class-parents newc))))))
	  ;; Reverse the list of our parents so that they are prioritized in
	  ;; the same order as specified in the code.
	  (cl-callf nreverse (eieio--class-parents newc))
	  ;; Before adding new slots, let's add all the methods and classes
	  ;; in from the parent class.
	  (eieio-copy-parents-into-subclass newc))

      (cl-assert (eq cname 'eieio-default-superclass))
      (setf (eieio--class-parents newc) (list (cl--find-class 'record))))

    ;; turn this into a usable self-pointing symbol;  FIXME: Why?
    (when eieio-backward-compatibility
      (set cname cname)
      (make-obsolete-variable cname (format "use '%s instead" cname)
                              "25.1"))

    ;; Store the new class vector definition into the symbol.  We need to
    ;; do this first so that we can call defmethod for the accessor.
    ;; The vector will be updated by the following while loop and will not
    ;; need to be stored a second time.
    (setf (cl--find-class cname) newc)

    ;; Query each slot in the declaration list and mangle into the
    ;; class structure I have defined.
    (pcase-dolist (`(,name . ,slot) slots)
      (let* ((init    (or (plist-get slot :initform)
			  (if (member :initform slot) nil
			    eieio--unbound-form)))
	     (initarg (plist-get slot :initarg))
	     (docstr  (plist-get slot :documentation))
	     (prot    (plist-get slot :protection))
	     (alloc   (plist-get slot :allocation))
	     (type    (plist-get slot :type))
	     (custom  (plist-get slot :custom))
	     (label   (plist-get slot :label))
	     (customg (plist-get slot :group))
	     (printer (plist-get slot :printer))

	     (skip-nil (eieio--class-option-assoc options :allow-nil-initform))
	     )

        (unless (or (macroexp-const-p init)
                    (eieio--eval-default-p init))
          ;; FIXME: We duplicate this test here and in `defclass' because
          ;; if we move this part to `defclass' we may break some existing
          ;; code (because the `fboundp' test in `eieio--eval-default-p'
          ;; returns a different result at compile time).
          (setq init (macroexp-quote init)))

	;; Clean up the meaning of protection.
        (setq prot
              (pcase prot
                ((or 'nil 'public :public) nil)
                ((or 'protected :protected) 'protected)
                ((or 'private :private) 'private)
                (_ (signal 'invalid-slot-type (list :protection prot)))))

	;; The default type specifier is supposed to be t, meaning anything.
	(if (not type) (setq type t))

	;; intern the symbol so we can use it blankly
        (if eieio-backward-compatibility
            (and initarg (not (keywordp initarg))
                 (progn
                   (set initarg initarg)
                   (make-obsolete-variable
                    initarg (format "use '%s instead" initarg) "25.1"))))

	;; The customgroup should be a list of symbols.
	(cond ((and (null customg) custom)
	       (setq customg '(default)))
	      ((not (listp customg))
	       (setq customg (list customg))))
	;; The customgroup better be a list of symbols.
	(dolist (cg customg)
          (unless (symbolp cg)
            (signal 'invalid-slot-type (list :group cg))))

	;; First up, add this slot into our new class.
	(eieio--add-new-slot
         newc (cl--make-slot-descriptor
               name init type
               `(,@(if docstr `((:documentation . ,docstr)))
                 ,@(if custom  `((:custom . ,custom)))
                 ,@(if label   `((:label . ,label)))
                 ,@(if customg `((:group . ,customg)))
                 ,@(if printer `((:printer . ,printer)))
                 ,@(if prot    `((:protection . ,prot)))))
         initarg alloc 'defaultoverride skip-nil)

	;; We need to id the group, and store them in a group list attribute.
	(dolist (cg customg)
          (cl-pushnew cg groups :test #'equal))
	))

    ;; Now that everything has been loaded up, all our lists are backwards!
    ;; Fix that up now and turn them into vectors.
    (cl-callf (lambda (slots) (apply #'vector (nreverse slots)))
        (eieio--class-slots newc))
    (cl-callf nreverse (eieio--class-initarg-tuples newc))

    ;; The storage for class-class-allocation-type needs to be turned into
    ;; a vector now.
    (cl-callf (lambda (slots) (apply #'vector slots))
        (eieio--class-class-slots newc))

    ;; Also, setup the class allocated values.
    (let* ((slots (eieio--class-class-slots newc))
           (n (length slots))
           (v (make-vector n nil)))
      (dotimes (i n)
        (setf (aref v i) (eval
                          (cl--slot-descriptor-initform (aref slots i))
                          t)))
      (setf (eieio--class-class-allocation-values newc) v))

    ;; Attach slot symbols into a hash table, and store the index of
    ;; this slot as the value this table.
    (let* ((slots (eieio--class-slots newc))
	   ;; (cslots (eieio--class-class-slots newc))
	   (oa (make-hash-table :test #'eq)))
      ;; (dotimes (cnt (length cslots))
      ;;   (setf (gethash (cl--slot-descriptor-name (aref cslots cnt)) oa) (- -1 cnt)))
      (dotimes (cnt (length slots))
        (setf (gethash (cl--slot-descriptor-name (aref slots cnt)) oa)
              (+ (eval-when-compile eieio--object-num-slots) cnt)))
      (setf (eieio--class-index-table newc) oa))

    ;; Set up a specialized doc string.
    ;; Use stored value since it is calculated in a non-trivial way
    (let ((docstring (eieio--class-option-assoc options :documentation)))
      (setf (eieio--class-docstring newc) docstring)
      (when eieio-backward-compatibility
        (put cname 'variable-documentation docstring)))

    ;; Save the file location where this class is defined.
    (add-to-list 'current-load-list `(define-type . ,cname))

    ;; We have a list of custom groups.  Store them into the options.
    (let ((g (eieio--class-option-assoc options :custom-groups)))
      (mapc (lambda (cg) (cl-pushnew cg g :test 'equal)) groups)
      (if (memq :custom-groups options)
	  (setcar (cdr (memq :custom-groups options)) g)
	(setq options (cons :custom-groups (cons g options)))))

    ;; Set up the options we have collected.
    (setf (eieio--class-options newc) options)

    ;; Create the cached default object.
    (let ((cache (make-record newc
                              (+ (length (eieio--class-slots newc))
                                 ;; FIXME: Why +1 -1 ?
                                 (eval-when-compile eieio--object-num-slots)
                                 -1)
                              nil)))
      (let ((eieio-skip-typecheck t))
	;; All type-checking has been done to our satisfaction
	;; before this call.  Don't waste our time in this call..
	(eieio-set-defaults cache t))
      (setf (eieio--class-default-object-cache newc) cache))

    ;; Return our new class object
    ;; newc
    cname
    ))

(defun eieio--eval-default-p (val)
  "Whether the default value VAL should be evaluated for use."
  (and (consp val) (symbolp (car val)) (fboundp (car val))))

(defun eieio--perform-slot-validation-for-default (slot skipnil)
  "For SLOT, signal if its type does not match its default value.
If SKIPNIL is non-nil, then if default value is nil return t instead."
  (let ((value (cl--slot-descriptor-initform slot))
        (spec (cl--slot-descriptor-type slot)))
    (if (not (or (not (macroexp-const-p value))
                 eieio-skip-typecheck
                 (and skipnil (null value))
                 (eieio--perform-slot-validation spec (eval value t))))
        (signal 'invalid-slot-type (list (cl--slot-descriptor-name slot) spec value)))))

(defun eieio--slot-override (old new skipnil)
  (cl-assert (eq (cl--slot-descriptor-name old) (cl--slot-descriptor-name new)))
  ;; There is a match, and we must override the old value.
  (let* ((a (cl--slot-descriptor-name old))
         (tp (cl--slot-descriptor-type old))
         (d (cl--slot-descriptor-initform new))
         (type (cl--slot-descriptor-type new))
         (oprops (cl--slot-descriptor-props old))
         (nprops (cl--slot-descriptor-props new))
         (custg (alist-get :group nprops)))
    ;; If type is passed in, is it the same?
    (if (not (eq type t))
        (if (not (equal type tp))
            (error
             "Child slot type `%s' does not match inherited type `%s' for `%s'"
             type tp a))
      (setf (cl--slot-descriptor-type new) tp))
    ;; If we have a repeat, only update the initarg...
    (unless (eq d eieio--unbound-form)
      (eieio--perform-slot-validation-for-default new skipnil)
      (setf (cl--slot-descriptor-initform old) d))

    ;; PLN Tue Jun 26 11:57:06 2007 : The protection is
    ;; checked and SHOULD match the superclass
    ;; protection. Otherwise an error is thrown. However
    ;; I wonder if a more flexible schedule might be
    ;; implemented.
    ;;
    ;; EML - We used to have (if prot... here,
    ;;       but a prot of 'nil means public.
    ;;
    (let ((super-prot (alist-get :protection oprops))
          (prot (alist-get :protection nprops)))
      (if (not (eq prot super-prot))
          (error "Child slot protection `%s' does not match inherited protection `%s' for `%s'"
                 prot super-prot a)))
    ;; End original PLN

    ;; PLN Tue Jun 26 11:57:06 2007 :
    ;; Do a non redundant combination of ancient custom
    ;; groups and new ones.
    (when custg
      (let* ((list1 (alist-get :group oprops)))
        (dolist (elt custg)
          (unless (memq elt list1)
            (push elt list1)))
        (setf (alist-get :group (cl--slot-descriptor-props old)) list1)))
    ;;  End PLN

    ;;  PLN Mon Jun 25 22:44:34 2007 : If a new cust is
    ;;  set, simply replaces the old one.
    (dolist (prop '(:custom :label :documentation :printer))
      (when (alist-get prop (cl--slot-descriptor-props new))
        (setf (alist-get prop (cl--slot-descriptor-props old))
              (alist-get prop (cl--slot-descriptor-props new))))

      )  ))

(defun eieio--add-new-slot (newc slot init alloc
				 &optional defaultoverride skipnil)
  "Add into NEWC attribute SLOT.
If a slot of that name already exists in NEWC, then do nothing.
If it doesn't exist, INIT is the initarg, if any.
Argument ALLOC specifies if the slot is allocated per instance, or per class.
If optional DEFAULTOVERRIDE is non-nil, then if A exists in NEWC,
we must override its value for a default.
Optional argument SKIPNIL indicates if type checking should be skipped
if default value is nil."
  ;; Make sure we duplicate those items that are sequences.
  (let* ((a (cl--slot-descriptor-name slot))
         (d (cl--slot-descriptor-initform slot))
         (old (car (cl-member a (eieio--class-slots newc)
                              :key #'cl--slot-descriptor-name)))
         (cold (car (cl-member a (eieio--class-class-slots newc)
                               :key #'cl--slot-descriptor-name))))
    (cl-pushnew a eieio--known-slot-names)
    (when (eq alloc :class)
      (cl-pushnew a eieio--known-class-slot-names))
    (condition-case nil
        (if (sequencep d) (setq d (copy-sequence d)))
      ;; This copy can fail on a cons cell with a non-cons in the cdr.  Let's
      ;; skip it if it doesn't work.
      (error nil))
    ;; (if (sequencep type) (setq type (copy-sequence type)))
    ;; (if (sequencep cust) (setq cust (copy-sequence cust)))
    ;; (if (sequencep custg) (setq custg (copy-sequence custg)))

    ;; To prevent override information w/out specification of storage,
    ;; we need to do this little hack.
    (if cold (setq alloc :class))

    (if (memq alloc '(nil :instance))
        ;; In this case, we modify the INSTANCE version of a given slot.
        (progn
          ;; Only add this element if it is so-far unique
          (if (not old)
              (progn
                (eieio--perform-slot-validation-for-default slot skipnil)
                (push slot (eieio--class-slots newc))
                )
            ;; When defaultoverride is true, we are usually adding new local
            ;; attributes which must override the default value of any slot
            ;; passed in by one of the parent classes.
            (when defaultoverride
              (eieio--slot-override old slot skipnil)))
          (when init
            (cl-pushnew (cons init a) (eieio--class-initarg-tuples newc)
                        :test #'equal)))

      ;; CLASS ALLOCATED SLOTS
      (if (not cold)
          (progn
            (eieio--perform-slot-validation-for-default slot skipnil)
            ;; Here we have found a :class version of a slot.  This
            ;; requires a very different approach.
            (push slot (eieio--class-class-slots newc)))
        (when defaultoverride
          ;; There is a match, and we must override the old value.
          (eieio--slot-override cold slot skipnil))))))

(defun eieio-copy-parents-into-subclass (newc)
  "Copy into NEWC the slots of PARENTS.
Follow the rules of not overwriting early parents when applying to
the new child class."
  (let ((sn (eieio--class-option-assoc (eieio--class-options newc)
                                       :allow-nil-initform)))
    (dolist (pcv (eieio--class-parents newc))
      ;; First, duplicate all the slots of the parent.
      (let ((pslots (eieio--class-slots pcv))
            (pinit (eieio--class-initarg-tuples pcv)))
        (dotimes (i (length pslots))
	  (let* ((sd (cl--copy-slot-descriptor (aref pslots i)))
                 (init (car (rassq (cl--slot-descriptor-name sd) pinit))))
	    (eieio--add-new-slot newc sd init nil nil sn))
          )) ;; while/let
      ;; Now duplicate all the class alloc slots.
      (let ((pcslots (eieio--class-class-slots pcv)))
        (dotimes (i (length pcslots))
          (eieio--add-new-slot newc (cl--copy-slot-descriptor
                                     (aref pcslots i))
                               nil :class sn)
          )))))


;;; Slot type validation

;; This is a hideous hack for replacing `typep' from cl-macs, to avoid
;; requiring the CL library at run-time.  It can be eliminated if/when
;; `typep' is merged into Emacs core.

(defun eieio--perform-slot-validation (spec value)
  "Return non-nil if SPEC does not match VALUE."
  (or (eq spec t)			; t always passes
      (eq value eieio--unbound)		; unbound always passes
      (cl-typep value spec)))

(defun eieio--validate-slot-value (class slot-idx value slot)
  "Make sure that for CLASS referencing SLOT-IDX, VALUE is valid.
Checks the :type specifier.
SLOT is the slot that is being checked, and is only used when throwing
an error."
  (if eieio-skip-typecheck
      nil
    ;; Trim off object IDX junk added in for the object index.
    (setq slot-idx (- slot-idx (eval-when-compile eieio--object-num-slots)))
    (let* ((sd (aref (cl--class-slots class) ;??
                     slot-idx))
           (st (cl--slot-descriptor-type sd)))
      (cond
       ((not (eieio--perform-slot-validation st value))
	(signal 'invalid-slot-type
                (list (cl--class-name class) slot st value)))
       ((alist-get :read-only (cl--slot-descriptor-props sd))
        (signal 'eieio-read-only (list (cl--class-name class) slot)))))))

(defun eieio--validate-class-slot-value (class slot-idx value slot)
  "Make sure that for CLASS referencing SLOT-IDX, VALUE is valid.
Checks the :type specifier.
SLOT is the slot that is being checked, and is only used when throwing
an error."
  (if eieio-skip-typecheck
      nil
    (let ((st (cl--slot-descriptor-type (aref (eieio--class-class-slots class)
                                              slot-idx))))
      (if (not (eieio--perform-slot-validation st value))
	  (signal 'invalid-slot-type
                  (list (cl--class-name class) slot st value))))))

(defun eieio-barf-if-slot-unbound (value instance slotname fn)
  "Throw a signal if VALUE is a representation of an UNBOUND slot.
INSTANCE is the object being referenced.  SLOTNAME is the offending
slot.  If the slot is ok, return VALUE.
Argument FN is the function calling this verifier."
  (if (and (eq value eieio--unbound) (not eieio-skip-typecheck))
      (slot-unbound instance (eieio--object-class instance) slotname fn)
    value))


;;; Get/Set slots in an object.

(eval-and-compile
  (defun eieio--check-slot-name (exp _obj slot &rest _)
    (pcase slot
      ((and (or `',name (and name (pred keywordp)))
            (guard (not (eieio--known-slot-name-p name))))
       (macroexp-warn-and-return
        (format-message "Unknown slot `%S'" name)
        exp nil 'compile-only name))
      (_ exp))))

(defun eieio-oref (obj slot)
  "Return the value in OBJ at SLOT in the object vector."
  (declare (compiler-macro eieio--check-slot-name)
           ;; FIXME: Make it a gv-expander such that the hash-table lookup is
           ;; only performed once when used in `push' and friends?
           (gv-setter eieio-oset))
  (cl-check-type slot symbol)
  (cond
   ((cl-typep obj '(or eieio-object cl-structure-object))
    (let* ((class (eieio--object-class obj))
           (c (eieio--slot-name-index class slot)))
      (if (not c)
	  ;; It might be missing because it is a :class allocated slot.
	  ;; Let's check that info out.
	  (if (and (eieio--class-p class)
                   (setq c (eieio--class-slot-name-index class slot)))
	      ;; Oref that slot.
	      (aref (eieio--class-class-allocation-values class) c)
	    ;; The slot-missing method is a cool way of allowing an object author
	    ;; to intercept missing slot definitions.  Since it is also the LAST
	    ;; thing called in this fn, its return value would be retrieved.
	    (slot-missing obj slot 'oref))
	(eieio-barf-if-slot-unbound (aref obj c) obj slot 'oref))))
   ((cl-typep obj 'oclosure) (oclosure--slot-value obj slot))
   (t
    (signal 'wrong-type-argument
            (list '(or eieio-object cl-structure-object oclosure) obj)))))



(defun eieio-oref-default (class slot)
  "Do the work for the macro `oref-default' with similar parameters.
Fills in CLASS's SLOT with its default value."
  (declare (gv-setter eieio-oset-default)
           (compiler-macro
            (lambda (exp)
              (ignore class)
              (pcase slot
                ((and (or `',name (and name (pred keywordp)))
                      (guard (not (eieio--known-slot-name-p name))))
                 (macroexp-warn-and-return
                  (format-message "Unknown slot `%S'" name)
                  exp nil 'compile-only name))
                ((and (or `',name (and name (pred keywordp)))
                      (guard (not (memq name eieio--known-class-slot-names))))
                 (macroexp-warn-and-return
                  (format-message "Slot `%S' is not class-allocated" name)
                  exp nil 'compile-only name))
                (_ exp)))))
  (cl-check-type class (or eieio-object class))
  (cl-check-type slot symbol)
  (let* ((cl (cond ((symbolp class) (cl--find-class class))
                   ((eieio-object-p class) (eieio--object-class class))
                   (t class)))
	 (c (eieio--slot-name-index cl slot)))
    (if (not c)
	;; It might be missing because it is a :class allocated slot.
	;; Let's check that info out.
	(if (and (eieio--class-p cl)
                 (setq c
		       (eieio--class-slot-name-index cl slot)))
	    ;; Oref that slot.
	    (aref (eieio--class-class-allocation-values cl)
		  c)
	  (slot-missing class slot 'oref-default))
      (eieio-barf-if-slot-unbound
       (let ((val (cl--slot-descriptor-initform
                   (aref (eieio--class-slots cl)
                         (- c (eval-when-compile eieio--object-num-slots))))))
	 (eval val t))
       class (eieio--class-name cl) 'oref-default))))

(defun eieio-oset (obj slot value)
  "Do the work for the macro `oset'.
Fills in OBJ's SLOT with VALUE."
  (declare (compiler-macro eieio--check-slot-name))
  (cl-check-type slot symbol)
  (cond
   ((cl-typep obj '(or eieio-object cl-structure-object))
    (let* ((class (eieio--object-class obj))
           (c (eieio--slot-name-index class slot)))
      (if (not c)
	  ;; It might be missing because it is a :class allocated slot.
	  ;; Let's check that info out.
	  (if (and (eieio--class-p class)
                   (setq c
		         (eieio--class-slot-name-index class slot)))
	      ;; Oset that slot.
	      (progn
	        (eieio--validate-class-slot-value class c value slot)
	        (aset (eieio--class-class-allocation-values class)
		      c value))
	    ;; See oref for comment on `slot-missing'
	    (slot-missing obj slot 'oset value))
	(eieio--validate-slot-value class c value slot)
	(aset obj c value))))
   ((cl-typep obj 'oclosure) (oclosure--set-slot-value obj slot value))
   (t
    (signal 'wrong-type-argument
            (list '(or eieio-object cl-structure-object oclosure) obj)))))

(defun eieio-oset-default (class slot value)
  "Do the work for the macro `oset-default'.
Fills in the default value in CLASS' in SLOT with VALUE."
  (declare (compiler-macro
            (lambda (exp)
              (ignore class value)
              (pcase slot
                ((and (or `',name (and name (pred keywordp)))
                      (guard (not (eieio--known-slot-name-p name))))
                 (macroexp-warn-and-return
                  (format-message "Unknown slot `%S'" name)
                  exp nil 'compile-only name))
                ((and (or `',name (and name (pred keywordp)))
                      (guard (not (memq name eieio--known-class-slot-names))))
                 (macroexp-warn-and-return
                  (format-message "Slot `%S' is not class-allocated" name)
                  exp nil 'compile-only name))
                (_ exp)))))
  (setq class (eieio--class-object class))
  (cl-check-type class eieio--class)
  (cl-check-type slot symbol)
  (let* ((c (eieio--slot-name-index class slot)))
    (if (not c)
        ;; It might be missing because it is a :class allocated slot.
        ;; Let's check that info out.
        (if (and (eieio--class-p class)
                 (setq c (eieio--class-slot-name-index class slot)))
            (progn
              ;; Oref that slot.
              (eieio--validate-class-slot-value class c value slot)
              (aset (eieio--class-class-allocation-values class) c
                    value))
          (signal 'invalid-slot-name (list (cl--class-name class) slot)))
      ;; `oset-default' on an instance-allocated slot is allowed by EIEIO but
      ;; not by CLOS and is mildly inconsistent with the :initform thingy, so
      ;; it'd be nice to get rid of it.
      ;; This said, it is/was used at one place by gnus/registry.el, so it
      ;; might be used elsewhere as well, so let's keep it for now.
      ;; FIXME: Generate a compile-time warning for it!
      ;; (error "Can't `oset-default' an instance-allocated slot: %S of %S"
      ;;        slot class)
      (eieio--validate-slot-value class c value slot)
      ;; Set this into the storage for defaults.
      (setf (cl--slot-descriptor-initform
             (aref (eieio--class-slots class)
                   (- c (eval-when-compile eieio--object-num-slots))))
            (macroexp-quote value))
      ;; Take the value, and put it into our cache object.
      (eieio-oset (eieio--class-default-object-cache class)
                  slot value)
      )))


;;; EIEIO internal search functions
;;
(defun eieio--slot-name-index (class slot)
  "In CLASS find the index of the named SLOT.
The slot is a symbol which is installed in CLASS by the `defclass' call.
If SLOT is the value created with :initarg instead,
reverse-lookup that name, and recurse with the associated slot value."
  ;; Removed checks to outside this call
  (let* ((fsi (gethash slot (cl--class-index-table class))))
    (if (integerp fsi)
        fsi
      (when eieio-backward-compatibility
	(let ((fn (eieio--initarg-to-attribute class slot)))
	  (when fn
            (when (eq eieio-backward-compatibility 'warn)
              (message "Accessing slot `%S' via obsolete initarg name `%S'"
                       fn slot))
            ;; Accessing a slot via its :initarg is accepted by EIEIO
            ;; (but not CLOS) but is a bad idea (for one: it's slower).
            (eieio--slot-name-index class fn)))))))

(defun eieio--class-slot-name-index (class slot)
  "In CLASS find the index of the named SLOT.
The slot is a symbol which is installed in CLASS by the `defclass'
call.  If SLOT is the value created with :initarg instead,
reverse-lookup that name, and recurse with the associated slot value."
  ;; This will happen less often, and with fewer slots.  Do this the
  ;; storage cheap way.
  (let ((index nil)
        (slots (eieio--class-class-slots class)))
    (dotimes (i (length slots))
      (if (eq slot (cl--slot-descriptor-name (aref slots i)))
          (setq index i)))
    index))

;;;
;; Way to assign slots based on a list.  Used for constructors, or
;; even resetting an object at run-time
;;
(defun eieio-set-defaults (obj &optional set-all)
  "Take object OBJ, and reset all slots to their defaults.
If SET-ALL is non-nil, then when a default is nil, that value is
reset.  If SET-ALL is nil, the slots are only reset if the default is
not nil."
  (let ((slots (eieio--class-slots (eieio--object-class obj))))
    (dotimes (i (length slots))
      (let* ((name (cl--slot-descriptor-name (aref slots i)))
             ;; If the `:initform` signals an error, just skip it,
             ;; since the error is intended to be signal'ed from
             ;; `initialize-instance` rather than at the time of `defclass`.
             (df (ignore-errors (eieio-oref-default obj name))))
        (if (or df set-all)
            (eieio-oset obj name df))))))

(defun eieio--initarg-to-attribute (class initarg)
  "For CLASS, convert INITARG to the actual attribute name.
If there is no translation, pass it in directly (so we can cheat if
need be... May remove that later...)"
  (let ((tuple (assoc initarg (eieio--class-initarg-tuples class))))
    (if tuple
	(cdr tuple)
      nil)))

(defun eieio--class-precedence-c3 (class)
  "Return all parents of CLASS in c3 order."
  (let ((parents (cl--class-parents class)))
    (cons class
          (merge-ordered-lists
           (append
            (mapcar #'eieio--class-precedence-c3 parents)
            (list parents))
           (lambda (remaining-inputs)
            (signal 'inconsistent-class-hierarchy
                    (list remaining-inputs)))))))
;;;
;; Method Invocation Order: Depth First

(defun eieio--class-precedence-dfs (class)
  "Return all parents of CLASS in depth-first order."
  (let* ((parents (cl--class-parents class))
	 (classes (copy-sequence
		   (apply #'append
			  (list class)
			  (mapcar
			   (lambda (parent)
			     (cons parent
				   (eieio--class-precedence-dfs parent)))
			   parents))))
	 (tail classes))
    ;; Remove duplicates.
    (while tail
      (setcdr tail (delq (car tail) (cdr tail)))
      (setq tail (cdr tail)))
    classes))

;;;
;; Method Invocation Order: Breadth First
(defun eieio--class-precedence-bfs (class)
  "Return all parents of CLASS in breadth-first order."
  (let* ((result)
         (queue (cl--class-parents class)))
    (while queue
      (let ((head (pop queue)))
	(unless (member head result)
	  (push head result)
	  (setq queue (append queue (cl--class-parents head))))))
    (cons class (nreverse result)))
  )

;;;
;; Method Invocation Order

(defun eieio--class-precedence-list (class)
  "Return (transitively closed) list of parents of CLASS.
The order, in which the parents are returned depends on the
method invocation orders of the involved classes."
  (if (or (null class) (eq class eieio-default-superclass))
      nil
    (let ((class (eieio--full-class-object class)))
      (cl-case (eieio--class-method-invocation-order class)
        (:depth-first
         (eieio--class-precedence-dfs class))
        (:breadth-first
         (eieio--class-precedence-bfs class))
        (:c3
         (eieio--class-precedence-c3 class))))))

(define-obsolete-function-alias
  'class-precedence-list #'eieio--class-precedence-list "24.4")


;;; Here are some special types of errors
;;
(define-error 'invalid-slot-name "Invalid slot name")
(define-error 'invalid-slot-type "Invalid slot type")
(define-error 'eieio-read-only "Read-only slot")
(define-error 'unbound-slot "Unbound slot")
(define-error 'inconsistent-class-hierarchy "Inconsistent class hierarchy")

;;; Hooking into cl-generic.

(require 'cl-generic)

;;;; General support to dispatch based on the type of the argument.

;; FIXME: We could almost use the typeof-generalizer (i.e. the same as
;; used for cl-structs), except that that generalizer doesn't support
;; `:method-invocation-order' :-(

(defun cl--generic-struct-tag (name &rest _)
  ;; Use exactly the same code as for `typeof'.
  `(cl-type-of ,name))

(cl-generic-define-generalizer eieio--generic-generalizer
  ;; Use the exact same tagcode as for cl-struct, so that methods
  ;; that dispatch on both kinds of objects get to share this
  ;; part of the dispatch code.
  50 #'cl--generic-struct-tag
  (lambda (tag &rest _)
    (let ((class (cl--find-class tag)))
      (and (eieio--class-p class)
           (cl--class-allparents class)))))

(cl-defmethod cl-generic-generalizers :extra "class" (specializer)
  "Support for dispatch on types defined by EIEIO's `defclass'."
  ;; CLHS says:
  ;;    A class must be defined before it can be used as a parameter
  ;;    specializer in a defmethod form.
  ;; So we can ignore types that are not known to denote classes.
  (or
   (and (eieio--class-p (eieio--class-object specializer))
        (list eieio--generic-generalizer))
   (cl-call-next-method)))

;;;; Dispatch for arguments which are classes.

;; Since EIEIO does not support metaclasses, users can't easily use the
;; "dispatch on argument type" for class arguments.  That's why EIEIO's
;; `defmethod' added the :static qualifier.  For cl-generic, such a qualifier
;; would not make much sense (e.g. to which argument should it apply?).
;; Instead, we add a new "subclass" specializer.

(defun eieio--generic-subclass-specializers (tag &rest _)
  (when (cl--class-p tag)
    (when (eieio--class-p tag)
      (setq tag (eieio--full-class-object tag))) ;Autoload, if applicable.
    (mapcar (lambda (class) `(subclass ,class))
            (cl--class-allparents tag))))

(cl-generic-define-generalizer eieio--generic-subclass-generalizer
  60 (lambda (name &rest _) `(and (symbolp ,name) (cl--find-class ,name)))
  #'eieio--generic-subclass-specializers)

(cl-defmethod cl-generic-generalizers ((_specializer (head subclass)))
  "Support for (subclass CLASS) specializers.
These match if the argument is the name of a subclass of CLASS."
  (list eieio--generic-subclass-generalizer))

(defmacro eieio-declare-slots (&rest slots)
  "Declare that SLOTS are known eieio object slot names."
  (let ((slotnames (mapcar (lambda (s) (if (consp s) (car s) s)) slots))
        (classslots (delq nil
                          (mapcar (lambda (s)
                                    (when (and (consp s)
                                               (eq :class (plist-get (cdr s)
                                                                     :allocation)))
                                      (car s)))
                                  slots))))
    `(eval-when-compile
       ,@(when classslots
           (mapcar (lambda (s) `(add-to-list 'eieio--known-class-slot-names ',s))
                   classslots))
       ,@(mapcar (lambda (s) `(add-to-list 'eieio--known-slot-names ',s))
                 slotnames))))

(provide 'eieio-core)

;;; eieio-core.el ends here
