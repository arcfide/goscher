#! /usr/bin/env scheme-script
(import (chezscheme))

(define lib-dir "/home/arcfide/code")

(optimize-level 3)
(generate-inspector-information #f)

(define (lib path)
  (format "~a/~a" lib-dir path))

(load-shared-object "chez_sockets.so.1")
(source-directories 
  (cons (lib "arcfide/sockets") (source-directories)))

(make-boot-file "goscher.boot" '("petite")
  (lib "arcfide/chezweb/cheztangle.ss")
  (lib "srfi/private/include.chezscheme.sls")
  (lib "srfi/private/let-opt.sls")
  (lib "srfi/9/records.sls")
  (lib "srfi/39/parameters.chezscheme.sls")
  (lib "srfi/23/error.sls")
  (lib "srfi/14/char-sets.sls")
  (lib "srfi/14.sls")
  (lib "srfi/8/receive.sls")
  (lib "srfi/8.sls")
  (lib "srfi/13/strings.sls")
  (lib "srfi/13.sls")
  (lib "arcfide/extended-definitions.sls")
  (lib "riastradh/foof-loop/loop.sls")
  (lib "riastradh/foof-loop/nested.sls")
  (lib "riastradh/foof-loop.sls")
  (lib "arcfide/ffi-bind.sls")
  (lib "arcfide/errno.sls")
  (lib "arcfide/sockets/compat.chezscheme.sls")
  (lib "arcfide/sockets.sls")
  (lib "arcfide/sockets/socket-ports.chezscheme.w")
  "goscher.ss")

