#lang racket/base
(require racket/tcp)
 

(define listener (tcp-listen 8080 4 #t))
(let loop ()
  (define-values (input output) (tcp-accept listener))
  (thread 
    (lambda ()
      (let loop ()
        (define in (read-bytes-line input))
        (unless (eof-object? in)
          (write-bytes in output)
          (newline output)
          (flush-output output)
          (loop)))
      (close-input-port input)
      (close-output-port output)))
  (loop))
