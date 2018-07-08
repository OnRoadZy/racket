#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define def-eval (make-base-eval))

@;{@title[#:tag "define"]{Definitions: @racket[define]}}
@title[#:tag "define"]{定义：@racket[define]}

@;{A basic definition has the form}
一个基本定义具为如下表：

@specform[(define id expr)]{}

@;{in which case @racket[_id] is bound to the result of
@racket[_expr].}
在这种情况下，@racket[_id]被绑定到@racket[_expr]的结果。

@defexamples[
#:eval def-eval
(define salutation (list-ref '("Hi" "Hello") (random 2)))
salutation
]

@;------------------------------------------------------------------------
@;{@section{Function Shorthand}}
@section[#:tag "Function-Shorthand"]{函数简写}

@;{The @racket[define] form also supports a shorthand for function
definitions:}
@racket[define]表还支持函数定义的一个简写：

@specform[(define (id arg ...) body ...+)]{}

@;{which is a shorthand for}
这是以下内容的简写：

@racketblock[
(define _id (lambda (_arg ...) _body ...+))
]

@defexamples[
#:eval def-eval
(define (greet name)
  (string-append salutation ", " name))
(greet "John")
]

@def+int[
#:eval def-eval
(define (greet first [surname "Smith"] #:hi [hi salutation])
  (string-append hi ", " first " " surname))
(greet "John")
(greet "John" #:hi "Hey")
(greet "John" "Doe")
]

@;{The function shorthand via @racket[define] also supports a
@tech{rest argument} (i.e., a final argument to collect extra
arguments in a list):}
函数简写通过@racket[define]也支持一个@tech{剩余参数（rest argument）}（即，一个最终参数以在一个列表中收集额外参数）：

@specform[(define (id arg ... . rest-id) body ...+)]{}

@;{which is a shorthand}
它是以下内容的一个简写：

@racketblock[
(define _id (lambda (_arg ... . _rest-id) _body ...+))
]

@defexamples[
#:eval def-eval
(define (avg . l)
  (/ (apply + l) (length l)))
(avg 1 2 3)
]

@;------------------------------------------------------------------------
@;{@section{Curried Function Shorthand}}
@section[#:tag "Curried-Function-Shorthand"]{柯里函数简写}

@;{Consider the following @racket[make-add-suffix] function that takes a
string and returns another function that takes a string:}
注意下面的@racket[make-add-suffix]函数，它接收一个字符串并返回另一个接受一个字符串的函数：

@def+int[
#:eval def-eval
(define make-add-suffix
  (lambda (s2)
    (lambda (s) (string-append s s2))))
]

@;{Although it's not common, result of @racket[make-add-suffix] could be
called directly, like this:}
虽然不常见，但@racket[make-add-suffix]的结果可以直接调用，就像这样：

@interaction[
#:eval def-eval
((make-add-suffix "!") "hello")
]

@;{In a sense, @racket[make-add-suffix] is a function takes two
arguments, but it takes them one at a time. A function that takes some
of its arguments and returns a function to consume more is sometimes
called a @defterm{curried function}.}
从某种意义上说，@racket[make-add-suffix]是一个函数，接受两个参数，但一次只接受一个参数。一个函数，它接受它的参数的一些并返回一个函数以接受更多，这种函数有时被称为一个@defterm{柯里函数（curried function）}。

@;{Using the function-shorthand form of @racket[define],
@racket[make-add-suffix] can be written equivalently as}
使用@racket[define]的函数简写表，@racket[make-add-suffix]可以等效地编写为：

@racketblock[
(define (make-add-suffix s2)
  (lambda (s) (string-append s s2)))
]

@;{This shorthand reflects the shape of the function call
@racket[(make-add-suffix "!")]. The @racket[define] form further
supports a shorthand for defining curried functions that reflects
nested function calls:}
这个简写反映了函数调用@racket[(make-add-suffix "!")]的形态。@racket[define]表更进一步支持定义反映嵌套函数调用的柯里函数的一个简写：

@def+int[
#:eval def-eval
(define ((make-add-suffix s2) s)
  (string-append s s2))
((make-add-suffix "!") "hello")
]
@defs+int[
#:eval def-eval
[(define louder (make-add-suffix "!"))
 (define less-sure (make-add-suffix "?"))]
(less-sure "really")
(louder "really")
]

@;{The full syntax of the function shorthand for @racket[define] is as follows:}
用于@racket[define]的函数简写的完整语法如下所示：

@specform/subs[(define (head args) body ...+)
               ([head id
                      (head args)]
                [args (code:line arg ...)
                      (code:line arg ... @#,racketparenfont{.} rest-id)])]{}

@;{The expansion of this shorthand has one nested @racket[lambda] form
for each @racket[_head] in the definition, where the innermost
@racket[_head] corresponds to the outermost @racket[lambda].}
这个简写的扩展有一个给定义中的每个@racket[_head]的嵌套@racket[lambda]表，其最里面的@racket[_head]与最外面的@racket[lambda]对应。

@;------------------------------------------------------------------------
@;{@section[#:tag "multiple-values"]{Multiple Values and @racket[define-values]}}
@section[#:tag "multiple-values"]{多值和define-values}

@;{A Racket expression normally produces a single result, but some
expressions can produce multiple results. For example,
@racket[quotient] and @racket[remainder] each produce a single value,
but @racket[quotient/remainder] produces the same two values at once:}
一个Racket表达式通常产生一个单独的结果，但有些表达式可以产生多个结果。例如，@racket[quotient]和@racket[remainder]各自产生一个值，但@racket[quotient/remainder]同时产生同样的两个值：

@interaction[
#:eval def-eval
(quotient 13 3)
(remainder 13 3)
(quotient/remainder 13 3)
]

@;{As shown above, the @tech{REPL} prints each result value on its own
line.}
如上所示，@tech{REPL}在自己的行打印每一结果值。

@;{Multiple-valued functions can be implemented in terms of the
@racket[values] function, which takes any number of values and
returns them as the results:}
多值函数可以依据@racket[values]函数来实现，它接受任意数量的值并将它们作为结果返回：

@interaction[
#:eval def-eval
(values 1 2 3)
]
@def+int[
#:eval def-eval
(define (split-name name)
  (let ([parts (regexp-split " " name)])
    (if (= (length parts) 2)
        (values (list-ref parts 0) (list-ref parts 1))
        (error "not a <first> <last> name"))))
(split-name "Adam Smith")
]

@;{The @racket[define-values] form binds multiple identifiers at once to
multiple results produced from a single expression:}
@racket[define-values]表同时绑定多个标识符到产生于一个单表达式的多个结果：

@specform[(define-values (id ...) expr)]{}

@;{The number of results produced by the @racket[_expr] must match the
number of @racket[_id]s.}
由@racket[_expr]产生的结果数量必须与@racket[_id]的数量相匹配。

@defexamples[
#:eval def-eval
(define-values (given surname) (split-name "Adam Smith"))
given
surname
]

@;{A @racket[define] form (that is not a function shorthand) is
equivalent to a @racket[define-values] form with a single @racket[_id].}
一个@racket[define]表（不是一个函数简写）等价于一个带有一个单个@racket[_id]的@racket[define-values]表。

@;{@refdetails["define"]{definitions}}
@margin-note{在《Racket参考》中的“（define）”部分提供了更多关于定义的内容。}

@;------------------------------------------------------------------------
@;{@section[#:tag "intdefs"]{Internal Definitions}}
@section[#:tag "intdefs"]{内部定义}

@;{When the grammar for a syntactic form specifies @racket[_body], then
the corresponding form can be either a definition or an expression.
A definition as a @racket[_body] is an @defterm{internal definition}.}
当一个句法表的语法指定@racket[_body]，那相应的表可以是一个定义或一个表达式。作为一个@racket[_body]的一个定义是一个@defterm{内部定义（internal definition）}。

@;{Expressions and internal definitions in a @racket[_body] sequence can
be mixed, as long as the last @racket[_body] is an expression.}
只要最后一个@racket[_body]是表达式，在一个@racket[_body]序列中的表达式和内部定义可以被混合。

@;{For example, the syntax of @racket[lambda] is}
例如， @racket[lambda]的语法是：

@specform[
(lambda gen-formals
  body ...+)
]

@;{so the following are valid instances of the grammar:}
所以下面是语法的有效实例：

@racketblock[
(lambda (f)                (code:comment @#,elem{@;{no definitions}没有定义})
  (printf "running\n")
  (f 0))

(lambda (f)                (code:comment @#,elem{@;{one definition}一个定义})
  (define (log-it what)
    (printf "~a\n" what))
  (log-it "running")
  (f 0)
  (log-it "done"))

(lambda (f n)              (code:comment @#,elem{@;{two definitions}两个定义})
  (define (call n)
    (if (zero? n)
        (log-it "done")
        (begin
          (log-it "running")
          (f n)
          (call (- n 1)))))
  (define (log-it what)
    (printf "~a\n" what))
  (call n))
]

@;{Internal definitions in a particular @racket[_body] sequence are
mutually recursive; that is, any definition can refer to any other
definition---as long as the reference isn't actually evaluated before
its definition takes place. If a definition is referenced too early,
an error occurs.}
在一个特定的@racket[_body]序列中的内部定义是相互递归的，也就是说，任何定义都可以引用任何其它定义——只要这个引用在定义发生之前没有实际被求值。如果一个定义被过早引用，一个错误就会发生。

@defexamples[
(define (weird)
  (define x x)
  x)
(weird)
]

@;{A sequence of internal definitions using just @racket[define] is
easily translated to an equivalent @racket[letrec] form (as introduced
in the next section). However, other definition forms can appear as a
@racket[_body], including @racket[define-values], @racket[struct] (see
@secref["define-struct"]) or @racket[define-syntax] (see
@secref["macros"]).}
内部定义的一个序列只使用@racket[define]很容易转换为一个等效的@racket[letrec]表（如同在下一节中介绍的）。然而，其它的定义表可以表现为一个@racket[_body]，包括@racket[define-values]、@racket[struct]（见《@secref["define-struct"]》）或@racket[define-syntax]（见《@secref["macros"]》）。

@;{@refdetails/gory["intdef-body"]{internal definitions}}
@margin-note{在《Racket参考》文档的“（intdef-body）”部分有内部定义更多知识点。}

@; ----------------------------------------------------------------------

@close-eval[def-eval]
