#reader(lib "docreader.ss" "scribble")
@require["../web-server.ss"]

@title[#:tag "dispatchers"
       #:style 'toc]{Dispatchers}

The @web-server is really just a particular configuration of a
dispatching server. There are a number of dispatchers that are defined
to support the @web-server . Other dispatching servers, or variants
of the @web-server , may find these useful. In particular, if you want
a peculiar processing pipeline for your @web-server installation, this
documentation will be useful.

@local-table-of-contents[]

@; ------------------------------------------------------------
@section[#:tag "dispatch.ss"]{General}

@file{dispatchers/dispatch.ss} provides a few functions for dispatchers in general.

@defthing[dispatcher? contract?]{
 Equivalent to @scheme[(connection? request? . -> . void)].
}
                  
@defproc[(dispatcher-interface-version? (any any/c)) boolean?]{
 Returns @scheme[#t] if @scheme[any] is @scheme['v1]. Returns @scheme[#f] otherwise.
} 

@defstruct[exn:dispatcher ()]{
 An exception thrown to indicate that a dispatcher does not apply to a particular
 request.
}

@defproc[(next-dispatcher) void]{
 Raises a @scheme[exn:dispatcher]
}

As the @scheme[dispatcher?] contract suggests, a dispatcher is a function that takes a connection
and request object and does something to them. Mostly likely it will generate
some response and output it on the connection, but it may do something
different. For example, it may apply some test to the request object, perhaps
checking for a valid source IP address, and error if the test is not passed, and call @scheme[next-dispatcher]
otherwise.

Consider the following example dispatcher, that captures the essence of URL rewriting:
@schemeblock[
 (code:comment "(url? -> url?) dispatcher? -> dispatcher?")
 (lambda (rule inner)
   (lambda (conn req)
     (code:comment "Call the inner dispatcher...")
     (inner conn
            (code:comment "with a new request object...")
            (copy-struct request req
                         (code:comment "with a new URL!")
                         [request-uri (rule (request-uri req))]))))
] 

@; ------------------------------------------------------------
@section[#:tag "filesystem-map.ss"]{Mapping URLs to Paths}

@file{dispatchers/filesystem-map.ss} provides a means of mapping
URLs to paths on the filesystem.

@defthing[url-path? contract?]{
 This contract is equivalent to @scheme[((url?) . ->* . (path? (listof path-element?)))].
 The returned @scheme[path?] is the path on disk. The list is the list of
 path elements that correspond to the path of the URL.}

@defproc[(make-url->path (base path?))
         url-path?]{
 The @scheme[url-path?] returned by this procedure considers the root
 URL to be @scheme[base]. It ensures that @scheme[".."]s in the URL
 do not escape the @scheme[base] and removes them silently otherwise.}                             

@defproc[(make-url->valid-path (url->path url->path?))
         url->path?]{
 Runs the underlying @scheme[url->path], but only returns if the path
 refers to a file that actually exists. If it is does not, then the suffix
 elements of the URL are removed until a file is found. If this never occurs,
 then an error is thrown.
 
 This is primarily useful for dispatchers that allow path information after
 the name of a service to be used for data, but where the service is represented
 by a file. The most prominent example is obviously servlets.}

@; ------------------------------------------------------------
@section[#:tag "dispatch-sequencer.ss"]{Sequencing}

@file{dispatchers/dispatch-sequencer.ss} defines a dispatcher constructor
that invokes a sequence of dispatchers until one applies.

@defproc[(make (dispatcher dispatcher?) ...)
         dispatcher?]{
 Invokes each @scheme[dispatcher], invoking the next if the first
 calls @scheme[next-dispatcher]. If no @scheme[dispatcher] applies,
 then it calls @scheme[next-dispatcher] itself.
}
 
@; XXX Kind of timeout that is proportional to bindings
@; ------------------------------------------------------------
@section[#:tag "dispatch-timeout.ss"]{Timeouts}

@file{dispatchers/dispatch-timeout.ss} defines a dispatcher constructor
that changes the timeout on the connection and calls the next
dispatcher.

@defproc[(make [new-timeout integer?])
         dispatcher?]{
 Changes the timeout on the connection with @scheme[adjust-connection-timeout!]
 called with @scheme[new-timeout].
}
                     
@; ------------------------------------------------------------
@section[#:tag "dispatch-lift.ss"]{Lifting Procedures}

@file{dispatchers/dispatch-lift.ss} defines:

@defproc[(make (proc (request? . -> . response?)))
         dispatcher?]{
 Constructs a dispatcher that calls @scheme[proc] on the request
 object, and outputs the response to the connection.
} 

@; XXX Change filtering to take predicate, rather than regexp
@; ------------------------------------------------------------
@section[#:tag "dispatch-filter.ss"]{Filtering Requests}

@file{dispatchers/dispatch-filter.ss} defines a dispatcher constructor 
that calls an underlying dispatcher
with all requests that pass a predicate.

@defproc[(make (regex regexp?) (inner dispatcher?))
         dispatcher?]{
 Calls @scheme[inner] if the URL path of the request, converted to
 a string, matches @scheme[regex]. Otherwise, calls @scheme[next-dispatcher].
} 

@; ------------------------------------------------------------
@section[#:tag "dispatch-pathprocedure.ss"]{Procedure Invocation upon Request}

@file{dispatchers/dispatch-pathprocedure.ss} defines a dispatcher constructor
for invoking a particular procedure when a request is given to a particular
URL path.

@defproc[(make (path string?) (proc (request? . -> . response?)))
         dispatcher?]{
 Checks if the request URL path as a string is equal to @scheme[path]
 and if so, calls @scheme[proc] for a response.
}
                     
This is used in the standard @web-server pipeline to provide
a URL that refreshes the password file, servlet cache, etc.
                     
@; ------------------------------------------------------------
@section[#:tag "dispatch-log.ss"]{Logging}

@file{dispatchers/dispatch-log.ss} defines a dispatcher constructor
for transparent logging of requests.

@; XXX Take formatting procedure
@defproc[(make [#:log-format log-format symbol? 'parenthesized-default]
               [#:log-path log-path (or/c path-string? false/c) #f])
         dispatcher?]{
 If @scheme[log-path] is not @scheme[#f] and @scheme[log-format] is
 @scheme['parenthesized-default] or @scheme[extended], then the request
 is logged to the @scheme[log-path]. In either case, @scheme[next-dispatcher]
 is invoked after this.
 
 If @scheme[log-format] is @scheme['parenthesized-default], then the 
 log looks like: @scheme[(list 'from (request-client-ip req)
                               'to (request-host-ip req)
                               'for (url->string (request-uri req)) 'at
                               (date->string (seconds->date (current-seconds)) #t))].

 If @scheme[log-format] is @scheme['extended], then the log looks like: 
 @scheme[`((client-ip ,(request-client-ip req))
           (host-ip ,(request-host-ip req))
           (referer ,(or/c bytes? false/c))                                              
           (uri ,(url->string (request-uri req)))
           (time ,(current-seconds)))].
}
                      
@; ------------------------------------------------------------
@section[#:tag "dispatch-passwords.ss"]{Password Protection}

@file{dispatchers/dispatch-passwords.ss} defines a dispatcher constructor
that performs HTTP Basic authentication filtering.

@defproc[(make [#:password-file password-file path-string? "passwords"]
               [#:authentication-responder 
                authentication-responder 
                ((url url?) (header (cons/c symbol? string?)) . -> . response?)
                (gen-authentication-responder "forbidden.html")])
         (values (-> void)
                 dispatcher?)]{
 The first returned value is a procedure that refreshes the password
 file used by the dispatcher.
 
 The dispatcher that is returned does the following:                               
 Checks if the request contains Basic authentication credentials, and that
 they are included in @scheme[password-file]. If they are not, 
 @scheme[authentication-responder] is called with a @scheme[header] that
 requests credentials. If they are, then @scheme[next-dispatcher] is
 invoked.
 
 @; XXX Separate out password-file work
 @scheme[password-file] is parsed as:
 @schemeblock[(list ([domain : string?]
                     [path : string-regexp?]
                     (list [user : symbol?]
                           [pass : string?])
                     ...)
                    ...)]
 For example:
 @schemeblock['(("secret stuff" "/secret(/.*)?" (bubba "bbq") (|Billy| "BoB")))]
}

@; ------------------------------------------------------------
@section[#:tag "dispatch-host.ss"]{Virtual Hosts}

@file{dispatchers/dispatch-host.ss} defines a dispatcher constructor
that calls a different dispatcher based upon the host requested.

@defproc[(make (lookup-dispatcher (symbol? . -> . dispatcher?)))
         dispatcher?]{
 Extracts a host from the URL requested, or the Host HTTP header,
 calls @scheme[lookup-dispatcher] with the host, and invokes the
 returned dispatcher. If no host can be extracted, then @scheme['none]
 is used.
}                                
                              
@; ------------------------------------------------------------
@section[#:tag "dispatch-files.ss"]{Serving Files}

@file{dispatchers/dispatch-files.ss} allows files to be served.
It defines a dispatcher construction procedure:

@defproc[(make [#:url->path url->path url->path?]
               [#:path->mime-type path->mime-type (path? . -> . bytes?) (lambda (path) TEXT/HTML-MIME-TYPE)]
               [#:indices indices (listof string?) (list "index.html" "index.htm")])
         dispatcher?]{
 Uses @scheme[url->path] to extract a path from the URL in the request
 object. If this path does not exist, then the dispatcher does not apply.
 If the path is a directory, then the @scheme[indices] are checked in order
 for an index file to serve. In that case, or in the case of a path that is
 a file already, @scheme[path->mime-type] is consulted for the MIME
 Type of the path. The file is then
 streamed out the connection object.
 
 This dispatcher supports HTTP Range GET requests and HEAD requests.}
                     
@; ------------------------------------------------------------
@section[#:tag "dispatch-servlets.ss"]{Serving Scheme Servlets}

@file{dispatchers/dispatch-servlets.ss} defines a dispatcher constructor
that runs servlets written in Scheme.

@; XXX Remove config:scripts
@defproc[(make [config:scripts (box/c cache-table?)]
               [#:url->path url->path url->path?]
               [#:make-servlet-namespace 
                make-servlet-namespace
                make-servlet-namespace?
                (make-make-servlet-namespace)]
               [#:responders-servlet-loading 
                responders-servlet-loading
                ((url url?) (exn any/c) . -> . response?)
                servlet-loading-responder]
               [#:responders-servlet
                responders-servlet
                ((url url?) (exn any/c) . -> . response?)
                (gen-servlet-responder "servlet-error.html")]
               [#:timeouts-default-servlet
                timeouts-default-servlet
                integer?
                30])
         (values (-> void)
                 dispatcher?)]{
 The first returned value is a procedure that refreshes the servlet
 code cache.
                               
 The dispatcher does the following:                               
 If the request URL contains a continuation reference, then it is invoked with the
 request. Otherwise, @scheme[url->path] is used to resolve the URL to a path.
 The path is evaluated as a module, in a namespace constructed by @scheme[make-servlet-namespace].
 If this fails then @scheme[responders-servlet-loading] is used to format a response
 with the exception. If it succeeds, then @scheme[start] export of the module is invoked.
 If there is an error when a servlet is invoked, then @scheme[responders-servlet] is
 used to format a response with the exception.
                       
 Servlets that do not specify timeouts are given timeouts according to @scheme[timeouts-default-servlet].
}

@; ------------------------------------------------------------
@section[#:tag "dispatch-lang.ss"]{Serving Web Language Servlets}

@file{dispatchers/dispatch-lang.ss} defines a dispatcher constructor
that runs servlets written in the Web Language.

@defproc[(make [#:url->path url->path url->path?]
               [#:make-servlet-namespace make-servlet-namespace 
                                         make-servlet-namespace?
                                         (make-make-servlet-namespace)]
               [#:responders-servlet-loading responders-servlet-loading servlet-loading-responder]
               [#:responders-servlet responders-servlet (gen-servlet-responder "servlet-error.html")])
         dispatcher?]{
 If the request URL contains a serialized continuation, then it is invoked with the
 request. Otherwise, @scheme[url->path] is used to resolve the URL to a path.
 The path is evaluated as a module, in a namespace constructed by @scheme[make-servlet-namespace].
 If this fails then @scheme[responders-servlet-loading] is used to format a response
 with the exception. If it succeeds, then @scheme[start] export of the module is invoked.
 If there is an error when a servlet is invoked, then @scheme[responders-servlet] is
 used to format a response with the exception.
}                      
