;;; leuven-theme.el --- Elegant Emacs color theme for a white background -*- lexical-binding: t -*-

;; Copyright (C) 2003-2025 Free Software Foundation, Inc.

;; Author: Fabrice Niessen <(concat "fniessen" at-sign "pirilampo.org")>
;; URL: https://github.com/fniessen/emacs-leuven-theme
;; Version: 1.2.0
;; Last-Updated: 2024-03-04 10:45
;; Keywords: color theme

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

;; The "leuven" color theme is an elegant and visually appealing theme designed
;; to enhance the appearance of Emacs, particularly in Org mode and other
;; contexts.  It provides a carefully crafted color scheme optimized for a white
;; background, creating a pleasant and readable environment for your Emacs
;; sessions.

;; To use the "leuven" theme, simply add the following line to your Emacs
;; configuration file:

;;   (load-theme 'leuven t)

;; This will load and activate the theme.

;; Requirements:
;; - Emacs 24 or later.

;; For more information and updates, visit the theme's GitHub repository at:
;; https://github.com/fniessen/emacs-leuven-theme

;;; Code:

;;; Options.

(defgroup leuven nil
  "Leuven theme options.
The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom leuven-scale-org-document-title t
  "Scale Org document title.
This can be nil for unscaled, t for using the theme default, or a scaling
number."
  :type '(choice
          (const :tag "Unscaled" nil)
          (const :tag "Default provided by theme" t)
          (number :tag "Set scaling")))

(defcustom leuven-scale-outline-headlines t
  "Scale `outline' (and `org') level-1 headlines.
This can be nil for unscaled, t for using the theme default, or a scaling
number."
  :type '(choice
          (const :tag "Unscaled" nil)
          (const :tag "Default provided by theme" t)
          (number :tag "Set scaling")))

(defcustom leuven-scale-org-agenda-structure t
  "Scale Org agenda structure lines, like dates.
This can be nil for unscaled, t for using the theme default, or a scaling
number."
  :type '(choice
          (const :tag "Unscaled" nil)
          (const :tag "Default provided by theme" t)
          (number :tag "Set scaling")))

(defcustom leuven-scale-volatile-highlight t
  "Increase size in the `next-error' face.
This can be nil for unscaled, t for using the theme default, or a scaling
number."
  :type '(choice
          (const :tag "Unscaled" nil)
          (const :tag "Default provided by theme" t)
          (number :tag "Set scaling")))

;;;###autoload
(defun leuven-scale-font (control default-height)
  "Function for splicing optional font heights into face descriptions.
CONTROL can be a number, nil, or t.  When t, use DEFAULT-HEIGHT."
  (cond
   ((numberp control) (list :height control))
   ((eq t control) (list :height default-height))
   (t nil)))

;;; Theme Faces.

