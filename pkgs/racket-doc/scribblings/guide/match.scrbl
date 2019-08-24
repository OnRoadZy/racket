#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/match))

@(begin
  (define match-eval (make-base-eval))
  (interaction-eval #:eval match-eval (require racket/match)))

@;{@title[#:tag "match"]{Pattern Matching}}
@title[#:tag "match"]{模式匹配}

@;{The @racket[match] form supports pattern matching on arbitrary Racket
values, as opposed to functions like @racket[regexp-match] that
compare regular expressions to byte and character sequences (see
@secref["regexp"]).}
@racket[match]表支持对任意Racket值的模式匹配，而不是像@racket[regexp-match]那样的函数，将正则表达式与字符及字节序列比较（参见@secref["regexp"]）。

@specform[
(match target-expr
  [pattern expr ...+] ...)
]

@;{The @racket[match] form takes the result of @racket[target-expr] and
tries to match each @racket[_pattern] in order. As soon as it finds a
match, it evaluates the corresponding @racket[_expr] sequence to
obtain the result for the @racket[match] form. If @racket[_pattern]
includes @deftech{pattern variables}, they are treated like wildcards,
and each variable is bound in the @racket[_expr] to the input
fragments that it matched.}
@racket[match]表获取@racket[target-expr]的结果并试图按顺序匹配每个@racket[_pattern]。一旦它找到一个匹配，对相应的@racket[_expr]序列求值以得到@racket[匹配（match）]表的结果。如果@racket[_pattern]包括@deftech{模式变量（pattern variables）}，他们被当作通配符，并且在@racket[_expr]里的每个变量被绑定给的被匹配的输入片段。

@;{Most Racket literal expressions can be used as patterns:}
大多数Racket的字面表达式可以用作模式：

@interaction[
#:eval match-eval
(match 2
  [1 'one]
  [2 'two]
  [3 'three])
(match #f
  [#t 'yes]
  [#f 'no])
(match "apple"
  ['apple 'symbol]
  ["apple" 'string]
  [#f 'boolean])
]

@;{Constructors like @racket[cons], @racket[list], and @racket[vector]
can be used to create patterns that match pairs, lists, and vectors:}
像@racket[cons]、@racket[list]和@racket[vector]这样的构造器，可以用于创建模式，以匹配配对、列表和向量：

@interaction[
#:eval match-eval
(match '(1 2)
  [(list 0 1) 'one]
  [(list 1 2) 'two])
(match '(1 . 2)
  [(list 1 2) 'list]
  [(cons 1 2) 'pair])
(match #(1 2)
  [(list 1 2) 'list]
  [(vector 1 2) 'vector])
]

@;{A constructor bound with @racket[struct] also can be used as a pattern
constructor:}
用@racket[struct]绑定的一个构造器也可以用作一个模式构造器：

@interaction[
#:eval match-eval
(struct shoe (size color))
(struct hat (size style))
(match (hat 23 'bowler)
 [(shoe 10 'white) "bottom"]
 [(hat 23 'bowler) "top"])
]

@;{Unquoted, non-constructor identifiers in a pattern are @tech{pattern
variables} that are bound in the result expressions, except @racket[_],
which does not bind (and thus is usually used as a catch-all):}
不带引号的，在一个模式中的非构造器标识符是@tech{模式变量（pattern
variables）}，它在结果表达式中被绑定，除了@racket[_]，它不绑定（因此，这通常是作为一个泛称（笼统描述））：

@interaction[
#:eval match-eval
(match '(1)
  [(list x) (+ x 1)]
  [(list x y) (+ x y)])
(match '(1 2)
  [(list x) (+ x 1)]
  [(list x y) (+ x y)])
(match (hat 23 'bowler)
  [(shoe sz col) sz] 
  [(hat sz stl) sz])
(match (hat 11 'cowboy)
  [(shoe sz 'black) 'a-good-shoe] 
  [(hat sz 'bowler) 'a-good-hat]
  [_ 'something-else])
]

@;{An ellipsis, written @litchar{...}, acts like a Kleene star within a
list or vector pattern: the preceding sub-pattern can be used to match
any number of times for any number of consecutive elements of the list
or vector. If a sub-pattern followed by an ellipsis includes a pattern
variable, the variable matches multiple times, and it is bound in the
result expression to a list of matches:}
省略号，写作@litchar{...}，就像在列表或向量模式中的克莱尼星号（Kleene star）：前面的子模式可以用于对列表或向量元素的任意数量的连续元素的任意次匹配。如果后跟省略号的子模式包含一个模式变量，这个变量会匹配多次，并在结果表达式里被绑定到一个匹配列表中：

@interaction[
#:eval match-eval
(match '(1 1 1)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 1 2)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 2 3 4)
  [(list 1 x ... 4) x])
(match (list (hat 23 'bowler) (hat 22 'pork-pie))
  [(list (hat sz styl) ...) (apply + sz)])
]

@;{Ellipses can be nested to match nested repetitions, and in that case,
pattern variables can be bound to lists of lists of matches:}
省略号可以嵌套以匹配嵌套的重复，在这种情况下，模式变量可以绑定到匹配列表的列表中：

@interaction[
#:eval match-eval
(match '((! 1) (! 2 2) (! 3 3 3))
  [(list (list '! x ...) ...) x])
]

@;{The @racket[quasiquote] form  (see @secref["qq"] for more about it) can also be used to build patterns.
While unquoted portions of a normal quasiquoted form mean regular racket evaluation, here unquoted
portions mean go back to regular pattern matching.}
@racket[quasiquote]表（见《@secref["qq"]》以获取更多关于它的信息）也可以用来建立模式。而一个通常的准引用（quasiquote）表的非引用部分意味着普通的racket求值，这里非引用部分意味着回到普通模式匹配。

@;{So, in the example below, the with expression is the pattern and it gets rewritten into the
application expression, using quasiquote as a pattern in the first instance and quasiquote
to build an expression in the second.}
因此，在下面的例子中，with表达模式是模式并且它被改写成应用表达式，在第一个实例里用准引用作为一个模式，在第二个实例里准引用构建一个表达式。

@interaction[
#:eval match-eval
(match `{with {x 1} {+ x 1}}
  [`{with {,id ,rhs} ,body}
   `{{lambda {,id} ,body} ,rhs}])
 ]

@;{For information on many more pattern forms, see @racketmodname[racket/match].}
有关更多模式表的信息，请参见@racketmodname[racket/match]。

@;{Forms like @racket[match-let] and @racket[match-lambda] support
patterns in positions that otherwise must be identifiers. For example,
@racket[match-let] generalizes @racket[let] to a @as-index{destructing
bind}:}
像@racket[match-let]和@racket[match-lambda]的表支持位置模式，否则必须是标识符。例如，@racket[match-let]将@racket[let]归纳为@as-index{解构绑定（destructing
bind）}：

@interaction[
#:eval match-eval
(match-let ([(list x y z) '(1 2 3)])
  (list z y x))
]

@;{For information on these additional forms, see @racketmodname[racket/match].}
有关这些附加表的信息，请参见@racketmodname[racket/match]。

@;{@refdetails["match"]{pattern matching}}
@;@refdetails["match"]{模式匹配}

@close-eval[match-eval]
