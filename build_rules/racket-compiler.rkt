#lang racket/base

(require
  racket/cmdline
  racket/file
  racket/port
  racket/string
  compiler/compiler
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
     (write-varint port q)]))

(struct work-request (args request-id))

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
  (work-request (reverse rev-args) request-id))

(define (run-persistent-worker)
  (define proto-length (read-proto-varint (current-input-port) #t))
  (unless (eof-object? proto-length)
    (define port (make-limited-input-port (current-input-port) proto-length))
    (define req (read-work-request port))
    (run-single-compile (work-request-args req))
    ;; We don't include any output or handle multiple requests currently
    (write-varint 0 (current-output-port))
    (flush-output (current-output-port))
    (run-persistent-worker)))

(define (run-single-compile args)
  (define links-arg #f)
  (define file-arg #f)
  (define bin-dir-arg #f)
  (define output-dir-arg #f)

  (command-line
    #:argv args
    #:once-each
    [("--links") links "Link files"
     (set! links-arg links)]
    [("--file") file "Source file tuple"
     (set! file-arg file)]
    [("--bin_dir") directory "Bin directory"
     (set! bin-dir-arg directory)]
    [("--output_dir") directory "Output directory"
     (set! output-dir-arg directory)])

  ;; Setup collection-links
  (define cwd (current-directory))
  (define links
    (read (open-input-string links-arg)))
  (current-library-collection-links
    (cons #f (map (lambda (p) (build-path cwd p)) links)))

  ;; Determine source files
  (define bin-dir-path
    (if (equal? bin-dir-arg "")
        cwd
        (build-path cwd bin-dir-arg)))
  (define file-tuple
    (read (open-input-string file-arg)))
  (define source-path
    (match file-tuple
      [(list path short-path root)
       (define root-path
         (if (equal? root "")
             cwd
             (build-path cwd root)))
       (if (equal? root-path bin-dir-path)
           path
           (let ([gen-path
                   ;; TODO(endobson) fix this when there is a less hacky way.
                   (if (string-prefix? path "external/")
                       (build-path bin-dir-path path)
                       (build-path bin-dir-path short-path))])
             (make-parent-directory* gen-path)
             (when (file-exists? gen-path)
               (delete-file gen-path))
             (make-file-or-directory-link (path->complete-path path) gen-path)
             gen-path))]))

  ((compile-zos #f #:module? #t) (list source-path) output-dir-arg))

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
