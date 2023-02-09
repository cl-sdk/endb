(defpackage :endb/sql/expr
  (:use :cl)
  (:export #:sql-= #:sql-<> #:sql-is #:sql-not #:sql-and #:sql-or
           #:sql-< #:sql-<= #:sql-> #:sql->=
           #:sql-+ #:sql-- #:sql-* #:sql-/ #:sql-%
           #:sql-between #:sql-in #:sql-in-query #:sql-exists #:sql-coalesce
           #:sql-union-all #:sql-union #:sql-except #:sql-intersect
           #:sql-cast #:sql-nullif #:sql-abs
           #:sql-count-star #:sql-count #:sql-sum #:sql-avg #:sql-min #:sql-max
           #:sql-create-table #:sql-drop-table #:sql-create-view #:sql-drop-view #:sql-create-index #:sql-drop-index #:sql-insert #:sql-delete
           #:base-table-rows #:base-table-columns
           #:sql-runtime-error))
(in-package :endb/sql/expr)

(define-condition sql-runtime-error (error)
  ())

(deftype sql-null ()
  `(eql :null))

(deftype sql-boolean ()
  `(or boolean sql-null))

(deftype sql-number ()
  `(or number sql-null))

(deftype sql-string ()
  `(or string sql-null))

(deftype sql-value ()
  `(or sql-null sql-boolean sql-number sql-string))

(declaim (ftype (function (sql-value sql-value) sql-boolean) sql-=))
(defun sql-= (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (equal x y)))

(declaim (ftype (function (sql-value sql-value) sql-boolean) sql-<>))
(defun sql-<> (x y)
  (sql-not (sql-= x y)))

(declaim (ftype (function (sql-value sql-value) sql-boolean) sql-is))
(defun sql-is (x y)
  (equal x y))

(declaim (ftype (function (sql-number sql-number) sql-boolean) sql-<))
(defun sql-< (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (< x y)))

(declaim (ftype (function (sql-number sql-number) sql-boolean) sql-<=))
(defun sql-<= (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (<= x y)))

(declaim (ftype (function (sql-number sql-number) sql-boolean) sql->))
(defun sql-> (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (> x y)))

(declaim (ftype (function (sql-number sql-number) sql-boolean) sql->=))
(defun sql->= (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (>= x y)))

(declaim (ftype (function (sql-boolean) sql-boolean) sql-not))
(defun sql-not (x)
  (if (eq :null x)
      :null
      (not x)))

(defmacro sql-and (x y)
  (let ((x-sym (gensym)))
    `(let ((,x-sym ,x))
       (if (eq :null ,x-sym)
           (and ,y :null)
           (and ,x-sym ,y)))))

(defmacro sql-or (x y)
  (let ((x-sym (gensym)))
    `(let ((,x-sym ,x))
       (if (eq :null ,x-sym)
           (or ,y :null)
           (or ,x-sym ,y)))))

(declaim (ftype (function (sql-value sql-value &rest sql-value) sql-value) sql-coalesce))
(defun sql-coalesce (x y &rest args)
  (let ((tail (member-if-not (lambda (x)
                               (eq :null x))
                             (cons x (cons y args)))))
    (if tail
        (first tail)
        :null)))

(declaim (ftype (function (sql-value &optional sql-number) sql-value) sql-+))
(defun sql-+ (x &optional (y 0))
  (cond
    ((or (eq :null x) (eq :null y)) :null)
    ((not (numberp x)) 0)
    (t (+ x y))))

(declaim (ftype (function (sql-number &optional sql-number) sql-number) sql--))
(defun sql-- (x &optional (y 0 yp))
  (if (or (eq :null x) (eq :null y))
      :null
      (if yp
          (- x y)
          (- x))))

(declaim (ftype (function (sql-number sql-number) sql-number) sql-*))
(defun sql-* (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (* x y)))

(declaim (ftype (function (sql-number sql-number) sql-number) sql-/))
(defun sql-/ (x y)
  (cond
    ((or (eq :null x) (eq :null y) (zerop y)) :null)
    ((and (integerp x) (integerp y)) (truncate x y))
    (t (/ x y))))

(declaim (ftype (function (sql-number sql-number) sql-number) sql-%))
(defun sql-% (x y)
  (if (or (eq :null x) (eq :null y))
      :null
      (mod x y)))

(declaim (ftype (function (sql-value sequence) sql-boolean) sql-in))
(defun sql-in (item xs)
  (block in
    (reduce (lambda (x y)
              (let ((result (sql-= y item)))
                (if (eq t result)
                    (return-from in result)
                    (sql-or x result))))
            xs
            :initial-value nil)))

(declaim (ftype (function (sql-value sequence) sql-boolean) sql-in-query))
(defun sql-in-query (item xs)
  (when (and xs (not (= 1 (length (first xs)))))
    (error 'sql-runtime-error :message "IN query must return single column."))
  (sql-in item (mapcar #'first xs)))

(declaim (ftype (function (sql-number sql-number sql-number) sql-boolean) sql-between))
(defun sql-between (expr lhs rhs)
  (sql-and (sql->= expr lhs) (sql-<= expr rhs)))

(declaim (ftype (function (sequence) sql-boolean) sql-exists))
(defun sql-exists (rows)
  (not (null rows)))

(declaim (ftype (function (sequence sequence) sequence) sql-union))
(defun sql-union (lhs rhs)
  (%sql-distinct (nunion lhs rhs :test 'equal)))

(declaim (ftype (function (sequence sequence) sequence) sql-union-all))
(defun sql-union-all (lhs rhs)
  (nconc lhs rhs))

(declaim (ftype (function (sequence sequence) sequence) sql-except))
(defun sql-except (lhs rhs)
  (%sql-distinct (nset-difference lhs rhs :test 'equal)))

(declaim (ftype (function (sequence sequence) sequence) sql-intersect))
(defun sql-intersect (lhs rhs)
  (%sql-distinct (nintersection lhs rhs :test 'equal)))

(declaim (ftype (function (sql-value keyword) sql-value) sql-cast))
(defun sql-cast (x type)
  (if (eq :null x)
      :null
      (if (and (floatp x) (eq :integer type))
          (round x)
          (coerce x (ecase type
                      (:integer 'integer)
                      (:real 'real)
                      ((:decimal :signed) 'number)
                      (:varchar 'string))))))

(declaim (ftype (function (sql-value sql-value) sql-value) sql-nullif))
(defun sql-nullif (x y)
  (if (eq t (sql-= x y))
      :null
      x))

(declaim (ftype (function (sql-number) sql-number) sql-abs))
(defun sql-abs (x)
  (if (eq :null x)
      :null
      (abs x)))

(declaim (ftype (function (sequence) sql-value) sql-scalar-subquery))
(defun sql-scalar-subquery (rows)
  (when (> 1 (length rows))
    (error 'sql-runtime-error :message "Scalar subquery must return max one row."))
  (if (null rows)
      :null
      (caar rows)))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-count-star))
(defun sql-count-star (xs &key distinct)
  (declare (ignore distinct))
  (length xs))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-count))
(defun sql-count (xs &key distinct)
  (count-if-not (lambda (x)
                  (eq :null x))
                (if distinct
                    (%sql-distinct xs)
                    xs)))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-avg))
(defun sql-avg (xs &key distinct)
  (let ((xs-no-nulls (delete :null (if distinct
                                       (%sql-distinct xs)
                                       xs))))
    (if xs-no-nulls
        (sql-/ (reduce #'sql-+ xs-no-nulls) (coerce (length xs-no-nulls) 'double-float))
        :null)))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-sum))
(defun sql-sum (xs &key distinct)
  (let ((xs-no-nulls (delete :null (if distinct
                                       (%sql-distinct xs)
                                       xs))))
    (if xs-no-nulls
        (reduce #'sql-+ xs-no-nulls)
        :null)))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-min))
(defun sql-min (xs &key distinct)
  (let ((xs-no-nulls (delete :null (if distinct
                                       (%sql-distinct xs)
                                       xs))))
    (if xs-no-nulls
        (reduce
         (lambda (x y)
           (if (sql-< x y)
               x
               y))
         xs-no-nulls)
        :null)))

(declaim (ftype (function (sequence &key (:distinct boolean)) sql-number) sql-max))
(defun sql-max (xs &key distinct)
  (let ((xs-no-nulls (delete :null (if distinct
                                       (%sql-distinct xs)
                                       xs))))
    (if xs-no-nulls
        (reduce
         (lambda (x y)
           (if (sql-> x y)
               x
               y))
         xs-no-nulls)
        :null)))

(declaim (ftype (function (sequence) sequence) %sql-distinct))
(defun %sql-distinct (rows)
  (delete-duplicates rows :test 'equal))

(declaim (ftype (function (sequence t t) sequence) %sql-limit))
(defun %sql-limit (rows limit offset)
  (subseq rows (or offset 0) (if offset
                                 (+ offset limit)
                                 limit)))

(declaim (ftype (function (sequence list) sequence) %sql-order-by))
(defun %sql-order-by (rows order-by)
  (labels ((asc (x y)
             (cond
               ((eq :null x) t)
               ((eq :null y) nil)
               (t (< x y))))
           (desc (x y)
             (cond
               ((eq :null y) t)
               ((eq :null x) nil)
               (t (> x y)))))
    (sort rows (lambda (x y)
                 (loop for (idx direction) in order-by
                       for cmp = (ecase direction
                                   ((nil :asc) #'asc)
                                   (:desc #'desc))
                       for xv = (nth (1- idx) x)
                       for yv = (nth (1- idx) y)
                       thereis (funcall cmp xv yv)
                       until (funcall cmp yv xv))))))


(declaim (ftype (function (sequence number number) hash-table) %sql-group-by))
(defun %sql-group-by (rows group-count group-expr-count)
  (let ((acc (make-hash-table :test 'equal)))
    (if (and (null rows) (zerop group-count))
        (setf (gethash () acc) ())
        (loop for row in rows
              for k = (subseq row 0 group-count)
              do (setf (gethash k acc)
                       (let ((group-acc (or (gethash k acc) (make-list group-expr-count))))
                         (mapcar #'cons (subseq row group-count) group-acc)))))
    acc))

(defstruct base-table
  columns
  rows)

(defun sql-create-table (db table-name columns)
  (unless (gethash table-name db)
    (let ((table (make-base-table :columns columns :rows ())))
      (setf (gethash table-name db) table)
      (values nil t))))

(defun sql-drop-table (db table-name &key if-exists)
  (when (or (remhash table-name db) if-exists)
    (values nil t)))

(defun sql-create-view (db view-name query)
  (unless (gethash view-name db)
    (setf (gethash view-name db) query)
    (values nil t)))

(defun sql-drop-view (db view-name &key if-exists)
  (when (or (remhash view-name db) if-exists)
    (values nil t)))

(defun sql-create-index (db)
  (declare (ignore db))
  (values nil t))

(defun sql-drop-index (db)
  (declare (ignore db)))

(defun sql-insert (db table-name values &key column-names)
  (let ((table (gethash table-name db)))
    (unless (listp table)
      (let* ((rows (base-table-rows table))
             (values (if column-names
                         (let ((column->idx (make-hash-table :test 'equal)))
                           (loop for column in column-names
                                 for idx from 0
                                 do (setf (gethash column column->idx) idx))
                           (mapcar (lambda (row)
                                     (mapcar (lambda (column)
                                               (nth (gethash column column->idx) row))
                                             (base-table-columns table)))
                                   values))
                         values)))
        (setf (base-table-rows table) (append values rows))
        (values nil (length values))))))

(defun sql-delete (db table-name values)
  (let ((table (gethash table-name db)))
    (unless (listp table)
      (let* ((table (gethash table-name db))
             (rows (base-table-rows table)))
        (setf (base-table-rows table) (nset-difference rows values :test 'equal))
        (values nil (length values))))))
