;;; solo-modeline.el --- Show mode-line only in the active window  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Miguel Guedes

;; Author: Miguel Guedes <miguel.a.guedes@gmail.com>
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A global minor mode that shows the mode-line only in the active window.
;; Inactive windows get their mode-line hidden (via window parameter) and
;; instead display a discrete buffer name label in the top-right corner.
;; Window dividers provide visual separation between windows.

;;; Code:

(require 'solo-modeline-inactive)

(defgroup solo-modeline nil
  "Show mode-line only in the active window."
  :group 'frames)

(defcustom solo-modeline-show-buffer-labels t
  "When non-nil, show buffer name labels in inactive windows."
  :type 'boolean
  :group 'solo-modeline)

(defcustom solo-modeline-manage-window-dividers t
  "When non-nil, enable `window-divider-mode' automatically.
Set to nil if you manage window dividers yourself."
  :type 'boolean
  :group 'solo-modeline)

(defcustom solo-modeline-window-divider-width 1
  "Width in pixels of the bottom window divider."
  :type 'natnum
  :group 'solo-modeline)

(defvar solo-modeline--saved-divider-width nil
  "Saved value of `window-divider-default-bottom-width'.")

(defvar solo-modeline--saved-divider-places nil
  "Saved value of `window-divider-default-places'.")

(defvar solo-modeline--saved-divider-mode nil
  "Whether `window-divider-mode' was active before solo-modeline enabled it.")

(defun solo-modeline--update (&rest _)
  "Update mode-lines and buffer name labels across all windows."
  (let ((active (selected-window))
        inactive)
    (walk-windows
     (lambda (win)
       (if (eq win active)
           (set-window-parameter win 'mode-line-format nil)
         (set-window-parameter win 'mode-line-format 'none)
         (push win inactive)))
     nil t)
    (when solo-modeline-show-buffer-labels
      (solo-modeline-inactive-update inactive))))

(defun solo-modeline--cleanup ()
  "Restore mode-lines and remove labels on all windows."
  (solo-modeline-inactive-remove)
  (walk-windows
   (lambda (win)
     (set-window-parameter win 'mode-line-format nil))
   nil t)
  (force-mode-line-update t))

;;;###autoload
(define-minor-mode solo-modeline-mode
  "Show mode-line only in the active window.
Inactive windows display a discrete buffer name label in the top-right
corner.  Window dividers provide visual separation."
  :global t
  :lighter nil
  (if solo-modeline-mode
      (progn
        (when solo-modeline-manage-window-dividers
          (setq solo-modeline--saved-divider-mode (bound-and-true-p window-divider-mode)
                solo-modeline--saved-divider-width window-divider-default-bottom-width
                solo-modeline--saved-divider-places window-divider-default-places)
          (setq window-divider-default-bottom-width solo-modeline-window-divider-width
                window-divider-default-places 'bottom-only)
          (window-divider-mode 1))
        (add-hook 'window-selection-change-functions #'solo-modeline--update)
        (add-hook 'window-configuration-change-hook #'solo-modeline--update)
        (solo-modeline--update))
    (remove-hook 'window-selection-change-functions #'solo-modeline--update)
    (remove-hook 'window-configuration-change-hook #'solo-modeline--update)
    (solo-modeline--cleanup)
    (when solo-modeline-manage-window-dividers
      (setq window-divider-default-bottom-width solo-modeline--saved-divider-width
            window-divider-default-places solo-modeline--saved-divider-places)
      (unless solo-modeline--saved-divider-mode
        (window-divider-mode -1)))))

(provide 'solo-modeline)

;;; solo-modeline.el ends here
