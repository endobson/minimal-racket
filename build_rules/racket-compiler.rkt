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
  (work-request (reverse rev-args) request-id))

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

(define-namespace-anchor anchor)

(define (run-single-compile args)
  (define links-arg #f)
  (define file-arg #f)
  (define bin-dir-arg #f)
  (define output-file-arg #f)

  (command-line
    #:argv args
    #:once-each
    [("--links") links "Link files"
     (set! links-arg links)]
    [("--file") file "Source file tuple"
     (set! file-arg file)]
    [("--bin_dir") directory "Bin directory"
     (set! bin-dir-arg directory)]
    [("--output_file") file "Output file"
     (set! output-file-arg file)])

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

  (with-module-reading-parameterization
    (lambda ()
      (parameterize ([current-namespace (make-empty-namespace)])
        (namespace-attach-module (namespace-anchor->namespace anchor) 'racket)
        (compile-file source-path output-file-arg
                      (lambda (expr) (check-module-form expr 'unused source-path)))))))

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
