#! /usr/bin/scheme --program
(import (chezscheme))

(unless (and (pair? (command-line-arguments)) (pair? (cdr (command-line-arguments))))
	(printf "~a: <final> <build_dir> <in>  ...~%" (car (command-line)))
	(exit 1))

(optimize-level 3)
(generate-inspector-information #f)

(define final-out (car (command-line-arguments)))
(define build-dir (cadr (command-line-arguments)))

(define (build-files files)
	(if (pair? files)
		(let ([outfile (string-append  build-dir (path-last (path-root (car files))) ".so")])
			(compile-file (string-append build-dir (car files)) outfile)
			(cons outfile (build-files (cdr files))))
		'()))

(let* (
		[out-files (build-files (cddr (command-line-arguments)))]
		[cmd (format "cat ~{'~a'~^ ~} > '~a'" out-files final-out)])
	(printf "~a~%" cmd)
	(system cmd))

(printf "~%Done!~%")
