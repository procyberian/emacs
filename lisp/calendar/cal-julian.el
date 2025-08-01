;;; cal-julian.el --- calendar functions for the Julian calendar  -*- lexical-binding:t -*-

;; Copyright (C) 1995, 1997, 2001-2025 Free Software Foundation, Inc.

;; Author: Edward M. Reingold <reingold@cs.uiuc.edu>
;; Maintainer: emacs-devel@gnu.org
;; Keywords: calendar
;; Human-Keywords: Julian calendar, Julian day number, calendar, diary
;; Package: calendar

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

;; See calendar.el.

;;; Code:

(require 'calendar)

(defun calendar-julian-to-absolute (date)
  "The number of days elapsed between the Gregorian date 12/31/1 BC and DATE.
The Gregorian date Sunday, December 31, 1 BC is imaginary."
  (let ((month (calendar-extract-month date))
        (year (calendar-extract-year date)))
    (+ (calendar-day-number date)
       (if (and (zerop (% year 100))
                (not (zerop (% year 400)))
                (> month 2))
           1 0)       ; correct for Julian but not Gregorian leap year
       (* 365 (1- year))
       (/ (1- year) 4)
       -2)))

;;;###cal-autoload
(defun calendar-julian-from-absolute (date)
  "Compute the Julian (month day year) corresponding to the absolute DATE.
The absolute date is the number of days elapsed since the (imaginary)
Gregorian date Sunday, December 31, 1 BC."
  (let* ((approx (/ (+ date 2) 366))    ; approximation from below
         (year                 ; search forward from the approximation
          (+ approx
             (calendar-sum y approx
                           (>= date (calendar-julian-to-absolute
                                     (list 1 1 (1+ y))))
                           1)))
         (month                         ; search forward from January
          (1+ (calendar-sum m 1
                            (> date
                               (calendar-julian-to-absolute
                                (list m
                                      (if (and (= m 2) (zerop (% year 4)))
                                          29
                                        (aref [31 28 31 30 31 30 31
                                                  31 30 31 30 31]
                                              (1- m)))
                                      year)))
                            1)))
         (day                       ; calculate the day by subtraction
          (- date (1- (calendar-julian-to-absolute (list month 1 year))))))
    (list month day year)))

;;;###cal-autoload
(defun calendar-julian-date-string (&optional date)
  "String of Julian date of Gregorian DATE.
Defaults to today's date if DATE is not given.
Driven by the variable `calendar-date-display-form'."
  (calendar-date-string
   (calendar-julian-from-absolute
    (calendar-absolute-from-gregorian (or date (calendar-current-date))))
   nil t))

;;;###cal-autoload
(defun calendar-julian-print-date ()
  "Show the Julian calendar equivalent of the date under the cursor."
  (interactive)
  (message "Julian date: %s"
           (calendar-julian-date-string (calendar-cursor-to-date t))))

;;;###cal-autoload
(defun calendar-julian-goto-date (date &optional noecho)
  "Move cursor to Julian DATE; echo Julian date unless NOECHO is non-nil."
  (interactive
   (let* ((today (calendar-current-date))
          (year (calendar-read-sexp
                 "Julian calendar year (>0)"
                 (lambda (x) (> x 0))
                 (calendar-extract-year
                  (calendar-julian-from-absolute
                   (calendar-absolute-from-gregorian
                    today)))))
          (month-array calendar-month-name-array)
          (completion-ignore-case t)
          (month (cdr (assoc-string
                       (completing-read
                        "Julian calendar month name: "
                        (mapcar 'list (append month-array nil))
                        nil t)
                       (calendar-make-alist month-array 1) t)))
          (last
           (if (and (zerop (% year 4)) (= month 2))
               29
             (aref [31 28 31 30 31 30 31 31 30 31 30 31] (1- month))))
          (day (calendar-read-sexp
                "Julian calendar day (%d-%d)"
                (lambda (x)
                  (and (< (if (and (= year 1) (= month 1)) 2 0) x)
                       (<= x last)))
                (if (and (= year 1) (= month 1)) 3 1)
                (if (and (= year 1) (= month 1)) 3 1) last)))
     (list (list month day year))))
  (calendar-goto-date (calendar-gregorian-from-absolute
                       (calendar-julian-to-absolute date)))
  (or noecho (calendar-julian-print-date)))

;;;###holiday-autoload
(defun holiday-julian (month day string)
  "Holiday on MONTH, DAY (Julian) called STRING.
If MONTH, DAY (Julian) is visible, the value returned is corresponding
Gregorian date in the form of the list (((month day year) STRING)).  Returns
nil if it is not visible in the current calendar window."
  (let ((gdate (calendar-nongregorian-visible-p
                month day 'calendar-julian-to-absolute
                'calendar-julian-from-absolute
                ;; In the Gregorian case, we'd use the lower year when
                ;; month >= 11. In the Julian case, there is an offset
                ;; of two weeks (ie 1 Nov Greg = 19 Oct Julian). So we
                ;; use month >= 10, since it can't cause any problems.
                (lambda (m) (< m 10)))))
    (if gdate (list (list gdate string)))))

;;;###cal-autoload
(defun calendar-astro-to-absolute (d)
  "Absolute date of astronomical (Julian) day number D."
  (- d 1721424.5))

;;;###cal-autoload
(defun calendar-astro-from-absolute (d)
  "Astronomical (Julian) day number of absolute date D."
  (+ d 1721424.5))

;;;###cal-autoload
(defun calendar-astro-date-string (&optional date)
  "String of astronomical (Julian) day number after noon UTC of Gregorian DATE.
Defaults to today's date if DATE is not given."
  (number-to-string
   (ceiling
    (calendar-astro-from-absolute
     (calendar-absolute-from-gregorian (or date (calendar-current-date)))))))

;;;###cal-autoload
(defun calendar-astro-print-day-number ()
  "Show astronomical (Julian) day number after noon UTC on cursor date."
  (interactive)
  (message
   "Astronomical (Julian) day number (at noon UTC): %s.0"
   (calendar-astro-date-string (calendar-cursor-to-date t))))

;;;###cal-autoload
(defun calendar-astro-goto-day-number (daynumber &optional noecho)
  "Move cursor to astronomical (Julian) DAYNUMBER.
Echo astronomical (Julian) day number unless NOECHO is non-nil."
  (interactive (list (calendar-read-sexp
                      "Astronomical (Julian) day number (>1721425)"
                      (lambda (x) (> x 1721425))
                      1721426)))
  (calendar-goto-date
   (calendar-gregorian-from-absolute
    (floor
     (calendar-astro-to-absolute daynumber))))
  (or noecho (calendar-astro-print-day-number)))

;;;###diary-autoload
(defun diary-julian-date ()
  "Julian calendar equivalent of date diary entry."
  ;; This function is designed to be used in sexp diary entries, and
  ;; may be present in users' diary files, so suppress the warning
  ;; about this prefix-less dynamic variable.  It's called from
  ;; `diary-list-sexp-entries', which binds the variable.
  (with-suppressed-warnings ((lexical date))
    (defvar date))
  (format "Julian date: %s" (calendar-julian-date-string date)))

;; To be called from diary-list-sexp-entries, where DATE is bound.
;;;###diary-autoload
(defun diary-astro-day-number ()
  "Astronomical (Julian) day number diary entry."
  ;; This function is designed to be used in sexp diary entries, and
  ;; may be present in users' diary files, so suppress the warning
  ;; about this prefix-less dynamic variable.  It's called from
  ;; `diary-list-sexp-entries', which binds the variable.
  (with-suppressed-warnings ((lexical date))
    (defvar date))
  (format "Astronomical (Julian) day number at noon UTC: %s.0"
          (calendar-astro-date-string date)))

(provide 'cal-julian)

;;; cal-julian.el ends here
