#lang racket/base

(require
  "lib1.rkt"
  foo-collection/foo)

(unless (= (+ lib1 foo) 11)
  (error 'test "Bad math"))

