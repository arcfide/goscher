#! /usr/bin/scheme --program
(import (chezscheme))

(unless (pair? (command-line-arguments))
	(printf "~a: <in> <out> <in> <out>  ...~%" (car (command-line)))
	(exit 1))

(optimize-level 3)
(generate-inspector-information #f)

(let (
		[op 
			(open-file-output-port 
				(car (command-line-arguments))
				(file-options no-fail))])
	(let loop ([files (cdr (command-line-arguments))])
		(if (pair? files)
			(begin 
				(call-with-input-file (car files)
					(lambda (ip) (compile-port ip op)))
				(loop (cdr files)))
			(close-port op))))