;;;###theme-autoload
(deftheme leuven
  "Face colors with a light background.
Basic, Font Lock, Isearch, Gnus, Message, Org mode, Diff, Ediff,
Flyspell, Semantic, and Ansi-Color faces are included -- and much
more..."
  :background-mode 'light
  :kind 'color-scheme
  :family 'leuven)

(let ((class '((class color) (min-colors 89)))

      ;; Leuven generic colors.
      (cancel '(:slant italic :strike-through t :foreground "#A9A9A9"))
      ;; (clock-line '(:box (:line-width 1 :color "#335EA8") :foreground "black" :background "#EEC900"))
      (code-block '(:foreground "#000088" :background "#FFFFE0"))
      (code-inline '(:foreground "#006400" :background "#FDFFF7"))
      (column '(:height 1.0 :weight normal :slant normal :underline nil :strike-through unspecified :foreground "#E6AD4F" :background "#FFF2DE"))
      (completion-inline '(:weight normal :foreground "#C0C0C0" :inherit hl-line)) ; Like Google.
      (completion-other-candidates '(:foreground "black" :background "#F7F7F7"))
      (completion-selected-candidate '(:weight bold :foreground "black" :background "#C1E0FD"))
      (diff-added '(:background "#DDFFDD"))
      (diff-changed '(:foreground "#0000FF" :background "#DDDDFF"))
      (diff-header '(:weight bold :foreground "#800000" :background "#FFFFAF"))
      (diff-hunk-header '(:foreground "#990099" :background "#FFEEFF"))
      (diff-none '(:foreground "#888888"))
      (diff-refine-added '(:background "#97F295"))
      (diff-refine-removed '(:background "#FFB6BA"))
      (diff-removed '(:background "#FEE8E9"))
      (directory '(:weight bold :foreground "blue" :background "#FFFFD2"))
      (file '(:foreground "black"))
      (function-param '(:foreground "#247284"))
      (grep-file-name '(:weight bold :foreground "#2A489E")) ; Used for grep hits.
      (grep-line-number '(:weight bold :foreground "#A535AE"))
      (highlight-blue '(:background "#B6D6FD"))
      (highlight-gray '(:background "#E4E4E3"))
      ;; (highlight-green '(:background "#D5F1CF"))
      ;; (highlight-red '(:background "#FFC8C8"))
      (highlight-yellow '(:background "#F6FECD"))
      (link '(:weight normal :underline t :foreground "#006DAF"))
      (link-no-underline '(:weight normal :foreground "#006DAF"))
      (mail-header-name '(:family "Sans Serif" :weight normal :foreground "#A3A3A2"))
      (mail-header-other '(:family "Sans Serif" :slant normal :foreground "#666666"))
      (mail-read '(:foreground "#8C8C8C"))
      (mail-read-high '(:foreground "#808080"))
      (mail-ticked '(:foreground "#FF3300"))
      (mail-to '(:family "Sans Serif" :underline unspecified :foreground "#006DAF"))
      (mail-unread '(:weight bold :foreground "#000000"))
      (mail-unread-high '(:weight bold :foreground "#135985"))
      (marked-line '(:foreground "#AA0000" :background "#FFAAAA"))
      (match '(:weight bold :background "#FFFF00")) ; occur patterns + match in helm for files + match in Org files.
      (ol1 `(,@(leuven-scale-font leuven-scale-outline-headlines 1.3) :weight bold :overline "#A7A7A7" :foreground "#3C3C3C" :background "#F0F0F0"))
      (ol2 '(:height 1.0 :weight bold :overline "#123555" :foreground "#123555" :background "#E5F4FB"))
      (ol3 '(:height 1.0 :weight bold :foreground "#005522" :background "#EFFFEF"))
      (ol4 '(:height 1.0 :weight bold :slant normal :foreground "#EA6300"))
      (ol5 '(:height 1.0 :weight bold :slant normal :foreground "#E3258D"))
      (ol6 '(:height 1.0 :weight bold :slant italic :foreground "#0077CC"))
      (ol7 '(:height 1.0 :weight bold :slant italic :foreground "#2EAE2C"))
      (ol8 '(:height 1.0 :weight bold :slant italic :foreground "#FD8008"))
      (paren-matched '(:background "#C0E8C3")) ; Or take that green for region?
      (paren-unmatched '(:weight bold :underline "red" :foreground "black" :background "#FFA5A5"))
      (region '(:background "#8ED3FF"))
      (shadow '(:foreground "#7F7F7F"))
      (string '(:foreground "#008000")) ; or #D0372D
      (subject '(:family "Sans Serif" :weight bold :foreground "black"))
      (symlink '(:foreground "#1F8DD6"))
      (tab '(:foreground "#E8E8E8" :background "white"))
      (trailing '(:foreground "#E8E8E8" :background "#FFFFAB"))
      (volatile-highlight '(:underline unspecified :foreground "white" :background "#9E3699"))
      (volatile-highlight-supersize `(,@(leuven-scale-font leuven-scale-volatile-highlight 1.1) :underline unspecified :foreground "white" :background "#9E3699")) ; flash-region
      (vc-branch '(:box (:line-width 1 :color "#00CC33") :foreground "black" :background "#AAFFAA"))
      (xml-attribute '(:foreground "#F36335"))
      (xml-tag '(:foreground "#AE1B9A"))
      (highlight-current-tag '(:background "#E8E8FF")) ; #EEF3F6 or #FFEB26
  )

  (custom-theme-set-faces
   'leuven
   `(default ((,class (:foreground "#333333" :background "#FFFFFF"))))
   `(bold ((,class (:weight bold :foreground "black"))))
   `(bold-italic ((,class (:weight bold :slant italic :foreground "black"))))
   `(italic ((,class (:slant italic :foreground "#1A1A1A"))))
   `(underline ((,class (:underline t))))
   `(cursor ((,class (:background "#21BDFF"))))

   ;; Lucid toolkit emacs menus.
   `(menu ((,class (:foreground "#FFFFFF" :background "#333333"))))

   ;; Highlighting faces.
   `(fringe ((,class (:foreground "#4C9ED9" :background "white"))))
   `(highlight ((,class ,highlight-blue)))
   `(region ((,class ,region)))
   `(secondary-selection ((,class ,match))) ; Used by Org-mode for highlighting matched entries and keywords.
   `(isearch ((,class (:underline "black" :foreground "white" :background "#5974AB"))))
   `(isearch-fail ((,class (:weight bold :foreground "black" :background "#FFCCCC"))))
   `(lazy-highlight ((,class (:foreground "black" :background "#FFFF00")))) ; Isearch others (see `match').
   `(trailing-whitespace ((,class ,trailing)))
   `(query-replace ((,class (:inherit isearch))))
   `(whitespace-hspace ((,class (:foreground "#D2D2D2")))) ; see also `nobreak-space'
   `(whitespace-indentation ((,class ,tab)))
   `(whitespace-line ((,class (:foreground "#CC0000" :background "#FFFF88"))))
   `(whitespace-tab ((,class ,tab)))
   `(whitespace-trailing ((,class ,trailing)))

   ;; Mode line faces.
   `(mode-line ((,class (:box (:line-width 1 :color "#1A2F54") :foreground "#85CEEB" :background "#335EA8"))))
   `(mode-line-inactive ((,class (:box (:line-width 1 :color "#4E4E4C") :foreground "#F0F0EF" :background "#9B9C97"))))
   `(mode-line-buffer-id ((,class (:weight bold :foreground "white"))))
   `(mode-line-emphasis ((,class (:weight bold :foreground "white"))))
   `(mode-line-highlight ((,class (:foreground "yellow"))))

   ;; Escape and prompt faces.
   `(minibuffer-prompt ((,class (:weight bold :foreground "black" :background "gold"))))
   `(minibuffer-noticeable-prompt ((,class (:weight bold :foreground "black" :background "gold"))))
   `(escape-glyph ((,class (:foreground "#008ED1"))))
   `(error ((,class (:foreground "red"))))
   `(warning ((,class (:weight bold :foreground "orange"))))
   `(success ((,class (:foreground "green4"))))

   ;; Font lock faces.
   `(font-lock-builtin-face ((,class (:foreground "#006FE0"))))
   `(font-lock-comment-delimiter-face ((,class (:foreground "#8D8D84")))) ; #696969
   `(font-lock-comment-face ((,class (:slant italic :foreground "#8D8D84")))) ; #696969
   `(font-lock-constant-face ((,class (:foreground "#D0372D"))))
   `(font-lock-doc-face ((,class (:foreground "#036A07"))))
   `(font-lock-function-name-face ((,class (:weight normal :foreground "#006699"))))
   `(font-lock-keyword-face ((,class (:bold unspecified :foreground "#0000FF")))) ; #3654DC
   `(font-lock-preprocessor-face ((,class (:foreground "#808080"))))
   `(font-lock-regexp-grouping-backslash ((,class (:weight bold :inherit unspecified))))
   `(font-lock-regexp-grouping-construct ((,class (:weight bold :inherit nil))))
   `(font-lock-string-face ((,class ,string)))
   `(font-lock-type-face ((,class (:weight normal :foreground "#6434A3"))))
   `(font-lock-variable-name-face ((,class (:weight normal :foreground "#BA36A5")))) ; #800080
   `(font-lock-warning-face ((,class (:weight bold :foreground "red"))))

   ;; Button and link faces.
   `(link ((,class ,link)))
   `(link-visited ((,class (:underline t :foreground "#E5786D"))))
   `(button ((,class (:underline t :foreground "#006DAF"))))
   `(header-line ((,class (:box (:line-width 1 :color "black") :foreground "black" :background "#F0F0F0"))))

   ;; Gnus faces.
   `(gnus-button ((,class (:weight normal))))
   `(gnus-cite-attribution-face ((,class (:foreground "#5050B0"))))
   `(gnus-cite-1 ((,class (:foreground "#5050B0" :background "#F6F6F6"))))
   `(gnus-cite-2 ((,class (:foreground "#660066" :background "#F6F6F6"))))
   `(gnus-cite-3 ((,class (:foreground "#007777" :background "#F6F6F6"))))
   `(gnus-cite-4 ((,class (:foreground "#990000" :background "#F6F6F6"))))
   `(gnus-cite-5 ((,class (:foreground "#000099" :background "#F6F6F6"))))
   `(gnus-cite-6 ((,class (:foreground "#BB6600" :background "#F6F6F6"))))
   `(gnus-cite-7 ((,class (:foreground "#5050B0" :background "#F6F6F6"))))
   `(gnus-cite-8 ((,class (:foreground "#660066" :background "#F6F6F6"))))
   `(gnus-cite-9 ((,class (:foreground "#007777" :background "#F6F6F6"))))
   `(gnus-cite-10 ((,class (:foreground "#990000" :background "#F6F6F6"))))
   `(gnus-emphasis-bold ((,class (:weight bold))))
   `(gnus-emphasis-highlight-words ((,class (:foreground "yellow" :background "black"))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground "#FF50B0"))))
   `(gnus-group-mail-1-empty ((,class (:foreground "#5050B0"))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground "#FF0066"))))
   `(gnus-group-mail-2-empty ((,class (:foreground "#660066"))))
   `(gnus-group-mail-3 ((,class ,mail-unread)))
   `(gnus-group-mail-3-empty ((,class ,mail-read)))
   `(gnus-group-mail-low ((,class ,cancel)))
   `(gnus-group-mail-low-empty ((,class ,cancel)))
   `(gnus-group-news-1 ((,class (:weight bold :foreground "#FF50B0"))))
   `(gnus-group-news-1-empty ((,class (:foreground "#5050B0"))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground "#FF0066"))))
   `(gnus-group-news-2-empty ((,class (:foreground "#660066"))))
   `(gnus-group-news-3 ((,class ,mail-unread)))
   `(gnus-group-news-3-empty ((,class ,mail-read)))
   `(gnus-group-news-4 ((,class (:weight bold :foreground "#FF0000"))))
   `(gnus-group-news-4-empty ((,class (:foreground "#990000"))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground "#FF0099"))))
   `(gnus-group-news-5-empty ((,class (:foreground "#000099"))))
   `(gnus-group-news-6 ((,class (:weight bold :foreground "gray50"))))
   `(gnus-group-news-6-empty ((,class (:foreground "#808080"))))
   `(gnus-header-content ((,class ,mail-header-other)))
   `(gnus-header-from ((,class (:family "Sans Serif" :foreground "black"))))
   `(gnus-header-name ((,class ,mail-header-name)))
   `(gnus-header-newsgroups ((,class (:family "Sans Serif" :foreground "#3399CC"))))
   `(gnus-header-subject ((,class ,subject)))
   `(gnus-picon ((,class (:foreground "yellow" :background "white"))))
   `(gnus-picon-xbm ((,class (:foreground "yellow" :background "white"))))
   `(gnus-server-closed ((,class (:slant italic :foreground "blue" :background "white"))))
   `(gnus-server-denied ((,class (:weight bold :foreground "red" :background "white"))))
   `(gnus-server-opened ((,class (:family "Sans Serif" :foreground "#466BD7"))))
   `(gnus-signature ((,class (:slant italic :foreground "#8B8D8E"))))
   `(gnus-splash ((,class (:foreground "#FF8C00"))))
   `(gnus-summary-cancelled ((,class ,cancel)))
   `(gnus-summary-high-ancient ((,class ,mail-unread-high)))
   `(gnus-summary-high-read ((,class ,mail-read-high)))
   `(gnus-summary-high-ticked ((,class ,mail-ticked)))
   `(gnus-summary-high-unread ((,class ,mail-unread-high)))
   `(gnus-summary-low-ancient ((,class (:slant italic :foreground "black"))))
   `(gnus-summary-low-read ((,class (:slant italic :foreground "#999999" :background "#E0E0E0"))))
   `(gnus-summary-low-ticked ((,class ,mail-ticked)))
   `(gnus-summary-low-unread ((,class (:slant italic :foreground "black"))))
   `(gnus-summary-normal-ancient ((,class ,mail-read)))
   `(gnus-summary-normal-read ((,class ,mail-read)))
   `(gnus-summary-normal-ticked ((,class ,mail-ticked)))
   `(gnus-summary-normal-unread ((,class ,mail-unread)))
   `(gnus-summary-selected ((,class (:foreground "white" :background "#008CD7"))))
   `(gnus-x-face ((,class (:foreground "black" :background "white"))))

   ;; Message faces.
   `(message-header-name ((,class ,mail-header-name)))
   `(message-header-cc ((,class ,mail-to)))
   `(message-header-other ((,class ,mail-header-other)))
   `(message-header-subject ((,class ,subject)))
   `(message-header-to ((,class ,mail-to)))
   `(message-cited-text ((,class (:foreground "#5050B0" :background "#F6F6F6"))))
   `(message-separator ((,class (:family "Sans Serif" :weight normal :foreground "#BDC2C6"))))
   `(message-header-newsgroups ((,class (:family "Sans Serif" :foreground "#3399CC"))))
   `(message-header-xheader ((,class ,mail-header-other)))
   `(message-mml ((,class (:foreground "forest green"))))

   ;; ANSI colors.
   `(ansi-color-bold ((,class (:weight bold))))
   `(ansi-color-black ((,class (:foreground "black" :background "black"))))
   `(ansi-color-red ((,class (:foreground "red3" :background "red3"))))
   `(ansi-color-green ((,class (:foreground "forest green" :background "forest green"))))
   `(ansi-color-yellow ((,class (:foreground "yellow3" :background "yellow3"))))
   `(ansi-color-blue ((,class (:foreground "blue" :background "blue"))))
   `(ansi-color-magenta ((,class (:foreground "magenta3" :background "magenta3"))))
   `(ansi-color-cyan ((,class (:foreground "deep sky blue" :background "deep sky blue"))))
   `(ansi-color-white ((,class (:foreground "gray60" :background "gray60"))))
   `(ansi-color-bright-black ((,class (:foreground "gray30" :background "gray30"))))
   `(ansi-color-bright-red ((,class (:foreground "red1" :background "red1"))))
   `(ansi-color-bright-green ((,class (:foreground "lime green" :background "lime green"))))
   `(ansi-color-bright-yellow ((,class (:foreground "yellow2" :background "yellow2"))))
   `(ansi-color-bright-blue ((,class (:foreground "dodger blue" :background "dodger blue"))))
   `(ansi-color-bright-magenta ((,class (:foreground "magenta" :background "magenta"))))
   `(ansi-color-bright-cyan ((,class (:foreground "sky blue" :background "sky blue"))))
   `(ansi-color-bright-white ((,class (:foreground "gray80" :background "gray80"))))

   ;; Diff.
   `(diff-added ((,class ,diff-added)))
   `(diff-changed ((,class ,diff-changed)))
   `(diff-context ((,class ,diff-none)))
   `(diff-file-header ((,class ,diff-header)))
   `(diff-file1-hunk-header ((,class (:foreground "dark magenta" :background "#EAF2F5"))))
   `(diff-file2-hunk-header ((,class (:foreground "#2B7E2A" :background "#EAF2F5"))))
   `(diff-function ((,class (:foreground "#CC99CC"))))
   `(diff-header ((,class ,diff-header)))
   `(diff-hunk-header ((,class ,diff-hunk-header)))
   `(diff-index ((,class ,diff-header)))
   `(diff-indicator-added ((,class (:foreground "#3A993A" :background "#CDFFD8"))))
   `(diff-indicator-changed ((,class (:background "#DBEDFF"))))
   `(diff-indicator-removed ((,class (:foreground "#CC3333" :background "#FFDCE0"))))
   `(diff-refine-added ((,class ,diff-refine-added)))
   `(diff-refine-change ((,class (:background "#DDDDFF"))))
   `(diff-refine-removed ((,class ,diff-refine-removed)))
   `(diff-removed ((,class ,diff-removed)))

   ;; SMerge.
   `(smerge-mine ((,class ,diff-changed)))
   `(smerge-other ((,class ,diff-added)))
   `(smerge-base ((,class ,diff-removed)))
   `(smerge-markers ((,class (:background "#FFE5CC"))))
   `(smerge-refined-changed ((,class (:background "#AAAAFF"))))

   ;; Ediff.
   `(ediff-current-diff-A ((,class (:background "#FFDDDD"))))
   `(ediff-current-diff-B ((,class (:background "#DDFFDD"))))
   `(ediff-current-diff-C ((,class (:background "cyan"))))
   `(ediff-even-diff-A ((,class (:background "light grey"))))
   `(ediff-even-diff-B ((,class (:background "light grey"))))
   `(ediff-fine-diff-A ((,class (:background "#FFAAAA"))))
   `(ediff-fine-diff-B ((,class (:background "#55FF55"))))
   `(ediff-odd-diff-A ((,class (:background "light grey"))))
   `(ediff-odd-diff-B ((,class (:background "light grey"))))

   ;; Flyspell.
   (if (version< emacs-version "24.4")
       `(flyspell-duplicate ((,class (:underline "#F4EB80" :inherit unspecified))))
     `(flyspell-duplicate ((,class (:underline (:style wave :color "#F4EB80") :background "#FAF7CC" :inherit nil)))))
   (if (version< emacs-version "24.4")
       `(flyspell-incorrect ((,class (:underline "#FAA7A5" :inherit nil))))
     `(flyspell-incorrect ((,class (:underline (:style wave :color "#FAA7A5") :background "#F4D7DA":inherit nil)))))

   ;; ;; Semantic faces.
   ;; `(semantic-decoration-on-includes ((,class (:underline ,cham-4))))
   ;; `(semantic-decoration-on-private-members-face ((,class (:background ,alum-2))))
   ;; `(semantic-decoration-on-protected-members-face ((,class (:background ,alum-2))))
   `(semantic-decoration-on-unknown-includes ((,class (:background "#FFF8F8"))))
   ;; `(semantic-decoration-on-unparsed-includes ((,class (:underline ,orange-3))))
   `(semantic-highlight-func-current-tag-face ((,class ,highlight-current-tag)))
   `(semantic-tag-boundary-face ((,class (:overline "#777777")))) ; Method separator.
   ;; `(semantic-unmatched-syntax-face ((,class (:underline ,red-1))))

   `(Info-title-1-face ((,class ,ol1)))
   `(Info-title-2-face ((,class ,ol2)))
   `(Info-title-3-face ((,class ,ol3)))
   `(Info-title-4-face ((,class ,ol4)))
   `(ace-jump-face-foreground ((,class (:weight bold :foreground "black" :background "#FEA500"))))
   `(ahs-face ((,class (:background "#E4E4FF"))))
   `(ahs-definition-face ((,class (:background "#FFB6C6"))))
   `(ahs-plugin-default-face ((,class (:background "#FFE4FF")))) ; Current.
   `(anzu-match-1 ((,class (:foreground "black" :background "aquamarine"))))
   `(anzu-match-2 ((,class (:foreground "black" :background "springgreen"))))
   `(anzu-match-3 ((,class (:foreground "black" :background "red"))))
   `(anzu-mode-line ((,class (:foreground "black" :background "#80FF80"))))
   `(anzu-mode-line-no-match ((,class (:foreground "black" :background "#FF8080"))))
   `(anzu-replace-highlight ((,class (:inherit query-replace))))
   `(anzu-replace-to ((,class (:weight bold :foreground "#BD33FD" :background "#FDBD33"))))
   `(auto-dim-other-buffers-face ((,class (:background "#F7F7F7"))))
   `(avy-background-face ((,class (:background "#A9A9A9"))))
   `(avy-lead-face ((,class (:weight bold :foreground "black" :background "#F6F707"))))
   `(avy-lead-face-0 ((,class (:weight bold :foreground "white" :background "#4E8D12"))))
   `(bbdb-company ((,class (:slant italic :foreground "steel blue"))))
   `(bbdb-field-name ((,class (:weight bold :foreground "steel blue"))))
   `(bbdb-field-value ((,class (:foreground "steel blue"))))
   `(bbdb-name ((,class (:underline t :foreground "#FF6633"))))
   `(bmkp-light-autonamed ((,class (:background "#F0F0F0"))))
   `(bmkp-light-fringe-autonamed ((,class (:foreground "#5A5A5A" :background "#D4D4D4"))))
   `(bmkp-light-fringe-non-autonamed ((,class (:foreground "#FFFFCC" :background "#01FFFB")))) ; default
   `(bmkp-light-non-autonamed ((,class (:background "#BFFFFE"))))
   `(bmkp-no-local ((,class (:background "pink"))))
   `(browse-kill-ring-separator-face ((,class (:foreground "red"))))
   `(calendar-month-header ((,class (:weight bold :foreground "#4F4A3D" :background "#FFFFCC"))))
   `(calendar-today ((,class (:weight bold :foreground "#4F4A3D" :background "#FFFFCC"))))
   `(calendar-weekday-header ((,class (:weight bold :foreground "#1662AF"))))
   `(calendar-weekend-header ((,class (:weight bold :foreground "#4E4E4E"))))
   `(cfw:face-annotation ((,class (:foreground "green" :background "red"))))
   `(cfw:face-day-title ((,class (:foreground "#C9C9C9"))))
   `(cfw:face-default-content ((,class (:foreground "#2952A3"))))
   `(cfw:face-default-day ((,class (:weight bold))))
   `(cfw:face-disable ((,class (:foreground "DarkGray"))))
   `(cfw:face-grid ((,class (:foreground "#DDDDDD"))))
   `(cfw:face-header ((,class (:foreground "#1662AF" :background "white" :weight bold))))
   `(cfw:face-holiday ((,class (:foreground "#777777" :background "#E4EBFE"))))
   `(cfw:face-periods ((,class (:foreground "white" :background "#668CD9" :slant italic))))
   `(cfw:face-saturday ((,class (:foreground "#4E4E4E" :background "white" :weight bold))))
   `(cfw:face-select ((,class (:foreground "#4A95EB" :background "#EDF1FA"))))
   `(cfw:face-sunday ((,class (:foreground "#4E4E4E" :background "white" :weight bold))))
   `(cfw:face-title ((,class (:height 2.0 :foreground "#676767" :weight bold :inherit variable-pitch))))
   `(cfw:face-today ((,class (:foreground "#4F4A3D" :background "#FFFFCC"))))
   `(cfw:face-today-title ((,class (:foreground "white" :background "#1766B1"))))
   `(cfw:face-toolbar ((,class (:background "white"))))
   `(cfw:face-toolbar-button-off ((,class (:foreground "#CFCFCF" :background "white"))))
   `(cfw:face-toolbar-button-on ((,class (:foreground "#5E5E5E" :background "#F6F6F6"))))
   `(change-log-date ((,class (:foreground "purple"))))
   `(change-log-file ((,class (:weight bold :foreground "#4183C4"))))
   `(change-log-list ((,class (:foreground "black" :background "#75EEC7"))))
   `(change-log-name ((,class (:foreground "#008000"))))
   `(circe-highlight-all-nicks-face ((,class (:foreground "blue" :background "#F0F0F0")))) ; other nick names
   `(circe-highlight-nick-face ((,class (:foreground "#009300" :background "#F0F0F0")))) ; messages with my nick cited
   `(circe-my-message-face ((,class (:foreground "#8B8B8B" :background "#F0F0F0"))))
   `(circe-originator-face ((,class (:foreground "blue"))))
   `(circe-prompt-face ((,class (:foreground "red"))))
   `(circe-server-face ((,class (:foreground "#99CAE5"))))

   ;; `(ac-selection-face ((,class ,completion-selected-candidate)))
   `(ac-selection-face ((,class (:weight bold :foreground "white" :background "orange")))) ; TEMP For diff'ing AC from Comp.
   `(ac-candidate-face ((,class ,completion-other-candidates)))
   `(ac-completion-face ((,class ,completion-inline)))
   `(ac-candidate-mouse-face ((,class (:inherit highlight))))
   `(popup-scroll-bar-background-face ((,class (:background "#EBF4FE"))))
   `(popup-scroll-bar-foreground-face ((,class (:background "#D1DAE4")))) ; Scrollbar (visible).

   ;; Company.
   `(company-tooltip-common-selection ((,class (:weight bold :foreground "#0474B6" :inherit company-tooltip-selection)))) ; Prefix + common part in tooltip (for selection).
   `(company-tooltip-selection ((,class ,completion-selected-candidate))) ; Suffix in tooltip (for selection).
   `(company-tooltip-annotation-selection ((,class (:weight bold :foreground "#818181")))) ; Annotation (for selection).
   `(company-tooltip-common ((,class (:weight normal :foreground "#0474B6" :inherit company-tooltip)))) ; Prefix + common part in tooltip.
   `(company-tooltip ((,class ,completion-other-candidates))) ; Suffix in tooltip.
   `(company-tooltip-annotation ((,class (:weight normal :foreground "#818181")))) ; Annotation.
   `(company-preview ((,class ,completion-inline)))
   `(company-preview-common ((,class ,completion-inline)))
   `(company-scrollbar-bg ((,class (:background "#EBF4FE"))))
   `(company-scrollbar-fg ((,class (:background "#D1DAE4")))) ; Scrollbar (visible).

   ;; Centaur Tabs
   ;; With the addition of tab-mode, centaur tabs looks there first for how the tabline should look
   (if (version<= "27.0" emacs-version)
       `(tab-line ((t (:background ,"#5D6B99" :foreground ,"#5D6B99")))))
   `(centaur-tabs-default ((t (:background ,"#335EA8" :foreground ,"#FFFFFF" :box nil))))
   `(centaur-tabs-background-color ((t (:background ,"#5D6B99" :foreground ,"#5D6B99" :box nil))))
   `(centaur-tabs-active-bar-face ((t (:background ,"#335EA8" :foreground ,"#FFFFFF"  :box nil))))
   `(centaur-tabs-selected ((t (:foreground ,"#333333" :background ,"#F5CC84" :box nil))))
   `(centaur-tabs-unselected ((t (:foreground ,"#FFFFFF" :background ,"#3B4F81" :box nil))))
   `(centaur-tabs-selected-modified ((t (:foreground ,"#333333" :background ,"#F5CC84" :weight ,'bold :box nil))))
   `(centaur-tabs-unselected-modified ((t (:foreground ,"#FFFFFF" :background ,"#3B4F81" :weight ,'bold :box nil))))
   `(centaur-tabs-modified-marker-selected ((t (:foreground ,"#333333" :background ,"#F5CC84" :weight ,'bold :box nil))))
   `(centaur-tabs-modified-marker-unselected ((t (:foreground ,"#FFFFFF" :background ,"#3B4F81" :weight ,'bold :box nil))))

   ;; doom-modeline
   `(doom-modeline-bar ((t (:background ,"#5D6B99"))))
   `(doom-modeline-info ((t (:inherit ,'mode-line-emphasis))))
   `(doom-modeline-urgent ((t (:inherit ,'mode-line-emphasis))))
   `(doom-modeline-warning ((t (:inherit ,'mode-line-emphasis))))
   `(doom-modeline-debug ((t (:inherit ,'mode-line-emphasis))))
   `(doom-modeline-buffer-minor-mode ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-project-dir ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-project-parent-dir ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-persp-name ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-buffer-file ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-buffer-modified ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-lsp-success ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-buffer-path ((t (:inherit ,'mode-line-emphasis :weight ,'bold))))
   `(doom-modeline-buffer-project-root ((t (:inherit ,'mode-line-emphasis))))

   `(compare-windows ((,class (:background "#FFFF00"))))
   ;; `(completions-common-part ((,class (:foreground "red" :weight bold))))
   ;; `(completions-first-difference ((,class (:foreground "green" :weight bold))))
   `(compilation-error ((,class (:weight bold :foreground "red")))) ; Used for grep error messages.
   `(compilation-info ((,class (:weight bold :foreground "#6784d7"))))
   `(compilation-line-number ((,class ,grep-line-number)))
   `(compilation-warning ((,class (:weight bold :foreground "orange"))))
   `(compilation-mode-line-exit ((,class (:weight bold :foreground "green")))) ; :exit[matched]
   `(compilation-mode-line-fail ((,class (:weight bold :foreground "violet")))) ; :exit[no match]
   `(compilation-mode-line-run ((,class (:weight bold :foreground "orange")))) ; :run
   `(css-property ((,class (:foreground "#00AA00"))))
   `(css-selector ((,class (:weight bold :foreground "blue"))))
   `(custom-button ((,class (:box (:line-width 2 :style released-button) :foreground "black" :background "lightgrey"))))
   `(custom-button-mouse ((,class (:box (:line-width 2 :style released-button) :foreground "black" :background "grey90"))))
   `(custom-button-pressed ((,class (:box (:line-width 2 :style pressed-button) :foreground "black" :background "light grey"))))
   `(custom-button-pressed-unraised ((,class (:underline t :foreground "magenta4"))))
   `(custom-button-unraised ((,class (:underline t))))
   `(custom-changed ((,class (:foreground "white" :background "blue"))))
   `(custom-comment ((,class (:background "gray85"))))
   `(custom-comment-tag ((,class (:foreground "blue4"))))
   `(custom-documentation ((,class (nil))))
   `(custom-face-tag ((,class (:family "Sans Serif" :height 1.2 :weight bold))))
   `(custom-group-tag ((,class (:height 1.2 :weight bold :foreground "blue1"))))
   `(custom-group-tag-1 ((,class (:family "Sans Serif" :height 1.2 :weight bold :foreground "red1"))))
   `(custom-invalid ((,class (:foreground "yellow" :background "red"))))
   `(custom-link ((,class (:underline t :foreground "blue1"))))
   `(custom-modified ((,class (:foreground "white" :background "blue"))))
   `(custom-rogue ((,class (:foreground "pink" :background "black"))))
   `(custom-saved ((,class (:underline t))))
   `(custom-set ((,class (:foreground "blue" :background "white"))))
   `(custom-state ((,class (:foreground "green4"))))
   `(custom-themed ((,class (:foreground "white" :background "blue1"))))
   `(custom-variable-button ((,class (:weight bold :underline t))))
   `(custom-variable-tag ((,class (:family "Sans Serif" :height 1.2 :weight bold :foreground "blue1"))))
   `(custom-visibility ((,class ,link)))
   `(diff-hl-change ((,class (:foreground "blue3" :background "#DBEDFF"))))
   `(diff-hl-delete ((,class (:foreground "red3" :background "#FFDCE0"))))
   `(diff-hl-dired-change ((,class (:weight bold :foreground "black" :background "#FFA335"))))
   `(diff-hl-dired-delete ((,class (:weight bold :foreground "#D73915"))))
   `(diff-hl-dired-ignored ((,class (:weight bold :foreground "white" :background "#C0BBAB"))))
   `(diff-hl-dired-insert ((,class (:weight bold :foreground "#B9B9BA"))))
   `(diff-hl-dired-unknown ((,class (:foreground "white" :background "#3F3BB4"))))
   `(diff-hl-insert ((,class (:foreground "green4" :background "#CDFFD8"))))
   `(diff-hl-unknown ((,class (:foreground "white" :background "#3F3BB4"))))
   `(diary-face ((,class (:foreground "#87C9FC"))))
   `(dircolors-face-asm ((,class (:foreground "black"))))
   `(dircolors-face-backup ((,class (:foreground "black"))))
   `(dircolors-face-compress ((,class (:foreground "red"))))
   `(dircolors-face-dir ((,class ,directory)))
   `(dircolors-face-doc ((,class (:foreground "black"))))
   `(dircolors-face-dos ((,class (:foreground "ForestGreen"))))
   `(dircolors-face-emacs ((,class (:foreground "black"))))
   `(dircolors-face-exec ((,class (:foreground "ForestGreen"))))
   `(dircolors-face-html ((,class (:foreground "black"))))
   `(dircolors-face-img ((,class (:foreground "magenta3"))))
   `(dircolors-face-lang ((,class (:foreground "black"))))
   `(dircolors-face-lang-interface ((,class (:foreground "black"))))
   `(dircolors-face-make ((,class (:foreground "black"))))
   `(dircolors-face-objet ((,class (:foreground "black"))))
   `(dircolors-face-package ((,class (:foreground "black"))))
   `(dircolors-face-paddb ((,class (:foreground "black"))))
   `(dircolors-face-ps ((,class (:foreground "black"))))
   `(dircolors-face-sound ((,class (:foreground "DeepSkyBlue"))))
   `(dircolors-face-tar ((,class (:foreground "red"))))
   `(dircolors-face-text ((,class (:foreground "black"))))
   `(dircolors-face-yacc ((,class (:foreground "black"))))
   `(dired-directory ((,class ,directory)))
   `(dired-header ((,class ,directory)))
   `(dired-ignored ((,class (:strike-through t :foreground "red"))))
   `(dired-mark ((,class ,marked-line)))
   `(dired-marked ((,class ,marked-line)))
   `(dired-symlink ((,class ,symlink)))
   `(diredfl-compressed-file-suffix ((,class (:foreground "#000000" :background "#FFF68F"))))
   `(diredp-compressed-file-suffix ((,class (:foreground "red"))))
   `(diredp-date-time ((,class (:foreground "purple"))))
   `(diredp-dir-heading ((,class ,directory)))
   `(diredp-dir-name ((,class ,directory)))
   `(diredp-dir-priv ((,class ,directory)))
   `(diredp-exec-priv ((,class (:background "#03C03C"))))
   `(diredp-executable-tag ((,class (:foreground "ForestGreen" :background "white"))))
   `(diredp-file-name ((,class ,file)))
   `(diredp-file-suffix ((,class (:foreground "#C0C0C0"))))
   `(diredp-flag-mark-line ((,class ,marked-line)))
   `(diredp-ignored-file-name ((,class ,shadow)))
   `(diredp-read-priv ((,class (:background "#0A99FF"))))
   `(diredp-write-priv ((,class (:foreground "white" :background "#FF4040"))))
   `(eldoc-highlight-function-argument ((,class (:weight bold :foreground "red" :background "#FFE4FF"))))
   `(elfeed-search-filter-face ((,class (:foreground "gray"))))
   ;; `(eww-form-checkbox ((,class ())))
   ;; `(eww-form-select ((,class ())))
   ;; `(eww-form-submit ((,class ())))
   `(eww-form-text ((,class (:weight bold :foreground "#40586F" :background "#A7CDF1"))))
   ;; `(eww-form-textarea ((,class ())))
   `(file-name-shadow ((,class ,shadow)))
   `(flycheck-error ((,class (:underline (:color "#FE251E" :style wave) :weight bold :background "#FFE1E1"))))
   `(flycheck-error-list-line-number ((,class (:foreground "#A535AE"))))
   `(flycheck-fringe-error ((,class (:foreground "#FE251E"))))
   `(flycheck-fringe-info ((,class (:foreground "#158A15"))))
   `(flycheck-fringe-warning ((,class (:foreground "#F4A939"))))
   `(flycheck-info ((,class (:underline (:color "#158A15" :style wave) :weight bold))))
   `(flycheck-warning ((,class (:underline (:color "#F4A939" :style wave) :weight bold :background "#FFFFBE"))))
   `(font-latex-bold-face ((,class (:weight bold :foreground "black"))))
   `(fancy-narrow-blocked-face ((,class (:foreground "#9998A4"))))
   `(flycheck-color-mode-line-error-face ((, class (:background "#CF5B56"))))
   `(flycheck-color-mode-line-warning-face ((, class (:background "#EBC700"))))
   `(flycheck-color-mode-line-info-face ((, class (:background "yellow"))))
   `(font-latex-italic-face ((,class (:slant italic :foreground "#1A1A1A"))))
   `(font-latex-math-face ((,class (:foreground "blue"))))
   `(font-latex-sectioning-1-face ((,class (:family "Sans Serif" :height 2.7 :weight bold :foreground "cornflower blue"))))
   `(font-latex-sectioning-2-face ((,class ,ol1)))
   `(font-latex-sectioning-3-face ((,class ,ol2)))
   `(font-latex-sectioning-4-face ((,class ,ol3)))
   `(font-latex-sectioning-5-face ((,class ,ol4)))
   `(font-latex-sedate-face ((,class (:foreground "#FF5500"))))
   `(font-latex-string-face ((,class (:weight bold :foreground "#0066FF"))))
   `(font-latex-verbatim-face ((,class (:foreground "#000088" :background "#FFFFE0" :inherit nil))))
   `(git-commit-summary-face ((,class (:foreground "#000000"))))
   `(git-commit-comment-face ((,class (:slant italic :foreground "#696969"))))
   `(git-timemachine-commit ((,class ,diff-removed)))
   `(git-timemachine-minibuffer-author-face ((,class ,diff-added)))
   `(git-timemachine-minibuffer-detail-face ((,class ,diff-header)))
   `(google-translate-text-face ((,class (:foreground "#777777" :background "#F5F5F5"))))
   `(google-translate-phonetic-face ((,class (:inherit shadow))))
   `(google-translate-translation-face ((,class (:weight normal :foreground "#3079ED" :background "#E3EAF2"))))
   `(google-translate-suggestion-label-face ((,class (:foreground "red"))))
   `(google-translate-suggestion-face ((,class (:slant italic :underline t))))
   `(google-translate-listen-button-face ((,class (:height 0.8))))
   `(helm-action ((,class (:foreground "black"))))
   `(helm-bookmark-file ((,class ,file)))
   `(helm-bookmarks-su-face ((,class (:foreground "red"))))
   `(helm-buffer-directory ((,class ,directory)))
   ;; `(helm-non-file-buffer ((,class (:slant italic :foreground "blue"))))
   ;; `(helm-buffer-file ((,class (:foreground "#333333"))))
   `(helm-buffer-modified ((,class (:slant italic :foreground "#BA36A5"))))
   `(helm-buffer-process ((,class (:foreground "#008200"))))
   `(helm-candidate-number ((,class (:foreground "black" :background "#FFFF66"))))
   `(helm-dir-heading ((,class (:foreground "blue" :background "pink"))))
   `(helm-dir-priv ((,class (:foreground "dark red" :background "light grey"))))
   `(helm-ff-directory ((,class ,directory)))
   `(helm-ff-dotted-directory ((,class ,directory)))
   `(helm-ff-executable ((,class (:foreground "green3" :background "white"))))
   `(helm-ff-file ((,class (:foreground "black"))))
   `(helm-ff-invalid-symlink ((,class (:foreground "yellow" :background "red"))))
   `(helm-ff-symlink ((,class ,symlink)))
   `(helm-file-name ((,class (:foreground "blue"))))
   `(helm-gentoo-match-face ((,class (:foreground "red"))))
   `(helm-grep-file ((,class ,grep-file-name)))
   `(helm-grep-lineno ((,class ,grep-line-number)))
   `(helm-grep-match ((,class ,match)))
   `(helm-grep-running ((,class (:weight bold :foreground "white"))))
   `(helm-isearch-match ((,class (:background "#CCFFCC"))))
   `(helm-lisp-show-completion ((,class ,volatile-highlight-supersize))) ; See `helm-dabbrev'.
   ;; `(helm-ls-git-added-copied-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-added-modified-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-conflict-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-deleted-and-staged-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-deleted-not-staged-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-modified-and-staged-face ((,class (:foreground ""))))
   `(helm-ls-git-modified-not-staged-face ((,class (:foreground "#BA36A5"))))
   ;; `(helm-ls-git-renamed-modified-face ((,class (:foreground ""))))
   ;; `(helm-ls-git-untracked-face ((,class (:foreground ""))))
   `(helm-match ((,class ,match)))
   `(helm-moccur-buffer ((,class (:foreground "#0066CC"))))
   `(helm-selection ((,class (:background "#3875D6" :foreground "white"))))
   `(helm-selection-line ((,class ,highlight-gray))) ; ???
   `(helm-separator ((,class (:foreground "red"))))
   `(helm-source-header ((,class (:weight bold :box (:line-width 1 :color "#C7C7C7") :background "#DEDEDE" :foreground "black"))))
   `(helm-swoop-target-line-block-face ((,class (:background "#CCCC00" :foreground "#222222"))))
   `(helm-swoop-target-line-face ((,class (:background "#CCCCFF"))))
   `(helm-swoop-target-word-face ((,class (:weight bold :foreground unspecified :background "#FDBD33"))))
   `(helm-visible-mark ((,class ,marked-line)))
   `(helm-w3m-bookmarks-face ((,class (:underline t :foreground "cyan1"))))
   `(highlight-changes ((,class (:foreground unspecified)))) ;; blue "#2E08B5"
   `(highlight-changes-delete ((,class (:strike-through nil :foreground unspecified)))) ;; red "#B5082E"
   `(highlight-symbol-face ((,class (:background "#FFFFA0"))))
   `(hl-line ((,class ,highlight-yellow))) ; Highlight current line.
   `(hl-tags-face ((,class ,highlight-current-tag))) ; ~ Pair highlighting (matching tags).
   `(holiday-face ((,class (:foreground "#777777" :background "#E4EBFE"))))
   `(html-helper-bold-face ((,class (:weight bold :foreground "black"))))
   `(html-helper-italic-face ((,class (:slant italic :foreground "black"))))
   `(html-helper-underline-face ((,class (:underline t :foreground "black"))))
   `(html-tag-face ((,class (:foreground "blue"))))
   `(ilog-non-change-face ((,class (:height 2.0 :foreground "#6434A3"))))
   `(ilog-change-face ((,class (:height 2.0 :foreground "#008200"))))
   `(ilog-echo-face ((,class (:height 2.0 :foreground "#006FE0"))))
   `(ilog-load-face ((,class (:foreground "#BA36A5"))))
   `(ilog-message-face ((,class (:foreground "#808080"))))
   `(image-dired-thumb-flagged ((,class (:background "red"))))
   `(image-dired-thumb-mark ((,class :background "#FFAAAA")))
   `(indent-guide-face ((,class (:foreground "#D3D3D3"))))
   `(info-file ((,class (:family "Sans Serif" :height 1.8 :weight bold :box (:line-width 1 :color "#0000CC") :foreground "cornflower blue" :background "LightSteelBlue1"))))
   `(info-header-node ((,class (:underline t :foreground "orange")))) ; nodes in header
   `(info-header-xref ((,class (:underline t :foreground "dodger blue")))) ; cross references in header
   `(info-index-match ((,class (:weight bold :foreground unspecified :background "#FDBD33")))) ; when using `i'
   `(info-menu-header ((,class ,ol2))) ; menu titles (headers) -- major topics
   `(info-menu-star ((,class (:foreground "black")))) ; every 3rd menu item
   `(info-node ((,class (:underline t :foreground "blue")))) ; node names
   `(info-quoted-name ((,class ,code-inline)))
   `(info-string ((,class ,string)))
   `(info-title-1 ((,class ,ol1)))
   `(info-xref ((,class (:underline t :foreground "#006DAF")))) ; unvisited cross-references
   `(info-xref-visited ((,class (:underline t :foreground "magenta4")))) ; previously visited cross-references
   ;; js2-highlight-vars-face (~ auto-highlight-symbol)
   `(js2-error ((,class (:box (:line-width 1 :color "#FF3737") :background "#FFC8C8")))) ; DONE.
   `(js2-external-variable ((,class (:foreground "#FF0000" :background "#FFF8F8")))) ; DONE.
   `(js2-function-param ((,class ,function-param)))
   `(js2-instance-member ((,class (:foreground "DarkOrchid"))))
   `(js2-jsdoc-html-tag-delimiter ((,class (:foreground "#D0372D"))))
   `(js2-jsdoc-html-tag-name ((,class (:foreground "#D0372D"))))
   `(js2-jsdoc-tag ((,class (:weight normal :foreground "#6434A3"))))
   `(js2-jsdoc-type ((,class (:foreground "SteelBlue"))))
   `(js2-jsdoc-value ((,class (:weight normal :foreground "#BA36A5")))) ; #800080
   `(js2-magic-paren ((,class (:underline t))))
   `(js2-private-function-call ((,class (:foreground "goldenrod"))))
   `(js2-private-member ((,class (:foreground "PeachPuff3"))))
   `(js2-warning ((,class (:underline "orange"))))

   ;; Org non-standard faces.
   `(leuven-org-deadline-overdue ((,class (:foreground "#F22659"))))
   `(leuven-org-deadline-today ((,class (:weight bold :foreground "#4F4A3D" :background "#FFFFCC"))))
   `(leuven-org-deadline-tomorrow ((,class (:foreground "#40A80B"))))
   `(leuven-org-deadline-future ((,class (:foreground "#40A80B"))))
   `(leuven-gnus-unseen ((,class (:weight bold :foreground "#FC7202"))))
   `(leuven-gnus-date ((,class (:foreground "#FF80BF"))))
   `(leuven-gnus-size ((,class (:foreground "#8FBF60"))))
   `(leuven-todo-items-face ((,class (:weight bold :foreground "#FF3125" :background "#FFFF88"))))

   `(light-symbol-face ((,class (:background "#FFFFA0"))))
   `(linum ((,class (:foreground "#9A9A9A" :background "#EDEDED"))))
   `(log-view-file ((,class (:foreground "#0000CC" :background "#EAF2F5"))))
   `(log-view-message ((,class (:foreground "black" :background "#EDEA74"))))
   `(lsp-modeline-code-actions-preferred-face ((,class (:foreground "#000000" :background "#FFF68F"))))
   `(lsp-ui-doc-background ((,class (:background "#F6FECD"))))
   `(lsp-ui-sideline-code-action ((,class (:foreground "#000000" :background "#FFF68F"))))
   `(lui-button-face ((,class ,link)))
   `(lui-highlight-face ((,class (:box (:line-width 1 :color "#CC0000") :foreground "#CC0000" :background "#FFFF88")))) ; my nickname
   `(lui-time-stamp-face ((,class (:foreground "purple"))))
   `(magit-blame-header ((,class (:inherit magit-diff-file-header))))
   `(magit-blame-heading ((,class (:overline "#A7A7A7" :foreground "red" :background "#E6E6E6"))))
   `(magit-blame-hash ((,class (:overline "#A7A7A7" :foreground "red" :background "#E6E6E6"))))
   `(magit-blame-name ((,class (:overline "#A7A7A7" :foreground "#036A07" :background "#E6E6E6"))))
   `(magit-blame-date ((,class (:overline "#A7A7A7" :foreground "blue" :background "#E6E6E6"))))
   `(magit-blame-summary ((,class (:overline "#A7A7A7" :weight bold :foreground "#707070" :background "#E6E6E6"))))
   `(magit-branch ((,class ,vc-branch)))
   `(magit-diff-add ((,class ,diff-added)))
   `(magit-diff-del ((,class ,diff-removed)))
   `(magit-diff-file-header ((,class (:height 1.1 :weight bold :foreground "#4183C4"))))
   `(magit-diff-hunk-header ((,class ,diff-hunk-header)))
   `(magit-diff-none ((,class ,diff-none)))
   `(magit-header ((,class (:foreground "white" :background "#FF4040"))))
   `(magit-item-highlight ((,class (:background "#EAF2F5"))))
   `(magit-item-mark ((,class ,marked-line)))
   `(magit-log-head-label ((,class (:box (:line-width 1 :color "blue" :style nil)))))
   `(magit-log-tag-label ((,class (:box (:line-width 1 :color "#00CC00" :style nil)))))
   `(magit-section-highlight ((,class (:background  "#F6FECD"))))
   `(magit-section-title ((,class (:family "Sans Serif" :height 1.8 :weight bold :foreground "cornflower blue" :inherit nil))))
   `(makefile-space-face ((,class (:background "hot pink"))))
   `(makefile-targets ((,class (:weight bold :foreground "blue"))))
   ;; `(markdown-blockquote-face ((,class ())))
   `(markdown-bold-face ((,class (:inherit bold))))
   ;; `(markdown-comment-face ((,class ())))
   ;; `(markdown-footnote-face ((,class ())))
   ;; `(markdown-header-delimiter-face ((,class ())))
   ;; `(markdown-header-face ((,class ())))
   `(markdown-header-face-1 ((,class ,ol1)))
   `(markdown-header-face-2 ((,class ,ol2)))
   `(markdown-header-face-3 ((,class ,ol3)))
   `(markdown-header-face-4 ((,class ,ol4)))
   `(markdown-header-face-5 ((,class ,ol5)))
   `(markdown-header-face-6 ((,class ,ol6)))
   ;; `(markdown-header-rule-face ((,class ())))
   `(markdown-inline-code-face ((,class ,code-inline)))
   `(markdown-italic-face ((,class (:inherit italic))))
   `(markdown-language-keyword-face ((,class (:inherit org-block-begin-line))))
   ;; `(markdown-line-break-face ((,class ())))
   `(markdown-link-face ((,class ,link-no-underline)))
   ;; `(markdown-link-title-face ((,class ())))
   ;; `(markdown-list-face ((,class ())))
   ;; `(markdown-math-face ((,class ())))
   ;; `(markdown-metadata-key-face ((,class ())))
   ;; `(markdown-metadata-value-face ((,class ())))
   ;; `(markdown-missing-link-face ((,class ())))
   `(markdown-pre-face ((,class (:inherit org-block-background))))
   ;; `(markdown-reference-face ((,class ())))
   ;; `(markdown-strike-through-face ((,class ())))
   `(markdown-url-face ((,class ,link)))
   `(match ((,class ,match)))           ; Used for grep matches.
   `(mc/cursor-bar-face ((,class (:height 1.0 :foreground "#1664C4" :background "#1664C4"))))
   `(mc/cursor-face ((,class (:inverse-video t))))
   `(mc/region-face ((,class (:inherit region))))
   `(mm-uu-extract ((,class ,code-block)))
   `(moccur-current-line-face ((,class (:foreground "black" :background "#FFFFCC"))))
   `(moccur-face ((,class (:foreground "black" :background "#FFFF99"))))
   `(next-error ((,class ,volatile-highlight-supersize)))
   `(nobreak-space ((,class (:background "#CCE8F6"))))
   `(nxml-attribute-local-name-face ((,class ,xml-attribute)))
   `(nxml-attribute-value-delimiter-face ((,class (:foreground "green4"))))
   `(nxml-attribute-value-face ((,class (:foreground "green4"))))
   `(nxml-comment-content-face ((,class (:slant italic :foreground "red"))))
   `(nxml-comment-delimiter-face ((,class (:foreground "red"))))
   `(nxml-element-local-name ((,class ,xml-tag)))
   `(nxml-element-local-name-face ((,class (:foreground "blue"))))
   `(nxml-processing-instruction-target-face ((,class (:foreground "purple1"))))
   `(nxml-tag-delimiter-face ((,class (:foreground "blue"))))
   `(nxml-tag-slash-face ((,class (:foreground "blue"))))
   `(org-agenda-block-count ((,class (:weight bold :foreground "#A5A5A5"))))
   `(org-agenda-calendar-event ((,class (:weight bold :foreground "#3774CC" :background "#E4EBFE"))))
   `(org-agenda-calendar-sexp ((,class (:foreground "#327ACD" :background "#F3F7FC"))))
   `(org-agenda-clocking ((,class (:foreground "black" :background "#EEC900"))))
   `(org-agenda-column-dateline ((,class ,column)))
   `(org-agenda-current-time ((,class (:underline t :foreground "#1662AF"))))
   `(org-agenda-date ((,class (,@(leuven-scale-font leuven-scale-org-agenda-structure 1.6) :weight bold :foreground "#1662AF"))))
   `(org-agenda-date-today ((,class (,@(leuven-scale-font leuven-scale-org-agenda-structure 1.6) :weight bold :foreground "#4F4A3D" :background "#FFFFCC"))))
   `(org-agenda-date-weekend ((,class (,@(leuven-scale-font leuven-scale-org-agenda-structure 1.6) :weight bold :foreground "#4E4E4E"))))
   `(org-agenda-diary ((,class (:weight bold :foreground "green4" :background "light blue"))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground "gold2"))))
   `(org-agenda-done ((,class (:foreground "#555555"))))
   `(org-agenda-filter-category ((,class (:weight bold :foreground "orange"))))
   `(org-agenda-filter-effort ((,class (:weight bold :foreground "orange"))))
   `(org-agenda-filter-regexp ((,class (:weight bold :foreground "orange"))))
   `(org-agenda-filter-tags ((,class (:weight bold :foreground "orange"))))
   `(org-agenda-restriction-lock ((,class (:background "#E77D63"))))
   `(org-agenda-structure ((,class (,@(leuven-scale-font leuven-scale-org-agenda-structure 1.6) :weight bold :foreground "#1F8DD6"))))
   `(org-archived ((,class (:foreground "gray70"))))
   `(org-beamer-tag ((,class (:box (:line-width 1 :color "#FABC18") :foreground "#2C2C2C" :background "#FFF8D0"))))
   `(org-block ((,class ,code-block)))
   `(org-block-background ((,class (:background "#FFFFE0")))) ;; :inherit fixed-pitch))))
   `(org-block-begin-line ((,class (:underline "#A7A6AA" :foreground "#555555" :background "#E2E1D5"))))
   `(org-block-end-line ((,class (:overline "#A7A6AA" :foreground "#555555" :background "#E2E1D5"))))
   `(org-checkbox ((,class (:weight bold :box (:line-width 1 :style pressed-button) :foreground "#123555" :background "#D4D4D4"))))
   `(org-clock-overlay ((,class (:foreground "white" :background "SkyBlue4"))))
   `(org-code ((,class ,code-inline)))
   `(org-column ((,class ,column)))
   `(org-column-title ((,class ,column)))
   `(org-date ((,class (:underline t :foreground "#00459E"))))
   `(org-default ((,class (:foreground "#333333" :background "#FFFFFF"))))
   `(org-dim ((,class (:foreground "#AAAAAA"))))
   `(org-document-info ((,class (:foreground "#484848"))))
   `(org-document-info-keyword ((,class (:foreground "#008ED1" :background "#EAEAFF"))))
   `(org-document-title ((,class (,@(leuven-scale-font leuven-scale-org-document-title 1.8)  :weight bold :foreground "black"))))
   `(org-done ((,class (:weight bold :box (:line-width 1 :color "#BBBBBB") :foreground "#BBBBBB" :background "#F0F0F0"))))
   `(org-drawer ((,class (:weight bold :foreground "#00BB00" :background "#EEFFEE"))))
   `(org-ellipsis ((,class (:underline nil :foreground "#999999")))) ; #FFEE62
   `(org-example ((,class (:foreground "blue" :background "#EEFFEE"))))
   `(org-footnote ((,class (:underline t :foreground "#008ED1"))))
   `(org-formula ((,class (:foreground "chocolate1"))))
   ;; org-habit colors are thanks to zenburn
   `(org-habit-ready-face ((t :background "#7F9F7F"))) ; ,zenburn-green
   `(org-habit-alert-face ((t :background "#E0CF9F" :foreground "#3F3F3F"))) ; ,zenburn-yellow-1 fg ,zenburn-bg
   `(org-habit-clear-face ((t :background "#5C888B")))                       ; ,zenburn-blue-3
   `(org-habit-overdue-face ((t :background "#9C6363")))                     ; ,zenburn-red-3
   `(org-habit-clear-future-face ((t :background "#4C7073")))                ; ,zenburn-blue-4
   `(org-habit-ready-future-face ((t :background "#5F7F5F")))                ; ,zenburn-green-2
   `(org-habit-alert-future-face ((t :background "#D0BF8F" :foreground "#3F3F3F"))) ; ,zenburn-yellow-2 fg ,zenburn-bg
   `(org-habit-overdue-future-face ((t :background "#8C5353"))) ; ,zenburn-red-4
   `(org-headline-done ((,class (:height 1.0 :weight normal :foreground "#ADADAD"))))
   `(org-hide ((,class (:foreground "#E2E2E2"))))
   `(org-inlinetask ((,class (:box (:line-width 1 :color "#EBEBEB") :foreground "#777777" :background "#FFFFD6"))))
   `(org-latex-and-related ((,class (:foreground "#336699" :background "white"))))
   `(org-level-1 ((,class ,ol1)))
   `(org-level-2 ((,class ,ol2)))
   `(org-level-3 ((,class ,ol3)))
   `(org-level-4 ((,class ,ol4)))
   `(org-level-5 ((,class ,ol5)))
   `(org-level-6 ((,class ,ol6)))
   `(org-level-7 ((,class ,ol7)))
   `(org-level-8 ((,class ,ol8)))
   `(org-link ((,class ,link)))
   `(org-list-dt ((,class (:weight bold :foreground "#335EA8"))))
   `(org-macro ((,class (:weight bold :foreground "#EDB802"))))
   `(org-meta-line ((,class (:slant normal :foreground "#008ED1" :background "#EAEAFF"))))
   `(org-mode-line-clock ((,class (:box (:line-width 1 :color "#335EA8") :foreground "black" :background "#FFA335"))))
   `(org-mode-line-clock-overrun ((,class (:weight bold :box (:line-width 1 :color "#335EA8") :foreground "white" :background "#FF4040"))))
   `(org-number-of-items ((,class (:weight bold :foreground "white" :background "#79BA79"))))
   `(org-property-value ((,class (:foreground "#00A000"))))
   `(org-quote ((,class (:slant italic :foreground "dim gray" :background "#FFFFE0"))))
   `(org-scheduled ((,class (:foreground "#333333"))))
   `(org-scheduled-previously ((,class (:foreground "#1466C6"))))
   `(org-scheduled-today ((,class (:weight bold :foreground "#4F4A3D" :background "#FFFFCC"))))
   `(org-sexp-date ((,class (:foreground "#3774CC"))))
   `(org-special-keyword ((,class (:weight bold :foreground "#00BB00" :background "#EEFFEE"))))
   `(org-table ((,class (:foreground "dark green" :background "#EEFFEE")))) ;; :inherit fixed-pitch))))
   `(org-tag ((,class (:weight normal :slant italic :foreground "#9A9FA4" :background "white"))))
   `(org-target ((,class (:foreground "#FF6DAF"))))
   `(org-time-grid ((,class (:foreground "#B8B8B8"))))
   `(org-todo ((,class (:weight bold :box (:line-width 1 :color "#D8ABA7") :foreground "#D8ABA7" :background "#FFE6E4"))))
   `(org-upcoming-deadline ((,class (:foreground "#FF5555"))))
   `(org-verbatim ((,class (:foreground "#0066CC" :background "#F7FDFF"))))
   `(org-verse ((,class (:slant italic :foreground "dim gray" :background "#EEEEEE"))))
   `(org-warning ((,class (:weight bold :foreground "black" :background "#CCE7FF"))))
   `(outline-1 ((,class ,ol1)))
   `(outline-2 ((,class ,ol2)))
   `(outline-3 ((,class ,ol3)))
   `(outline-4 ((,class ,ol4)))
   `(outline-5 ((,class ,ol5)))
   `(outline-6 ((,class ,ol6)))
   `(outline-7 ((,class ,ol7)))
   `(outline-8 ((,class ,ol8)))
   `(pabbrev-debug-display-label-face ((,class (:foreground "white" :background "#A62154"))))
   `(pabbrev-suggestions-face ((,class (:weight bold :foreground "white" :background "red"))))
   `(pabbrev-suggestions-label-face ((,class (:weight bold :foreground "white" :background "purple"))))
   `(paren-face-match ((,class ,paren-matched)))
   `(paren-face-mismatch ((,class ,paren-unmatched)))
   `(paren-face-no-match ((,class ,paren-unmatched)))
   `(persp-selected-face ((,class (:weight bold :foreground "#EEF5FE"))))
   `(powerline-active1 ((,class (:foreground "#85CEEB" :background "#383838" :inherit mode-line))))
   `(powerline-active2 ((,class (:foreground "#85CEEB" :background "#4070B6" :inherit mode-line))))
   `(powerline-inactive1 ((,class (:foreground "#F0F0EF" :background "#686868" :inherit mode-line-inactive))))
   `(powerline-inactive2 ((,class (:foreground "#F0F0EF" :background "#A9A9A9" :inherit mode-line-inactive))))
   `(rainbow-delimiters-depth-1-face ((,class (:foreground "#707183"))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground "#7388D6"))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground "#909183"))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground "#709870"))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground "#907373"))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground "#6276BA"))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground "#858580"))))
   `(rainbow-delimiters-depth-8-face ((,class (:foreground "#80A880"))))
   `(rainbow-delimiters-depth-9-face ((,class (:foreground "#887070"))))
   `(rainbow-delimiters-mismatched-face ((,class ,paren-unmatched)))
   `(rainbow-delimiters-unmatched-face ((,class ,paren-unmatched)))
   `(recover-this-file ((,class (:weight bold :background "#FF3F3F"))))
   `(rng-error ((,class (:weight bold :foreground "red" :background "#FBE3E4"))))
   `(sh-heredoc ((,class (:foreground "blue" :background "#EEF5FE"))))
   `(sh-quoted-exec ((,class (:foreground "#FF1493"))))
   `(shadow ((,class ,shadow)))         ; Used for grep context lines.
   `(shell-option-face ((,class (:foreground "forest green"))))
   `(shell-output-2-face ((,class (:foreground "blue"))))
   `(shell-output-3-face ((,class (:foreground "purple"))))
   `(shell-output-face ((,class (:foreground "black"))))
   ;; `(shell-prompt-face ((,class (:weight bold :foreground "yellow"))))
   `(shm-current-face ((,class (:background "#EEE8D5"))))
   `(shm-quarantine-face ((,class (:background "lemonchiffon"))))
   `(show-paren-match ((,class ,paren-matched)))
   `(show-paren-mismatch ((,class ,paren-unmatched)))
   `(sml-modeline-end-face ((,class (:background "#6BADF6")))) ; #335EA8
   `(sml-modeline-vis-face ((,class (:background "#1979CA"))))
   `(term ((,class (:foreground "#333333" :background "#FFFFFF"))))

   ;; `(sp-pair-overlay-face ((,class ())))
   ;; `(sp-show-pair-enclosing ((,class ())))
   ;; `(sp-show-pair-match-face ((,class ()))) ; ~ Pair highlighting (matching tags).
   ;; `(sp-show-pair-mismatch-face ((,class ())))
   ;; `(sp-wrap-overlay-closing-pair ((,class ())))
   ;; `(sp-wrap-overlay-face ((,class ())))
   ;; `(sp-wrap-overlay-opening-pair ((,class ())))
   ;; `(sp-wrap-tag-overlay-face ((,class ())))

   `(speedbar-button-face ((,class (:foreground "green4"))))
   `(speedbar-directory-face ((,class (:foreground "blue4"))))
   `(speedbar-file-face ((,class (:foreground "cyan4"))))
   `(speedbar-highlight-face ((,class ,volatile-highlight)))
   `(speedbar-selected-face ((,class (:underline t :foreground "red"))))
   `(speedbar-tag-face ((,class (:foreground "brown"))))
   `(svn-status-directory-face ((,class ,directory)))
   `(svn-status-filename-face ((,class (:weight bold :foreground "#4183C4"))))
   `(svn-status-locked-face ((,class (:weight bold :foreground "red"))))
   `(svn-status-marked-face ((,class ,marked-line)))
   `(svn-status-marked-popup-face ((,class (:weight bold :foreground "green3"))))
   `(svn-status-switched-face ((,class (:slant italic :foreground "gray55"))))
   `(svn-status-symlink-face ((,class ,symlink)))
   `(svn-status-update-available-face ((,class (:foreground "orange"))))
   `(tex-verbatim ((,class (:foreground "blue"))))
   `(tool-bar ((,class (:box (:line-width 1 :style released-button) :foreground "black" :background "gray75"))))
   `(tooltip ((,class (:foreground "black" :background "light yellow"))))
   `(traverse-match-face ((,class (:weight bold :foreground "blue violet"))))
   `(vc-annotate-face-3F3FFF ((,class (:foreground "#3F3FFF" :background "black"))))
   `(vc-annotate-face-3F6CFF ((,class (:foreground "#3F3FFF" :background "black"))))
   `(vc-annotate-face-3F99FF ((,class (:foreground "#3F99FF" :background "black"))))
   `(vc-annotate-face-3FC6FF ((,class (:foreground "#3F99FF" :background "black"))))
   `(vc-annotate-face-3FF3FF ((,class (:foreground "#3FF3FF" :background "black"))))
   `(vc-annotate-face-3FFF56 ((,class (:foreground "#4BFF4B" :background "black"))))
   `(vc-annotate-face-3FFF83 ((,class (:foreground "#3FFFB0" :background "black"))))
   `(vc-annotate-face-3FFFB0 ((,class (:foreground "#3FFFB0" :background "black"))))
   `(vc-annotate-face-3FFFDD ((,class (:foreground "#3FF3FF" :background "black"))))
   `(vc-annotate-face-56FF3F ((,class (:foreground "#4BFF4B" :background "black"))))
   `(vc-annotate-face-83FF3F ((,class (:foreground "#B0FF3F" :background "black"))))
   `(vc-annotate-face-B0FF3F ((,class (:foreground "#B0FF3F" :background "black"))))
   `(vc-annotate-face-DDFF3F ((,class (:foreground "#FFF33F" :background "black"))))
   `(vc-annotate-face-F6FFCC ((,class (:foreground "black" :background "#FFFFC0"))))
   `(vc-annotate-face-FF3F3F ((,class (:foreground "#FF3F3F" :background "black"))))
   `(vc-annotate-face-FF6C3F ((,class (:foreground "#FF3F3F" :background "black"))))
   `(vc-annotate-face-FF993F ((,class (:foreground "#FF993F" :background "black"))))
   `(vc-annotate-face-FFC63F ((,class (:foreground "#FF993F" :background "black"))))
   `(vc-annotate-face-FFF33F ((,class (:foreground "#FFF33F" :background "black"))))

   ;; ;; vc
   ;; (vc-up-to-date-state    ((,c :foreground ,(gc 'green-1))))
   ;; (vc-edited-state        ((,c :foreground ,(gc 'yellow+1))))
   ;; (vc-missing-state       ((,c :foreground ,(gc 'red))))
   ;; (vc-conflict-state      ((,c :foreground ,(gc 'red+2) :weight bold)))
   ;; (vc-locked-state        ((,c :foreground ,(gc 'cyan-1))))
   ;; (vc-locally-added-state ((,c :foreground ,(gc 'blue))))
   ;; (vc-needs-update-state  ((,c :foreground ,(gc 'magenta))))
   ;; (vc-removed-state       ((,c :foreground ,(gc 'red-1))))

   `(vhl/default-face ((,class ,volatile-highlight))) ; `volatile-highlights.el' (for undo, yank).
   `(w3m-anchor ((,class ,link)))
   `(w3m-arrived-anchor ((,class (:foreground "purple1"))))
   `(w3m-bitmap-image-face ((,class (:foreground "gray4" :background "green"))))
   `(w3m-bold ((,class (:weight bold :foreground "black"))))
   `(w3m-current-anchor ((,class (:weight bold :underline t :foreground "blue"))))
   `(w3m-form ((,class (:underline t :foreground "tan1"))))
   `(w3m-form-button-face ((,class (:weight bold :underline t :foreground "gray4" :background "light grey"))))
   `(w3m-form-button-mouse-face ((,class (:underline t :foreground "light grey" :background "#2B7E2A"))))
   `(w3m-form-button-pressed-face ((,class (:weight bold :underline t :foreground "gray4" :background "light grey"))))
   `(w3m-header-line-location-content-face ((,class (:foreground "#7F7F7F":background "#F7F7F7"))))
   `(w3m-header-line-location-title-face ((,class (:foreground "#2C55B1" :background "#F7F7F7"))))
   `(w3m-history-current-url-face ((,class (:foreground "lemon chiffon"))))
   `(w3m-image-face ((,class (:weight bold :foreground "DarkSeaGreen2"))))
   `(w3m-link-numbering ((,class (:foreground "#B4C7EB")))) ; mouseless browsing
   `(w3m-strike-through-face ((,class (:strike-through t))))
   `(w3m-underline-face ((,class (:underline t))))

   ;; `(web-mode-block-attr-name-face ((,class ())))
   ;; `(web-mode-block-attr-value-face ((,class ())))
   ;; `(web-mode-block-comment-face ((,class ())))
   ;; `(web-mode-block-control-face ((,class ())))
   ;; `(web-mode-block-delimiter-face ((,class ())))
   ;; `(web-mode-block-face ((,class ())))
   ;; `(web-mode-block-string-face ((,class ())))
   ;; `(web-mode-bold-face ((,class ())))
   ;; `(web-mode-builtin-face ((,class ())))
   ;; `(web-mode-comment-face ((,class ())))
   ;; `(web-mode-comment-keyword-face ((,class ())))
   ;; `(web-mode-constant-face ((,class ())))
   ;; `(web-mode-css-at-rule-face ((,class ())))
   ;; `(web-mode-css-color-face ((,class ())))
   ;; `(web-mode-css-comment-face ((,class ())))
   ;; `(web-mode-css-function-face ((,class ())))
   ;; `(web-mode-css-priority-face ((,class ())))
   ;; `(web-mode-css-property-name-face ((,class ())))
   ;; `(web-mode-css-pseudo-class-face ((,class ())))
   ;; `(web-mode-css-selector-face ((,class ())))
   ;; `(web-mode-css-string-face ((,class ())))
   ;; `(web-mode-css-variable-face ((,class ())))
   ;; `(web-mode-current-column-highlight-face ((,class ())))
   `(web-mode-current-element-highlight-face ((,class (:background "#99CCFF")))) ; #FFEE80
   ;; `(web-mode-doctype-face ((,class ())))
   ;; `(web-mode-error-face ((,class ())))
   ;; `(web-mode-filter-face ((,class ())))
   `(web-mode-folded-face ((,class (:box (:line-width 1 :color "#777777") :foreground "#9A9A6A" :background "#F3F349"))))
   ;; `(web-mode-function-call-face ((,class ())))
   ;; `(web-mode-function-name-face ((,class ())))
   ;; `(web-mode-html-attr-custom-face ((,class ())))
   ;; `(web-mode-html-attr-engine-face ((,class ())))
   ;; `(web-mode-html-attr-equal-face ((,class ())))
   `(web-mode-html-attr-name-face ((,class ,xml-attribute)))
   ;; `(web-mode-html-attr-value-face ((,class ())))
   ;; `(web-mode-html-entity-face ((,class ())))
   `(web-mode-html-tag-bracket-face ((,class ,xml-tag)))
   ;; `(web-mode-html-tag-custom-face ((,class ())))
   `(web-mode-html-tag-face ((,class ,xml-tag)))
   ;; `(web-mode-html-tag-namespaced-face ((,class ())))
   ;; `(web-mode-inlay-face ((,class ())))
   ;; `(web-mode-italic-face ((,class ())))
   ;; `(web-mode-javascript-comment-face ((,class ())))
   ;; `(web-mode-javascript-string-face ((,class ())))
   ;; `(web-mode-json-comment-face ((,class ())))
   ;; `(web-mode-json-context-face ((,class ())))
   ;; `(web-mode-json-key-face ((,class ())))
   ;; `(web-mode-json-string-face ((,class ())))
   ;; `(web-mode-jsx-depth-1-face ((,class ())))
   ;; `(web-mode-jsx-depth-2-face ((,class ())))
   ;; `(web-mode-jsx-depth-3-face ((,class ())))
   ;; `(web-mode-jsx-depth-4-face ((,class ())))
   ;; `(web-mode-keyword-face ((,class ())))
   ;; `(web-mode-param-name-face ((,class ())))
   ;; `(web-mode-part-comment-face ((,class ())))
   `(web-mode-part-face ((,class (:background "#FFFFE0"))))
   ;; `(web-mode-part-string-face ((,class ())))
   ;; `(web-mode-preprocessor-face ((,class ())))
   `(web-mode-script-face ((,class (:background "#EFF0F1"))))
   ;; `(web-mode-sql-keyword-face ((,class ())))
   ;; `(web-mode-string-face ((,class ())))
   ;; `(web-mode-style-face ((,class ())))
   ;; `(web-mode-symbol-face ((,class ())))
   ;; `(web-mode-type-face ((,class ())))
   ;; `(web-mode-underline-face ((,class ())))
   ;; `(web-mode-variable-name-face ((,class ())))
   ;; `(web-mode-warning-face ((,class ())))
   ;; `(web-mode-whitespace-face ((,class ())))

   `(which-func ((,class (:weight bold :slant italic :foreground "white"))))
   ;; `(which-key-command-description-face)
   ;; `(which-key-group-description-face)
   ;; `(which-key-highlighted-command-face)
   ;; `(which-key-key-face)
   `(which-key-local-map-description-face ((,class (:weight bold :background "#F3F7FC" :inherit which-key-command-description-face))))
   ;; `(which-key-note-face)
   ;; `(which-key-separator-face)
   ;; `(which-key-special-key-face)
   `(widget-button ((,class ,link)))
   `(widget-button-pressed ((,class (:foreground "red"))))
   `(widget-documentation ((,class (:foreground "green4"))))
   `(widget-field ((,class (:background "gray85"))))
   `(widget-inactive ((,class (:foreground "dim gray"))))
   `(widget-single-line-field ((,class (:background "gray85"))))
   `(woman-bold ((,class (:weight bold :foreground "#F13D3D"))))
   `(woman-italic ((,class (:weight bold :slant italic :foreground "#46BE1B"))))
   `(woman-symbol ((,class (:weight bold :foreground "purple"))))
   `(yas-field-debug-face ((,class (:foreground "white" :background "#A62154"))))
   `(yas-field-highlight-face ((,class (:box (:line-width 1 :color "#838383") :foreground "black" :background "#D4DCD8"))))

   ;; `(ztreep-arrow-face ((,class ())))
   ;; `(ztreep-diff-header-face ((,class ())))
   ;; `(ztreep-diff-header-small-face ((,class ())))
   `(ztreep-diff-model-add-face ((,class (:weight bold :foreground "#008800"))))
   `(ztreep-diff-model-diff-face ((,class (:weight bold :foreground "#0044DD"))))
   `(ztreep-diff-model-ignored-face ((,class (:strike-through t :foreground "#9E9E9E"))))
   `(ztreep-diff-model-normal-face ((,class (:foreground "#000000"))))
   ;; `(ztreep-expand-sign-face ((,class ())))
   ;; `(ztreep-header-face ((,class ())))
   ;; `(ztreep-leaf-face ((,class ())))
   ;; `(ztreep-node-face ((,class ())))

   ))

(custom-theme-set-variables 'leuven

  ;; highlight-sexp-mode.
  '(hl-sexp-background-color "#efebe9")

 )

;;;###autoload
(when (and (boundp 'custom-theme-load-path)
           load-file-name)
  ;; Add theme folder to `custom-theme-load-path' when installing over MELPA.
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'leuven)

;; This is for the sake of Emacs.
;; Local Variables:
;; time-stamp-end: "$"
;; time-stamp-format: "%Y-%02m-%02d %02H:%02M"
;; time-stamp-start: "Last-Updated: "
;; End:

;;; leuven-theme.el ends here
