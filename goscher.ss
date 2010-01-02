;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Goscher: Scheme Gopher Server
;;; 
;;; Copyright (c) 2010 Aaron Hsu <arcfide@sacrideo.us>
;;; 
;;; Permission to use, copy, modify, and distribute this software for
;;; any purpose with or without fee is hereby granted, provided that the
;;; above copyright notice and this permission notice appear in all
;;; copies.
;;; 
;;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
;;; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
;;; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
;;; DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
;;; OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
;;; TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
;;; PERFORMANCE OF THIS SOFTWARE.

;;; Dependencies:
;;;  SRFI 13
;;;     STRING-TOKENIZE 
;;;    STRING-NULL? 
;;;    STRING-PREFIX?
;;;   SRFI 14
;;;    CHAR-SET 
;;;    CHAR-SET-COMPLEMENT
;;;  DIRECTORY-SEPARATOR
;;;  FOOF-LOOP
;;;  NESTED-FOOF-LOOP
;;;  FILE-DIRECTORY?
;;;  FILE-REGULAR?
;;;  READ-LINE (Arcfide-Misc)
;;;  FORMAT 
;;;  MAKE-PARAMETER
;;;  LET-VALUES
;;;  WITH-OUTPUT-TO-FILE
;;;  REMP

(load-shared-object "libc.so.6")

