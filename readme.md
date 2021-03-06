Join the conversation about the Arc Runtime Project ("ar") on Convore:
https://convore.com/arc-runtime-project/

Goals of ar include:

* Make Arc (even more!) hackable, enabling people to create their
  own personal programming language -- beyond what can be done just
  with with macros.

* Provide a complete implementation of Arc 3.1, as one of the
  available languages based on ar.

* Be at least as good as Arc 3.1 at running a production website; thus
  for example you should be able to run a news.arc site on top of ar
  if you wanted to.

* Use the latest Racket version directly, instead of relying on the
  "mzscheme" backwards compatibility mode.

* Fix bugs and make enhancements in the runtime which are easier to do
  with a compiler which isn't quite as tightly bound to Scheme.

This code is under development, much of Arc is unimplemented.

Get to the REPL with:

    ./arc

or, if you have rlwrap:

    rlwrap -q \" ./arc

You can load Arc files from the command line and then go into the
REPL:

    /path/to/ar/arc foo.arc bar.arc

or, if you want to execute your Arc program without entering the REPL:

    /path/to/ar/arc --no-repl foo.arc bar.arc

With `arc-script`, you can write a shell script in Arc.  (Though still
todo is conveniently accessing the command line arguments).

For example, if the file "hello" contained:

    #!/path/to/ar/arc-script
    (prn "hello there")

you could run this script with:

    $ chmod +x hello
    $ ./hello    

if you have ar on your path, you can also use env to avoid hard coding
the path to ar:

    #!/usr/bin/env arc-script
    (prn "hello there")

Run tests with:

    ./tests.sh

Bug reports are *greatly* appreciated!


Todo
----

