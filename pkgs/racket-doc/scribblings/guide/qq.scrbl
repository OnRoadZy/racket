#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define qq (racket quasiquote))
@(define uq (racket unquote))

@;{@title[#:tag "qq"]{Quasiquoting: @racket[quasiquote] and @racketvalfont{`}}}
@title[#:tag "qq"]{准引用：@racket[quasiquote]和@racketvalfont{`}}

@;{@refalso["quasiquote"]{@racket[quasiquote]}}
@margin-note{在《Racket参考》中的“（quasiquote）”部分也有关于@racket[quasiquote]的文档。}

@;{The @racket[quasiquote] form is similar to @racket[quote]:}
@racket[quasiquote]表类似于@racket[quote]：

@specform[(#,qq datum)]

@;{However, for each @racket[(#,uq _expr)]
that appears within the @racket[_datum], the @racket[_expr] is
evaluated to produce a value that takes the place of the
@racket[unquote] sub-form.}
然而，对出现在@racket[_datum]之中的每个@racket[(#,uq _expr)]，@racket[_expr]被求值以产生一个替代@racket[unquote]子表的值。

@examples[
(eval:alts (#,qq (1 2 (#,uq (+ 1 2)) (#,uq (- 5 1))))
           `(1 2 ,(+ 1 2), (- 5 1)))
]

@;{This form can be used to write functions that build lists according to
certain patterns.}
此表可用于编写根据特定模式建造列表的函数。

@examples[
(eval:alts (define (deep n)
             (cond
               [(zero? n) 0]
               [else
                (#,qq ((#,uq n) (#,uq (deep (- n 1)))))]))
           (define (deep n)
             (cond
               [(zero? n) 0]
               [else
                (quasiquote ((unquote n) (unquote (deep (- n 1)))))])))
(deep 8)
]

@;{Or even to cheaply construct expressions programmatically. (Of course, 9 times out of 10,
you should be using a @seclink["macros"]{macro} to do this 
(the 10th time being when you're working through
a textbook like @hyperlink["http://www.cs.brown.edu/~sk/Publications/Books/ProgLangs/"]{PLAI}).)}
甚至可以以编程方式方便地构造表达式。（当然，第9次就超出了10次，你应该使用一个《@seclink["macros"]{宏}》来做这个（第10次是当你学习了一本像《@hyperlink["http://www.cs.brown.edu/~sk/Publications/Books/ProgLangs/"]{PLAI}》那样的教科书之后）。）

@examples[(define (build-exp n)
            (add-lets n (make-sum n)))
          
          (eval:alts
           (define (add-lets n body)
             (cond
               [(zero? n) body]
               [else
                (#,qq 
                 (let ([(#,uq (n->var n)) (#,uq n)])
                   (#,uq (add-lets (- n 1) body))))]))
           (define (add-lets n body)
             (cond
               [(zero? n) body]
               [else
                (quasiquote 
                 (let ([(unquote (n->var n)) (unquote n)])
                   (unquote (add-lets (- n 1) body))))])))
          
          (eval:alts
           (define (make-sum n)
             (cond
               [(= n 1) (n->var 1)]
               [else
                (#,qq (+ (#,uq (n->var n))
                         (#,uq (make-sum (- n 1)))))]))
           (define (make-sum n)
             (cond
               [(= n 1) (n->var 1)]
               [else
                (quasiquote (+ (unquote (n->var n))
                               (unquote (make-sum (- n 1)))))])))
          (define (n->var n) (string->symbol (format "x~a" n)))
          (build-exp 3)]

@;{The @racket[unquote-splicing] form is similar to @racket[unquote], but
its @racket[_expr] must produce a list, and the
@racket[unquote-splicing] form must appear in a context that produces
either a list or a vector. As the name suggests, the resulting list
is spliced into the context of its use.}
@racket[unquote-splicing]表和@racket[unquote]相似，但其@racket[_expr]必须产生一个列表，而且@racket[unquote-splicing]表必须出现在一个产生一个列表或一个向量的上下文里。顾名思义，这个结果列表被拼接到它自己使用的上下文中。

@examples[
(eval:alts (#,qq (1 2 (#,(racket unquote-splicing) (list (+ 1 2) (- 5 1))) 5))
           `(1 2 ,@(list (+ 1 2) (- 5 1)) 5))
]

@;{Using splicing we can revise the construction of our example expressions above
to have just a single @racket[let] expression and a single @racket[+] expression.}
使用拼接，我们可以修改上边我们的示例表达式的构造，以只需要一个单个的@racket[let]表达式和一个单个的@racket[+]表达式。

@examples[(eval:alts
           (define (build-exp n)
             (add-lets 
              n
              (#,qq (+ (#,(racket unquote-splicing) 
                        (build-list
                         n
                         (λ (x) (n->var (+ x 1)))))))))
           (define (build-exp n)
             (add-lets
              n
              (quasiquote (+ (unquote-splicing 
                              (build-list 
                               n
                               (λ (x) (n->var (+ x 1))))))))))
          (eval:alts
           (define (add-lets n body)
             (#,qq
              (let (#,uq
                    (build-list
                     n
                     (λ (n)
                       (#,qq 
                        [(#,uq (n->var (+ n 1))) (#,uq (+ n 1))]))))
                (#,uq body))))
           (define (add-lets n body)
             (quasiquote
              (let (unquote
                    (build-list 
                     n
                     (λ (n) 
                       (quasiquote
                        [(unquote (n->var (+ n 1))) (unquote (+ n 1))]))))
                (unquote body)))))
          (define (n->var n) (string->symbol (format "x~a" n)))
          (build-exp 3)]

@;{If a @racket[quasiquote] form appears within an enclosing
@racket[quasiquote] form, then the inner @racket[quasiquote]
effectively cancels one layer of @racket[unquote] and
@racket[unquote-splicing] forms, so that a second @racket[unquote]
or @racket[unquote-splicing] is needed.}
如果一个@racket[quasiquote]表出现在一个封闭的@racket[quasiquote]表里，那这个内部的@racket[quasiquote]有效地取消@racket[unquote]表和@racket[unquote-splicing]表的一层，结果一个第二层@racket[unquote]或@racket[unquote-splicing]表被需要。

@examples[
(eval:alts (#,qq (1 2 (#,qq (#,uq (+ 1 2)))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  (,(string->uninterned-symbol "unquote") (+ 1 2)))))
(eval:alts (#,qq (1 2 (#,qq (#,uq (#,uq (+ 1 2))))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  (,(string->uninterned-symbol "unquote") 3))))
(eval:alts (#,qq (1 2 (#,qq ((#,uq (+ 1 2)) (#,uq (#,uq (- 5 1)))))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  ((,(string->uninterned-symbol "unquote") (+ 1 2))
                   (,(string->uninterned-symbol "unquote") 4)))))
]

@;{The evaluations above will not actually print as shown. Instead, the
shorthand form of @racket[quasiquote] and @racket[unquote] will be
used: @litchar{`} (i.e., a backquote) and @litchar{,} (i.e., a comma).
The same shorthands can be used in expressions:}
上面的求值实际上不会像显示那样打印。相反，@racket[quasiquote]和@racket[unquote]的速记形式将被使用：@litchar{`}（即一个反引号）和@litchar{,}（即一个逗号）。同样的速记可在表达式中使用：

@examples[
`(1 2 `(,(+ 1 2) ,,(- 5 1)))
]

@;{The shorthand form of @racket[unquote-splicing] is @litchar[",@"]:}
@racket[unquote-splicing]的速记形式是@litchar[",@"]：

@examples[
`(1 2 ,@(list (+ 1 2) (- 5 1)))
]
