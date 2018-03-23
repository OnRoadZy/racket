#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@;{@title[#:tag "characters"]{Characters}}
@title[#:tag "characters"]{字符（Character）}

@;{A Racket @deftech{character} corresponds to a Unicode @defterm{scalar
value}. Roughly, a scalar value is an unsigned integer whose
representation fits into 21 bits, and that maps to some notion of a
natural-language character or piece of a character. Technically, a
scalar value is a simpler notion than the concept called a
``character'' in the Unicode standard, but it's an approximation that
works well for many purposes. For example, any accented Roman letter
can be represented as a scalar value, as can any common Chinese character.}
Racket @deftech{字符（character）}对应于Unicode@defterm{标量值（scalar
value）}。粗略地说，一个标量值是一个无符号整数，它的表示适合21位，并且映射到某种自然语言字符或字符块的某些概念。从技术上讲，标量值是比Unicode标准中的“字符”概念更简单的概念，但它是一种用于许多目的的近似值。例如，任何重音罗马字母都可以表示为一个标量值，就像任何普通的汉字一样。

@;{Although each Racket character corresponds to an integer, the
character datatype is separate from numbers. The
@racket[char->integer] and @racket[integer->char] procedures convert
between scalar-value numbers and the corresponding character.}
虽然每个Racket字符对应一个整数，但字符数据类型和数值是有区别的。@racket[char->integer]和@racket[integer->char]程序在标量值和相应字符之间转换。

@;{A printable character normally prints as @litchar{#\} followed
by the represented character. An unprintable character normally prints
as @litchar{#\u} followed by the scalar value as hexadecimal
number. A few characters are printed specially; for example, the space
and linefeed characters print as @racket[#\space] and
@racket[#\newline], respectively.}
一个可打印字符通常在以@litchar{#\}作为代表字符后打印。一个不可打印字符通常在以@litchar{#\u}开始十六进制数的标量值打印。几个字符特殊打印；例如，空格和换行字符分别打印为@racket[#\space]和@racket[#\newline]。

@;{@refdetails/gory["parse-character"]{the syntax of characters}}
@refdetails/gory["parse-character"]{字符的语法}

@examples[
(integer->char 65)
(char->integer #\A)
#\u03BB
(eval:alts @#,racketvalfont["#\\u03BB"] #\u03BB)
(integer->char 17)
(char->integer #\space)
]

@;{The @racket[display] procedure directly writes a character to the
current output port (see @secref["i/o"]), in contrast to the
character-constant syntax used to print a character result.}
@racket[display]程序直接将字符写入当前输出端口（见@secref["i/o"])，与用于打印字符结果的字符常量语法形成对照。

@examples[
#\A
(display #\A)
]

@;{Racket provides several classification and conversion procedures on
characters. Beware, however, that conversions on some Unicode
characters work as a human would expect only when they are in a string
(e.g., upcasing ``@elem["\uDF"]'' or downcasing ``@elem["\u03A3"]'').}
Racket提供了几种分类和转换字符的程序。注意，然而，某些Unicode字符要如人类希望的那样转换只有在一个字符串中才行（例如，”@elem["\uDF"]”的大写转换或者”@elem["\u03A3"]”的小写转换）。

@examples[
(char-alphabetic? #\A)
(char-numeric? #\0)
(char-whitespace? #\newline)
(char-downcase #\A)
(char-upcase #\uDF)
]

@;{The @racket[char=?] procedure compares two or more characters, and
@racket[char-ci=?] compares characters ignoring case. The
@racket[eqv?] and @racket[equal?] procedures behave the same as
@racket[char=?] on characters; use @racket[char=?] when you want to
more specifically declare that the values being compared are
characters.}
@racket[char=?]程序比较两个或多个字符，@racket[char-ci=?]比较忽略字符。@racket[eqv?]和@racket[equal?]程序的行为与 @racket[char=?]在字符方面的表现一样；当更具体地声明正在比较的值是字符时使用 @racket[char=?]。

@examples[
(char=? #\a #\A)
(char-ci=? #\a #\A)
(eqv? #\a #\A)
]

@;{@refdetails["characters"]{characters and character procedures}}
@refdetails["characters"]{字符和字符程序}