* (ssexpand 'a.b:c.d) => ((a b:c) d) not (compose a.b c.d)
* (ssexpand '~a.b) => (~a b) not (complement a.b)
* (map (table) list.nil) => Error: procedure application: expected procedure, given: '#hash(); arguments were: 'nil
* (err "foo" '(1 2 3)) prints "Error: foo {1 2 3 . nil}"
* The code currently requires Racket, though a compatibility mode for
  PLT Scheme would be useful.
* clean up messy code in io.arc
* I haven't been able to replicate the socket force close problem yet
  that Arc 3.1 solves by using custodians; is this still a problem in
  Racket?
* the strategy for representing Racket lists in Arc (which we need to
  have ac return an Arc list representing Racket code) is a bit
  confused... a clearer way to distinguish nil and () would be better.
* would be nice if typing ^C returned to the REPL
* pipe-from
* ac-nameit, ac-dbname
* atstrings
* ac-binaries
* direct-calls
* macex1
* explicit-flush
* declare
* primitives
  * current-process-milliseconds
  * current-gc-milliseconds
  * memory
  * sin
  * cos
  * tan
  * asin
  * acos
  * atan
  * log
* Arc 3.1 calls ac-macex in ac-assignn... I wonder why?
* need tests for
  * atomic
  * force-close on sockets (see comment on force-close in arc3.1/ac.scm)
  * threads
  * whilet
  * awhen
  * whiler
  * consif
  * check
  * reinsert-sorted and insortnew
  * memo and defmemo
  * prall, prs
  * templates
  * cache, defcache
  * until
  * queue
  * flushout
  * noisy-each
  * trav
  * hooks
  * out
  * get
  * evtil
  * rand-key
  * ratio
  * dead
  * socket-accept
  * setuid
  * dir
  * rmfile
  * client-ip


Changes
-------

* Arc lists are implemented using Racket's mutable pairs (mpair's)

  as a fix for the [queue bug](http://awwx.ws/queue-test-summary).


* quasiquotation is implemented with Alan Bawden's algorithm

  as a fix for list splicing in nested quasiquotes, which was giving
  people trouble writing macro-defining macros.


* Function rest arguments are 'nil terminated Arc lists

         (cdr ((fn args args) 1)) => nil


* the Arc compiler is reflected into Arc (where it can be hacked by
  redefining or extending the functions which implement the compiler)

         arc> (ac-literal? 123)
         t
         arc> (eval 123)
         123
         arc> +
         #<procedure:ar-+>
         arc> (ac-literal? +)
         nil
         arc> (eval +)
         err: Bad object in expression #<procedure:ar-+>
         arc> (defrule ac-literal? (isa x 'fn) t)
         #<procedure:g1444>
         arc> (ac-literal? +)
         t
         arc> (eval +)
         #<procedure:ar-+>


* lexical identifiers take precedence over macros

         arc> (mac achtung (x) `(+ ,x 2))
         #(tagged mac #<procedure>)
         arc> (let achtung [+ _ 5] (achtung 0))
         5

* quote passes its value unchanged through the compiler, instead of
  copying it

  This isn't noticeable when just using quote to quote literal values
  in the usual way like '(a b c); because the original value isn't
  accessible to the program we can't tell if it was copied or not.

  However the behavior of quote is visible when using macros, since
  they can insert arbitrary values inside the quote expression.

  Choosing not to copy the quoted value means we can define inline
  like this:

         (mac inline (x)
           `',(eval x))

  and we'll get the same value out of inline that we put in:

         arc> (= x '(a b c))
         (a b c)
         arc> (is x (inline x))
         t

  I'm not sure if I understand all the ramifications of this change;
  but that we can define inline so simply is at least suggestive that
  this may be the right axiomatic approach.


* function values are considered literals by the compiler

  This is another change which isn't visible unless you're using
  macros (there otherwise isn't a way to insert a function *value*
  into the source code the compiler compiles).

  In Arc 3.1, a function value can be included in a macro expansion,
  but it needs to be quoted:

         (mac evens (xs) `(',keep even ,xs))

         (def foo () (evens '(1 2 3 4 5 6 7 8)))

         (wipe keep)

         arc> (foo)
         (2 4 6 8)

  With this change, the function value no longer needs to be quoted:

         (mac evens (xs) `(,keep even ,xs))


* macro values can also be included in a macro expansion

         (mac bar () `(prn "hi, this is bar"))

         (mac foo () `(,bar))

         arc> (foo)
         hi, this is bar


* join can accept a non-list as its last argument

         (join '(1 2) 3) => (1 2 . 3)

  which turns out to be useful in macros and other code which works
  with dotted lists.  It means that any list can be split on any cdr,
  and applying join to the pieces will result in the original list.


* global variables are represented in Racket's namespace with their plain name

  In Arc 3.1, global variable are stored in Racket's namespace with a
  "_" prefix, which can be seen e.g. in some error messages:

         arc> x
         Error: "reference to undefined identifier: _x"

  This implementation uses the plain variable name with no prefix:

         arc> x
         Error: reference to undefined identifier: x

  To avoid clashes with Racket identifiers which need to be in the
  namespace, Racket identifiers are prefixed with "racket-".


* implicit variables

  which can help make programs more concise when the same variable
  doesn't need to be threaded through many layers of function calls.


* implements stdin, stdout, stderr as implicit variables

  removing an unnecessary layer of parentheses.


* uniq implemented using Racket's gensym


* defvar allows global variables to be hacked to supply your own
  implementation for getting or setting the variable


* readline accepts CR-LF line endings

  which is useful for Internet protocols such as HTTP.


* [...] is implemented with a macro

  [a b c] is expanded by the reader into (square-bracket a b c).
  Meanwhile there's a square-bracket macro:

         (mac square-bracket body
           `(fn (_) (,@body)))

  this makes it easier to hack the square bracket syntax.

* the REPL removes excess characters at the end of the input line

  In Arc 3.1:

         arc> (readline) ;Fee fi fo fum
         " ;Fee fi fo fum"
         arc>

  this is because Racket's reader reads up to the closing ")", leaving
  the rest of the input line in the input buffer, which is then read
  by readline.

  On the assumption that the REPL is being run from a terminal and
  thus there will always be a trailing newline (which sends the input
  line to the process), the ar REPL cleans out the input buffer up to
  and including the newline:

         arc> (readline) ;Fee fi fo fum
         hello
         "hello"
         arc>

* (coerce '() 'cons) now returns nil

  thus any list can be coerce'd to a "cons", even though the empty
  list isn't actually represented by a cons cell.


* embedding other runtimes based on ar

  Multiple runtimes can loaded and run within the same memory space.
  Each runtime has its own set of global variables, and can have a
  different set of definitions loaded.  Thus the other runtimes can be
  a hacked version of ar, or have some other language than Arc loaded.

         arc> (load "embed.arc")
         nil
         arc> (= a (new-arc))
         #<procedure>
         arc> a!+
         #<procedure:+>
         arc> (a!ar-load "arc.arc")
         nil
         arc> (a!eval '(map odd '(1 2 3 4 5 6)))
         (t nil t nil t nil)


The Arc Implementation Language (Ail)
-------------------------------------

Ail is an language intermediate between Racket and Arc, though closer
to Racket than to Arc.  The Arc runtime is written in Ail, and the Arc
compiler compiles Arc to Ail.

The purpose of Ail is to make Arc more hackable, because it puts Arc's
runtime implementation in Arc's namespace where it can be directly
modified from Arc.

Ail is a terrible language for *writing* code in.  It is like assembly
language or bytecode: it's something you'd rather have generated for
you.

Ail can also be used to access Racket from Arc, though it doesn't by
itself provide a convenient way to do that.  However, a more friendly
interface could be built that used Ail internally.

Ail details:

* Definitions and global variables are in Arc's namespace. Thus if you
  define a function `foo` in Ail, it becomes a function `foo` in Arc.
  Likewise, if code in Ail calls a function `bar`, and `bar` is
  defined in Arc, Arc's `bar` will be called.

* Function calls such as `(foo 1 2 3)` are made using Racket's plain
  function call mechanism, and so can only call functions.

* Racket identifiers are loaded into the namespace with a "racket-"
  prefix.  Thus you can refer to Racket's `+` with `racket-+`,
  Racket's `let` with `racket-let`, and so on.

* Ail code is not loaded in a Racket module, but is instead eval'ed
  one form at a time.  This is like Arc's `load` or Racket's
  [racket/load](http://docs.racket-lang.org/reference/load-lang.html)
  language.

  This means that Ail code isn't separatated into compile-time and
  run-time phases like code in Racket's modules are; but it also means
  that we don't get some optimizations done for us that Racket's
  modules provide.

* Racket macros can be used from Ail code (but don't work from Arc).

* Ail code can be generated from Arc by using `ail-code`.  For
  example, from Arc:

         (ail-code (racket-let ((foo 3))
                     (+ foo 2)))

  note that *Arc's* `+` is being called here, not Racket's.  If we
  wanted Racket's `+`, we'd use `racket-+`.

  `ail-code` is only necessary when we need to use a Racket macro or
  special form, since Racket functions can be called directly from
  Arc.  For example, from Arc:

         (racket-+ 3 4 5)


Contributors
------------

This project is derived from Paul Graham and Robert Morris's [Arc 3.1
release](http://arclanguage.org/item?id=10254); indeed, a goal is to
incorporate as much of the original code with the fewest changes as
possible.

Kartik Agaram discovered the queue bug (and provided a runnable
example!), which was the original motivation for implementing Arc
lists using Racket mpair's.

Waterhouse [investigated the queue
bug](http://arclanguage.org/item?id=13518), determining that it is a
garbage collection issue; this in turn gives us confidence that
implementing Arc lists with Racket mpair's is in fact one way to fix
the bug.  (Note that waterhouse also provided a [direct
fix](http://arclanguage.org/item?id=13616) for Arc 3.1, so you don't
need this runtime implementation just to get a fix for the queue bug).

Reflecting the Arc compiler into Arc was inspired by rntz's [Arc
compiler written in Arc](https://github.com/nex3/arc/tree/arcc).

rocketnia explained why my definition of inline was broken by quote
copying its value, and contributed the patch to make quote not do
that.

rocketnia provided the patch to make lexical variables take precedence
over macros with the same name; waterhouse contributed the test.

Pauan moved Arc's coerce and + functions out of ar; and made `(coerce
'() 'cons)` return nil.
