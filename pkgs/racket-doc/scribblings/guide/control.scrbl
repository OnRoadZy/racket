#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define cc-eval (make-base-eval))

@;{@title[#:tag "control" #:style 'toc]{Exceptions and Control}}
@title[#:tag "control" #:style 'toc]{异常与控制}

@;{Racket provides an especially rich set of control operations---not
only operations for raising and catching exceptions, but also
operations for grabbing and restoring portions of a computation.}
Racket提供了一组特别丰富的控制操作——不仅是用于提高和捕捉异常的操作，还包括抓取和恢复计算部分的操作。

@local-table-of-contents[]

@; ----------------------------------------

@;{@section[#:tag "exns"]{Exceptions}}
@section[#:tag "exns"]{异常}

@;{Whenever a run-time error occurs, an @deftech{exception} is
raised. Unless the exception is caught, then it is handled by printing
a message associated with the exception, and then escaping from the
computation.}
每当发生运行时错误时，就会引发@deftech{异常（exception）}。除非捕获异常，然后通过打印与异常相关联的消息来处理，然后从计算中逃逸。

@interaction[
(/ 1 0)
(car 17)
]

@;{To catch an exception, use the @racket[with-handlers] form:}
若要捕获异常，请使用@racket[with-handlers]表：

@specform[
(with-handlers ([predicate-expr handler-expr] ...)
  body ...+)
]{}

@;{Each @racket[_predicate-expr] in a handler determines a kind of
exception that is caught by the @racket[with-handlers] form, and the
value representing the exception is passed to the handler procedure
produced by @racket[_handler-expr].  The result of the
@racket[_handler-expr] is the result of the @racket[with-handlers]
expression.}
在处理器中的每个@racket[_predicate-expr]确定一种异常，它由@racket[with-handlers]表捕获，代表异常的值传递给处理器程序由@racket[_handler-expr]生成。@racket[_handler-expr]的结果即@racket[with-handlers]表达式的结果。

@;{For example, a divide-by-zero error raises an instance of the
@racket[exn:fail:contract:divide-by-zero] structure type:}
例如，零做除数错误创建了@racket[exn:fail:contract:divide-by-zero]结构类型：

@interaction[
(with-handlers ([exn:fail:contract:divide-by-zero?
                 (lambda (exn) +inf.0)])
  (/ 1 0))
(with-handlers ([exn:fail:contract:divide-by-zero?
                 (lambda (exn) +inf.0)])
  (car 17))
]

@;{The @racket[error] function is one way to raise your own exception. It
packages an error message and other information into an
@racket[exn:fail] structure:}
@racket[error]函数是引起异常的一种方法。它打包一个错误信息和其它信息进入@racket[exn:fail]结构：

@interaction[
(error "crash!")
(with-handlers ([exn:fail? (lambda (exn) 'air-bag)])
  (error "crash!"))
]

@;{The @racket[exn:fail:contract:divide-by-zero] and @racket[exn:fail]
structure types are sub-types of the @racket[exn] structure
type. Exceptions raised by core forms and functions always raise an
instance of @racket[exn] or one of its sub-types, but an exception
does not have to be represented by a structure. The @racket[raise]
function lets you raise any value as an exception:}
@racket[exn:fail:contract:divide-by-zero]和@racket[exn:fail]结构类型是@racket[exn]结构类型的子类型。核心表和核心函数引起的异常总是创建@racket[exn]的或其子类的一个实例，但异常不必通过结构表示。@racket[raise]函数允许你创建任何值作为异常：

@interaction[
(raise 2)
(with-handlers ([(lambda (v) (equal? v 2)) (lambda (v) 'two)])
  (raise 2))
(with-handlers ([(lambda (v) (equal? v 2)) (lambda (v) 'two)])
  (/ 1 0))
]

@;{Multiple @racket[_predicate-expr]s in a @racket[with-handlers] form
let you handle different kinds of exceptions in different ways. The
predicates are tried in order, and if none of them match, then the
exception is propagated to enclosing contexts.}
在一个@racket[with-handlers]表里的多个@racket[_predicate-expr]让你在不同的途径处理各种不同的异常。判断按顺序进行尝试，如果没有匹配，则将异常传播到封闭上下文中。

@interaction[
(define (always-fail n)
  (with-handlers ([even? (lambda (v) 'even)]
                  [positive? (lambda (v) 'positive)])
    (raise n)))
(always-fail 2)
(always-fail 3)
(always-fail -3)
(with-handlers ([negative? (lambda (v) 'negative)])
 (always-fail -3))
]

@;{Using @racket[(lambda (v) #t)] as a predicate captures all exceptions, of course:}
使用@racket[(lambda (v) #t)]作为判断捕获所有异常，当然：

@interaction[
(with-handlers ([(lambda (v) #t) (lambda (v) 'oops)])
  (car 17))
]

@;{Capturing all exceptions is usually a bad idea, however. If the user
types Ctl-C in a terminal window or clicks the @onscreen{Stop} button
in DrRacket to interrupt a computation, then normally the
@racket[exn:break] exception should not be caught. To catch only
exceptions that represent errors, use @racket[exn:fail?] as the
predicate:}
然而，捕获所有异常通常是个坏主意。如果用户在一个终端窗口键入Ctl-C或者在DrRacket点击@onscreen{停止按钮（Stop）}中断计算，那么通常@racket[exn:break]异常不会被捕获。仅仅会抓取具有代表性的错误，使用@racket[exn:fail?]作为判断：

@interaction[
(with-handlers ([exn:fail? (lambda (v) 'oops)])
  (car 17))
(eval:alts @;{ `examples' doesn't catch break exceptions!};“示例”不捕获中断异常！
 (with-handlers ([exn:fail? (lambda (v) 'oops)])
   (break-thread (current-thread)) (code:comment @#,t{simulate Ctl-C})
   (car 17))
 (error "user break"))
]

@; ----------------------------------------

@;{@section[#:tag "prompt"]{Prompts and Aborts}}
@section[#:tag "prompt"]{提示和中止}

@;{When an exception is raised, control escapes out of an arbitrary deep
evaluation context to the point where the exception is caught---or all
the way out if the exception is never caught:}
当一个异常被引发时，控制将从一个任意深度的求值上下文逃逸到异常被捕获的位置——或者如果没有捕捉到异常，那么所有的出路都会消失：

@interaction[
(+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (/ 1 0)))))))
]

@;{But if control escapes ``all the way out,'' why does the @tech{REPL}
keep going after an error is printed? You might think that it's
because the @tech{REPL} wraps every interaction in a
@racket[with-handlers] form that catches all exceptions, but that's
not quite the reason.}
但如果控制逃逸“所有的出路”，为什么@tech{REPL}在一个错误被打印之后能够继续运行？你可能会认为这是因为@tech{REPL}把每一个互动封装进了@racket[with-handlers]表里，它抓取了所有的异常，但这确实不是原因。

@;{The actual reason is that the @tech{REPL} wraps the interaction with a
@deftech{prompt}, which effectively marks the evaluation context with
an escape point. If an exception is not caught, then information about
the exception is printed, and then evaluation @deftech{aborts} to the
nearest enclosing prompt. More precisely, each prompt has a
@deftech{prompt tag}, and there is a designated @deftech{default
prompt tag} that the uncaught-exception handler uses to @tech{abort}.}
实际的原因是，@tech{REPL}用一个@deftech{提示（prompt）}封装了互动，有效地用一个逃逸位置标记求值上下文。如果一个异常没有被捕获，那么关于异常的信息被打印，然后求值@deftech{中止（aborts）}到最近的封闭提示。更确切地说，每个提示有@deftech{提示标签（prompt tag）}，并有指定的@deftech{默认提示标签（default
prompt tag）}，未捕获的异常处理程序用来@tech{中止}。

@;{The @racket[call-with-continuation-prompt] function installs a prompt
with a given @tech{prompt tag}, and then it evaluates a given thunk
under the prompt. The @racket[default-continuation-prompt-tag]
function returns the @tech{default prompt tag}. The
@racket[abort-current-continuation] function escapes to the nearest
enclosing prompt that has a given @tech{prompt tag}.}
@racket[call-with-continuation-prompt]函数用一个给定的@tech{提示标签}设置提示，然后在提示符下对一个给定的铛（thunk）求值。@racket[default-continuation-prompt-tag]函数返回默认提示标记。@racket[abort-current-continuation]函数转义到具有给定@tech{提示标签}的最近的封闭提示符。

@interaction[
(define (escape v)
  (abort-current-continuation
   (default-continuation-prompt-tag)
   (lambda () v)))
(+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (escape 0)))))))
(+ 1
   (call-with-continuation-prompt
    (lambda ()
      (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (escape 0))))))))
    (default-continuation-prompt-tag)))
]

@;{In @racket[escape] above, the value @racket[v] is wrapped in a
procedure that is called after escaping to the enclosing prompt.}
在上面的@racket[escape]中，值@racket[v]被封装在一个过程中，该过程在转义到封闭提示符后被调用。

@;{@tech{Prompts} and @tech{aborts} look very much like exception
handling and raising. Indeed, prompts and aborts are essentially a
more primitive form of exceptions, and @racket[with-handlers] and
@racket[raise] are implemented in terms of prompts and aborts. The
power of the more primitive forms is related to the word
``continuation'' in the operator names, as we discuss in the next
section.}
@tech{提示（prompts）}和@tech{中止（aborts）}看起来非常像异常处理和引发。事实上，提示和中止本质上是一种更原始的异常形式，与@racket[with-handlers]和@racket[raise]都是按提示执行和中止。更原始形式的权力与操作符名称中的“延续（continuation）”一词有关，我们将在下一节中讨论。

@; ----------------------------------------------------------------------

@;{@section[#:tag "conts"]{Continuations}}
@section[#:tag "conts"]{延续}

@;{A @deftech{continuation} is a value that encapsulates a piece of an
expression's evaluation context. The @racket[call-with-composable-continuation]
function captures the @deftech{current continuation} starting outside
the current function call and running up to the nearest enclosing
prompt. (Keep in mind that each @tech{REPL} interaction is implicitly
wrapped in a prompt.)}
@deftech{延续（continuation）}是一个值，该值封装了表达式的求值上下文。@racket[call-with-composable-continuation]函数从当前函数调用和运行到最近的外围提示捕获@deftech{当前延续（current continuation）}。（记住，每个@tech{REPL}互动都是隐含地封装在一个提示中。）

@;{For example, in}
例如，在下面内容里

@racketblock[
(+ 1 (+ 1 (+ 1 0)))
]

@;{at the point where @racket[0] is evaluated, the expression context
includes three nested addition expressions. We can grab that context by
changing @racket[0] to grab the continuation before returning 0:}
在求值@racket[0]的位置，表达式上下文包含三个嵌套的加法表达式。我们可以通过更改@racket[0]来获取上下文，然后在返回0之前获取延续：

@interaction[
#:eval cc-eval
(define saved-k #f)
(define (save-it!)
  (call-with-composable-continuation
   (lambda (k) (code:comment @#,t{@racket[k] is the captured continuation})
     (set! saved-k k)
     0)))
(+ 1 (+ 1 (+ 1 (save-it!))))
]

@;{The @tech{continuation} saved in @racket[save-k] encapsulates the
program context @racket[(+ 1 (+ 1 (+ 1 _?)))], where @racket[_?]
represents a place to plug in a result value---because that was the
expression context when @racket[save-it!] was called. The
@tech{continuation} is encapsulated so that it behaves like the
function @racket[(lambda (v) (+ 1 (+ 1 (+ 1 v))))]:}
保存在@racket[save-k]中的@tech{延续}封装程序上下文@racket[(+ 1 (+ 1 (+ 1 _?)))]，@racket[_?]代表插入结果值的位置——因为在@racket[save-it!]被调用时这是表达式上下文。@tech{延续}被封装从而其行为类似于函数@racket[(lambda (v) (+ 1 (+ 1 (+ 1 v))))]：

@interaction[
#:eval cc-eval
(saved-k 0)
(saved-k 10)
(saved-k (saved-k 0))
]

@;{The continuation captured by
@racket[call-with-composable-continuation] is determined dynamically,
not syntactically. For example, with}
通过@racket[call-with-composable-continuation]捕获的延续是动态确定的，没有语法。例如，用

@interaction[
#:eval cc-eval
(define (sum n)
  (if (zero? n)
      (save-it!)
      (+ n (sum (sub1 n)))))
(sum 5)
]

@;{the continuation in @racket[saved-k] becomes @racket[(lambda (x) (+ 5
(+ 4 (+ 3 (+ 2 (+ 1 x))))))]:}
在@racket[saved-k]里延续成为@racket[(lambda (x) (+ 5
(+ 4 (+ 3 (+ 2 (+ 1 x))))))]：

@interaction[
#:eval cc-eval
(saved-k 0)
(saved-k 10)
]

@;{A more traditional continuation operator in Racket (or Scheme) is
@racket[call-with-current-continuation], which is usually abbreviated
@racket[call/cc]. It is like
@racket[call-with-composable-continuation], but applying the captured
continuation first @tech{aborts} (to the current @tech{prompt}) before
restoring the saved continuation. In addition, Scheme systems
traditionally support a single prompt at the program start, instead of
allowing new prompts via
@racket[call-with-continuation-prompt]. Continuations as in Racket
are sometimes called @deftech{delimited continuations}, since a
program can introduce new delimiting prompts, and continuations as
captured by @racket[call-with-composable-continuation] are sometimes
called @deftech{composable continuations}, because they do not have a
built-in @tech{abort}.}
在Racket（或Scheme）中较传统的延续运算符是@racket[call-with-current-continuation]，它通常缩写为@racket[call/cc]。这是像@racket[call-with-composable-continuation]，但应用捕获的延续在还原保存的延续前首先@tech{中止}（对于当前@tech{提示}）。此外，Scheme系统传统上支持程序启动时的单个提示符，而不是通过@racket[call-with-continuation-prompt]允许新提示。在Racket中延续有时被称为@deftech{分隔的延续（delimited continuations）}，因为一个程序可以引入新定义的提示，并且作为@racket[call-with-composable-continuation]捕获的延续有时被称为@deftech{组合的延续（composable continuations）}，因为他们没有一个内置的@tech{中止}。

@;{For an example of how @tech{continuations} are useful, see
@other-manual['(lib "scribblings/more/more.scrbl")]. For specific
control operators that have more convenient names than the primitives
described here, see @racketmodname[racket/control].}
作为一个@tech{延续}是多么有用的例子，请参见《 更多：用Racket进行系统编程（More: Systems Programming with Racket）》@;{@other-manual['(lib "scribblings/more/more.scrbl")]}。对于具体的控制操作符，它有比这里描述的原语更恰当的名字，请参见@racketmodname[racket/control]部分。

@; ----------------------------------------------------------------------

@close-eval[cc-eval]
