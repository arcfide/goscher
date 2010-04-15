#! /usr/bin/scheme --program
(import (chezscheme) (arcfide building))

(load-shared-object "sockets.so.1")

(optimize-level 3)
(generate-inspector-information #f)
(source-directories
  (cons "/home/arcfide/code/arcfide/sockets"
        (source-directories)))

(define files
  (map resolve-library-path
    '((srfi private include)
      (srfi private let-opt)
      (srfi :9 records)
      (srfi :39 parameters)
      (srfi :23 error)
      (srfi :14 char-sets)
      (srfi :14)
      (srfi :8 receive)
      (srfi :8)
      (srfi :13 strings)
      (srfi :13)
      (arcfide extended-definitions)
      (riastradh foof-loop loop)
      (riastradh foof-loop nested)
      (riastradh foof-loop)
      (arcfide ffi-bind)
      (arcfide errno)
      (arcfide sockets compat)
      (arcfide sockets)
      (arcfide sockets socket-ports)
      "goscher")))
      
(apply make-boot-file 
  `("goscher.boot" ("petite") ,@files))
