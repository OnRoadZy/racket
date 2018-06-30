#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/undefined
                     racket/shared))

@;{@title[#:tag "void+undefined"]{Void and Undefined}}
@title[#:tag "void+undefined"]{无效值（Void）和未定义值（Undefined）}

@;{Some procedures or expression forms have no need for a result
value. For example, the @racket[display] procedure is called only for
the side-effect of writing output. In such cases the result value is
normally a special constant that prints as @|void-const|.  When the
result of an expression is simply @|void-const|, the @tech{REPL} does not
print anything.}
某些过程或表达式表不需要一个结果值。例如，@racket[display]过程被别用仅为写输出的副作用。在这样的情况下，结果值通常是一个特殊的常量，它打印为@|void-const|。当一个表达式的结果是简单的@|void-const|时，@tech{REPL}不打印任何东西。

@;{The @racket[void] procedure takes any number of arguments and returns
@|void-const|. (That is, the identifier @racketidfont{void} is bound
to a procedure that returns @|void-const|, instead of being bound
directly to @|void-const|.)}
@racket[void]过程接受任意数量的参数并返回@|void-const|。（即，@racketidfont{void}标识符绑定到一个返回@|void-const|的过程，而不是直接绑定到@|void-const|。）

@examples[
(void)
(void 1 2 3)
(list (void))
]

@;{The @racket[undefined] constant, which prints as @|undefined-const|, is
sometimes used as the result of a reference whose value is not yet
available. In previous versions of Racket (before version 6.1),
referencing a local binding too early produced @|undefined-const|;
too-early references now raise an exception, instead.}
@racket[undefined]常量，它打印为@|undefined-const|，有时是作为一个参考的结果，其值是不可用的。在Racket以前的版本（6.1以前的版本），过早参考一个局部绑定会产生@|undefined-const|；相反，现在过早参考会引发一个异常。

@;{@margin-note{The @racket[undefined] result can still be produced
in some cases by the @racket[shared] form.}}
@margin-note{在某些情况下，@racket[undefined]结果仍然可以通过@racket[shared]表产生。}

@def+int[
(define (fails)
  (define x x)
  x)
(fails)
]
