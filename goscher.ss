;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Goscher: Scheme Gopher Server
;;; 
;;; Copyright (c) 2011 Aaron Hsu <arcfide@sacrideo.us>
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

(load-shared-object "libc.so.6")
(load-shared-object "chez_sockets.so.1")

(module (start-proc)
	(import (chezscheme)
		(only (srfi :13) string-tokenize string-null? string-prefix?)
		(only (srfi :14) char-set char-set-complement)
		(riastradh foof-loop)
		(arcfide sockets)
		(arcfide sockets socket-ports))

;;;;;;;;;;;;;;;;;;;;;;
;; General Settings ;;
;;;;;;;;;;;;;;;;;;;;;;

;; special-files
;; List of files that are considered special in a given directory.
;; These are handled specially when rendering a directory.

(define special-files
	'("+INDEX"))

;; gopher-entry-format
;; This is the field layout of a gopher entry that we use throughout
;; the program. 

(define gopher-entry-format "~a~a\t~a\t~a\t~d")

;; log-file-default
;; This is the default log file location that is searched if the 
;; goscher settings do not contain a log file.

(define log-file-default "/var/log/goscher")

;; conf-dir
;; A string path that points to the directory containing the 
;; configuration files for Goscher.

(define conf-dir
	(make-parameter "/etc/goscher/"
		(lambda (x) 
			(unless (string? x) 
	(error 'conf-dir "Invalid conf-dir value" x)) x)))

;; root-dir
;; This is the root directory string path that is the root of the 
;; publically visible files on the server.

(define root-dir
	(make-parameter "/var/goscher/"
		(lambda (x) 
			(unless (string? x) 
	(error 'root-dir "Invalid root-dir value" x)) x)))

;; log-file
;; A textual port to be used to print logging information.

(define log-file
	(make-parameter #f
		(lambda (x) 
			(unless (or (not x) (and (port? x) (textual-port? x)))
				(error 'log-file "Invalid log-file value" x))
			x)))

;; extension-types
;; An association list of extensions and goscher file types.

(define extension-types
	(make-parameter '()
		(lambda (e) 
			(unless (or (null? e) (pair? e))
				(error 'extension-types "Extensions DB must be an A-list."))
			e)))

;; settings
;; An association list of the settings read in from the goscher 
;; configuration file.

(define settings
	(make-parameter '(())
		(lambda (e)
			(unless (pair? e)
				(error 'settings "Must use an alist for the settings, not ~s" e))
			e)))

;;;;;;;;;;;;;;;;;;;;;;;;
;; Settings accessors ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; goscher-host : → host-string
;; Searches the settings to get the host of the server.

(define (goscher-host)
	(let ([res (assq 'host (settings))])
		(if res (cdr res) (error 'goscher-host "No definition for host."))))

;; goscher-port : → port
;; The port of the goscher server extracted from the settings.

(define (goscher-port)
	(let ([res (assq 'port (settings))])
		(if res (cdr res) (error 'goscher-port "No port defined."))))

(define (inetd?)
	(let ([res (assq 'inetd (settings))])
		(and res (cdr res))))

;; 

(define latin-1-transcoder/crlf
	(make-transcoder (latin-1-codec) (eol-style crlf)))

(define (run-goscher/inetd)
	(let (
			[ip (transcoded-port (standard-input-port) latin-1-transcoder/crlf)]
			[op/binary (standard-output-port)]
			[op/text (transcoded-port (standard-output-port) latin-1-transcoder/crlf)])
		(handle-request/port ip op/binary op/text "inetd")))

(define (run-goscher/standalone)
	(define (loop)
		(let-values ([(sock addr) (accept-socket (s))])
			(fork-thread (delay (handle-request/socket sock addr))))
		(loop))
	(define s (make-parameter #f))
	(define a (make-parameter #f))
	(define (start-up)
		(s (create-socket socket-domain/internet 
											socket-type/stream 
											socket-protocol/auto))
		(set-socket-nonblocking! (s) #f)
		(a (string->internet-address (format "0.0.0.0:~d"
																				 (goscher-port))))
		(bind-socket (s) (a))
		(listen-socket (s) (socket-maximum-connections)))
	(define (clean-up) (close-socket (s)))
	(dynamic-wind start-up loop clean-up))
	
(define (handle-request/socket sock addr)
	(let (
			[op/binary (socket->output-port sock)]
			[op/text (socket->output-port sock latin-1-transcoder/crlf)]
			[ip (socket->input-port sock latin-1-transcoder/crlf)])
		(handle-request/port ip op/binary op/text addr)
		(close-socket sock)))

(define (handle-request/port ip op/binary op/text addr)
	(let-values ([(path plus?) (get-request ip addr)])
		(when (good-path? path)
			(cond
				[plus? (plus-kludge op/text path)]
				[(file-directory? path) 
				 (goscher-directory op/text path)]
				[(file-regular? path) 
				 (goscher-file op/binary op/text path)]
				[else 
					(goscher-not-found op/text)])))
	(for-each flush-output-port op/text op/binary)
	(for-each close-port op/text op/binary ip))

(define (good-path? path)
	(define (split x)
		(string-tokenize x (char-set-complement (char-set (directory-separator)))))
	(define (head? h l)
		(if (pair? h)
			(if (string=? (car h) (car l))
				(head? (cdr h) (cdr l))
				#f)
			#t))
	(let loop ([parts (split path)] [final '()])
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
	(let ([s (get-line ip)]
				[addr (if (string? addr)
									addr
									(internet-address->string addr))])
		(goscher-log `(received ,s from ,addr))
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

(define (gopher+? request)
	(and (not (null? request)) (not (null? (cdr request))) 
			 (char=? #\$ (string-ref (cadr request) 0))))

(define (goscher-directory op dir)
	(let ([db (goscher-index dir)])
		(iterate! (for entry rest (in-list (get-file-list dir)))
			(print-directory-entry op entry (selector-path dir) db)))
	(print-lastline op))

(define (get-file-list dir)
	(list-sort string<?
		(remp (lambda (e) (member e special-files))
			(directory-list dir))))

(define (goscher-index dir)
	(let ([index-fname (directory+file #f dir "+INDEX")])
		(if (file-exists? index-fname)
				(call-with-input-file index-fname read)
				'())))

(define (selector-path dir)
	(if (string-prefix? (root-dir) dir)
			(substring dir (string-length (root-dir)) (string-length dir))
			dir))

(define (print-directory-entry op entry dir db)
	(cond 
		[(gopher-link? entry) (print-gopher-link op entry dir db)]
		[else 
			(format op gopher-entry-format
				(entry-type entry dir db)
				(entry-user-name entry db)
				(entry-selector entry dir)
				(entry-host entry dir)
				(entry-port entry dir))])
	(put-string op "\n"))

(define (gopher-link? name) 
	(char=? #\@ (string-ref name (1- (string-length name)))))

(define (print-gopher-link op entry dir db)
	(let ([attribs (call-with-input-file (directory+file #t dir entry) read)])
		(format op gopher-entry-format
			(get-attribute attribs 'type (lookup-filetype entry db))
			(get-attribute attribs 'name entry)
			(get-attribute attribs 'selector entry)
			(get-attribute attribs 'server (goscher-host))
			(get-attribute attribs 'port (goscher-port)))))

(define get-attribute
	(case-lambda 
		[(db key) (get-attribute db key "")]
		[(db key default)
		 (let ([val (assq key db)])
			 (if val (cdr val) default))])) 

(define (entry-type entry dir db)
	(if (file-directory? (directory+file #t dir entry)) 
		1
		(lookup-filetype entry db)))

(define (lookup-filetype name db)
	(let* ([db (assoc name db)]
				 [type (if db (assq 'type (cdr db)) #f)])
		(if type (cdr type)
			(if (char=? #\. (string-ref name 0))
				0
				(let ([ext (path-extension name)])
					(if (string-null? ext) 0
							(let ([res (assoc ext (extension-types))])
								(if res (cdr res) 9))))))))

(define (entry-user-name name db)
	(let ([entry (assoc name db)])
		(if entry
			(let ([username (assq 'name (cdr entry))])
				(if username (cdr username) name))
			name)))

(define (entry-selector entry dir)
	(directory+file #f dir entry))

(define (entry-host entry dir)
	(goscher-host))

(define (entry-port entry dir)
	(goscher-port))

(define (print-lastline op)
	(put-string op ".\n"))

(define (goscher-file op/binary op/text file)
	(let ([db (goscher-index (path-parent file))])
		(case (lookup-filetype (path-last file) db)
			[(0 4 6 I g) (goscher-document op/binary op/text file)]
			[(5 9) (goscher-stream op/binary file)]
			[else (goscher-not-found op/text)])))

(define (goscher-document opb opt file)
	(goscher-stream opb file)
	(print-lastline opt))

(define (goscher-stream op file)
	(let ([ip (open-file-input-port file)])
		(let loop ()
			(let ([c (get-u8 ip)])
				(if (eof-object? c)
						(close-port ip)
						(begin (put-u8 op c)
									 (loop)))))))

(define (directory+file root? dir file)
	(if (string-null? dir) 
		(string-append (if root? (root-dir) "") file)
		(string-append (if root? (root-dir) "")
			(if (char=? (directory-separator) 
									(string-ref dir (1- (string-length dir))))
					dir
					(string-append dir (string (directory-separator))))
			file)))

(define (load-extensions)
	(extension-types 
		(fold-left 
			(lambda (s e)
				(append (convert-extension-file e) s))
			'()
			(filter (lambda (e) (string-prefix? "extensions." e))
				(directory-list (conf-dir))))))

(define (convert-extension-file file)
	(let ([type (with-input-from-string (path-extension file) read)])
		(collect-list (for elem (in-file (directory+file #f (conf-dir) file)
															(lambda (p) (get-line p))))
			(cons elem type))))

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
			(errorf 'load-settings "Could not find ~s" settings-path))
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
	(if (inetd?) 
			(run-goscher/inetd)
			(run-goscher/standalone)))

)

(scheme-start start-proc)
