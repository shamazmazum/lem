(in-package :lem)

(defvar *comp-buffer-name* "*Completion*")

(defvar *mb-win*)
(defvar *mb-print-flag* nil)

(defun mb-init ()
  (setq *mb-win*
	(cl-ncurses:newwin
	 1
	 cl-ncurses:*cols*
	 (1- cl-ncurses:*lines*)
	 0)))

(defun mb-resize ()
  (cl-ncurses:mvwin *mb-win*
    (1- cl-ncurses:*lines*)
    0)
  (cl-ncurses:wresize *mb-win*
    1
    cl-ncurses:*cols*)
  (cl-ncurses:werase *mb-win*)
  (cl-ncurses:wrefresh *mb-win*))

(defun mb-clear ()
  (when *mb-print-flag*
    (cl-ncurses:werase *mb-win*)
    (cl-ncurses:wrefresh *mb-win*)
    (setq *mb-print-flag* nil)))

(defun mb-write (msg)
  (setq *mb-print-flag* t)
  (cl-ncurses:werase *mb-win*)
  (cl-ncurses:mvwaddstr *mb-win* 0 0 msg)
  (cl-ncurses:wrefresh *mb-win*))

(defun mb-y-or-n-p (prompt)
  (setq *mb-print-flag* t)
  (do () (nil)
    (cl-ncurses:werase *mb-win*)
    (cl-ncurses:mvwaddstr *mb-win* 0 0 (format nil "~a [y/n]?" prompt))
    (cl-ncurses:wrefresh *mb-win*)
    (let ((c (getch)))
      (cond
       ((char= #\y c)
        (return t))
       ((char= #\n c)
        (return nil))))))

(defun mb-read-char (prompt)
  (setq *mb-print-flag* t)
  (cl-ncurses:werase *mb-win*)
  (cl-ncurses:mvwaddstr *mb-win* 0 0 prompt)
  (cl-ncurses:wrefresh *mb-win*)
  (getch))

(let ((popup-window))
  (defun mb-completion (comp-f str)
    (multiple-value-bind (result strings) (funcall comp-f str)
      (let ((buffer (get-buffer-create *comp-buffer-name*)))
        (buffer-erase buffer)
        (dolist (s strings)
          (buffer-append-line buffer s))
        (setq popup-window (pop-to-buffer buffer))
        (window-update-all))
      result))
  (defun mb-readline (prompt &optional comp-f existing-p)
    (setq *mb-print-flag* t)
    (let ((str "")
          (comp-flag))
      (do ((break nil))
          (break)
        (cl-ncurses:werase *mb-win*)
        (cl-ncurses:mvwaddstr *mb-win* 0 0 (format nil "~a~a" prompt str))
        (cl-ncurses:wrefresh *mb-win*)
        (let ((c (getch)))
          (cond
           ((char= c key::ctrl-j)
            (when (or (string= str "")
                    (null existing-p)
                    (funcall existing-p str))
              (setq break t)))
           ((char= c key::ctrl-i)
            (when comp-f
              (setq comp-flag t)
              (setq str
                (mb-completion comp-f str))))
           ((char= c key::ctrl-h)
            (setq str (subseq str 0 (1- (length str)))))
           (t
            (setq str (concatenate 'string str (string c)))))))
      (when comp-flag
        (let ((*current-window* popup-window))
          (delete-window)))
      str)))

(defun mb-read-buffer (prompt &optional default existing)
  (when default
    (setq prompt (format nil "~a(~a) " prompt default)))
  (let* ((buffer-names (mapcar 'buffer-name *buffer-list*))
         (result (mb-readline prompt
                   (lambda (name)
                     (completion name buffer-names))
                   (and existing
                     (lambda (name)
                       (member name buffer-names :test 'string=))))))
    (if (string= result "")
      default
      result)))
