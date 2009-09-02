;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Goscher: Scheme Gopher Server
;;; 
;;; Copyright (c) 2009 Aaron Hsu <arcfide@sacrideo.us>
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
;;;	SRFI 13
;;; 		STRING-TOKENIZE 
;;;		STRING-NULL? 
;;;		STRING-PREFIX?
;;; 	SRFI 14
;;;		CHAR-SET 
;;;		CHAR-SET-COMPLEMENT
;;;	DIRECTORY-SEPARATOR
;;;	FOOF-LOOP
;;;	NESTED-FOOF-LOOP
;;;	FILE-DIRECTORY?
;;;	FILE-REGULAR?
;;;	READ-LINE (Arcfide-Misc)
;;;	FORMAT 
;;;	MAKE-PARAMETER
;;;	LET-VALUES
;;;	WITH-OUTPUT-TO-FILE
;;;	REMP

(module (start-proc)
	(import (chezscheme)
		(only (srfi :13) string-tokenize string-null? string-prefix?)
		(only (srfi :14) char-set char-set-complement)
		(riastradh foof-loop))

(define special-files
  '("+INDEX"))

(define gopher-entry-format "~a~a	~a	~a	~d")

(define conf-dir
	(make-parameter "/etc/goscher/"
		(lambda (x) (unless (string? x) (error 'conf-dir "Invalid conf-dir value" x)) x)))
(define root-dir
	(make-parameter "/var/goscher/"
		(lambda (x) (unless (string? x) (error 'root-dir "Invalid root-dir value" x)) x)))
(define log-file
	(make-parameter "/var/log/goscher"
		(lambda (x) (unless (string? x) (error 'log-file "Invalid log-file value" x)) x)))

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

(define run-goscher
  (lambda ()
    (let-values ([(path plus?) (get-request)])
      (when path
        (cond
          [plus? (plus-kludge path)]
          [(file-directory? path) 
           (goscher-directory path)]
          [(file-regular? path) 
           (goscher-file path)]
          [else 
            (goscher-not-found)])))))

(define goscher-not-found
  (lambda ()
    (display "3Error! Please contact Administrator.		")
    (display (goscher-host))
    (display #\tab)
    (display (goscher-port))
    (print-crlf)))

(define plus-kludge
  (lambda (path)
    (display "+-1") (print-crlf)
    (format #t "+INFO: 1Main menu (non-gopher+)		~a	~d"
      (goscher-host) (goscher-port))
    (print-crlf)
    (print-lastline)))

(define goscher-log
  (lambda data 
    (with-output-to-file (log-file)
      (lambda () 
        (for-each write data)
        (newline))
      'append)))

(define get-request
  (lambda ()
    (let ([s (get-line (current-input-port))])
      (if (eof-object? s)
        (values #f #f)
        (let ([req (split-request-string s)])
          (cond 
            [(string-null? (car req)) 
             (values (root-dir) (gopher+? req))]
            [else 
             (values (directory+file #t "" (car req))
               (gopher+? req))]))))))

(define split-request-string 
  (lambda (str)
    (string-split #\tab str)))

(define gopher+?
  (lambda (request)
    (and (not (null? (cdr request))) 
         (char=? #\$ (string-ref (cadr request) 0)))))

(define goscher-directory
  (lambda (dir)
    (let ([db (goscher-index dir)])
      (iterate! (for entry rest (in-list (get-file-list dir)))
        (print-directory-entry entry (selector-path dir) db)))
    (print-lastline)))

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
  (lambda (entry dir db)
    (cond 
      [(gopher-link? entry) (print-gopher-link entry dir db)]
      [else 
        (format #t gopher-entry-format
          (entry-type entry dir db)
          (entry-user-name entry db)
          (entry-selector entry dir)
          (entry-host entry dir)
          (entry-port entry dir))])
    (print-crlf)))

(define gopher-link?
  (lambda (name) 
    (char=? #\@ (string-ref name (1- (string-length name))))))

(define print-gopher-link
  (lambda (entry dir db)
    (let ([attribs (call-with-input-file (directory+file #t dir entry) read)])
      (format #t gopher-entry-format
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

(define print-crlf
  (lambda ()
    (display #\return)
    (display #\newline)))

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
            (if ext 
                (let ([res (assoc (path-extension name) (extension-types))])
                  (if res (cdr res) 9))
                0)))))))

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

(define print-lastline
  (lambda ()
    (display #\.)
    (print-crlf)))

(define goscher-file
  (lambda (file)
    (let ([db (goscher-index (path-parent file))])
      (case (lookup-filetype (path-last file) db)
        [(0 4 6 I g) (goscher-document file)]
        [(5 9) (goscher-stream file)]
        [else (goscher-not-found)]))))

(define goscher-document
  (lambda (file)
    (goscher-stream file)
    (print-lastline)))

(define goscher-stream
  (lambda (file)
    (iterate! (for char (in-file file))
      (display char))))

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
	(let (
			[settings-path 
				(if (pair? maybe-file) 
					(car maybe-file)
					(string-append (conf-dir) "goscher.conf"))])
		(unless (file-exists? settings-path)
			(error 'load-settings "Could not find goscher.conf"))
		(settings (call-with-input-file settings-path read))))

(define (start-proc . fns)
	(define (grab x p)
		(let ([res (assq x (settings))])
			(or res (p))))
	(if (pair? fns)
		(load-settings (car fns))
		(load-settings))
	(load-extensions)
	(parameterize (
			[conf-dir (grab 'conf-dir conf-dir)]
			[root-dir (grab 'root-dir root-dir)]
			[log-file (grab 'log-file log-file)])
		(run-goscher)))

)

(scheme-start start-proc)
