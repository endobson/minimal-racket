#lang racket/base

(require
  racket/runtime-path
  racket/port)

(define-runtime-path file1 "test-data1")
(define-runtime-path file2 "test-data2")

(call-with-input-file file1 port->string)
(call-with-input-file file2 port->string)
