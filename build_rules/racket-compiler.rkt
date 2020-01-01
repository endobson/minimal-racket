#lang racket/base

(require
  racket/cmdline
  racket/file
  racket/port
  racket/string
  compiler/compile-file
  syntax/modread
  racket/match)

(define (read-proto-varint port [allow-eof? #f])
  (cond
    [(eof-object? (peek-byte port))
     (if allow-eof?
         eof
         (error 'parse-proto "Bytestream ended while parsing a varint"))]
    [else
      (let loop ([acc 0] [mult 1])
        (define byte (read-byte port))
        (define val (bitwise-bit-field byte 0 7))
        (when (eof-object? byte)
          (error 'parse-proto "Bytestream ended while parsing a varint"))
        (define cont (bitwise-bit-set? byte 7))
        (define new-acc (+ acc (* mult val)))
        (if cont
            (loop new-acc (* mult 128))
            new-acc))]))

(define (read-proto-primitive port type)
  (case type
    [(string) (read-proto-string port (read-proto-varint port))]
    [(bytes) (read-proto-bytes port (read-proto-varint port))]
    [(int32) (read-proto-varint port)]
    [else (error 'read-proto-primitive "Not yet implemented: ~a" type)]))

(define (read-proto-string port length)
  (define bytes (read-bytes length port))
  (unless (equal? (bytes-length bytes) length)
    (error 'parse-proto "Bytestream ended in the middle of a string field"))
  (bytes->string/utf-8 bytes))

(define (read-proto-bytes port length)
  (define bytes (read-bytes length port))
  (unless (equal? (bytes-length bytes) length)
    (error 'parse-proto "Bytestream ended in the middle of a bytes field"))
  bytes)

(define (extract-wire-key value)
  (define encoding
    (case (bitwise-bit-field value 0 3)
      [(0) 'varint]
      [(1) '64bit]
      [(2) 'length-delimited]
      [(5) '32bit]
      [else (error 'extract-wire-key "Unknown encoding")]))
  (values (arithmetic-shift value -3)
          encoding))

(define (write-varint number port)
  (cond
    [(< number 128)
     (write-byte number port)]
    [else
     (define-values (q r) (quotient/remainder number 128))
     (write-byte (+ 128 r) port)
     (write-varint q port)]))

(define (write-tagged-int32 field-number val port)
  (write-varint (+ (arithmetic-shift field-number 3) 0) port)
  (write-varint val port))

(define (write-tagged-string field-number val port)
  (write-varint (+ (arithmetic-shift field-number 3) 2) port)
  (define bytes-val (string->bytes/utf-8 val))
  (write-varint (bytes-length bytes-val) port)
  (write-bytes bytes-val port))

(struct work-request (args request-id) #:transparent)

(define (read-work-request port)
  (define rev-args '())
  (define request-id #f)
  (let read-fields ()
    (define full-tag (read-proto-varint port #t))
    (unless (eof-object? full-tag)
      (match/values (extract-wire-key full-tag)
        [(1 'length-delimited)
         (set! rev-args (cons (read-proto-primitive port 'string) rev-args)) ]
        [(2 'length-delimited)
         ;; Currently we just ignore the input field
         (void (read-proto-primitive port 'bytes)) ]
        [(3 'varint)
         (when request-id
           (error 'read-work-request "Two request-id fields"))
         (set! request-id (read-proto-primitive port 'int32)) ]
        [(tag wire-type)
         (error 'persistent-worker "Unknown tag: ~a with wire-type: ~a" tag wire-type)])
      (read-fields)))
  (work-request (reverse rev-args) (or request-id 0)))

(define (run-persistent-worker)
  (define proto-length (read-proto-varint (current-input-port) #t))
  (unless (eof-object? proto-length)
    (define port (make-limited-input-port (current-input-port) proto-length))
    (define req (read-work-request port))
    (define stdout/stderr (open-output-string))
    (define stdin (open-input-string ""))
    (define exit-code
      (parameterize ([current-output-port stdout/stderr]
                     [current-error-port stdout/stderr]
                     [current-input-port stdin])
        (with-handlers ([exn?
                         (lambda (e)
                           ((error-display-handler) (exn-message e) e)
                           1)])
          (run-single-compile (work-request-args req))
          0)))
    (define work-response-bytes
      (let ([work-response-buffer (open-output-bytes)])
        (write-tagged-int32 1 exit-code work-response-buffer)
        (write-tagged-string 2 (get-output-string stdout/stderr) work-response-buffer)
        (write-tagged-int32 3 (work-request-request-id req) work-response-buffer)
        (get-output-bytes work-response-buffer)))

    (write-varint (bytes-length work-response-bytes) (current-output-port))
    (write-bytes work-response-bytes (current-output-port))
    (flush-output (current-output-port))

    (run-persistent-worker)))

(define (basename p)
  (let-values ([(base name dir?) (split-path p)])
    base))

(define-namespace-anchor anchor)

(define (run-single-compile args)
  (define collection-links #f)
  (define source-path #f)
  (define output-path #f)

  (command-line
    #:argv args
    #:once-each
    [("--links") links "Link files"
     (set! collection-links
           (cons #f (map path->complete-path (read (open-input-string links)))))]
    [("--source_file") path "Source file path"
     (set! source-path (build-path path))]
    [("--output_file") path "Output file path"
     (set! output-path (build-path path))])

  (define output-base-dir (basename (basename (path->complete-path output-path))))

  (parameterize ([current-namespace (make-empty-namespace)]
                 [current-load-relative-directory output-base-dir]
                 [current-write-relative-directory output-base-dir]
                 [current-library-collection-links collection-links])
    (namespace-attach-module (namespace-anchor->namespace anchor) 'racket)
    (with-module-reading-parameterization
      (lambda ()
        (call-with-input-file source-path
          (lambda (in)
            (port-count-lines! in)
            (define stx (read-syntax source-path in))
            (unless (eof-object? (read-syntax source-path in))
              (error 'compile "More than one object"))
            (call-with-output-file output-path
              (lambda (out)
                (write (compile-syntax (check-module-form stx 'unused source-path)) out)))))))))

(module* main #f
  (let ([args (current-command-line-arguments)])
    (unless (= (vector-length args) 1)
      (error 'args "There must be exactly one argument"))
    (define arg (vector-ref args 0))
    (if (equal? arg "--persistent_worker")
        (run-persistent-worker)
        (let ()
          ;; Find the arg file and read it
          (unless (string-prefix? arg "@")
            (error 'args "The arg must start with '@'"))
          (run-single-compile (file->lines (substring arg 1)))))))
