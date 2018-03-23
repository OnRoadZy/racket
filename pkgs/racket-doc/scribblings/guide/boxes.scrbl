#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@;{@title[#:tag "boxes"]{Boxes}}
@title[#:tag "boxes"]{格子（Box）}

@;{A @deftech{box} is like a single-element vector. It can print as a
quoted @litchar{#&} followed by the printed form of the boxed value.
A @litchar{#&} form can also be used as an expression, but since the
resulting box is constant, it has practically no use.}
一个@deftech{格子（box）}是一个单元素向量。它可以打印成一个引用@litchar{#&}后边跟随这个格子值的打印表。一个@litchar{#&}表也可以用来作为一种表达，但由于作为结果的格子是常量，它实际上没有使用。

@; So what are boxes good for, anyway?

@examples[
(define b (box "apple"))
b
(unbox b)
(set-box! b '(banana boat))
b
]

@;{@refdetails["boxes"]{boxes and box procedures}}
@refdetails["boxes"]{格子和格子程序}
