#!/usr/bin/env racket
#lang racket/base

(require
  racket/list

  racket/match
  racket/string
  racket/port
  racket/system
  racket/cmdline)

(match-define (vector path) (current-command-line-arguments))

(define files
  (string-split
    (string-trim
      (with-output-to-string
        (lambda ()
          (unless (system* "/usr/bin/env" "tar" "tfz" path)
            (error 'extract-files "Error listing file")))))
    "\n"))

(define zo-files (filter (lambda (f) (regexp-match? #rx".*\\.zo" f)) files))

(displayln "V70_OSX_ZOS = [")
(for ([zo zo-files])
  (printf "\"~a\",\n" (substring zo (string-length "racket/"))))
(displayln "]")
