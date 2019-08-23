#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@;{@title[#:tag "for"]{Iterations and Comprehensions}}
@title[#:tag "for"]{迭代和推导}

@;{The @racket[for] family of syntactic forms support iteration over
@defterm{sequences}. Lists, vectors, strings, byte strings, input
ports, and hash tables can all be used as sequences, and constructors
like @racket[in-range] offer even more kinds of sequences.}
用于语法形式的@racket[for]家族支持对@defterm{序列（sequences）}进行迭代。列表、向量、字符串、字节字符串、输入端口和散列表都可以用作序列，像@racket[in-range]的构造函数可以提供更多类型的序列。

@;{Variants of @racket[for] accumulate iteration results in different
ways, but they all have the same syntactic shape. Simplifying for
now, the syntax of @racket[for] is}
@racket[for]的变种以不同的方式累积迭代结果，但它们都具有相同的语法形态。 现在简化了，for的语法是

@specform[
(for ([id sequence-expr] ...)
  body ...+)
]{}

@;{A @racket[for] loop iterates through the sequence produced by the
@racket[_sequence-expr]. For each element of the sequence,
@racket[for] binds the element to @racket[_id], and then it evaluates
the @racket[_body]s for side effects.}
@racket[for]循环遍历由@racket[_sequence-expr]生成的序列。 对于序列的每个元素，@racket[for]将元素绑定到@racket[_id]，然后副作用求值@racket[_body]。

@examples[
(for ([i '(1 2 3)])
  (display i))
(for ([i "abc"])
  (printf "~a..." i))
(for ([i 4])
  (display i))
]

@;{The @racket[for/list] variant of @racket[for] is more Racket-like. It
accumulates @racket[_body] results into a list, instead of
evaluating @racket[_body] only for side effects. In more
technical terms, @racket[for/list] implements a @defterm{list
comprehension}.}
@racket[for]的@racket[for/list]变体更像Racket。它将@racket[_body]结果累积到列表中，而不是仅仅副作用求值@racket[_body]。 在更多的技术术语中，@racket[for/list]实现了@defterm{列表理解（list
comprehension）}。

@examples[
(for/list ([i '(1 2 3)])
  (* i i))
(for/list ([i "abc"])
  i)
(for/list ([i 4])
  i)
]

@;{The full syntax of @racket[for] accommodates multiple sequences to
iterate in parallel, and the @racket[for*] variant nests the
iterations instead of running them in parallel. More variants of
@racket[for] and @racket[for*] accumulate @racket[_body] results
in different ways.  In all of these variants, predicates that prune
iterations can be included along with bindings.}
@racket[for]的完整语法可容纳多个序列并行迭代，@racket[for*]变体可以嵌套迭代，而不是并行运行。 @racket[for]和@racket[for*]的更多变体以不同的方式产生积累@racket[_body]结果。 在所有这些变体中，包含迭代的判断可以同时包含绑定。

@;{Before details on the variations of @racket[for], though, it's best to
see the kinds of sequence generators that make interesting examples.}
不过，在@racket[for]的变体细节之前，最好是先查看生成有趣示例的序列生成器的类型。

@;{@section[#:tag "sequences"]{Sequence Constructors}}
@section[#:tag "sequences"]{序列构造器}

@;{The @racket[in-range] function generates a sequence of numbers, given
an optional starting number (which defaults to @racket[0]), a number
before which the sequence ends, and an optional step (which defaults
to @racket[1]). Using a non-negative integer @racket[_k] directly as 
a sequence is a shorthand for @racket[(in-range _k)].}
@racket[in-range]函数生成数值序列，给定可选的起始数字（默认为@racket[0]），序列结束前的数字和可选的步长（默认为@racket[1]）。 直接使用非负整数@racket[_k]作为序列是对@racket[(in-range _k)]的简写。

@examples[
(for ([i 3])
  (display i))
(for ([i (in-range 3)])
  (display i))
(for ([i (in-range 1 4)])
  (display i))
(for ([i (in-range 1 4 2)])
  (display i))
(for ([i (in-range 4 1 -1)])
  (display i))
(for ([i (in-range 1 4 1/2)])
  (printf " ~a " i))
]

@;{The @racket[in-naturals] function is similar, except that the
starting number must be an exact non-negative integer (which defaults
to @racket[0]), the step is always @racket[1], and there is no upper
limit. A @racket[for] loop using just @racket[in-naturals] will never
terminate unless a body expression raises an exception or otherwise
escapes.}
@racket[in-naturals]函数是相似的，除了起始数字必须是确切的非负整数（默认为@racket[0]），步长总是@racket[1]，没有上限。@racket[for]循环只使用@racket[in-naturals]将永远不会终止，除非正文表达引发异常或以其它方式退出。

@examples[
(for ([i (in-naturals)])
  (if (= i 10)
      (error "too much!")
      (display i)))
]

@;{The @racket[stop-before] and @racket[stop-after] functions construct
a new sequence given a sequence and a predicate. The new sequence is
like the given sequence, but truncated either immediately before or
immediately after the first element for which the predicate returns
true.}
@racket[stop-before]函数和@racket[stop-after]函数构造给定序列和判断的新的序列。这个新序列就像这个给定的序列，但是在判断返回true的第一个元素之前或之后立即被截断。

@examples[
(for ([i (stop-before "abc def"
                      char-whitespace?)])
  (display i))
]

@;{Sequence constructors like @racket[in-list], @racket[in-vector] and
@racket[in-string] simply make explicit the use of a list, vector, or
string as a sequence. Along with @racket[in-range],
these constructors raise an exception when given the
wrong kind of value, and since they otherwise avoid a run-time
dispatch to determine the sequence type, they enable more efficient
code generation; see @secref["for-performance"] for more information.}
像@racket[in-list]、@racket[in-vector]和@racket[in-string]这样的序列构造器只是简单地使用列表（list）、向量（vector）和字符串（string）作为序列。和@racket[in-range]一样，这些构造器在给定错误类型的值时会引发异常，并且由于它们会避免运行时调度来确定序列类型，因此可以实现更高效的代码生成; 有关更多信息，请参阅@secref["for-performance"]。

@examples[
(for ([i (in-string "abc")])
  (display i))
(for ([i (in-string '(1 2 3))])
  (display i))
]

@;@refdetails["sequences"]{序列}

@;{@section{@racket[for] and @racket[for*]}}
@section[#:tag "for-and-for"]{@racket[for]和@racket[for*]}

@;{A more complete syntax of @racket[for] is}
更完整的@racket[for]语法是

@specform/subs[
(for (clause ...)
  body ...+)
([clause [id sequence-expr]
         (code:line #:when boolean-expr)
         (code:line #:unless boolean-expr)])
]{}

@;{When multiple @racket[[_id _sequence-expr]] clauses are provided
in a @racket[for] form, the corresponding sequences are traversed in
parallel:}
当多个@racket[[_id _sequence-expr]]子句在一个@racket[for]表里提供时，相应的序列并行遍历：

@interaction[
(for ([i (in-range 1 4)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

@;{With parallel sequences, the @racket[for] expression stops iterating
when any sequence ends. This behavior allows @racket[in-naturals],
which creates an infinite sequence of numbers, to be used for
indexing:}
对于并行序列，@racket[for]表达式在任何序列结束时停止迭代。这种行为允许@racket[in-naturals]创造数值的无限序列，可用于索引：

@interaction[
(for ([i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

@;{The @racket[for*] form, which has the same syntax as @racket[for],
nests multiple sequences instead of running them in parallel:}
@racket[for*]表具有与 @racket[for]相同的语法，嵌套多个序列，而不是并行运行它们：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

@;{Thus, @racket[for*] is a shorthand for nested @racket[for]s in the
same way that @racket[let*] is a shorthand for nested @racket[let]s.}
因此，@racket[for*]是对嵌套@racket[for]的一个简写，以同样的方式@racket[let*]是一个@racket[let]嵌套的简写。

@;{The @racket[#:when _boolean-expr] form of a @racket[_clause] is
another shorthand. It allows the @racket[_body]s to evaluate only
when the @racket[_boolean-expr] produces a true value:}
@racket[_clause]的@racket[#:when _boolean-expr]表是另一个简写。仅当@racket[_boolean-expr]产生一个真值时它允许@racket[_body]求值：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")]
       #:when (not (equal? chapter "Details")))
  (printf "~a ~a\n" book chapter))
]

@;{A @racket[_boolean-expr] with @racket[#:when] can refer to any of the
preceding iteration bindings. In a @racket[for] form, this scoping
makes sense only if the test is nested in the iteration of the
preceding bindings; thus, bindings separated by @racket[#:when] are
mutually nested, instead of in parallel, even with @racket[for].}
带@racket[#:when]的@racket[_boolean-expr]可以适用于任何上述迭代绑定。在@racket[for]表里，仅仅如果在前面绑定的迭代测试是嵌套的时，这个范围是有意义的；因此，用@racket[#:when]隔离绑定是多重嵌套的，而不是平行的，甚至于用@racket[for]也一样。

@interaction[
(for ([book '("Guide" "Reference" "Notes")]
      #:when (not (equal? book "Notes"))
      [i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion" "Index")]
      #:when (not (equal? chapter "Index")))
  (printf "~a Chapter ~a. ~a\n" book i chapter))
]

@;{An @racket[#:unless] clause is analogus to a @racket[#:when] clause, but
the @racket[_body]s evaluate only when the @racket[_boolean-expr]
produces a false value.}
@racket[#:unless]子句和@racket[#:when]子句是类似的，但仅当@racket[_boolean-expr]产生非值时对@racket[_body]求值。

@;{@section{@racket[for/list] and @racket[for*/list]}}
@section[#:tag "for|list-and-for|list"]{@racket[for/list]和@racket[for*/list]}

@;{The @racket[for/list] form, which has the same syntax as @racket[for],
evaluates the @racket[_body]s to obtain values that go into a
newly constructed list:}
@racket[for/list]表具有与@racket[for]相同的语法，它对 @racket[_body]求值以获取进入新构造列表的值：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@;{A @racket[#:when] clause in a @racket[for-list] form prunes the result
list along with evaluations of the @racket[_body]s:}
@racket[for-list]表的@racket[#:when]子句跟@racket[_body]求值一起修剪结果列表：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")]
           #:when (odd? i))
  chapter)
]

@;{This pruning behavior of @racket[#:when] is more useful with
@racket[for/list] than @racket[for]. Whereas a plain @racket[when]
form normally suffices with @racket[for], a @racket[when] expression
form in a @racket[for/list] would cause the result list to contain
@|void-const|s instead of omitting list elements.}
使用@racket[for/list]的@racket[#:when]修剪行为比@racket[for]更有用。而对@racket[for]来说直接的@racket[when]表通常是满足需要的，@racket[for/list]里的@racket[when]表达式表会导致结果列表包含 @|void-const|以代替省略列表元素。

@;{The @racket[for*/list] form is like @racket[for*], nesting multiple
iterations:}
@racket[for*/list]表类似于@racket[for*]，嵌套多个迭代：

@interaction[
(for*/list ([book '("Guide" "Ref.")]
            [chapter '("Intro" "Details")])
  (string-append book " " chapter))
]

@;{A @racket[for*/list] form is not quite the same thing as nested
@racket[for/list] forms. Nested @racket[for/list]s would produce a
list of lists, instead of one flattened list. Much like
@racket[#:when], then, the nesting of @racket[for*/list] is more
useful than the nesting of @racket[for*].}
@racket[for*/list]表与嵌套@racket[for/list]表不太一样。嵌套的@racket[for/list]将生成一个列表的列表，而不是一个简单列表。非常类似于@racket[#:when]，而且，@racket[for*/list]的嵌套比@racket[for*]的嵌套更有用。

@;{@section{@racket[for/vector] and @racket[for*/vector]}}
@section[#:tag "for|vector-and-for|vector"]{@racket[for/vector] and @racket[for*/vector]}

@;{The @racket[for/vector] form can be used with the same syntax as the
@racket[for/list] form, but the evaluated @racket[_body]s go into a
newly-constructed vector instead of a list:}
@racket[for/vector]表可以使用与@racket[for/list]表相同的语法，但是对@racket[_body]的求值放入一个新构造的向量而不是列表：

@interaction[
(for/vector ([i (in-naturals 1)]
             [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@;{The @racket[for*/vector] form behaves similarly, but the iterations are
nested as in @racket[for*].}
@racket[for*/vector]表的行为类似，但迭代和@racket[for*]一样嵌套。

@;{The @racket[for/vector] and @racket[for*/vector] forms also allow the
length of the vector to be constructed to be supplied in advance.  The
resulting iteration can be performed more efficiently than plain
@racket[for/vector] or @racket[for*/vector]:}
在预先提供的情况下，@racket[for/vector]和@racket[for*/vector]表也允许构造向量的长度。由此产生的迭代可以比直接的@racket[for/vector]或@racket[for*/vector]更有效地执行：

@interaction[
(let ([chapters '("Intro" "Details" "Conclusion")])
  (for/vector #:length (length chapters) ([i (in-naturals 1)]
                                          [chapter chapters])
    (string-append (number->string i) ". " chapter)))
]

@;{If a length is provided, the iteration stops when the vector is filled
or the requested iterations are complete, whichever comes first.  If
the provided length exceeds the requested number of iterations, then
the remaining slots in the vector are initialized to the default
argument of @racket[make-vector].}
如果提供了长度，当向量被填充或被请求完成时迭代停止，而无论哪个先来。如果所提供的长度超过请求的迭代次数，则向量中的剩余位置被初始化为@racket[make-vector]的缺省参数。

@;{@section{@racket[for/and] and @racket[for/or]}}
@section[#:tag "for|and-and-for|or"]{@racket[for/and]和@racket[for/or]}

@;{The @racket[for/and] form combines iteration results with
@racket[and], stopping as soon as it encounters @racket[#f]:}
@racket[for/and]表用@racket[and]组合迭代结果，一旦遇到@racket[#f]就停止：

@interaction[
(for/and ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

@;{The @racket[for/or] form combines iteration results with @racket[or],
stopping as soon as it encounters a true value:}
@racket[for/or]表用@racket[or]组合迭代结果，一旦遇到真（true）值立即停止：

@interaction[
(for/or ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

@;{As usual, the @racket[for*/and] and @racket[for*/or] forms provide the
same facility with nested iterations.}
与通常一样，@racket[for*/and]和@racket[for*/or]表提供与嵌套迭代相同的功能。

@;{@section{@racket[for/first] and @racket[for/last]}}
@section[#:tag "for|first-and-for|last"]{@racket[for/first]和@racket[for/last]}

@;{The @racket[for/first] form returns the result of the first time that
the @racket[_body]s are evaluated, skipping further iterations.
This form is most useful with a @racket[#:when] clause.}
@racket[for/first]表返回第一次对@racket[_body]进行求值的结果，跳过了进一步的迭代。这个带有一个@racket[#:when]子句的表是最非常有用的。

@interaction[
(for/first ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Intro")))
  chapter)
]

@;{If the @racket[_body]s are evaluated zero times, then the result
is @racket[#f].}
如@racket[_body]求值进行零次，那么结果是@racket[#f]。

@;{The @racket[for/last] form runs all iterations, returning the value of
the last iteration (or @racket[#f] if no iterations are run):}
@racket[for/last]表运行所有迭代，返回最后一次迭代的值（或如果没有迭代运行返回@racket[#f]）：

@interaction[
(for/last ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Index")))
  chapter)
]

@;{As usual, the @racket[for*/first] and @racket[for*/last] forms provide
the same facility with nested iterations:}
通常，@racket[for*/first]和@racket[for*/last]表提供和嵌套迭代相同的工具：

@interaction[
(for*/first ([book '("Guide" "Reference")]
             [chapter '("Intro" "Details" "Conclusion" "Index")]
             #:when (not (equal? chapter "Intro")))
  (list book chapter))

(for*/last ([book '("Guide" "Reference")]
            [chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Index")))
  (list book chapter))
]

@;{@section[#:tag "for/fold"]{@racket[for/fold] and @racket[for*/fold]}}
@section[#:tag "for/fold"]{@racket[for/fold]和@racket[for*/fold]}

@;{The @racket[for/fold] form is a very general way to combine iteration
results. Its syntax is slightly different than the syntax of
@racket[for], because accumulation variables must be declared at the
beginning:}
@racket[for/fold]表是合并迭代结果的一种非常通用的方法。由于必须在开始时声明累积变量，它的语法与原来的@racket[for]语法略有不同：

@racketblock[
(for/fold ([_accum-id _init-expr] ...)
          (_clause ...)
  _body ...+)
]

@;{In the simple case, only one @racket[[_accum-id _init-expr]] is
provided, and the result of the @racket[for/fold] is the final value
for @racket[_accum-id], which starts out with the value of
@racket[_init-expr]. In the @racket[_clause]s and
@racket[_body]s, @racket[_accum-id] can be referenced to get its
current value, and the last @racket[_body] provides the value of
@racket[_accum-id] for the next iteration.}
在简单的情况下，仅提供@racket[[_accum-id _init-expr]]，那么@racket[for/fold]的结果是@racket[_accum-id]的最终值，并启动了@racket[_init-expr]的值。在@racket[_clause]和@racket[_body]、@racket[_accum-id]可参照获得其当前值，并且最后的@racket[_body]为下一次迭代的提供@racket[_accum-id]值。

@examples[
(for/fold ([len 0])
          ([chapter '("Intro" "Conclusion")])
  (+ len (string-length chapter)))
(for/fold ([prev #f])
          ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Details" "Conclusion")]
           #:when (not (equal? chapter prev)))
  (printf "~a. ~a\n" i chapter)
  chapter)
]

@;{When multiple @racket[_accum-id]s are specified, then the last
@racket[_body] must produce multiple values, one for each
@racket[_accum-id]. The @racket[for/fold] expression itself produces
multiple values for the results.}
当多个@racket[_accum-id]被指定，那么最后的@racket[_body]必须产生多值，每一个对应@racket[_accum-id]。@racket[for/fold]的表达式本身给结果产生多值。

@examples[
(for/fold ([prev #f]
           [counter 1])
          ([chapter '("Intro" "Details" "Details" "Conclusion")]
           #:when (not (equal? chapter prev)))
  (printf "~a. ~a\n" counter chapter)
  (values chapter
          (add1 counter)))
]

@;{@section{Multiple-Valued Sequences}}
@section[#:tag "Multiple-Valued-Sequences"]{多值序列}

@;{In the same way that a function or expression can produce multiple
values, individual iterations of a sequence can produce multiple
elements.  For example, a hash table as a sequence generates two
values for each iteration: a key and a value.}
同样，函数或表达式可以生成多个值，序列的单个迭代可以生成多个元素。例如，作为序列的哈希表生成两个迭代的两个值：一个键和一个值。

@;{In the same way that @racket[let-values] binds multiple results to
multiple identifiers, @racket[for] can bind multiple sequence elements
to multiple iteration identifiers:}
同样方式，@racket[let-values]将多个结果绑定到多个标识符，@racket[for]能将多个序列元素绑定到多个迭代标识符：

@margin-note{
 @;{While @racket[let] must be changed to @racket[let-values]
             to bind multiple identifiers, @racket[for] simply allows a
             parenthesized list of identifiers instead of a single
             identifier in any clause.}
而@racket[let]必须改变@racket[let-values]以绑定多个标识符，@racket[for]只是允许标识符列表中的任何子句里的括号代替单个标识符。
   }

@interaction[
(for ([(k v) #hash(("apple" . 1) ("banana" . 3))])
  (printf "~a count: ~a\n" k v))
]

@;{This extension to multiple-value bindings works for all @racket[for]
variants. For example, @racket[for*/list] nests iterations, builds a
list, and also works with multiple-valued sequences:}
这种对多值绑定的扩展对所有@racket[for]变体都适用。例如，@racket[for*/list]嵌套迭代，构建列表，也可以处理多值序列：

@interaction[
(for*/list ([(k v) #hash(("apple" . 1) ("banana" . 3))]
            [(i) (in-range v)])
  k)
]


@;{@section{Breaking an Iteration}}
@section[#:tag "Breaking-an-Iteration"]{打断迭代}

@;{An even more complete syntax of @racket[for] is}
更完整的@racket[for]语法是

@specform/subs[
(for (clause ...)
  body-or-break ... body)
([clause [id sequence-expr]
         (code:line #:when boolean-expr)
         (code:line #:unless boolean-expr)
         break]
 [body-or-break body break]
 [break  (code:line #:break boolean-expr)
         (code:line #:final boolean-expr)])
]{}

@;{That is, a @racket[#:break] or @racket[#:final] clause can
be included among the binding clauses and body of the iteration. Among
the binding clauses, @racket[#:break] is like @racket[#:unless]
but when its @racket[_boolean-expr] is true, all sequences within the
@racket[for] are stopped. Among the @racket[_body]s,
@racket[#:break] has the same effect on sequences when its
@racket[_boolean-expr] is true, and it also prevents later
@racket[_body]s from evaluation in the current iteration.}
那是，@racket[#:break]或@racket[#:final]子句可以包括在迭代的绑定子句和主体之间。在绑定子句中，@racket[#:break]类似于@racket[#:unless]，但当其@racket[_boolean-expr]为真时，@racket[for]中的所有序列都将停止。处在@racket[_body]内，除了当@racket[_boolean-expr]是真时，@racket[#:break]对序列有一样的效果，并且它也阻止随后的@racket[_body]从当前迭代的求值。

@;{For example, while using @racket[#:unless] between clauses effectively
skips later sequences as well as the body,}
例如，当在有效跳跃后的序列以及主体之间使用@racket[#:unless]，

@interaction[
(for ([book '("Guide" "Story" "Reference")]
      #:unless (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

@;{using @racket[#:break] causes the entire @racket[for] iteration
to terminate:}
使用@racket[#:break]子句致使整个@racket[for]迭代终止：

@interaction[
(for ([book '("Guide" "Story" "Reference")]
      #:break (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
(for* ([book '("Guide" "Story" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  #:break (and (equal? book "Story")
               (equal? chapter "Conclusion"))
  (printf "~a ~a\n" book chapter))
]

@;{A @racket[#:final] clause is similar to @racket[#:break],
but it does not immediately terminate the iteration. Instead, it
allows at most one more element to be drawn for each sequence and at
most one more evaluation of the @racket[_body]s.}
@racket[#:final]子句类似于@racket[#:break]，但它不立即终止迭代。相反，它最多地允许为每一个序列和最多再一个 @racket[_body]的求值绘制再一个元素。

@interaction[
(for* ([book '("Guide" "Story" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  #:final (and (equal? book "Story")
               (equal? chapter "Conclusion"))
  (printf "~a ~a\n" book chapter))
(for ([book '("Guide" "Story" "Reference")]
      #:final (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

@;{@section[#:tag "for-performance"]{Iteration Performance}}
@section[#:tag "for-performance"]{迭代性能}

@;{Ideally, a @racket[for] iteration should run as fast as a loop that
you write by hand as a recursive-function invocation. A hand-written
loop, however, is normally specific to a particular kind of data, such
as lists. In that case, the hand-written loop uses selectors like
@racket[car] and @racket[cdr] directly, instead of handling all forms
of sequences and dispatching to an appropriate iterator.}
理想情况下，作为递归函数调用，@racket[for]迭代的运行速度应该与手工编写的循环一样快。然而，手写循环通常是针对特定类型的数据，如列表。在这种情况下，手写循环直接使用选择器，比如@racket[car]和@racket[cdr]，而不是处理所有序列表并分派给合适的迭代器。

@;{The @racket[for] forms can provide the performance of hand-written
loops when enough information is apparent about the sequences to
iterate. Specifically, the clause should have one of the following
@racket[_fast-clause] forms:}
当足够的信息反复提供给迭代序列时，@racket[for]表可以提供手写循环的性能。具体来说，子句应具有下列@racket[_fast-clause]表之一：

@racketgrammar[
fast-clause [id fast-seq]
            [(id) fast-seq]
            [(id id) fast-indexed-seq]
            [(id ...) fast-parallel-seq]
]

@racketgrammar[
#:literals [in-range in-naturals in-list in-vector in-string in-bytes in-value stop-before stop-after]
fast-seq (in-range expr)
         (in-range expr expr)
         (in-range expr expr expr)
         (in-naturals)
         (in-naturals expr)
         (in-list expr)
         (in-vector expr)
         (in-string expr)
         (in-bytes expr)
         (in-value expr)
         (stop-before fast-seq predicate-expr)
         (stop-after fast-seq predicate-expr)
]

@racketgrammar[
#:literals [in-indexed stop-before stop-after]
fast-indexed-seq (in-indexed fast-seq)
                  (stop-before fast-indexed-seq predicate-expr)
                  (stop-after fast-indexed-seq predicate-expr)
]

@racketgrammar[
#:literals [in-parallel stop-before stop-after]
fast-parallel-seq (in-parallel fast-seq ...)
                  (stop-before fast-parallel-seq predicate-expr)
                  (stop-after fast-parallel-seq predicate-expr)
]

@examples[
(time (for ([i (in-range 100000)])
        (for ([elem (in-list '(a b c d e f g h))]) (code:comment @#,elem{@;{fast}快})
          (void))))
(time (for ([i (in-range 100000)])
        (for ([elem '(a b c d e f g h)])           (code:comment @#,elem{@;{slower}慢})
          (void))))
(time (let ([seq (in-list '(a b c d e f g h))])
        (for ([i (in-range 100000)])
          (for ([elem seq])                        (code:comment @#,elem{@;{slower}慢})
            (void)))))
]

@;{The grammars above are not complete, because the set of syntactic
patterns that provide good performance is extensible, just like the
set of sequence values. The documentation for a sequence constructor
should indicate the performance benefits of using it directly in
a @racket[for] @racket[_clause].}
上面的语法是不完整的，因为提供良好性能的语法模式集是可扩展的，就像序列值集合一样。序列构造器的文档应该说明直接使用@racket[for]子句（@racket[_clause]）的性能优势。

@;{@refdetails["for"]{iterations and comprehensions}}
@;@refdetails["for"]{迭代和理解}
