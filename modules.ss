;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Supporting libraries
;;; 
;;; Copyright (c) 2008 Aaron Hsu <arcfide@sacrideo.us>
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

(module check-arg
  (check-arg)
  (import scheme)
  (include "lib/Misc/check-arg.ss"))

(module let-opt
  (;let-optionals
   (let-optionals* %let-optionals*)
   :optional)
  (import scheme)
  (include "lib/Misc/let-opt.ss"))

(module char-utils
  (char-titlecase char-cased?)
  (import scheme)
  (include "lib/Misc/char-utils.ss"))

(module syn-param 
  (with-extended-parameter-operators with-extended-parameter-operators*)
  (import scheme)
  (include "lib/Riastradh/syn-param.scm"))

(module srfi-8
  (receive-values receive)
  (import scheme)
  (include "lib/SRFI/srfi-8.scm"))

(module srfi-14
  (char-set? char-set= char-set<=
   char-set-hash
   char-set-cursor char-set-ref char-set-cursor-next end-of-char-set?
   char-set-fold char-set-unfold char-set-unfold!
   char-set-for-each char-set-map
   char-set-copy char-set
   list->char-set  string->char-set
   list->char-set! string->char-set!
   ucs-range->char-set  ->char-set
   ucs-range->char-set!
   char-set->list char-set->string   
   char-set-size char-set-count char-set-contains?
   char-set-every char-set-any
   char-set-adjoin  char-set-delete
   char-set-adjoin! char-set-delete!
   char-set-complement  char-set-union  char-set-intersection
   char-set-complement! char-set-union! char-set-intersection!
   char-set-difference  char-set-xor  char-set-diff+intersection
   char-set-difference! char-set-xor! char-set-diff+intersection!
   char-set:lower-case          char-set:upper-case     char-set:title-case
   char-set:letter              char-set:digit          char-set:letter+digit
   char-set:graphic             char-set:printing       char-set:whitespace
   char-set:iso-control char-set:punctuation    char-set:symbol
   char-set:hex-digit           char-set:blank          char-set:ascii
   char-set:empty               char-set:full)   
  (import scheme)
  (import check-arg)
  (import let-opt)
  (include "lib/SRFI/srfi-14.ss"))  

(module srfi-13
  (string-map string-map!
   string-fold string-unfold
   string-fold-right string-unfold-right
   string-tabulate string-for-each string-for-each-index
   string-every string-any
   string-hash string-hash-ci
   string-compare string-compare-ci
   string=    string<    string>    string<=    string>=    string<>
   string-ci= string-ci< string-ci> string-ci<= string-ci>= string-ci<>
   string-downcase  string-upcase  string-titlecase
   string-downcase! string-upcase! string-titlecase!
   string-take string-take-right
   string-drop string-drop-right
   string-pad string-pad-right
   string-trim string-trim-right string-trim-both
   string-filter string-delete
   string-index string-index-right
   string-skip  string-skip-right
   string-count
   string-prefix-length string-prefix-length-ci
   string-suffix-length string-suffix-length-ci
   string-prefix? string-prefix-ci?
   string-suffix? string-suffix-ci?
   string-contains string-contains-ci   
   string-copy! substring/shared
   string-reverse string-reverse! reverse-list->string
   string-concatenate string-concatenate/shared string-concatenate-reverse
   string-concatenate-reverse/shared
   string-append/shared
   xsubstring string-xcopy!
   string-null?
   string-join
   string-tokenize
   string-replace)
  (import (except (alias scheme (bitwise-and logand))
                  string->list string-copy string-fill!))
  (import srfi-14)
  (import srfi-8)
  (import check-arg)
  (import let-opt)
  (import char-utils)
  (include "lib/SRFI/srfi-13.scm"))

(module foof-loop
  (appending
   (appending-reverse append-reverse)
   (down-from %loop-check
              loop-clause-error-if-not-name
              syntactic-error-if-not-name
              syntactic-name?)
   in-file
   in-list   
   (in-lists %cars&cdrs)
   in-port
   (in-string %in-vector
              loop-clause-error-if-not-names
              syntactic-error-if-not-names)
   in-string-reverse
   in-vector
   in-vector-reverse
   listing
   (listing! %listing!)
   listing-into!
   (listing-reverse %%%accumulating
                    %%accumulating
                    %accumulating
                    receive)
   (loop %loop
         syntactic-error-if-not-bvl
         syntactic-error-if-not-bvls
         with-extended-parameter-operators)
   loop-clause-error
   maximizing
   (minimizing %extremizing)
   multiplying
   summing
   syntactic-error
   up-from)
  (import (alias scheme (values* values)))
  (import syn-param)
  ; (import ria-let-values)
  (import srfi-8)
  (include "lib/Riastradh/foof-loop.scm"))

(module nested-foof-loop
  (collect-and
   (collect-average receive)
   collect-count
   collect-display
   collect-extremum
   collect-extremum*
   collect-extremum-by
   collect-first
   collect-into-string!
   collect-into-vector!
   collect-last
   collect-list
   collect-list!
   collect-list-into!
   collect-list-reverse
   collect-maximum
   collect-maximum*
   collect-maximum-by
   collect-minimum
   collect-minimum*
   collect-minimum-by
   collect-or 
   collect-product
   collect-stream
   collect-string 
   collect-string-of-length
   collect-sum
   collect-vector
   collect-vector-of-length
   iterate
   iterate!
   (iterate* values*)
   iterate-values
   lazy-recur   
   lazy-recur*
   (nested-lazy-loop %nested-loop)
   (nested-loop loop)
   recur
   recur*
   recur-values)  
  (import (alias scheme (values* values)))
  (import syn-param) 
  ; (import ria-let-values)
  (import srfi-8) 
  (import foof-loop)
  (include "lib/Riastradh/nested-foof-loop.scm"))

(module arcfide-misc
  (read-line string-split)
  (import scheme)
  (import srfi-13)
  (import foof-loop)
  (import nested-foof-loop)
  (include "lib/Arcfide/misc.ss"))

