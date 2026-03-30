;;; solo-modeline-inactive.el --- Buffer name labels for inactive windows  -*- lexical-binding: t; -*-

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

;; Displays a discrete buffer name label in the top-right corner of specified
;; windows using per-window overlays.  When the first visible line is short
;; enough, the label floats in the available space.  When the line is long, the
;; label visually replaces the rightmost characters (the actual buffer content
;; is unchanged).  The `window' overlay property ensures correct behavior even
;; when the same buffer is displayed in multiple windows.

;;; Code:

(defface solo-modeline-inactive '((t (:inherit header-line)))
  "Face used for buffer name labels in inactive windows."
  :group 'solo-modeline)

(defvar solo-modeline-inactive--overlays nil
  "List of active buffer name label overlays.")

(defun solo-modeline-inactive-update (windows)
  "Display buffer name labels in each window in WINDOWS.
Any previously displayed labels are removed first."
  (solo-modeline-inactive-remove)
  (dolist (win windows)
    ;; Skip child frames (corfu, posframe, etc.)
    (unless (frame-parent (window-frame win))
      (with-current-buffer (window-buffer win)
        (let* ((name (buffer-name))
               (label (concat " " name " "))
               (label-len (string-width label))
               (win-width (- (window-body-width win)
                             (line-number-display-width)))
               (target-col (- win-width label-len))
               (start (window-start win))
               (eol (save-excursion (goto-char start) (line-end-position)))
               (line-col (save-excursion (goto-char eol) (current-column))))
          (if (< line-col target-col)
              ;; Short line: float label at right edge
              (let ((ov (make-overlay eol eol nil t)))
                (overlay-put ov 'window win)
                (overlay-put ov 'after-string
                             (concat (propertize " " 'display
                                                 `(space :align-to (- right-fringe ,label-len)))
                                     (propertize label 'face 'solo-modeline-inactive)))
                (push ov solo-modeline-inactive--overlays))
            ;; Long line: stamp label over content at right edge
            (let* ((ov-start (save-excursion
                               (goto-char start)
                               (move-to-column target-col)
                               (point)))
                   (ov (make-overlay ov-start eol)))
              (overlay-put ov 'window win)
              (overlay-put ov 'display (propertize label 'face 'solo-modeline-inactive))
              (push ov solo-modeline-inactive--overlays))))))))

(defun solo-modeline-inactive-remove ()
  "Remove all buffer name label overlays."
  (mapc #'delete-overlay solo-modeline-inactive--overlays)
  (setq solo-modeline-inactive--overlays nil))

(provide 'solo-modeline-inactive)

;;; solo-modeline-inactive.el ends here