(module (start-proc)
  (import (chezscheme)
    (only (srfi :13) string-tokenize string-null? string-prefix?)
    (only (srfi :14) char-set char-set-complement)
    (riastradh foof-loop)
    (arcfide sockets)
    (arcfide sockets socket-ports))

(define special-files
  '("+INDEX"))

(define gopher-entry-format "~a~a\t~a\t~a\t~d")

(define conf-dir
  (make-parameter "/etc/goscher/"
    (lambda (x) (unless (string? x) (error 'conf-dir "Invalid conf-dir value" x)) x)))
(define root-dir
  (make-parameter "/var/goscher/"
    (lambda (x) (unless (string? x) (error 'root-dir "Invalid root-dir value" x)) x)))
(define log-file-default "/var/log/goscher")
(define log-file
  (make-parameter #f
    (lambda (x) 
      (unless (or (not x) (and (port? x) (textual-port? x)))
        (error 'log-file "Invalid log-file value" x))
      x)))

(define extension-types
  (make-parameter '()
    (lambda (e) 
      (unless (or (null? e) (pair? e))
        (error 'extension-types "Extensions DB must be an A-list."))
      e)))

(define settings
  (make-parameter '(())
    (lambda (e)
      (unless (pair? e)
        (error 'settings "Must use an alist for the settings, not ~s" e))
      e)))

(define goscher-host
  (lambda () 
    (let ([res (assq 'host (settings))])
      (if res (cdr res) (error 'goscher-host "No definition for host.")))))

(define goscher-port
  (lambda ()
    (let ([res (assq 'port (settings))])
      (if res (cdr res) (error 'goscher-port "No port defined.")))))

(define (run-goscher)
  (define (loop)
    (let-values ([(sock addr) (accept-socket (s))])
      (fork-thread (delay (handle-request sock addr))))
    (loop))
  (define s (make-parameter #f))
  (define a (make-parameter #f))
  (define (start-up)
    (s (create-socket socket-domain/internet 
                      socket-type/stream 
                      socket-protocol/auto))
    (set-socket-nonblocking! (s) #f)
    (a (string->internet-address (format "127.0.0.1:~d"
                                         (goscher-port))))
    (bind-socket (s) (a))
    (listen-socket (s) (socket-maximum-connections)))
  (define (clean-up) (close-socket (s)))
  (dynamic-wind start-up loop clean-up))

(define (handle-request sock addr)
  (define trans (make-transcoder (latin-1-codec) (eol-style crlf)))
  (let-values ([(ip op) 
                (socket->port sock (buffer-mode block) trans)])
    (let-values ([(path plus?) (get-request ip addr)])
      (when (good-path? path)
        (cond
          [plus? (plus-kludge op path)]
          [(file-directory? path) 
           (goscher-directory op path)]
          [(file-regular? path) 
           (goscher-file op path)]
          [else 
            (goscher-not-found op)])))
    (close-port op)))

(define (good-path? path)
  (define (split x)
    (string-tokenize x (char-set-complement (char-set (directory-separator)))))
  (define (head? h l)
    (if (pair? h)
      (if (string=? (car h) (car l))
        (head? (cdr h) (cdr l))
        #f)
      #t))
  (let loop (
      [parts (split path)]
      [final '()])
    (if (pair? parts)
      (if (string=? ".." (car parts))
        (loop (cdr parts) (if (null? final) '() (cdr final)))
        (loop (cdr parts) (cons (car parts) final)))
      (head? (split (root-dir)) (reverse final)))))

(define (goscher-not-found op)
  (put-string op "3Error! Please contact Administrator.\t\t")
  (put-string op (goscher-host))
  (put-char op #\tab)
  (put-datum op (goscher-port))
  (put-string op "\n"))

(define (plus-kludge op path)
  (put-string op "+-1\n")
  (format op "+INFO: 1Main menu (non-gopher+)\t\t~a\t~d\n"
    (goscher-host) (goscher-port))
  (print-lastline op))

(define goscher-log
  (let ([m (make-mutex)])
    (lambda data 
      (when (log-file) 
        (with-mutex m
          (format (log-file) "~{~s\n~}" data))))))

(define (get-request ip addr)
  (let ([s (get-line ip)])
    (goscher-log `(received ,s from ,(internet-address->string addr)))
    (if (eof-object? s)
      (values #f #f)
      (let ([req (split-request-string s)])
        (cond 
          [(or (null? req) (string-null? (car req)))
           (values (root-dir) (gopher+? req))]
          [else 
           (values (directory+file #t "" (car req))
             (gopher+? req))])))))

(define (split-request-string str)
  (string-tokenize str (char-set-complement (char-set #\tab))))

(define gopher+?
  (lambda (request)
    (and (not (null? request)) (not (null? (cdr request))) 
         (char=? #\$ (string-ref (cadr request) 0)))))

(define goscher-directory
  (lambda (op dir)
    (let ([db (goscher-index dir)])
      (iterate! (for entry rest (in-list (get-file-list dir)))
        (print-directory-entry op entry (selector-path dir) db)))
    (print-lastline op)))

(define get-file-list
  (lambda (dir)
    (remp (lambda (e) (member e special-files))
      (directory-list dir))))

(define goscher-index
  (lambda (dir)
    (let ([index-fname (directory+file #f dir "+INDEX")])
      (if (file-exists? index-fname)
          (call-with-input-file index-fname read)
          '()))))

(define selector-path
  (lambda (dir)
    (if (string-prefix? (root-dir) dir)
        (substring dir (string-length (root-dir)) (string-length dir))
        dir)))

(define print-directory-entry 
  (lambda (op entry dir db)
    (cond 
      [(gopher-link? entry) (print-gopher-link op entry dir db)]
      [else 
        (format op gopher-entry-format
          (entry-type entry dir db)
          (entry-user-name entry db)
          (entry-selector entry dir)
          (entry-host entry dir)
          (entry-port entry dir))])
    (put-string op "\n")))

(define gopher-link?
  (lambda (name) 
    (char=? #\@ (string-ref name (1- (string-length name))))))

(define print-gopher-link
  (lambda (op entry dir db)
    (let ([attribs (call-with-input-file (directory+file #t dir entry) read)])
      (format op gopher-entry-format
        (get-attribute attribs 'type (lookup-filetype entry db))
  (get-attribute attribs 'name entry)
  (get-attribute attribs 'selector entry)
  (get-attribute attribs 'server (goscher-host))
  (get-attribute attribs 'port (goscher-port))))))

(define get-attribute
  (case-lambda 
    [(db key) (get-attribute db key "")]
    [(db key default)
     (let ([val (assq key db)])
       (if val (cdr val) default))])) 

(define entry-type
  (lambda (entry dir db)
    (if (file-directory? (directory+file #t dir entry)) 
      1
      (lookup-filetype entry db))))

(define lookup-filetype
  (lambda (name db)
    (let* ([db (assoc name db)]
           [type (if db (assq 'type (cdr db)) #f)])
      (if type (cdr type)
        (if (char=? #\. (string-ref name 0))
          0
          (let ([ext (path-extension name)])
            (if (string-null? ext) 0
                (let ([res (assoc ext (extension-types))])
                  (if res (cdr res) 9)))))))))

(define entry-user-name
  (lambda (name db)
    (let ([entry (assoc name db)])
      (if entry
        (let ([username (assq 'name (cdr entry))])
          (if username (cdr username) name))
        name))))

(define entry-selector
  (lambda (entry dir)
    (directory+file #f dir entry)))

(define entry-host
  (lambda (entry dir)
    (goscher-host)))

(define entry-port
  (lambda (entry dir)
    (goscher-port)))

(define (print-lastline op)
  (put-string op ".\n"))

(define (goscher-file op file)
  (let ([db (goscher-index (path-parent file))])
    (case (lookup-filetype (path-last file) db)
      [(0 4 6 I g) (goscher-document op file)]
      [(5 9) (goscher-stream op file)]
      [else (goscher-not-found op)])))

(define (goscher-document op file)
  (goscher-stream op file)
  (print-lastline op))

(define (goscher-stream op file)
  (define trans (make-transcoder (latin-1-codec) (eol-style none)))
  (let ([ip (open-file-input-port file 
                                  (file-options) 
                                  (buffer-mode block)
                                  trans)])
    (let loop ()
      (let ([c (get-char ip)])
        (if (eof-object? c)
            (close-port ip)
            (begin (put-char op c)
                   (loop)))))))

(define directory+file
  (lambda (root? dir file)
    (if (string-null? dir) 
      (string-append (if root? (root-dir) "") file)
      (string-append (if root? (root-dir) "")
        (if (char=? (directory-separator) 
                    (string-ref dir (1- (string-length dir))))
            dir
            (string-append dir (string (directory-separator))))
        file))))

(define load-extensions
  (lambda ()
    (extension-types 
      (fold-left 
        (lambda (s e)
          (append (convert-extension-file e) s))
        '()
        (filter (lambda (e) (string-prefix? "extensions." e))
          (directory-list (conf-dir)))))))

(define convert-extension-file
  (lambda (file)
    (let ([type (with-input-from-string (path-extension file) read)])
      (collect-list (for elem (in-file (directory+file #f (conf-dir) file)
                                (lambda (p) (get-line p))))
        (cons elem type)))))

(define (load-settings . maybe-file) 
  (define (grab x p)
    (let ([res (assq x (settings))])
      (if res (cdr res) (p))))
  (let (
      [settings-path 
        (if (pair? maybe-file) 
          (car maybe-file)
          (string-append (conf-dir) "goscher.conf"))])
    (unless (file-exists? settings-path)
      (error 'load-settings "Could not find goscher.conf"))
    (settings (call-with-input-file settings-path read))
    (conf-dir (grab 'conf-dir conf-dir))
    (root-dir (grab 'root-dir root-dir))
    (log-file (open-log-file (grab 'log-file log-file-default)))))

(define (open-log-file fname)
  (open-file-output-port
    fname
    (file-options append no-truncate no-fail)
    (buffer-mode line)
    (native-transcoder)))

(define (start-proc . fns)
  (if (pair? fns)
    (load-settings (car fns))
    (load-settings))
  (load-extensions)
  (run-goscher))

)

(scheme-start start-proc)
