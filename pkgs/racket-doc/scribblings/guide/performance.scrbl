#lang scribble/doc
@(require scribble/manual "guide-utils.rkt"
          (for-label racket/flonum
                     racket/unsafe/ops
                     racket/performance-hint
                     ffi/unsafe))

@;{@title[#:tag "performance"]{Performance}}
@title[#:tag "performance"]{性能}

@section-index["benchmarking"]
@section-index["speed"]

@;{Alan Perlis famously quipped ``Lisp programmers know the value of
everything and the cost of nothing.'' A Racket programmer knows, for
example, that a @racket[lambda] anywhere in a program produces a value
that is closed over its lexical environment---but how much does
allocating that value cost? While most programmers have a reasonable
grasp of the cost of various operations and data structures at the
machine level, the gap between the Racket language model and the
underlying computing machinery can be quite large.}
Alan Perlis著名佳句：“Lisp程序员知道一切的价值和虚无的代价（Lisp programmers know the value of
everything and the cost of nothing）。”一个Racket程序员知道，例如，
一个在程序中任何地方的@racket[lambda]都会生成一个在词法环境中封闭的值 —— 但是分配这个值要多少代价呢？
尽管大多数程序员对机器级别的各种操作和数据结构的成本有合理的把握，
但Racket语言模型和计算机底层之间的差距可能相当大。

@;{In this chapter, we narrow the gap by explaining details of the
Racket compiler and run-time system and how they affect the run-time
and memory performance of Racket code.}
在这一章中，我们通过解释Racket编译器和运行时系统的细节以及它们如何影响Racket代码的运行时间和内存性能来缩小这一差距。

@; ----------------------------------------------------------------------

@;{@section[#:tag "DrRacket-perf"]{Performance in DrRacket}}
@section[#:tag "DrRacket-perf"]{DrRacket中的性能}

@;{By default, DrRacket instruments programs for debugging, and
debugging instrumentation (provided by the
@other-doc['(lib "errortrace/scribblings/errortrace.scrbl")]
library) can significantly degrade performance for
some programs. Even when debugging is disabled through the
@onscreen{Choose Language...} dialog's @onscreen{Show Details} panel,
the @onscreen{Preserve stacktrace} checkbox is clicked by default,
which also affects performance. Disabling debugging and stacktrace
preservation provides performance results that are more consistent
with running in plain @exec{racket}.}
默认情况下，DrRacket为所有程序附加调试功能，并且这些调试工具
（由@other-doc['(lib "errortrace/scribblings/errortrace.scrbl")]库所提供）
会显著地降低一些程序的性能。即使调试在通过@onscreen{Choose Language...}
对话框的@onscreen{Show Details（显示详细信息）}面板被禁用，
@onscreen{Preserve stacktrace}复选框默认被点击选择，这也会影响性能。
禁用调试和堆栈保存后表现出的性能，更符合单独在@exec{racket}中运行的效果。

@;{Even so, DrRacket and programs developed within DrRacket use the same
Racket virtual machine, so garbage collection times (see
@secref["gc-perf"]) may be longer in DrRacket than when a program is
run by itself, and DrRacket threads may impede execution of program
threads. @bold{For the most reliable timing results for a program, run in
plain @exec{racket} instead of in the DrRacket development environment.}
Non-interactive mode should be used instead of the
@tech["REPL"] to benefit from the module system. See
@secref["modules-performance"] for details.}
即便如此，DrRacket和在DrRacket中开发的程序使用相同的Racket虚拟机，
所以在DrRacket的垃圾收集时间（见@secref["gc-perf"]）可能会比程序本身运行时间更长，
同时DrRacket线程可能妨碍程序线程的执行。
@bold{对于一个程序的最可靠的计时结果，是在普通的@exec{racket}中运行而不是在DrRacket开发环境中运行。}
以从模块系统中受益，应使用非交互式模式代替@tech["REPL"]。详情请参见@secref["modules-performance"]。

@; ----------------------------------------------------------------------

@;{@section[#:tag "JIT"]{The Bytecode and Just-in-Time (JIT) Compilers}}
@section[#:tag "JIT"]{字节码和即时（JIT）编译器}

@;{Every definition or expression to be evaluated by Racket is compiled
to an internal bytecode format. In interactive mode, this compilation
occurs automatically and on-the-fly. Tools like @exec{raco make} and
@exec{raco setup} marshal compiled bytecode to a file, so that you do
not have to compile from source every time that you run a
program. (Most of the time required to compile a file is actually in
macro expansion; generating bytecode from fully expanded code is
relatively fast.) See @secref["compile"] for more information on
generating bytecode files.}
每个将要被Racket求值的定义或表达式都被编译成一个内部字节码格式。
在交互模式下，这种编译是自动并即时进行。
同时，@exec{raco make}和@exec{raco setup}这样的工具将编译的字节码编组到一个文件中，
因此你每次运行一个程序时不必从源代码编译。
（编译一个文件的大部分时间实际上花费在宏扩展；从完全展开的代码生成的字节码是比较快的。）
参见@secref["compile"]获取生成字节码文件的更多信息。

@;{The bytecode compiler applies all standard optimizations, such as
constant propagation, constant folding, inlining, and dead-code
elimination. For example, in an environment where @racket[+] has its
usual binding, the expression @racket[(let ([x 1] [y (lambda () 4)]) (+
1 (y)))] is compiled the same as the constant @racket[5].}
字节码编译器应用所有标准的优化，比如常量传输、常量折叠、内联，和死代码消除。
例如，在一个@racket[+]有其通常绑定的环境中，
表达式@racket[(let ([x 1] [y (lambda () 4)]) (+ 1 (y)))]被编译成常量@racket[5]。

@;{On some platforms, bytecode is further compiled to native code via a
@deftech{just-in-time} or @deftech{JIT} compiler. The @tech{JIT}
compiler substantially speeds programs that execute tight loops,
arithmetic on small integers, and arithmetic on inexact real
numbers. Currently, @tech{JIT} compilation is supported for x86,
x86_64 (a.k.a. AMD64), ARM, and 32-bit PowerPC processors. The @tech{JIT}
compiler can be disabled via the @racket[eval-jit-enabled] parameter
or the @DFlag{no-jit}/@Flag{j} command-line flag for @exec{racket}.}
在一些平台上，字节码通过一个@deftech{just-in-time}编译器或者说@deftech{JIT}编译器进一步编译成本机代码。
@tech{JIT}编译器充分加快执行紧凑的循环的程序、小整数算法以及不精确实数算法。
目前，@tech{JIT}编译支持x86、x86_64（也叫作AMD64）、ARM和32位PowerPC处理器。
@tech{JIT}编译器可以通过@exec{racket}的@racket[eval-jit-enabled]参数或者@DFlag{no-jit}/@Flag{j}命令行标志禁用。

@;{The @tech{JIT} compiler works incrementally as functions are applied,
but the @tech{JIT} compiler makes only limited use of run-time
information when compiling procedures, since the code for a given
module body or @racket[lambda] abstraction is compiled only once. The
@tech{JIT}'s granularity of compilation is a single procedure body,
not counting the bodies of any lexically nested procedures. The
overhead for @tech{JIT} compilation is normally so small that it is
difficult to detect.}
@tech{JIT}编译器随着函数被调用逐步地工作，但是@tech{JIT}编译器在编译过程时只对运行时信息进行有限的使用，
因为给定的模块主体或@racket[lambda]表达式的代码只编译一次。@tech{JIT}的编译的粒度是单个的程序体，
不包含任何嵌套的程序的主体。@tech{JIT}编译的开销通常很小以致很难检测到。

@; ----------------------------------------------------------------------

@;{@section[#:tag "modules-performance"]{Modules and Performance}}
@section[#:tag "modules-performance"]{模块和性能}

@;{The module system aids optimization by helping to ensure that
identifiers have the usual bindings. That is, the @racket[+] provided
by @racketmodname[racket/base] can be recognized by the compiler and
inlined, which is especially important for @tech{JIT}-compiled code.
In contrast, in a traditional interactive Scheme system, the top-level
@racket[+] binding might be redefined, so the compiler cannot assume a
fixed @racket[+] binding (unless special flags or declarations
are used to compensate for the lack of a module system).}
模块系统通过帮助确保标识符具有通常的绑定来帮助优化。
那是，@racketmodname[racket/base]提供的@racket[+]可由编译器辨别并内联，
这对@tech{JIT}编译的代码是特别重要的。相反，在一个传统的交互式Scheme系统中，
顶层的@racket[+]绑定可能被重新定义，因此编译器不能假定一个固定的@racket[+]绑定（除非使用特殊的标志或声明来弥补模块系统的缺乏）。

@;{Even in the top-level environment, importing with @racket[require]
enables some inlining optimizations. Although a @racket[+] definition
at the top level might shadow an imported @racket[+], the shadowing
definition applies only to expressions evaluated later.}
即使在顶级环境中，带@racket[require]的导入使一些内联优化成为可能。
尽管一个在顶层的@racket[+]定义可能会对覆盖一个导入的@racket[+]，
但覆盖定义只适用于稍后求值的表达式。

@;{Within a module, inlining and constant-propagation optimizations take
additional advantage of the fact that definitions within a module
cannot be mutated when no @racket[set!] is visible at compile
time. Such optimizations are unavailable in the top-level
environment. Although this optimization within modules is important
for performance, it hinders some forms of interactive development and
exploration. The @racket[compile-enforce-module-constants] parameter
disables the @tech{JIT} compiler's assumptions about module
definitions when interactive exploration is more important. See
@secref["module-set"] for more information.}
在模块中，内联和常数传输优化采取额外的优势，因为模块中的定义无法改变值如果在编译时没有可见的@racket[set!]。
此类优化在顶层环境中不可用。虽然模块内的优化对性能很重要，但它也阻碍了一些交互式开发和探索的形式。
当交互式探索更重要时，@racket[compile-enforce-module-constants]参数禁用@tech{JIT}编译器关于模块定义的假设。
有关更多信息，请参阅@secref["module-set"]。

@;{The compiler may inline functions or propagate constants across module
boundaries. To avoid generating too much code in the case of function
inlining, the compiler is conservative when choosing candidates for
cross-module inlining; see @secref["func-call-performance"] for
information on providing inlining hints to the compiler.}
编译器可以内联函数或在模块边界上传播常量。为了避免在内联函数的情况下产生了太多的代码，
编译器会很保守地选择跨模块内联的候选人；参阅@secref["func-call-performance"]以了解更多关于提供给编译器的内联提示信息。

@;{The later section @secref["letrec-performance"] provides some
additional caveats concerning inlining of module bindings.}
后边的章节@secref["letrec-performance"]提供一些额外的关于模块绑定内联的附加说明。

@; ----------------------------------------------------------------------

@;{@section[#:tag "func-call-performance"]{Function-Call Optimizations}}
@section[#:tag "func-call-performance"]{函数调用优化}

@;{When the compiler detects a function call to an immediately visible
function, it generates more efficient code than for a generic call,
especially for tail calls. For example, given the program}
当编译器检测到一个对即时可见函数的调用时，它生成的代码比一般调用更高效，尤其对于尾部调用。例如，给定程序

@racketblock[
(letrec ([odd (lambda (x) 
                (if (zero? x) 
                    #f 
                    (even (sub1 x))))] 
         [even (lambda (x) 
                 (if (zero? x) 
                     #t 
                     (odd (sub1 x))))]) 
  (odd 40000000))
]

@;{the compiler can detect the @racket[odd]--@racket[even] loop and
produce code that runs much faster via loop unrolling and related
optimizations.}
编译器可以检测到@racket[odd]--@racket[even]循环并通过循环展开和相关的优化产生运行速度更快的代码。

@;{Within a module form, @racket[define]d variables are lexically scoped
like @racket[letrec] bindings, and definitions within a module
therefore permit call optimizations, so}
在一个模块表里，@racket[define]声明的变量有像@racket[letrec]绑定这样的词法作用域，并且在一个模块内的定义因此允许调用优化，那么

@racketblock[
(define (odd x) ....)
(define (even x) ....)
]

@;{within a module would perform the same as the @racket[letrec] version.}
在一个模块中的运行效果和@racket[letrec]的版本相同。

@;{For direct calls to functions with keyword arguments, the compiler can
typically check keyword arguments statically and generate a direct
call to a non-keyword variant of the function, which reduces the
run-time overhead of keyword checking. This optimization applies only
for keyword-accepting procedures that are bound with @racket[define].}
对于带有关键字参数的函数的直接调用，编译器通常可以静态检查关键字参数并生成一个对函数非关键字变体的直接调用，
从而减少关键字检查的运行时开销。此优化仅适用于用@racket[define]绑定的接受关键字的程序。

@;{For immediate calls to functions that are small enough, the compiler
may inline the function call by replacing the call with the body of
the function. In addition to the size of the target function's body,
the compiler's heuristics take into account the amount of inlining
already performed at the call site and whether the called function
itself calls functions other than simple primitive operations. When a
module is compiled, some functions defined at the module level are
determined to be candidates for inlining into other modules; normally,
only trivial functions are considered candidates for cross-module
inlining, but a programmer can wrap a function definition with
@racket[begin-encourage-inline] to encourage inlining
of the function.}
对于对足够小的函数的即时调用，编译器可以通过替换函数的主体成调用来内联函数调用。
除了目标函数体的大小之外，编译器也考虑了在调用位置已经执行的内联的数量以及被调用函数本身是否调用除简单基本操作之外的函数。
当一个模块被编译时，在模块层面定义的一些函数被确定为内联到其他模块的候选人；
通常情况下，只有较小的函数被认为是跨模块内联的候选人，
但开发者可以把函数定义在@racket[begin-encourage-inline]内来促进函数内联。

@;{Primitive operations like @racket[pair?], @racket[car], and
@racket[cdr] are inlined at the machine-code level by the @tech{JIT}
compiler. See also the later section @secref["fixnums+flonums"] for
information about inlined arithmetic operations.}
像@racket[pair?]、@racket[car]和@racket[cdr]这样的基础操作是在机器代码级被@tech{JIT}编译器内联。
参见后面的章节@secref["fixnums+flonums"]获取关于内联的算术运算的信息。

@; ----------------------------------------------------------------------

@;{@section{Mutation and Performance}}
@section[#:tag "Mutation_and_Performance"]{突变和性能}

@;{Using @racket[set!] to mutate a variable can lead to bad
performance. For example, the microbenchmark}
利用@racket[set!]突变一个变量会导致坏的性能。例如，小规模基准测试

@racketmod[
racket/base

(define (subtract-one x)
  (set! x (sub1 x))
  x)

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

@;{runs much more slowly than the equivalent}
比同等的慢得多

@racketmod[
racket/base

(define (subtract-one x)
  (sub1 x))

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

@;{In the first variant, a new location is allocated for @racket[x] on
every iteration, leading to poor performance. A more clever compiler
could unravel the use of @racket[set!] in the first example, but since
mutation is discouraged (see @secref["using-set!"]), the compiler's
effort is spent elsewhere.}
在第一个变量中，每次迭代都为@racket[x]分配一个新位置，导致性能不佳。一个更聪明的编译器可以解开在第一个示例中@racket[set!]的使用，由于不支持突变（参见@secref["using-set!"]），编译器的努力将花费在其它地方。

@;{More significantly, mutation can obscure bindings where inlining and
constant-propagation might otherwise apply. For example, in}
更重要的是，突变可以掩盖在内联和传播常数可能应用的绑定。例如，在

@racketblock[
(let ([minus1 #f])
  (set! minus1 sub1)
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (minus1 n)))))
]

@;{the @racket[set!] obscures the fact that @racket[minus1] is just
another name for the built-in @racket[sub1].}
@racket[set!]掩盖了一个事实：@racket[minus1]只是给内置的@racket[sub1]的另一个名字。

@; ----------------------------------------------------------------------

@;{@section[#:tag "letrec-performance"]{@racket[letrec] Performance}}
@section[#:tag "letrec-performance"]{@racket[letrec]性能}

@;{When @racket[letrec] is used to bind only procedures and literals,
then the compiler can treat the bindings in an optimal manner,
compiling uses of the bindings efficiently. When other kinds of
bindings are mixed with procedures, the compiler may be less able to
determine the control flow.}
当@racket[letrec]被用于仅绑定过程和字面量，那么编译器能够以最佳方式处理绑定，有效编译绑定的使用。当其它类型的绑定与程序混合时，编译器也许不太能确定控制流。

@;{For example,}
例如，

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [junk (display loop)]
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

@;{likely compiles to less efficient code than}
可能编译成比以下内容效率更低的代码

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

@;{In the first case, the compiler likely does not know that
@racket[display] does not call @racket[loop]. If it did, then
@racket[loop] might refer to @racket[next] before the binding is
available.}
在第一种情况下，编译器可能不知道@racket[display]不调用@racket[loop]。如果是，那么@racket[loop]可能在绑定成为可获得的之前引用@racket[next]。

@;{This caveat about @racket[letrec] also applies to definitions of
functions and constants as internal definitions or in modules. A
definition sequence in a module body is analogous to a sequence of
@racket[letrec] bindings, and non-constant expressions in a module
body can interfere with the optimization of references to later
bindings.}
这关于@racket[letrec]的附加说明也适用于作为内部定义或模块的函数和常量的定义。在一个模块主体中的一个定义序列类似于一个@racket[letrec]绑定序列，同时在一个模块主体中的非常数表达式可以用后期绑定引用的优化干涉。

@; ----------------------------------------------------------------------

@;{@section[#:tag "fixnums+flonums"]{Fixnum and Flonum Optimizations}}
@section[#:tag "fixnums+flonums"]{Fixnum和Flonum优化}

@;{A @deftech{fixnum} is a small exact integer. In this case, ``small''
depends on the platform. For a 32-bit machine, numbers that can be
expressed in 30 bits plus a sign bit are represented as fixnums. On a
64-bit machine, 62 bits plus a sign bit are available.}
一个@deftech{fixnum}是一个小的精确的整数。在这种情况下，“小”取决于平台。对于一个32位的机器，可以在30位加一个符号位表示的数字代表fixnum。在64位机器上，可用62位加一个符号位。

@;{A @deftech{flonum} is used to represent any inexact real number. They
correspond to 64-bit IEEE floating-point numbers on all platforms.}
一个@deftech{flonum}用来表示任何不精确实数。它们对应于所有平台上的64位IEEE浮点数。

@;{Inlined fixnum and flonum arithmetic operations are among the most
important advantages of the @tech{JIT} compiler. For example, when
@racket[+] is applied to two arguments, the generated machine code
tests whether the two arguments are fixnums, and if so, it uses the
machine's instruction to add the numbers (and check for overflow). If
the two numbers are not fixnums, then it checks whether
both are flonums; in that case, the machine's floating-point
operations are used directly. For functions that take any number of
arguments, such as @racket[+], inlining works for two or more
arguments (except for @racket[-], whose one-argument case is also
inlined) when the arguments are either all fixnums or all flonums.}
内联fixnum和flonum算术运算是@tech{JIT}编译器的最重要的好处。例如，当@racket[+]应用于两个参数，生成的机器代码的测试是否两参数是fixnum，如果是的话，它使用机器的指令添加数字（和溢出检查）。如果这两个数字都不fixnum，然后检查是否都flonum；在这种情况下，直接使用机器的浮点运算。当参数既是所有fixnum也是flonum时，对于函数可以接受任意数量的参数，如@racket[+]、对两个或两个以上参数的内联工作（除@racket[-]之外，其争论的焦点之一是内联）。

@;{Flonums are typically @defterm{boxed}, which means that memory is
allocated to hold every result of a flonum computation. Fortunately,
the generational garbage collector (described later in
@secref["gc-perf"]) makes allocation for short-lived results
reasonably cheap. Fixnums, in contrast are never boxed, so they are
typically cheap to use.}
flonum通常是@defterm{被装箱（boxed）}，这意味着内存被分配以容纳每一个flonum计算结果。幸运的是，世代的垃圾收集器（稍后在@secref["gc-perf"]中描述）为较短的结果廉价地做分配。fixnum相比之下没有被装箱，所以他们通常廉价地使用。

@;{@margin-note{See @secref["effective-futures"] for an example use of
@tech{flonum}-specific operations.}}
@margin-note{见@secref["effective-futures"]以了解一个@tech{flonum}具体操作的使用例子。}

@;{The @racketmodname[racket/flonum] library provides flonum-specific
operations, and combinations of flonum operations allow the @tech{JIT}
compiler to generate code that avoids boxing and unboxing intermediate
results. Besides results within immediate combinations,
flonum-specific results that are bound with @racket[let] and consumed
by a later flonum-specific operation are unboxed within temporary
storage. Finally, the compiler can detect some flonum-valued loop
accumulators and avoid boxing of the accumulator. The bytecode
decompiler (see @secref[#:doc '(lib "scribblings/raco/raco.scrbl")
"decompile"]) annotates combinations where the JIT can avoid boxes with
@racketidfont{#%flonum}, @racketidfont{#%as-flonum}, and
@racketidfont{#%from-flonum}.}
@racketmodname[racket/flonum]库提供flonum具体操作，以及flonum操作的组合允许@tech{JIT}编译器生成代码，它避免装箱和拆箱的中间结果。除了在即时的组合里结果，用@racket[let]绑定并被一个后来的具体flonum操作接受的flonum具体结果在临时存储之中被开箱。最后，编译器可以检测一些flonum值循环收集器并避免收集器的装箱。字节码反编译器（见@secref[#:doc '(lib "scribblings/raco/raco.scrbl")
"decompile"]）诠释组合，那里JIT可以避免用@racketidfont{#%flonum}、@racketidfont{#%as-flonum}和@racketidfont{#%from-flonum}装箱。

@;{@margin-note{Unboxing of local bindings and accumulators is not
supported by the JIT for PowerPC.}}
@margin-note{局部绑定和收集器的拆箱不被PowerPC的JIT支持。}

@;{The @racketmodname[racket/unsafe/ops] library provides unchecked
fixnum- and flonum-specific operations. Unchecked flonum-specific
operations allow unboxing, and sometimes they allow the compiler to
reorder expressions to improve performance. See also
@secref["unchecked-unsafe"], especially the warnings about unsafety.}
@racketmodname[racket/unsafe/ops]库提供未经检查的fixnum和flonum具体操作。未经检查的的flonum具体操作允许拆箱，并且有时它们允许编译器重排表达式来提高性能。也参见@secref["unchecked-unsafe"]，特别是关于不安全的警告。

@; ----------------------------------------------------------------------

@;{@section[#:tag "unchecked-unsafe"]{Unchecked, Unsafe Operations}}
@section[#:tag "unchecked-unsafe"]{未检查的、不安全的操作}

@;{The @racketmodname[racket/unsafe/ops] library provides functions that
are like other functions in @racketmodname[racket/base], but they
assume (instead of checking) that provided arguments are of the right
type. For example, @racket[unsafe-vector-ref] accesses an element from
a vector without checking that its first argument is actually a vector
and without checking that the given index is in bounds. For tight
loops that use these functions, avoiding checks can sometimes speed
the computation, though the benefits vary for different unchecked
functions and different contexts.}
@racketmodname[racket/unsafe/ops]库提供类似于@racketmodname[racket/base]里的其它函数的函数，但它们假设（而不是检查）提供的参数是正确的类型。例如，@racket[unsafe-vector-ref]从一个向量中访问一个元素，而不检查它的第一个参数实际上是一个向量，而不检查给定的索引是否处于界限之内。对于使用这些函数的紧循环，避免检查有时可以加快计算速度，尽管不同的未检查函数和不同上下文的好处有所不同。

@;{Beware that, as ``unsafe'' in the library and function names suggest,
misusing the exports of @racketmodname[racket/unsafe/ops] can lead to
crashes or memory corruption.}
要小心的是，如同在库和函数名建议中的“不安全”，滥用@racketmodname[racket/unsafe/ops]导出会导致崩溃或内存损坏。

@; ----------------------------------------------------------------------

@;{@section[#:tag "ffi-pointer-access"]{Foreign Pointers}}
@section[#:tag "ffi-pointer-access"]{外来的指针}

@;{The @racketmodname[ffi/unsafe] library provides functions for unsafely
reading and writing arbitrary pointer values. The JIT recognizes uses
of @racket[ptr-ref] and @racket[ptr-set!] where the second argument is
a direct reference to one of the following built-in C types:
@racket[_int8], @racket[_int16], @racket[_int32], @racket[_int64],
@racket[_double], @racket[_float], and @racket[_pointer]. Then, if the
first argument to @racket[ptr-ref] or @racket[ptr-set!] is a C pointer
(not a byte string), then the pointer read or write is performed
inline in the generated code.}
@racketmodname[ffi/unsafe]库提供非安全读写任意指针值的函数。JIT承认@racket[ptr-ref]和@racket[ptr-set!]的使用其在第二个参数是一个对下面的一个内置C类型的直接引用：@racket[_int8]、@racket[_int16]、@racket[_int32]、@racket[_int64]、@racket[_double]、@racket[_float]和@racket[_pointer]。然后，，然后在生成的代码中执行指针读写操作。

@;{The bytecode compiler will optimize references to integer
abbreviations like @racket[_int] to C types like
@racket[_int32]---where the representation sizes are constant across
platforms---so the JIT can specialize access with those C types. C
types such as @racket[_long] or @racket[_intptr] are not constant
across platforms, so their uses are currently not specialized by the
JIT.}
字节码编译器会优化涉及整数的缩写的引用，像@racket[_int]对C类型像@racket[_int32]——其表现大小是静态的跨平台——所以JIT可以专门用那些C类型访问。C类型如@racket[_long]或@racket[_intptr]不是静态的跨平台使用，所以它们的使用目前没有被JIT专门化。

@;{Pointer reads and writes using @racket[_float] or @racket[_double] are
not currently subject to unboxing optimizations.}
指针使用@racket[_float]或@racket[_double]读取和写入目前没有受到拆箱的优化。

@; ----------------------------------------------------------------------

@;{@section[#:tag "regexp-perf"]{Regular Expression Performance}}
@section[#:tag "regexp-perf"]{正则表达式性能}

@;{When a string or byte string is provided to a function like
@racket[regexp-match], then the string is internally compiled into
a @tech{regexp} value. Instead of supplying a string or byte string
multiple times as a pattern for matching, compile the pattern once to
a @tech{regexp} value using @racket[regexp], @racket[byte-regexp],
@racket[pregexp], or @racket[byte-pregexp]. In place of a constant
string or byte string, write a constant @tech{regexp} using an
@litchar{#rx} or @litchar{#px} prefix.}
当一个字符串或字节字符串提供一个类似@racket[regexp-match]的函数，然后这个字符串被内部编译成一个@tech{regexp}值。而是多次提供一个字符串或字节字符串作为一个匹配的模式，编译这个模式一次成为一个使用@racket[regexp]、@racket[byte-regexp]、@racket[pregexp]或@racket[byte-pregexp]的@tech{regexp}值。在一个常量字符串或字节字符串的地方，使用@litchar{#rx}或@litchar{#px}前缀写一个常数@tech{regexp}。

@racketblock[
(define (slow-matcher str)
  (regexp-match? "[0-9]+" str))

(define (fast-matcher str)
  (regexp-match? #rx"[0-9]+" str))

(define (make-slow-matcher pattern-str)
  (lambda (str)
    (regexp-match? pattern-str str)))

(define (make-fast-matcher pattern-str)
  (define pattern-rx (regexp pattern-str))
  (lambda (str)
    (regexp-match? pattern-rx str)))
]


@; ----------------------------------------------------------------------

@;{@section[#:tag "gc-perf"]{Memory Management}}
@section[#:tag "gc-perf"]{内存管理}

@;{The Racket implementation is available in two variants: @deftech{3m} and
@deftech{CGC}. The @tech{3m} variant uses a modern,
@deftech{generational garbage collector} that makes allocation
relatively cheap for short-lived objects. The @tech{CGC} variant uses
a @deftech{conservative garbage collector} which facilitates
interaction with C code at the expense of both precision and speed for
Racket memory management. The 3m variant is the standard one.}
Racket的实现在两个变种方面有表现：@tech{3m}和@deftech{CGC}。@tech{3m}变种使用了现代的@deftech{generational garbage collector（一代垃圾收集器）}，使得对短生存期对象的分配相对便宜。@tech{CGC}变种使用一个@deftech{conservative garbage collector（保守的垃圾收集器）}便于交互的C代码在Racket内存管理的精度和速度上的开销。3m变体是标准的。

@;{Although memory allocation is reasonably cheap, avoiding allocation
altogether is normally faster. One particular place where allocation
can be avoided sometimes is in @deftech{closures}, which are the
run-time representation of functions that contain free variables.
For example,}
虽然内存分配相当便宜，但避免完全分配通常更快。有时可以避免分配的一个特殊位置是在闭包中，这是包含自由变量函数的运行时表示。例如,

@racketblock[
(let loop ([n 40000000] [prev-thunk (lambda () #f)])
  (if (zero? n)
      (prev-thunk)
      (loop (sub1 n)
            (lambda () n))))
]

@;{allocates a closure on every iteration, since @racket[(lambda () n)]
effectively saves @racket[n].}
在每个迭代中分配一个闭包，因为@racket[(lambda () n)]有效地保存@racket[n]。

@;{The compiler can eliminate many closures automatically. For example,
in}
编译器可以自动清除许多闭包。例如，在

@racketblock[
(let loop ([n 40000000] [prev-val #f])
  (let ([prev-thunk (lambda () n)])
    (if (zero? n)
        prev-val
        (loop (sub1 n) (prev-thunk)))))
]

@;{no closure is ever allocated for @racket[prev-thunk], because its only
application is visible, and so it is inlined. Similarly, in}
中没有闭包被永远分配给@racket[prev-thunk]，因为只有应用程序是可见的，所以它是内联的。同样，在

@racketblock[
(let n-loop ([n 400000])
  (if (zero? n)
      'done
      (let m-loop ([m 100])
        (if (zero? m)
            (n-loop (sub1 n))
            (m-loop (sub1 m))))))
]

@;{then the expansion of the @racket[let] form to implement
@racket[m-loop] involves a closure over @racket[n], but the compiler
automatically converts the closure to pass itself @racket[n] as an
argument instead.}
中，那么@racket[let]的扩展表实现@racket[m-loop]包含一个n上的闭包，但编译器自动将闭包转变以传递给自己的@racket[n]而不是作为一个参数。

@;{@section[#:tag "Reachability and Garbage Collection"]{Reachability and Garbage Collection}}
@section[#:tag "Reachability and Garbage Collection"]{可执行性与垃圾收集}

@;{In general, Racket re-uses the storage for a value when the
garbage collector can prove that the object is unreachable from
any other (reachable) value. Reachability is a low-level, 
abstraction breaking concept (and thus one must understand many
details of the runtime system's implementation to accurate predicate
precisely when values are reachable from each other),
but generally speaking one value is reachable from a second one when 
there is some operation to recover the original value from the second
one.}
一般来说，当垃圾收集器可以证明对象与其它（可执行到的）值执行不到时，Racket重新使用存储值。可执行性（reachability）是一个低级别的抽象概念，打破概念抽象（因此，当值彼此是可执行到的时，必须准确理解运行时系统实现的许多细节，以便准确地判断。），但一般来说，当有一些操作从第二个恢复原始值时，可以从第二个值中获得一个值。 

@;{To help programmers understand when an object is no longer reachable and its
storage can be reused,
Racket provides @racket[make-weak-box] and @racket[weak-box-value],
the creator and accessor for a one-record struct that the garbage
collector treats specially. An object inside a weak box does not count
as reachable, and so @racket[weak-box-value] might return the object
inside the box, but it might also return @racket[#f] to indicate
that the object was otherwise unreachable and garbage collected.
Note that unless a garbage collection actually occurs, the value will
remain inside the weak box, even if it is unreachable.}
为了帮助程序员了解什么时候一个对象不再是可执行到的以及什么时候它的存储可以重复使用，Racket提供@racket[make-weak-box]和@racket[weak-box-value]，创建者和访问者针对垃圾收集器专门处理的一个记录结构。在弱格子中的一个对象不算作可执行到的，所以@racket[weak-box-value]可能返回格子里的对象，但它也可以返回@racket[#f]标示对象不可执行到同时垃圾被收集。注意，除非实际发生垃圾收集，否则该值将保持在弱格子中，即使它是不可执行到的。

@;{For example, consider this program:}
例如，考虑这个程序：

@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]

@;{It will print @litchar{b has #(struct:fish 7 blue)} twice because the
definition of @racket[f] still holds onto the fish. If the program
were this, however:}
因为@racket[f]的定义仍然保存着fish，它将打印@litchar{b has #(struct:fish 7 blue)}两次。然而，如果程序是这样的话：

@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (set! f #f)
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]

@;{the second printout will be @litchar{b has #f} because
no reference to the fish exists (other than the one in the box).}
第二个打印输出将是@litchar{b has #f}，因为没有对fish的引用存在（除了格子里的那个）。

@;{As a first approximation, all values in Racket must be allocated and will
demonstrate behavior similar to the fish above.
There are a number of exceptions, however:}
作为第一个近似值，Racket中的所有值都必须分配，并且会显示出与上面的fish相似的行为。然而，也有一些例外：

@;{@itemlist[
 @item{Small integers (recognizable with @racket[fixnum?]) are
                always available without explicit
                allocation. From the perspective of the garbage collector
                and weak boxes, their storage is never reclaimed. (Due to
                clever representation techniques, however, their storage
                does not count towards the space that Racket uses.
                That is, they are effectively free.)}
    
         @item{Procedures where
               the compiler can see all of their call sites may never be
               allocated at all (as discussed above). 
               Similar optimizations may also eliminate 
               the allocation for other kinds of values.}
         @item{Interned symbols are allocated only once (per place). A table inside
               Racket tracks this allocation so a symbol may not become garbage
               because that table holds onto it.}
         @item{Reachability is only approximate with the @tech{CGC} collector (i.e.,
               a value may appear reachable to that collector when there is,
               in fact, no way to reach it anymore.}]}
{@itemlist[
@item{小整数（用@racket[fixnum?]识别）总是没有明确分配的情况下可用。从垃圾收集器和弱格子的角度来看，它们的存储永远不会被回收。（然而，由于巧妙的表现技巧，它们的存储并不等于Racket的使用空间。也就是说，它们实际上是免费的。）}
@item{编译器可以看到所有调用站点的过程可能永远不会分配（如上所述）。类似的优化也可以消除对其他类型值的分配。}
@item{拘禁符号仅分配一次（如上所述）。Racket内部的表格跟踪这个分配，所以一个符号不能变成垃圾，因为那张表格保存着它。}
@item{可执行性是近似于@tech{CGC}收集器（即当有一个收集器的时候，一个值可以对那个收集器表现为可执行到的，事实上，再没有办法抓到它了。}]

@;{@section{Weak Boxes and Testing}}
@section[#:tag "Weak_Boxes_and_Testing"]{弱格子与测试}

@;{One important use of weak boxes is in testing that some abstraction properly 
releases storage for data it no longer needs, but there is a gotcha that 
can easily cause such test cases to pass improperly. }
弱格子的一个重要用途是在测试一些抽象地释放不再需要的存储数据，但是有一个问题，它很容易造成这样的测试用例不当通过。

@;{Imagine you're designing a data structure that needs to
hold onto some value temporarily but then should clear a field or
somehow break a link to avoid referencing that value so it can be
collected. Weak boxes are a good way to test that your data structure
properly clears the value. This is, you might write a test case
that builds a value, extracts some other value from it
(that you hope becomes unreachable), puts the extracted value into a weak-box,
and then checks to see if the value disappears from the box.}
假设您正在设计一个数据结构，它需要暂时保存某个值，但应清除一个字段或以某种方式中断一个链接以避免引用该值，以便收集该值。弱格子是测试数据结构正确清除值的好方法。也就是说，你可以编写一个构建一个值的测试用例，从中提取一些值（希望成为不可执行到的），将提取的值放入一个弱格子中，然后检查该值是否从该格子中消失。

@;{This code is one attempt to follow that pattern, but it has a subtle bug:}
这段代码是一种对于遵循这种模式的尝试，但它有一个微妙的bug：

@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb)))]

@;{Specifically, it will show that the weak box is empty, but not
because @racket[_fishes] no longer holds onto the value, but
because @racket[_fishes] itself is not reachable anymore!}
具体来说，它会显示弱格子是空的，但不是因为@racket[_fishes]不再保存这个值，而是因为@racket[_fishes]本身不再是可执行到的！

@;{Change the program to this one:}
把程序改成这个：

@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb))
             (printf "fishes is ~s\n" fishes))]

@;{and now we see the expected result. The difference is that last
occurrence of the variable @racket[_fishes]. That constitutes
a reference to the list, ensuring that the list is not itself
garbage collected, and thus the red fish is not either.}
并且现在我们看到了预期的结果。不同的是，最后一次发生的变量的@racket[_fishes]。这就构成了一个对列表的引用，确保列表本身不是垃圾收集的，因此red的fish也不是。

@;{@section{Reducing Garbage Collection Pauses}}
@section[#:tag "Reducing_Garbage_Collection_Pauses"]{减少垃圾收集停顿}

@;{By default, Racket's @tech{generational garbage collector} creates
brief pauses for frequent @deftech{minor collections}, which inspect
only the most recently allocated objects, and long pauses for infrequent
@deftech{major collections}, which re-inspect all memory.}
默认情况下，Racket的@tech{分代垃圾收集器（generational garbage collector）}因为频繁的@deftech{小收集（minor collections）}而产生短暂的停顿，这些小收集只检查最近分配的对象，并对稀少的@deftech{大收集（major collections）}进行长时间停顿，这些大收集重新检查所有内存。

@;{For some applications, such as animations and games,
long pauses due to a major collection can interfere
unacceptably with a program's operation. To reduce major-collection
pauses, the Racket garbage collector supports @deftech{incremental
garbage-collection} mode. In incremental mode, minor collections
create longer (but still relatively short) pauses by performing extra
work toward the next major collection. If all goes well, most of a
major collection's work has been performed by minor collections the
time that a major collection is needed, so the major collection's
pause is as short as a minor collection's pause. Incremental mode
tends to run more slowly overall, but it can
provide much more consistent real-time behavior.}
对于某些应用程序，如动画和游戏，由于大收集而产生的长时间停顿会用一个程序操作不可接受地干预。为了减少主要的收集停顿，Racket垃圾收集器支持@deftech{增量垃圾收集（incremental
garbage-collection）}模式。在增量模式中，小收集通过对下一个大收集执行额外的工作来造成更长（但仍然相对较短）的停顿。如果一切顺利，大多数大收集的工作都是由一个大收集被需要的小收集时间完成的，所以大收集的停顿和小收集的停顿一样短暂。增量模式总体上运行速度较慢，但它可以提供更一致的实时行为。

@;{If the @envvar{PLT_INCREMENTAL_GC} environment variable is set
to a value that starts with @litchar{1}, @litchar{y}, or @litchar{Y}
when Racket starts, incremental mode is permanently enabled. Since
incremental mode is only useful for certain parts of some programs,
however, and since the need for incremental mode is a property of a
program rather than its environment, the preferred way to enable
incremental mode is with @racket[(collect-garbage 'incremental)].}
当Racket启动时，如果@envvar{PLT_INCREMENTAL_GC}环境变量被设置成一个值，它从@litchar{1}、@litchar{y}或@litchar{Y}开始，增量模式是永久启用。然而，由于增量模式只对某些程序的某些部分有用，并且由于增量模式的需要是程序的一个属性而不是其环境，所以启用增量模式的首选方式是@racket[(collect-garbage 'incremental)]。

@;{Calling @racket[(collect-garbage 'incremental)] does not perform an
immediate garbage collection, but instead requests that each minor
collection perform incremental work up to the next major collection.
The request expires with the next major collection. Make a call to
@racket[(collect-garbage 'incremental)] in any repeating task within
an application that needs to be responsive in real time. Force a
full collection with @racket[(collect-garbage)] just before an initial
@racket[(collect-garbage 'incremental)] to initiate incremental mode
from an optimal state.}
调用@racket[(collect-garbage 'incremental)]不会执行一个立即垃圾收集，而是请求每个小收集执行增量工作到下一个大收集。请求失效于下一个大收集。在需要实时响应的一个应用程序里的任何重复任务中制造一个对@racket[(collect-garbage 'incremental)]的调用。在一个初始的@racket[(collect-garbage 'incremental)]之前强制一个用@racket[(collect-garbage)]的完全收集以从最佳状态启动增量模式。

@;{To check whether incremental mode is use and how it affects pause
times, enable @tt{debug}-level logging output for the
@racketidfont{GC} topic. For example,}
要检查增量模式是否使用以及它如何影响暂停时间，使@tt{debug}级日志能够为@racketidfont{GC}主题输出。例如,

@commandline{racket -W "debuG@"@"GC error" main.rkt}

@;{runs @filepath{main.rkt} with garbage-collection logging to stderr
(while preserving @tt{error}-level logging for all topics). Minor
collections are reported by @litchar{min} lines, increment-mode minor
collection are reported with @litchar{mIn} lines, and major
collections are reported with @litchar{MAJ} lines.}
用垃圾收集日志对标准错误（stderr）运行@filepath{main.rkt}（同时保持为所有主题的@tt{error}级记录）。小收集是由@litchar{min（分钟）}线报告，增量模式小收集用 @litchar{mIn}线报告，大收集用@litchar{MAJ（专业）}线报告。
