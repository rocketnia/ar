(load "equal-wrt-testing.arc")
(load "test.arc")
(load "embed.arc")

(def matches (pattern form)
  (iso (firstn len.pattern form) pattern))

;; returns an Arc list of Racket forms

(def rreadfile (filename)
  (w/infile in filename
    (accum a
      ((afn ()
        (racket
          (racket-let ((form (racket-read in)))
            (racket-unless (racket-eof-object? form)
              (a form)
              (self)))))))))

(def ac-upto (pattern)
  (prn)
  (write pattern) (prn)
  (let arc (empty-runtime (racket-path->string (racket-current-directory)))
    (catch
     (each form (rreadfile "ar.ail")
       (arc!ar-racket-eval arc!runtime* form)
       (when (matches pattern (ar-toarc form)) (throw nil)))
     (err "pattern not found in source" pattern))
    arc))

(mac rq (lit)
  `(racket ,(+ "(racket-quote " lit ")")))

(mac testfor (pattern . body)
  `(let a (ac-upto ',pattern)
     ,@body))

(testfor (racket-define -)
  (testis (a!- 5)        -5)
  (testis (a!- 20 4 3 2) 11))

(testfor (racket-define /)
  (testis (a!/ 24 3 2) 4))

(testfor (racket-define *)
  (testis (a!*)       1)
  (testis (a!* 5)     5)
  (testis (a!* 3 4 7) 84))

(testfor (racket-define cons)
  (testis (a!cons 1 2) '(1 . 2)))

(testfor (racket-define inside)
  (let s (outstring)
    (disp "foo" s)
    (testis (a!inside s) "foo")))

(testfor (racket-define instring)
  (let s (a!instring "foo")
    (testis (n-of 3 (readc s)) '(#\f #\o #\o))))

(testfor (racket-define nil)
  (testis a!nil nil))

(testfor (racket-define outstring)
  (let s (a!outstring)
    (disp "foo" s)
    (testis (inside s) "foo")))

(testfor (racket-define t)
  (testis a!t t))

(testfor (racket-define uniq)
  (testis (type (a!uniq)) 'sym))

(testfor (racket-define (ar-toarc x))
  (testis (a!ar-toarc (rq "(1 2 (3 . 4) 5 () 6)"))
          '(1 2 (3 . 4) 5 nil 6)))

(testfor (ar-def ar-r/list-toarc (x))
  (testis (a!ar-r/list-toarc (rq "()"))        'nil)
  (testis (a!ar-r/list-toarc (rq "(1 2 3)"))   '(1 2 3))
  (testis (a!ar-r/list-toarc (rq "(1 2 . 3)")) '(1 2 . 3)))

(testfor (ar-def list args)
  (testis (a!list 1 2 3) '(1 2 3)))

(mac test-racket-equal (expression expected)
  `(testis (racket-equal? ,expression ,expected)
           (rq "#t")))

(testfor (ar-def ar-list-fromarc (x))
  (test-racket-equal (a!ar-list-fromarc '())
                     (rq "()"))
  (test-racket-equal (a!ar-list-fromarc '(1 2))
                     (rq "(1 2)"))
  (test-racket-equal (a!ar-list-fromarc '(1 . 2))
                     (rq "(1 . 2)")))

(testfor (ar-def car (x))
  (testis (a!car 'nil)     'nil)
  (testis (a!car '(1 2 3)) 1))

(testfor (ar-def cdr (x))
  (testis (a!cdr 'nil)     'nil)
  (testis (a!cdr '(1 2 3)) '(2 3)))

(testfor (ar-def cadr (x))
  (testis (a!cadr '(1 2 3)) 2))

(testfor (ar-def cddr (x))
  (testis (a!cddr '(1 2 3 4)) '(3 4)))

(testfor (ar-def annotate (totype rep))
  (let x (a!annotate 'mytype 'foo)
    (testis (a!type x) 'mytype)
    (testis (a!rep x) 'foo)))

(testfor (ar-def map1 (f xs))
  (testis (a!map1 odd '(1 2 3 4))
          '(t nil t nil)))

(testfor (ar-def coerce (x totype . args))
  (testis (a!coerce #\A           'int)       65)
  (testis (a!coerce #\A           'string)    "A")
  (testis (a!coerce #\A           'sym)       'A)
  (testis (a!coerce 123           'num)       123)
  (testis (a!coerce 65            'char)      #\A)
  (testis (a!coerce 123           'string)    "123")
  (testis (a!coerce 128           'string 16) "80")
  (testis (a!coerce 13.4          'int)       13)
  (testis (a!coerce 65.0          'char)      #\A)
  (testis (a!coerce 14.5          'string)    "14.5")
  (testis (a!coerce "foo"         'sym)       'foo)
  (testis (a!coerce "foo"         'cons)      '(#\f #\o #\o))
  (testis (a!coerce "123.5"       'num)       123.5)
  (testis (a!coerce "123"         'int)       123)
  (testis (a!coerce '("a" b #\c)  'string)    "abc")
  (testis (a!coerce 'nil          'string)    "")
  (testis (a!coerce 'nil          'cons)      'nil))

(testfor (ar-def is args)
  (testis (a!is)       't)
  (testis (a!is 4)     't)
  (testis (a!is 3 4)   'nil)
  (testis (a!is 4 4)   't)
  (testis (a!is 4 4 5) 'nil)
  (testis (a!is 4 4 4) 't))

(testfor (ar-def caris (x val))
  (testis (a!caris 4 'x)      'nil)
  (testis (a!caris '(y z) 'x) 'nil)
  (testis (a!caris '(x y) 'x) 't))

(testfor (ar-def < args)
  (testis (a!<)             t)
  (testis (a!< 1)           t)
  (testis (a!< 1 2)         t)
  (testis (a!< 2 1)         nil)
  (testis (a!< 1 2 3)       t)
  (testis (a!< 1 3 2)       nil)
  (testis (a!< 3 1 2)       nil)
  (testis (a!< 1 2 3 4)     t)
  (testis (a!< 1 3 2 4)     nil)
  (testis (a!< "abc" "def") t)
  (testis (a!< "def" "abc") nil)
  (testis (a!< 'abc 'def)   t)
  (testis (a!< 'def 'abc)   nil)
  (testis (a!< #\a #\b)     t)
  (testis (a!< #\b #\a)     nil))

(testfor (ar-def > args)
  (testis (a!>)             t)
  (testis (a!> 1)           t)
  (testis (a!> 2 1)         t)
  (testis (a!> 1 2)         nil)
  (testis (a!> 3 2 1)       t)
  (testis (a!> 3 1 2)       nil)
  (testis (a!> 2 3 1)       nil)
  (testis (a!> 4 3 2 1)     t)
  (testis (a!> 4 3 1 2)     nil)
  (testis (a!> "def" "abc") t)
  (testis (a!> "abc" "def") nil)
  (testis (a!> 'def 'abc)   t)
  (testis (a!> 'abc 'def)   nil)
  (testis (a!> #\b #\a)     t)
  (testis (a!> #\a #\b)     nil))

(testfor (ar-def len (x))
  (testis (a!len "abc")           3)
  (testis (a!len (obj 'a 1 'b 2)) 2)
  (testis (a!len '())             0)
  (testis (a!len '(1))            1)
  (testis (a!len '(1 2))          2)
  (testis (a!len '(1 2 3))        3))

(testfor (ar-def join args)
  (testis (a!join)                '())
  (testis (a!join '())            '())
  (testis (a!join 1)              1)
  (testis (a!join '(1 2))         '(1 2))
  (testis (a!join '() '())        '())
  (testis (a!join '(1 2) '())     '(1 2))
  (testis (a!join '(1 2) 3)       '(1 2 . 3))
  (testis (a!join '() '(1 2))     '(1 2))
  (testis (a!join '(1 2) '(3 4))  '(1 2 3 4))
  (testis (a!join '(1 2) 3)       '(1 2 . 3))
  (testis (a!join '(1) '(2) '(3)) '(1 2 3)))

(testfor (ar-def + args)
  (testis (a!+)               0)
  (testis (a!+ #\a "b" 'c 3)  "abc3")
  (testis (a!+ "a" 'b #\c)    "abc")
  (testis (a!+ 'nil '(1 2 3)) '(1 2 3))
  (testis (a!+ '(1 2) '(3))   '(1 2 3))
  (testis (a!+ 1 2 3)         6))

(testfor (ar-def ar-apply (fn . racket-arg-list))
  (testis (a!ar-apply + 1 2 3)            6)
  (testis (a!ar-apply '(1 2 3) 1)         2)
  (testis (a!ar-apply "abcde" 2)          #\c)
  (testis (a!ar-apply (obj a 1 b 2) 'b)   2)
  (testis (a!ar-apply (obj a 1 b 2) 'x)   nil)
  (testis (a!ar-apply (obj a 1 b 2) 'x 3) 3))

(testfor (ar-def ar-funcall0 (fn))
  (testis (a!ar-funcall0 +)        0))

(testfor (ar-def ar-funcall1 (fn arg1))
  (testis (a!ar-funcall1 + 3)      3)
  (testis (a!ar-funcall1 "abcd" 2) #\c))

(testfor (ar-def ar-funcall2 (fn arg1 arg2))
  (testis (a!ar-funcall2 + 3 4)        7)
  (testis (a!ar-funcall2 (obj a 1 b 2) 'x 3) 3))

(testfor (ar-def ar-funcall3 (fn arg1 arg2 arg3))
  (testis (a!ar-funcall3 + 3 4 5) 12))

(testfor (ar-def ar-funcall4 (fn arg1 arg2 arg3 arg4))
  (testis (a!ar-funcall4 + 3 4 5 6) 18))

(testfor (ar-def ar-combine-args (as))
  (test-racket-equal (a!ar-combine-args (racket-list))
                     (rq "()"))
  (test-racket-equal (a!ar-combine-args (racket-list '()))
                     (rq "()"))
  (test-racket-equal (a!ar-combine-args (racket-list '(a)))
                     (rq "(a)"))
  (test-racket-equal (a!ar-combine-args (racket-list '(a b c)))
                     (rq "(a b c)"))
  (test-racket-equal (a!ar-combine-args (racket-list 'a '()))
                     (rq "(a)"))
  (test-racket-equal (a!ar-combine-args (racket-list 'a '(b c d)))
                     (rq "(a b c d)"))
  (test-racket-equal (a!ar-combine-args (racket-list 'a 'b '(c d)))
                     (rq "(a b c d)")))

(testfor (ar-def apply (fn . args))
  (testis (a!apply +) 0)
  (testis (a!apply join nil '((a b) (c d)))
          '(a b c d))
  (testis (a!apply + 1 2 '(3 4)) 10))

(testfor (ar-def ac (s env))
  (testis (a!ac + nil)
          (makeerr "Bad object in expression #<procedure:+>")))

(testfor (racket-define (eval form (runtime (racket-quote nil))))
  (testis (a!eval '(ail-code (racket-+ 3 4))) 7))
