#lang scribble/doc
@(require scribble/manual scribble/eval scribble/core "guide-utils.rkt")

@(define rx-eval (make-base-eval))

@;{@title[#:tag "regexp" #:style 'toc]{Regular Expressions}}
@title[#:tag "regexp" #:style 'toc]{正则表达式}

@;{@margin-note{This chapter is a modified version of @cite["Sitaram05"].}}
@margin-note{本章是@cite["Sitaram05"]的一个修改版本。}

@;{A @deftech{regexp} value encapsulates a pattern that is described by a
string or @tech{byte string}.  The regexp matcher tries to match this
pattern against (a portion of) another string or byte string, which we
will call the @deftech{text string}, when you call functions like
@racket[regexp-match].  The text string is treated as raw text, and
not as a pattern.}
一个@deftech{正则表达式（regexp）}值封装一个被一个字符串或@tech{字节字符串（bytestring）}描述的模式。当你调用像@racket[regexp-match]那样的函数时，正则表达式匹配器尝试对（一部分）其它的字符串或字节字符串匹配这个模式，我们将其称为@deftech{文本字符串（text string）}。文本字符串被视为原始文本，而不会视为一个模式。

@local-table-of-contents[]

@;@refdetails["regexp"]{regexps}
在《Racket参考》中的“正则表达式（regexp）”部分提供有更多关于正则表达式的内容。

@; ----------------------------------------

@;{@section[#:tag "regexp-intro"]{Writing Regexp Patterns}}
@section[#:tag "regexp-intro"]{编写正则表达式模式}

@;{A string or @tech{byte string} can be used directly as a @tech{regexp}
pattern, or it can be prefixed with @litchar{#rx} to form a literal
@tech{regexp} value. For example, @racket[#rx"abc"] is a string-based
@tech{regexp} value, and @racket[#rx#"abc"] is a @tech{byte
string}-based @tech{regexp} value. Alternately, a string or byte
string can be prefixed with @litchar{#px}, as in @racket[#px"abc"],
for a slightly extended syntax of patterns within the string.}
一个字符串或@tech{字节字符串（byte string）}可以被直接用作一个@tech{正则表达式（regexp）}模式，也可以用@litchar{#rx}来形成一个字面上的@tech{正则表达式}值来做前缀。例如，@racket[#rx"abc"]是一个基于字符串的@tech{正则表达式}值，并且@racket[#rx"abc"]是一个基于@tech{字节字符串}的@tech{正则表达式}值。或者，一个字符串或字节字符串可以用@litchar{#px}做前缀，就像在@racket[#px"abc"]中，给一个稍微扩展的字符串内的模式的语法。

@;{Most of the characters in a @tech{regexp} pattern are meant to match
occurrences of themselves in the @tech{text string}.  Thus, the pattern
@racket[#rx"abc"] matches a string that contains the characters
@litchar{a}, @litchar{b}, and @litchar{c} in succession. Other
characters act as @deftech{metacharacters}, and some character
sequences act as @deftech{metasequences}.  That is, they specify
something other than their literal selves.  For example, in the
pattern @racket[#rx"a.c"], the characters @litchar{a} and @litchar{c}
stand for themselves, but the @tech{metacharacter} @litchar{.} can
match @emph{any} character.  Therefore, the pattern @racket[#rx"a.c"]
matches an @litchar{a}, any character, and @litchar{c} in succession.}
在一个@tech{正则表达式}模式的大多数字符都表示在@tech{文本字符串}中自相匹配。因此，该模式@racket[#rx"abc"]匹配在继承中包含字符@litchar{a}、@litchar{b}和@litchar{c}的一个字符串。其它字符充当@deftech{元字符（metacharacters）}，而且许多字符序列充当@deftech{元序列（metasequences）}。也就是说，它们指定的东西不是它们字面本身。例如，在模@racket[#rx"a.c"]中，字符@litchar{a}和@litchar{c}代表它们自己，但@tech{元字符}@litchar{.}可以匹配任何字符。因此，该模式@racket[#rx"a.c"]在继承中匹配一个@litchar{a}、任意字符以及@litchar{c}。

@margin-note{
 @;{When we want a literal @litchar{\} inside a Racket string
or regexp literal, we must escape it so that it shows up in the string
at all. Racket strings use @litchar{\} as the escape character, so we
end up with two @litchar{\}s: one Racket-string @litchar{\} to escape
the regexp @litchar{\}, which then escapes the @litchar{.}.  Another
character that would need escaping inside a Racket string is
@litchar{"}.}
当我们想要在一个Racket字符串或正则表达式原义里的一个字面原义的@litchar{\}，我们必须将它转义以便它出现在所有字符串中。Racket字符串使用@litchar{\}作为转义字符，所以我们用两个@litchar{\}结束：一个Racket字符串@litchar{\}转义正则表达式@litchar{\}，它接着转义@litchar{.}。另一个将要在Racket字符串里转义的字符是@litchar{"}。
}

If we needed to match the character @litchar{.} itself, we can escape
it by precede it with a @litchar{\}.  The character sequence
@litchar{\.} is thus a @tech{metasequence}, since it doesn't match
itself but rather just @litchar{.}.  So, to match @litchar{a},
@litchar{.}, and @litchar{c} in succession, we use the regexp pattern
@racket[#rx"a\\.c"]; the double @litchar{\} is an artifact of Racket
strings, not the @tech{regexp} pattern itself.
如果我们需要匹配字符@litchar{.}本身，我们可以在它前面加上一个@litchar{\}来转义。字符序列@litchar{\.}就是一个@tech{元序列（metasequence）}，因为它不匹配它本身而只是@litchar{.}。所以，连续匹配@litchar{a}、@litchar{.}和@litchar{c}，我们使用正则表达式模@racket[#rx"a\\.c"]。双@litchar{\}字符是一个Racket字符串技巧，不是@tech{正则表达式}模式本身。

@;{The @racket[regexp] function takes a string or byte string and
produces a @tech{regexp} value. Use @racket[regexp] when you construct
a pattern to be matched against multiple strings, since a pattern is
compiled to a @tech{regexp} value before it can be used in a match.
The @racket[pregexp] function is like @racket[regexp], but using the
extended syntax. Regexp values as literals with @litchar{#rx} or
@litchar{#px} are compiled once and for all when they are read.}
@racket[regexp-quote]函数接受一个字符串或字节字符串并产生一个@tech{正则表达式}值。当你构建一个模式来匹配多个字符串时用@racket[regexp]，因为一个模式在它可以被用在一个匹配之前被编译成了一个@tech{正则表达式}值。这个@racket[pregexp]函数类似于@racket[regexp]，除了使用扩展语法之外。正则表达式值作为带@litchar{#rx}或@litchar{#px}的字面形式被编译一次并且当它们被读取时都这样。

@;{The @racket[regexp-quote] function takes an arbitrary string and
returns a string for a pattern that matches exactly the original
string. In particular, characters in the input string that could serve
as regexp metacharacters are escaped with a backslash, so that they
safely match only themselves.}
@racket[regexp-quote]函数接受任意的字符串并返回一个模式匹配原始字符串。特别是，在输入字符串中的字符，可以作为正则表达式元字符用一个反斜杠转义，所以只有它们自己使他们安全地匹配。

@interaction[
#:eval rx-eval
(regexp-quote "cons")
(regexp-quote "list?")
]

@;{The @racket[regexp-quote] function is useful when building a composite
@tech{regexp} from a mix of @tech{regexp} strings and verbatim strings.}
@racket[regexp-quote]函数在从一个混合的@tech{正则表达式}字符串和字面的字符串构建一个完整的@tech{正则表达式}是有用的。

@; ----------------------------------------

@;{@section[#:tag "regexp-match"]{Matching Regexp Patterns}}
@section[#:tag "regexp-match"]{匹配正则表达式模式}

@;{The @racket[regexp-match-positions] function takes a @tech{regexp}
pattern and a @tech{text string}, and it returns a match if the regexp
matches (some part of) the @tech{text string}, or @racket[#f] if the regexp
did not match the string. A successful match produces a list of
@deftech{index pairs}.}
@racket[regexp-match-positions]函数接受一个@tech{正则表达}模式和一个@tech{文本字符串}，如果这个正则表达式匹配（某部分）这个@tech{文本字符串}则返回一个匹配，或这如果这个正则表达式不匹配这个字符串则返回@racket[#f]。一个成功的匹配产生一个@deftech{索引配对（index pairs）}列表。

@examples[
#:eval rx-eval
(regexp-match-positions #rx"brain" "bird")
(regexp-match-positions #rx"needle" "hay needle stack")
]

@;{In the second example, the integers @racket[4] and @racket[10]
identify the substring that was matched. The @racket[4] is the
starting (inclusive) index, and @racket[10] the ending (exclusive)
index of the matching substring:}
在第二个例子中，整数@racket[4]和@racket[10]确定匹配的子串。这个@racket[4]是起始（包含）索引，同时这个@racket[10]是匹配子字符串的结尾（不包含）索引：

@interaction[
#:eval rx-eval
(substring "hay needle stack" 4 10)
]

@;{In this first example, @racket[regexp-match-positions]'s return list
contains only one index pair, and that pair represents the entire
substring matched by the regexp.  When we discuss @tech{subpatterns}
later, we will see how a single match operation can yield a list of
@tech{submatch}es.}
第一个例子中，@racket[regexp-match-positions]的返回列表只包含一个索引配对，并且那个索引配对代表由正则表达式匹配整个字符串。当我们论述了@tech{子模式（subpatterns）}后，我们将明白为什么一个单独的匹配操作可以产生一个@tech{子匹配（submatch）列表}。

@;{The @racket[regexp-match-positions] function takes optional third and
fourth arguments that specify the indices of the @tech{text string} within
which the matching should take place.}
@racket[regexp-match-positions]函数接受可选的第三和第四个参数，他们在这个匹配应该发生之中指定@tech{文本字符串}的指标。

@interaction[
#:eval rx-eval
(regexp-match-positions 
 #rx"needle" 
 "his needle stack -- my needle stack -- her needle stack"
 20 39)
]

@;{Note that the returned indices are still reckoned relative to the full
@tech{text string}.}
注意，返回指标仍然与完整的@tech{文字符串}相对应。

@;{The @racket[regexp-match] function is like
@racket[regexp-match-positions], but instead of returning index pairs,
it returns the matching substrings:}
@racket[regexp-match]函数类似于@racket[regexp-match-positions]，但它不是返回索引配对，它返回这个匹配的子字符串：

@interaction[
#:eval rx-eval
(regexp-match #rx"brain" "bird")
(regexp-match #rx"needle" "hay needle stack")
]

@;{When @racket[regexp-match] is used with byte-string regexp, the result
is a matching byte substring:}
当@racket[regexp-match]在字节字符串表达式中使用时，结果是一个匹配的字节子字符串：

@interaction[
#:eval rx-eval
(regexp-match #rx#"needle" #"hay needle stack")
]

@margin-note{
 @;{A byte-string regexp can be applied to a string, and a
             string regexp can be applied to a byte string. In both
             cases, the result is a byte string. Internally, all
             regexp matching is in terms of bytes, and a string regexp
             is expanded to a regexp that matches UTF-8 encodings of
             characters. For maximum efficiency, use byte-string
             matching instead of string, since matching bytes directly
             avoids UTF-8 encodings.}
一个字节字符串正则表达式可以被应用到一个字符串，而且一个字符串正则表达式可以应用到一个字节字符串。在这两种情况下，结果都是一个字节字符串。在内部，所有的正则表达式匹配是以字节为单位，并且一个字符串正则表达式被扩展到一个匹配字符的UTF-8编码的正则表达式。为最大限度地提高效率，使用字节字符串匹配代替字符串匹配，因为匹配字节直接避开了UTF-8编码。 
}

@;{If you have data that is in a port, there's no need to first read it
into a string. Functions like @racket[regexp-match] can match on the
port directly:}
如果你有在端口中的数据，这里无需首先将其读取到字符串中。像@racket[regexp-match]这样的函数可以在端口上直接匹配：

@interaction[
(define-values (i o) (make-pipe))
(write "hay needle stack" o)
(close-output-port o)
(regexp-match #rx#"needle" i)
]

@;{The @racket[regexp-match?] function is like
@racket[regexp-match-positions], but simply returns a boolean
indicating whether the match succeeded:}
@racket[regexp-match?]函数类似于@racket[regexp-match-positions]，但只简单地返回一个指示是否匹配成功的布尔值：

@interaction[
#:eval rx-eval
(regexp-match? #rx"brain" "bird")
(regexp-match? #rx"needle" "hay needle stack")
]

@;{The @racket[regexp-split] function takes two arguments, a
@tech{regexp} pattern and a text string, and it returns a list of
substrings of the text string; the pattern identifies the delimiter
separating the substrings.}
@racket[regexp-split]函数接受两个参数，一个@tech{正则表达式}模式和一个文本字符串，并返回一个文本字符串的子串列表；这个模式识别分隔子字符串的分隔符。

@interaction[
#:eval rx-eval
(regexp-split #rx":" "/bin:/usr/bin:/usr/bin/X11:/usr/local/bin")
(regexp-split #rx" " "pea soup")
]

@;{If the first argument matches empty strings, then the list of all the
single-character substrings is returned.}
如果第一个参数匹配空字符串，那么返回所有的单字符子字符串的列表。

@interaction[
#:eval rx-eval
(regexp-split #rx"" "smithereens")
]

@;{Thus, to identify one-or-more spaces as the delimiter, take care to
use the regexp @racket[#rx"\u20+"], not @racket[#rx"\u20*"].}
因此，识别一个或多个空格作为分隔符，注意使用正则表达@racket[#rx"\u20+"]，而不是@racket[#rx"\u20*"]。

@interaction[
#:eval rx-eval
(regexp-split #rx" +" "split pea     soup")
(regexp-split #rx" *" "split pea     soup")
]

@;{The @racket[regexp-replace] function replaces the matched portion of
the text string by another string.  The first argument is the pattern,
the second the text string, and the third is either the string to be
inserted or a procedure to convert matches to the insert string.}
@racket[regexp-replace]函数用另一个字符串替换这个文本字符串匹配的部分。第一个参数是模式，第二个参数是文本字符串，第三个参数是要插入的字符串或者一个将匹配转换为插入字符串的过程。

@interaction[
#:eval rx-eval
(regexp-replace #rx"te" "liberte" "ty") 
(regexp-replace #rx"." "racket" string-upcase)
]

@;{If the pattern doesn't occur in the text string, the returned string
is identical to the text string.}
如果该模式没有出现在这个文本字符串中，返回的字符串与这个文本字符串相同。

@;{The @racket[regexp-replace*] function replaces @emph{all} matches in
the text string by the insert string:}
@racket[regexp-replace*]函数通过这个插入的字符串在这个文本字符串中代替@emph{所有}相匹配的内容：

@interaction[
#:eval rx-eval
(regexp-replace* #rx"te" "liberte egalite fraternite" "ty")
(regexp-replace* #rx"[ds]" "drracket" string-upcase)
]

@; ----------------------------------------

@;{@section[#:tag "regexp-assert"]{Basic Assertions}}
@section[#:tag "regexp-assert"]{基本申明}

@;{The @deftech{assertions} @litchar{^} and @litchar{$} identify the
beginning and the end of the text string, respectively.  They ensure
that their adjoining regexps match at one or other end of the text
string:}
这个@deftech{判断（assertions）} @litchar{^}和@litchar{$}分别标识这个文本字符串的开头和结尾。它们确保在文本字符串的一个或其它尾部相邻的正则表达式匹配：

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"^contact" "first contact")
]

@;{The @tech{regexp} above fails to match because @litchar{contact} does
not occur at the beginning of the text string. In}
以上@tech{正则表达式}匹配失败是因为@litchar{contact}没有出现在文本字符串的开头。在

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"laugh$" "laugh laugh laugh laugh")
]

@;{the regexp matches the @emph{last} @litchar{laugh}.}
中，正则表达式匹配@emph{最后}的@litchar{laugh}。

@;{The metasequence @litchar{\b} asserts that a word boundary exists, but
this metasequence works only with @litchar{#px} syntax. In}
这个元序列@litchar{\b}判断一个字的边界存在，但这个元序列只能与@litchar{#px}语法一起工作。在

@interaction[
#:eval rx-eval
(regexp-match-positions #px"yack\\b" "yackety yack")
]

@;{the @litchar{yack} in @litchar{yackety} doesn't end at a word boundary
so it isn't matched.  The second @litchar{yack} does and is.}
里，@litchar{yackety}中的这个@litchar{yack}不结束于字边界，所以它并不匹配。第二@litchar{yack}在字边界结束，所以匹配。

@;{The metasequence @litchar{\B} (also @litchar{#px} only) has the
opposite effect to @litchar{\b}; it asserts that a word boundary does
not exist. In}
元序列@litchar{\B}（也只有@litchar{#px}）对@litchar{\b}有相反的影响；它判断一个字边界不存在。在

@interaction[
#:eval rx-eval
(regexp-match-positions #px"an\\B" "an analysis")
]

@;{the @litchar{an} that doesn't end in a word boundary is matched.}
里，这个不在一个字边界结束的@litchar{an}被匹配。

@; ----------------------------------------

@;{@section[#:tag "regexp-chars"]{Characters and Character Classes}}
@section[#:tag "regexp-chars"]{字符和字符类}

@;{Typically, a character in the regexp matches the same character in the
text string.  Sometimes it is necessary or convenient to use a regexp
@tech{metasequence} to refer to a single character. For example, the
metasequence @litchar{\.} matches the period character.}
通常，在正则表达式中的一个字符匹配文本字符串中的相同字符。有时使用一个正则表达式@tech{元序列（metasequence）}来引用一个单个字符是有必要的或方便的。例如，这个元序列@litchar{\.}匹配句点字符。

@;{The @tech{metacharacter} @litchar{.} matches @emph{any} character
(other than newline in @tech{multi-line mode}; see
@secref["regexp-cloister"]):}
这个@tech{元字符（metacharacter）}@litchar{.}匹配@emph{任意}字符（除了在@tech{多行模式（multi-line mode）}中的换行，参见《@secref["regexp-cloister"]》（Cloisters））：

@interaction[
#:eval rx-eval
(regexp-match #rx"p.t" "pet")
]

@;{The above pattern also matches @litchar{pat}, @litchar{pit},
@litchar{pot}, @litchar{put}, and @litchar{p8t}, but not
@litchar{peat} or @litchar{pfffft}.}
上面的模式也匹配@litchar{pat}、@litchar{pit}、@litchar{pot}、@litchar{put}和@litchar{p8t}，但不匹配@litchar{peat}或@litchar{pfffft}。

@;{A @deftech{character class} matches any one character from a set of
characters.  A typical format for this is the @deftech{bracketed
character class} @litchar{[}...@litchar{]}, which matches any one
character from the non-empty sequence of characters enclosed within
the brackets.  Thus, @racket[#rx"p[aeiou]t"] matches @litchar{pat},
@litchar{pet}, @litchar{pit}, @litchar{pot}, @litchar{put}, and
nothing else.}
一个@deftech{字符类（character class）}匹配来自一组字符中的任意一个字符。对这种情况的一个典型的格式是@deftech{括号字符类（bracketed
character class）}@litchar{[}...@litchar{]}，它匹配任意一个来自包含在括号内的非空序列的字符。因此，@racket[#rx"p[aeiou]t"]匹配@litchar{pat}、@litchar{pet}、@litchar{pit}、@litchar{pot}、@litchar{put}，别的都不匹配。

@;{Inside the brackets, a @litchar{-} between two characters specifies
the Unicode range between the characters.  For example,
@racket[#rx"ta[b-dgn-p]"] matches @litchar{tab}, @litchar{tac},
@litchar{tad}, @litchar{tag}, @litchar{tan}, @litchar{tao}, and
@litchar{tap}.}
在括号内，一个@litchar{-}介于两个字符之间指定字符之间的Unicode范围。例如，@racket[#rx"ta[b-dgn-p]"]匹配@litchar{tab}、@litchar{tac}、@litchar{tad}、@litchar{tag}、@litchar{tan}、@litchar{tao}和@litchar{tap}。

@;{An initial @litchar{^} after the left bracket inverts the set
specified by the rest of the contents; i.e., it specifies the set of
characters @emph{other than} those identified in the brackets. For
example, @racket[#rx"do[^g]"] matches all three-character sequences
starting with @litchar{do} except @litchar{dog}.}
在左括号后的一个初始@litchar{^}将反转通过剩下的内容指定的集合；@emph{也就是说}，它指定的这个字符集@emph{排除}括号中标识的字符集。例如，@racket[#rx"do[^g]"]匹配所有以 @litchar{do}开始但不是@litchar{dog}的三字符序列。

@;{Note that the @tech{metacharacter} @litchar{^} inside brackets means
something quite different from what it means outside.  Most other
@tech{metacharacters} (@litchar{.}, @litchar{*}, @litchar{+},
@litchar{?}, etc.) cease to be @tech{metacharacters} when inside
brackets, although you may still escape them for peace of mind. A
@litchar{-} is a @tech{metacharacter} only when it's inside brackets,
and when it is neither the first nor the last character between the
brackets.}
注意括号之内的@tech{元字符}@litchar{^}，它在括号里边的意义与在外边的意义截然不同。大多数其它的@tech{元字符}（@litchar{.}、@litchar{*}、@litchar{+}、@litchar{?}，等等）当在括号之内时不再是@tech{元字符}，即使你一直也许一直不予承认以求得内心平静。仅当它在括号内，并且当它既不是括号之间的第一个字符也不是最后一个字符时，一个@litchar{-}是一个@tech{元字符}。

@;{Bracketed character classes cannot contain other bracketed character
classes (although they contain certain other types of character
classes; see below).  Thus, a @litchar{[} inside a bracketed character
class doesn't have to be a metacharacter; it can stand for itself.
For example, @racket[#rx"[a[b]"] matches @litchar{a}, @litchar{[}, and
@litchar{b}.}
括号内的字符类不能包含其它被括号包裹的字符类（虽然它们包含字符类的某些其它类型，见下）。因此，在一个被括起来的字符类里的一个@litchar{[}不必是一个元字符；它可以代表自身。比如，@racket[#rx"[a[b]"]匹配@litchar{a}、@litchar{[}和@litchar{b}。

@;{Furthermore, since empty bracketed character classes are disallowed, a
@litchar{]} immediately occurring after the opening left bracket also
doesn't need to be a metacharacter.  For example, @racket[#rx"[]ab]"]
matches @litchar{]}, @litchar{a}, and @litchar{b}.}
此外，由于空括号字符类是不允许的，一个@litchar{]}立即出现在开左括号后也不必是一个元字符。比如，@racket[#rx"[]ab]"]匹配@litchar{]}、@litchar{a}和@litchar{b}。

@;{@subsection{Some Frequently Used Character Classes}}
@subsection[#:tag "Some-Frequently-Used-Character-Classes"]{常用的字符类}

@;{In @litchar{#px} syntax, some standard character classes can be
conveniently represented as metasequences instead of as explicit
bracketed expressions:  @litchar{\d} matches a digit
(the same as @litchar{[0-9]}); @litchar{\s} matches an ASCII whitespace character; and
@litchar{\w} matches a character that could be part of a
``word''.}
在@litchar{#px}语法里，一些标准的字符类可以方便地表示为元序列以代替明确的括号内表达式：@litchar{\d}匹配一个数字（与@litchar{[0-9]}一样）；@litchar{\s}匹配一个ASCII空白字符；而@litchar{\w}匹配可以是一个“字（word）”的一部分的一个字符。

@margin-note{
 @;{Following regexp custom, we identify ``word'' characters
as @litchar{[A-Za-z0-9_]}, although these are too restrictive for what
a Racketeer might consider a ``word.''}
遵循正则表达式惯例，我们确定”字“字符为@litchar{[A-Za-z0-9_]}，虽然这些对一个可能会看重一个”字“的Racket使用者来说过于严格。
   }

@;{The upper-case versions of these metasequences stand for the
inversions of the corresponding character classes: @litchar{\D}
matches a non-digit, @litchar{\S} a non-whitespace character, and
@litchar{\W} a non-``word'' character.}
这些元序列的这个大写版本代表对应字符类的倒转：@litchar{\D}匹配一个非数字，@litchar{\S}匹配一个非空格字符，而@litchar{\W}匹配一个非“字”字符。

@;{Remember to include a double backslash when putting these
metasequences in a Racket string:}
在把这些元序列放进一个Racket字符串里时，记得要包含一个双反斜杠：

@interaction[
#:eval rx-eval
(regexp-match #px"\\d\\d" 
 "0 dear, 1 have 2 read catch 22 before 9")
]

@;{These character classes can be used inside a bracketed expression. For
example, @racket[#px"[a-z\\d]"] matches a lower-case letter or a
digit.}
这些字符类可以使用进一个括号表达式中。比如，@racket[#px"[a-z\\d]"]匹配一个小写字母或一个数字。

@;{@subsection{POSIX character classes}}
@subsection[#:tag "POSIX-character-classes"]{POSIX字符类}

@;{A @deftech{POSIX character class} is a special @tech{metasequence} of
the form @litchar{[:}...@litchar{:]} that can be used only inside a
bracketed expression in @litchar{#px} syntax.  The POSIX classes
supported are}
一个@deftech{POSIX（可移植性操作系统接口）字符类}是表@litchar{[:}...@litchar{:]}的一种特殊的@tech{元序列（metasequence）}，这个表只能用在 @litchar{#px}语法中的一个括号表达式内。这个POSIX类支持

@itemize[#:style (make-style "compact" null)

 @item{@litchar{[:alnum:]} --- @;{ASCII letters and digits}ASCII字母和数字}

 @item{@litchar{[:alpha:]} --- @;{ASCII letters}ASCII字母}

 @item{@litchar{[:ascii:]} --- @;{ASCII characters}ASCII字符}

 @item{@litchar{[:blank:]} --- @;{ASCII widthful whitespace: space and tab}ASCII 等宽空格：空格和tab}

 @item{@litchar{[:cntrl:]} --- @;{``control'' characters: ASCII 0 to 32}“控制（control）”字符：ASCII 0到32}

 @item{@litchar{[:digit:]} --- @;{ASCII digits, same as @litchar{\d}}ASCII码数字，同@litchar{\d}}

 @item{@litchar{[:graph:]} --- @;{ASCII characters that use ink}使用墨水的ASCII字符}

 @item{@litchar{[:lower:]} --- @;{ASCII lower-case letters}ASCII小写字母}

 @item{@litchar{[:print:]} --- @;{ASCII ink-users plus widthful whitespace}ASCII墨水用户加等宽空白}

 @item{@litchar{[:space:]} --- @;{ASCII whitespace, same as @litchar{\s}}ASCII空白, 同@litchar{\s}}

 @item{@litchar{[:upper:]} --- @;{ASCII upper-case letters}ASCII大写字母}

 @item{@litchar{[:word:]} --- @;{ASCII letters and @litchar{_}, same as @litchar{\w}}ASCII字母和@litchar{_}，同@litchar{\w}}

 @item{@litchar{[:xdigit:]} --- @;{ASCII hex digits}ASCII十六进制数字}

]

@;{For example, the @racket[#px"[[:alpha:]_]"] matches a letter or
underscore.}
例如，这个@racket[#px"[[:alpha:]_]"]匹配一个字母或下划线

@interaction[
#:eval rx-eval
(regexp-match #px"[[:alpha:]_]" "--x--")
(regexp-match #px"[[:alpha:]_]" "--_--")
(regexp-match #px"[[:alpha:]_]" "--:--")
]

@;{The POSIX class notation is valid @emph{only} inside a bracketed
expression.  For instance, @litchar{[:alpha:]}, when not inside a
bracketed expression, will not be read as the letter class.  Rather,
it is (from previous principles) the character class containing the
characters @litchar{:}, @litchar{a}, @litchar{l}, @litchar{p},
@litchar{h}.}
这个POSIX类符号@emph{只（only）}适用于在一个带括号的表达式内。比如@litchar{[:alpha:]}，当不在一个带括号的表达式内时，不会被当做字母类读取。确切地说，它是（来自以前的准则）包含字符：@litchar{:}、@litchar{a}、@litchar{l}、@litchar{p}、@litchar{h}的字符类。

@interaction[
#:eval rx-eval
(regexp-match #px"[:alpha:]" "--a--")
(regexp-match #px"[:alpha:]" "--x--")
]

@; ----------------------------------------

@;{@section[#:tag "regexp-quant"]{Quantifiers}}
@section[#:tag "regexp-quant"]{量词}

@;{The @deftech{quantifiers} @litchar{*}, @litchar{+}, and @litchar{?}
match respectively: zero or more, one or more, and zero or one
instances of the preceding subpattern.}
这个@deftech{量词（quantifier）} @litchar{*}、 @litchar{+}和 @litchar{?}分别匹配：零个或多个，一个或多个，以及零个或一个前面子模式的实例。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"c[ad]*r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]*r" "cr")

(regexp-match-positions #rx"c[ad]+r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]+r" "cr")

(regexp-match-positions #rx"c[ad]?r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]?r" "cr")
(regexp-match-positions #rx"c[ad]?r" "car")
]

@;{In @litchar{#px} syntax, you can use braces to specify much
finer-tuned quantification than is possible with @litchar{*},
@litchar{+}, @litchar{?}:}
在@litchar{#px}语法里，你可以使用括号来指定比用@litchar{*}、@litchar{+}、@litchar{?}更精细的调整量：

@itemize[

 @item{
  @;{The quantifier @litchar["{"]@math{m}@litchar["}"] matches
       @emph{exactly} @math{m} instances of the preceding
       @tech{subpattern}; @math{m} must be a nonnegative integer.}
这个量词@litchar["{"]@math{m}@litchar["}"]@emph{精确}匹配前面@tech{子模式}的@math{m}实例；@math{m}必须是一个非负整数。
    }

 @item{
  @;{The quantifier
       @litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}"] matches
       at least @math{m} and at most @math{n} instances.  @litchar{m}
       and @litchar{n} are nonnegative integers with @math{m} less or
       equal to @math{n}.  You may omit either or both numbers, in
       which case @math{m} defaults to @math{0} and @math{n} to
       infinity.}
这个量词@litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}"]最少匹配@math{m}且最多匹配@math{n}个实例。@litchar{m}和@litchar{n}是非负整数，@math{m}小于或等于@math{n}。你可以省略一个数字或两个数字都省略，在这种情况下默认@math{m}为@math{0}，@math{n}为无穷大。
    }

]

@;{It is evident that @litchar{+} and @litchar{?} are abbreviations for
@litchar{{1,}} and @litchar{{0,1}} respectively, and @litchar{*}
abbreviates @litchar{{,}}, which is the same as @litchar{{0,}}.}
很明显，@litchar{+}和@litchar{?}是@litchar{{1,}}和@litchar{{0,1}}的缩写，@litchar{*}是@litchar{{,}}的缩写，这个和@litchar{{0,}}一样。

@interaction[
#:eval rx-eval
(regexp-match #px"[aeiou]{3}" "vacuous")
(regexp-match #px"[aeiou]{3}" "evolve")
(regexp-match #px"[aeiou]{2,3}" "evolve")
(regexp-match #px"[aeiou]{2,3}" "zeugma")
]

@;{The quantifiers described so far are all @deftech{greedy}: they match
the maximal number of instances that would still lead to an overall
match for the full pattern.}
到目前为止所描述的量词都是@deftech{贪婪的（greedy）}：它们匹配最大数量的实例，这样会导致一个对整个模式的总体匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"<.*>" "<tag1> <tag2> <tag3>")
]

@;{To make these quantifiers @deftech{non-greedy}, append a @litchar{?}
to them.  Non-greedy quantifiers match the minimal number of instances
needed to ensure an overall match.}
为了使这些量词成为@deftech{非贪婪的（non-greedy）}，给它们追加一个@litchar{?}。非贪婪量词匹配最小数量的实例需要确保整体匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"<.*?>" "<tag1> <tag2> <tag3>")
]

@;{The non-greedy quantifiers are respectively: @litchar{*?},
@litchar{+?}, @litchar{??}, @litchar["{"]@math{m}@litchar["}?"],
@litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}?"].  Note the two
uses of the metacharacter @litchar{?}.}
非贪婪量词分别为：@litchar{*?}、@litchar{+?}、@litchar{??}、@litchar["{"]@math{m}@litchar["}?"]、@litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}?"]。注意元字符@litchar{?}的这两种使用。

@; ----------------------------------------

@;{@section[#:tag "regexp-clusters"]{Clusters}}
@section[#:tag "regexp-clusters"]{簇}

@;{@deftech{Clustering}---enclosure within parens
@litchar{(}...@litchar{)}---identifies the enclosed
@deftech{subpattern} as a single entity.  It causes the matcher to
capture the @deftech{submatch}, or the portion of the string matching
the subpattern, in addition to the overall match:}
@deftech{簇（Clustering）}——圈占于括号内@litchar{(}...@litchar{)}——识别封闭的@deftech{子模式（subpattern）}作为一个单一的实体。它导致匹配器去捕获@deftech{子匹配（submatch）}，或者字符串的一部分匹配这个子模式，除了整体匹配除外：

@interaction[
#:eval rx-eval
(regexp-match #rx"([a-z]+) ([0-9]+), ([0-9]+)" "jan 1, 1970")
]

@;{Clustering also causes a following quantifier to treat the entire
enclosed subpattern as an entity:}
簇也导致一个后面的量词把整个封闭模式作为一个实体处理：

@interaction[
#:eval rx-eval
(regexp-match #rx"(pu )*" "pu pu platter")
]

@;{The number of submatches returned is always equal to the number of
subpatterns specified in the regexp, even if a particular subpattern
happens to match more than one substring or no substring at all.}
返回的匹配项数量总是等于在正则表达式中指定的子模式数量，即使一个特定的子模式碰巧匹配不止一个子字符串或根本没有子串。

@interaction[
#:eval rx-eval
(regexp-match #rx"([a-z ]+;)*" "lather; rinse; repeat;")
]

@;{Here, the @litchar{*}-quantified subpattern matches three times, but
it is the last submatch that is returned.}
在这里，这个@litchar{*}量化的子模式匹配三次，但这是被返回的最后一个匹配项。

@;{It is also possible for a quantified subpattern to fail to match, even
if the overall pattern matches.  In such cases, the failing submatch
is represented by @racket[#f]}
对一个量化的子模式来说不匹配也是可能的，即使是整个模式匹配。在这种情况下，这个失败的子匹配被@racket[#f]体现。

@interaction[
#:eval rx-eval
(define date-re
  (code:comment @#,t{@;{match `month year' or `month day, year';}匹配“月年”或“月日年”})
  (code:comment @#,t{@;{subpattern matches day, if present}子模式匹配天，如果目前})
  #rx"([a-z]+) +([0-9]+,)? *([0-9]+)")
(regexp-match date-re "jan 1, 1970")
(regexp-match date-re "jan 1970")
]


@;{@subsection{Backreferences}}
@subsection[#:tag "Backreferences"]{反向引用}

@;{@tech{Submatch}es can be used in the insert string argument of the
procedures @racket[regexp-replace] and @racket[regexp-replace*].  The
insert string can use @litchar{\}@math{n} as a @deftech{backreference}
to refer back to the @math{n}th submatch, which is the substring
that matched the @math{n}th subpattern.  A @litchar{\0} refers to the
entire match, and it can also be specified as @litchar{\&}.}
@tech{子匹配}可用于插入程序@racket[regexp-replace]和@racket[regexp-replace*]的字符串参数。这个插入的字符串可以使用@litchar{\}@math{n}做为@deftech{反向引用（backreference）}来反向引用第@math{n}个匹配项，它是匹配第@math{n}个子模式的子字符串。一个@litchar{\0}引用整个匹配，并且它也可以被指定为@litchar{\&}。

@interaction[
#:eval rx-eval
(regexp-replace #rx"_(.+?)_" 
  "the _nina_, the _pinta_, and the _santa maria_"
  "*\\1*")
(regexp-replace* #rx"_(.+?)_" 
  "the _nina_, the _pinta_, and the _santa maria_"
  "*\\1*")

(regexp-replace #px"(\\S+) (\\S+) (\\S+)"
  "eat to live"
  "\\3 \\2 \\1")
]

@;{Use @litchar{\\} in the insert string to specify a literal backslash.
Also, @litchar{\$} stands for an empty string, and is useful for
separating a backreference @litchar{\}@math{n} from an immediately
following number.}
在插入字符串中使用@litchar{\\}来指定一个字面反斜杠。同样，@litchar{\$}代表一个空字符串，并且对从一个紧随其后的数字来分离一个反向引用@litchar{\}@math{n}是有用的。

@;{Backreferences can also be used within a @litchar{#px} pattern to
refer back to an already matched subpattern in the pattern.
@litchar{\}@math{n} stands for an exact repeat of the @math{n}th
submatch. Note that @litchar{\0}, which is useful in an insert string,
makes no sense within the regexp pattern, because the entire regexp
has not matched yet so you cannot refer back to it.}
反向引用也可以用在一个@litchar{#px}模式内部来引用返回给这个模式里的一个已经匹配的子模式。@litchar{\}@math{n}代表第@math{n}个子匹配的一个精确重复。注意这个@litchar{\0}，它在一个插入的字符串中是有用的，在正则表达式模式内部毫无意义，因为整个正则表达式不匹配而无法对它反向引用。

@interaction[
#:eval rx-eval
(regexp-match #px"([a-z]+) and \\1"
              "billions and billions")
]

@;{Note that the @tech{backreference} is not simply a repeat of the
previous subpattern.  Rather it is a repeat of the particular
substring already matched by the subpattern.}
注意，这个@tech{反向引用}不是简单的一个以前子模式的重复。而是一个已经被子模式匹配的特定子字符串的重复。

@;{In the above example, the @tech{backreference} can only match
@litchar{billions}.  It will not match @litchar{millions}, even though
the subpattern it harks back to---@litchar{([a-z]+)}---would have had
no problem doing so:}
在上面的例子中，@tech{反向引用}只能匹配@litchar{billions}。它不会匹配@litchar{millions}，即使这个子模式重新回到——@litchar{([a-z]+)}——这样做会没有问题：

@interaction[
#:eval rx-eval
(regexp-match #px"([a-z]+) and \\1"
              "billions and millions")
]

@;{The following example marks all immediately repeating patterns in a
number string:}
下面的示例在一个数字字符串中标记所有立即重复的模式：

@interaction[
#:eval rx-eval
(regexp-replace* #px"(\\d+)\\1"
  "123340983242432420980980234"
  "{\\1,\\1}")
]

@;{The following example corrects doubled words:}
下面的示例修正重叠字：

@interaction[
#:eval rx-eval
(regexp-replace* #px"\\b(\\S+) \\1\\b"
  (string-append "now is the the time for all good men to "
                 "to come to the aid of of the party")
  "\\1")
]

@;{@subsection{Non-capturing Clusters}}
@subsection[#:tag "Non-capturing-Clusters"]{非捕捉簇}

@;{It is often required to specify a cluster (typically for
quantification) but without triggering the capture of @tech{submatch}
information.  Such clusters are called @deftech{non-capturing}.  To
create a non-capturing cluster, use @litchar{(?:} instead of
@litchar{(} as the cluster opener.}
它通常需要指定一个簇（通常用于量化）但没有触发@tech{子匹配}信息的捕捉。这种簇被称为@deftech{非捕捉（non-capturing）}。为了创建一个非捕捉簇，使用@litchar{(?:}代替@litchar{(}作为这个簇开启器。

@;{In the following example, a non-capturing cluster eliminates the
``directory'' portion of a given Unix pathname, and a capturing
cluster identifies the basename.}
在下面的例子中，一个非捕捉簇消除了一个给定UNIX路径名的“目录”部分，并一个捕捉簇识别出基本名。

@margin-note{
 @;{But don't parse paths with regexps. Use functions like
 @racket[split-path], instead.}
   但不要用正则表达式解析路径。使用诸如@racket[split-path]之类的函数来代替。
   }

@interaction[
#:eval rx-eval
(regexp-match #rx"^(?:[a-z]*/)*([a-z]+)$" 
              "/usr/local/bin/racket")
]

@;???????????????????????????????????????????????????????/
@;{@subsection[#:tag "regexp-cloister"]{Cloisters}}
@subsection[#:tag "regexp-cloister"]{回廊}

@;{The location between the @litchar{?} and the @litchar{:} of a
non-capturing cluster is called a @deftech{cloister}. You can put
modifiers there that will cause the enclustered @tech{subpattern} to
be treated specially.  The modifier @litchar{i} causes the subpattern
to match case-insensitively:}
一个非捕捉簇@litchar{?}和@litchar{:}之间的位置称为@deftech{回廊（cloister）}。你可以把修饰符放在这儿，有可能会使簇@tech{子模式（subpattern）}被特别处理。这个修饰符@litchar{i}使子模式匹配时不区分大小写：

@margin-note{
 @;{The term @defterm{cloister} is a useful, if terminally
cute, coinage from the abbots of Perl.}
   术语@defterm{回廊（cloister）}是一个有用的，如果最终的可爱，从Perl的住持创造的词语。
   }

@interaction[
#:eval rx-eval
(regexp-match #rx"(?i:hearth)" "HeartH")
]

@;{The modifier @litchar{m} causes the @tech{subpattern} to match in
@deftech{multi-line mode}, where @litchar{.} does not match a newline
character, @litchar{^} can match just after a newline, and @litchar{$}
can match just before a newline.}
修饰符@litchar{m}使@tech{子模式subpattern）}在@deftech{多行模式（multi-line mode）}匹配，在@litchar{.}的位置不匹配换行符，@litchar{^}仅在一个新行后可以匹配，而@litchar{$}仅在一个新行前可以匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"." "\na\n")
(regexp-match #rx"(?m:.)" "\na\n")
(regexp-match #rx"^A plan$" "A man\nA plan\nA canal")
(regexp-match #rx"(?m:^A plan$)" "A man\nA plan\nA canal")
]

@;{You can put more than one modifier in the cloister:}
你可以在回廊里放置多个修饰符：

@interaction[
#:eval rx-eval
(regexp-match #rx"(?mi:^A Plan$)" "a man\na plan\na canal")
]

@;{A minus sign before a modifier inverts its meaning.  Thus, you can use
@litchar{-i} in a @deftech{subcluster} to overturn the
case-insensitivities caused by an enclosing cluster.}
在修饰符前的一个减号反转它的意思。因此，你可以在@deftech{子类（subcluster）}中使用@litchar{-i}以翻转案例不由封闭簇造导致。

@interaction[
#:eval rx-eval
(regexp-match #rx"(?i:the (?-i:TeX)book)"
              "The TeXbook")
]

@;{The above regexp will allow any casing for @litchar{the} and
@litchar{book}, but it insists that @litchar{TeX} not be differently
cased.}
上述正表达式将允许任何针对@litchar{the}和@litchar{book}的外壳，但它坚持认为@litchar{TeX}有不同的包装。

@; ----------------------------------------

@;{@section[#:tag "regexp-alternation"]{Alternation}}
@section[#:tag "regexp-alternation"]{替代}

@;{You can specify a list of @emph{alternate} @tech{subpatterns} by
separating them by @litchar{|}.  The @litchar{|} separates
@tech{subpatterns} in the nearest enclosing cluster (or in the entire
pattern string if there are no enclosing parens).}
你可以通过用@litchar{|}分隔它们来指定@emph{替代（alternate）}@tech{子模式（subpatterns）}的列表。在最近的封闭簇里@litchar{|}分隔@tech{子模式（subpatterns）}（或在整个模式字符串里，假如没有封闭括号）。

@interaction[
#:eval rx-eval
(regexp-match #rx"f(ee|i|o|um)" "a small, final fee")
(regexp-replace* #rx"([yi])s(e[sdr]?|ing|ation)"
                 (string-append
                  "analyse an energising organisation"
                  " pulsing with noisy organisms")
                 "\\1z\\2")
]
 
@;{Note again that if you wish to use clustering merely to specify a list
of alternate subpatterns but do not want the submatch, use
@litchar{(?:} instead of @litchar{(}.}
不过注意，如果你想使用簇仅仅是指定替代子模式列表，却不想指定匹配项，那么使用@litchar{(?:}代替@litchar{(}。

@interaction[
#:eval rx-eval
(regexp-match #rx"f(?:ee|i|o|um)" "fun for all")
]

@;{An important thing to note about alternation is that the leftmost
matching alternate is picked regardless of its length.  Thus, if one
of the alternates is a prefix of a later alternate, the latter may not
have a chance to match.}
注意替代的一个重要事情是，最左匹配替代不管长短。因此，如果一个替代是后一个替代的前缀，后者可能没有机会匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"call|call-with-current-continuation" 
              "call-with-current-continuation")
]

@;{To allow the longer alternate to have a shot at matching, place it
before the shorter one:}
为了让较长的替代在匹配中有一个镜头，把它放在较短的一个之前：

@interaction[
#:eval rx-eval
(regexp-match #rx"call-with-current-continuation|call"
              "call-with-current-continuation")
]

@;{In any case, an overall match for the entire regexp is always
preferred to an overall non-match.  In the following, the longer
alternate still wins, because its preferred shorter prefix fails to
yield an overall match.}
在任何情况下，对于整个正则表达式的整体匹配总是倾向于整体的不匹配。在下面这里，较长的替代仍然更好，因为它的较短的前缀不能产生整体匹配。

@interaction[
#:eval rx-eval
(regexp-match
 #rx"(?:call|call-with-current-continuation) constrained"
 "call-with-current-continuation constrained")
]

@; ----------------------------------------

@;{@section{Backtracking}}
@section[#:tag "Backtracking"]{回溯}

@;{We've already seen that greedy quantifiers match the maximal number of
times, but the overriding priority is that the overall match succeed.
Consider}
我们已经明白贪婪的量词匹配的次数最多，但压倒一切的优先级才是整体匹配的成功。考虑以下内容

@interaction[
#:eval rx-eval
(regexp-match #rx"a*a" "aaaa")
]

@;{The regexp consists of two subregexps: @litchar{a*} followed by
@litchar{a}.  The subregexp @litchar{a*} cannot be allowed to match
all four @litchar{a}'s in the text string @racket[aaaa], even though
@litchar{*} is a greedy quantifier.  It may match only the first
three, leaving the last one for the second subregexp.  This ensures
that the full regexp matches successfully.}
这个正则表达式包括两个子正则表达式：@litchar{a*}，其次是@litchar{a}。子正则表达式@litchar{a*}不允许匹配文本字符串@racket[aaaa]里的所有的四个@litchar{a}，即使@litchar{*}是一个贪婪量词也一样。它可能仅匹配前面的三个，剩下最后一个给第二子正则表达式。这确保了完整的正则表达式匹配成功。

@;{The regexp matcher accomplishes this via a process called
@deftech{backtracking}.  The matcher tentatively allows the greedy
quantifier to match all four @litchar{a}'s, but then when it becomes
clear that the overall match is in jeopardy, it @emph{backtracks} to a
less greedy match of three @litchar{a}'s.  If even this fails, as in
the call}
正则表达式匹配器通过一个称为@deftech{回溯（backtracking）}的过程实现来这个。匹配器暂时允许贪婪量词匹配所有四个@litchar{a}，但当整体匹配处于岌岌可危的状态变得清晰时，它@emph{回溯（backtracks）}到一个不那么贪婪的三个@litchar{a}的匹配。如果这也失败了，与以下调用一样

@interaction[
#:eval rx-eval
(regexp-match #rx"a*aa" "aaaa")
]

@;{the matcher backtracks even further.  Overall failure is conceded
only when all possible backtracking has been tried with no success.}
匹配器回溯甚至更进一步。只有当所有可能的回溯尝试都没有成功时，整体失败才被承认。

@;{Backtracking is not restricted to greedy quantifiers.
Nongreedy quantifiers match as few instances as
possible, and progressively backtrack to more and more
instances in order to attain an overall match.  There
is backtracking in alternation too, as the more
rightward alternates are tried when locally successful
leftward ones fail to yield an overall match.}
回溯并不局限于贪婪量词。非贪婪量词匹配尽可能少的情况下，为了达到整体匹配，逐步回溯会有越来越多的实例。这里替代的回溯也更有向右替代的倾向，当局部成功的向左替代一旦失败则会产生一个整体的匹配。

@;{Sometimes it is efficient to disable backtracking.  For example, we
may wish to commit to a choice, or we know that trying alternatives is
fruitless.  A nonbacktracking regexp is enclosed in
@litchar{(?>}...@litchar{)}.}
有时禁用回溯是有效的。例如，我们可能希望作出选择，或者我们知道尝试替代是徒劳的。一个非回溯正则表达式在@litchar{(?>}...@litchar{)}里是封闭的。

@interaction[
#:eval rx-eval
(regexp-match #rx"(?>a+)." "aaaa")
]

@;{In this call, the subregexp @litchar{?>a+} greedily matches all four
@litchar{a}'s, and is denied the opportunity to backtrack.  So, the
overall match is denied.  The effect of the regexp is therefore to
match one or more @litchar{a}'s followed by something that is
definitely non-@litchar{a}.}
在这个调用里，子正则表达式@litchar{?>a+}贪婪地匹配所有四个@litchar{a}，并且回溯的机会被拒绝。因此，整体匹配被拒绝。这个正则表达式的效果因此对一个或多个@litchar{a}的匹配被某些明确@litchar{非a（non-a）}的予以继承。

@; ----------------------------------------

@;{@section{Looking Ahead and Behind}}
@section[#:tag "Looking-Ahead-and-Behind"]{前后查找}

@;{You can have assertions in your pattern that look @emph{ahead} or
@emph{behind} to ensure that a subpattern does or does not occur.
These ``look around'' assertions are specified by putting the
subpattern checked for in a cluster whose leading characters are:
@litchar{?=} (for positive lookahead), @litchar{?!} (negative
lookahead), @litchar{?<=} (positive lookbehind), @litchar{?<!}
(negative lookbehind).  Note that the subpattern in the assertion does
not generate a match in the final result; it merely allows or
disallows the rest of the match.}
用@litchar{?=}正向前查找窥探以提前确保其子模式能够匹配。

@;{@subsection{Lookahead}}
@subsection[#:tag "Lookahead"]{向前查找}

@;{Positive lookahead with @litchar{?=} peeks ahead to ensure that
its subpattern @emph{could} match.  }
用@litchar{?=}正向前查找窥探以提前确保其子模式能够匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"grey(?=hound)" 
  "i left my grey socks at the greyhound") 
]

@;{The regexp @racket[#rx"grey(?=hound)"] matches @litchar{grey}, but
@emph{only} if it is followed by @litchar{hound}.  Thus, the first
@litchar{grey} in the text string is not matched.}
正则表达式@racket[#rx"grey(?=hound)"]匹配@litchar{grey}，但@emph{仅仅}如果它后面紧跟着@litchar{hound}时成立。因此，文本字符串中的第一个@litchar{grey}不匹配。

@;{Negative lookahead with @litchar{?!} peeks ahead to ensure that its
subpattern @emph{could not} possibly match.}
用@litchar{?!}反向前查找窥探以提前确保其子模式@emph{不可能}匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"grey(?!hound)"
  "the gray greyhound ate the grey socks") 
]

@;{The regexp @racket[#rx"grey(?!hound)"] matches @litchar{grey}, but
only if it is @emph{not} followed by @litchar{hound}.  Thus the
@litchar{grey} just before @litchar{socks} is matched.}
正则表达式@racket[#rx"grey(?!hound)"]匹配@litchar{grey}，但只有@litchar{hound}@emph{不}跟着它才行。因此@litchar{grey}仅仅在@litchar{socks}之前才匹配。

@;{@subsection{Lookbehind}}
@subsection[#:tag "Lookbehind"]{向后查找}

@;{Positive lookbehind with @litchar{?<=} checks that its subpattern
@emph{could} match immediately to the left of the current position in
the text string.}
用@litchar{?<=}正向后查找检查其子模式@emph{可以}立即向文本字符串的当前位置左侧匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"(?<=grey)hound"
  "the hound in the picture is not a greyhound") 
]

@;{The regexp @racket[#rx"(?<=grey)hound"] matches @litchar{hound}, but
only if it is preceded by @litchar{grey}.}
正则表达式@racket[#rx"(?<=grey)hound"]匹配@litchar{hound}，但前提是它是先于@litchar{grey}的。

@;{Negative lookbehind with @litchar{?<!} checks that its subpattern
could not possibly match immediately to the left.}
用@litchar{?<!}负向后查找检查它的子模式不可能立即匹配左侧。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"(?<!grey)hound"
  "the greyhound in the picture is not a hound")
]

@;{The regexp @racket[#rx"(?<!grey)hound"] matches @litchar{hound}, but
only if it is @emph{not} preceded by @litchar{grey}.}
正则表达式@racket[#rx"(?<!grey)hound"]匹配@litchar{hound}，但前提是它@emph{不是}先于@litchar{grey}的。

@;{Lookaheads and lookbehinds can be convenient when they
are not confusing.  }
向前查找和向后查找在它们不混淆时可以是实用的。

@; ----------------------------------------

@;{@section{An Extended Example}}
@section[#:tag "An-Extended-Example"]{一个扩展示例}

@(define ex-eval (make-base-eval))

@;{Here's an extended example from Friedl's @italic{Mastering Regular
Expressions}, page 189, that covers many of the features described in
this chapter.  The problem is to fashion a regexp that will match any
and only IP addresses or @emph{dotted quads}: four numbers separated
by three dots, with each number between 0 and 255.}
这是一个从@italic{《Friedl’s Mastering Regular Expressions》}（189页）来的扩展的例子，涵盖了本章中介绍的许多特征。问题是要修饰一个正则表达式，它将匹配任何且唯一的IP地址或@emph{点缀四周（dotted quads）}：四个数字被三个点分开，每个数字在0和255之间。

@;{First, we define a subregexp @racket[n0-255] that matches 0 through
255:}
首先，我们定义了一个子正则表达式@racket[n0-255]以匹配0到255：

@interaction[
#:eval ex-eval
(define n0-255
  (string-append
   "(?:"
   "\\d|"        (code:comment @#,t{  0 through   9})
   "\\d\\d|"     (code:comment @#,t{ 00 through  99})
   "[01]\\d\\d|" (code:comment @#,t{000 through 199})
   "2[0-4]\\d|"  (code:comment @#,t{200 through 249})
   "25[0-5]"     (code:comment @#,t{250 through 255})
   ")"))
]

@margin-note{
 @;{Note that @racket[n0-255] lists prefixes as preferred
alternates, which is something we cautioned against in
@secref["regexp-alternation"].  However, since we intend to anchor
this subregexp explicitly to force an overall match, the order of the
alternates does not matter.}
请注意@racket[n0-255]表前缀作为首选的替代品，这是我们在@secref["regexp-alternation"]里的告诫。然而，由于我们意愿锚定这个子正则表达式明确地迫使一个整体匹配，交替的顺序并不重要。
   }

@;{The first two alternates simply get all single- and
double-digit numbers.  Since 0-padding is allowed, we
need to match both 1 and 01.  We need to be careful
when getting 3-digit numbers, since numbers above 255
must be excluded.  So we fashion alternates to get 000
through 199, then 200 through 249, and finally 250
through 255.}
前两个替代只得到所有的一位数和两位数。因为0-padding是允许的，我们要匹配1和01。我们当得到3位数字时要小心，因为数字255以上必须排除。因此，我们的修饰替代，得到000至199，然后200至249，最后250至255。

@;{An IP-address is a string that consists of four @racket[n0-255]s with
three dots separating them.}
IP地址是一个字符串，包括四个@racket[n0-255]用三个点分隔。

@interaction[
#:eval ex-eval
(define ip-re1
  (string-append
   "^"        (code:comment @#,t{@;{nothing before}前面什么都没有})
   n0-255     (code:comment @#,t{@;{the first @racket[n0-255],}第一个@racket[n0-255],})
   "(?:"      (code:comment @#,t{@;{then the subpattern of}接着是子模式})
   "\\."      (code:comment @#,t{@;{a dot followed by}被一个点跟着})
   n0-255     (code:comment @#,t{@;{an @racket[n0-255],}一个 @racket[n0-255],})
   ")"        (code:comment @#,t{@;{which is}它被})
   "{3}"      (code:comment @#,t{@;{repeated exactly 3 times}恰好重复三遍})
   "$"))      (code:comment @#,t{@;{with nothing following}后边什么也没有})
]

@;{Let's try it out:}
让我们试试看：

@interaction[
#:eval ex-eval
(regexp-match (pregexp ip-re1) "1.2.3.4")
(regexp-match (pregexp ip-re1) "55.155.255.265")
]

@;{which is fine, except that we also have}
这很好，除此之外我们还有

@interaction[
#:eval ex-eval
(regexp-match (pregexp ip-re1) "0.00.000.00")
]

@;{All-zero sequences are not valid IP addresses!  Lookahead to the
rescue.  Before starting to match @racket[ip-re1], we look ahead to
ensure we don't have all zeros.  We could use positive lookahead to
ensure there @emph{is} a digit other than zero.}
所有的零序列都不是有效的IP地址！用向前查找救援。在开始匹配@racket[ip-re1]之前，我们向前查找以确保我们没有零。我们可以用正向前查找以确保@emph{是}一个非零的数字。

@interaction[
#:eval ex-eval
(define ip-re
  (pregexp
   (string-append
     "(?=.*[1-9])" (code:comment @#,t{ensure there's a non-0 digit})
     ip-re1)))
]

@;{Or we could use negative lookahead to ensure that what's ahead isn't
composed of @emph{only} zeros and dots.}
或者我们可以用负前查找确保前面不是@emph{只}由零和点组成。

@interaction[
#:eval ex-eval
(define ip-re
  (pregexp
   (string-append
     "(?![0.]*$)" (code:comment @#,t{@;{not just zeros and dots}不只是零点和点})
                  (code:comment @#,t{@;{(note: @litchar{.} is not metachar inside @litchar{[}...@litchar{]})}（注：@litchar{.}不是在@litchar{[}...@litchar{]}里面的匹配器)})
     ip-re1)))
]

@;{The regexp @racket[ip-re] will match all and only valid IP addresses.}
正则表达式@racket[ip-re]会匹配所有的并且唯一的IP地址。

@interaction[
#:eval ex-eval
(regexp-match ip-re "1.2.3.4")
(regexp-match ip-re "0.0.0.0")
]

@close-eval[ex-eval]
@close-eval[rx-eval]
