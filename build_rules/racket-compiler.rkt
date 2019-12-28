#lang racket/base


(module* main #f
  (require
    racket/cmdline
    racket/file
    racket/string
    compiler/compiler
    racket/match)

  ;; Find arg file and read it
  (define args
    (let ([args (current-command-line-arguments)])
      (unless (= (vector-length args) 1)
        (error 'args "There must be exactly one argument"))
      (define arg (vector-ref args 0))
      (unless (string-prefix? arg "@")
        (error 'args "The arg must start with '@'"))
      (file->lines (substring arg 1))))

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
             (make-file-or-directory-link (path->complete-path path) gen-path)
             gen-path))]))

  ((compile-zos #f #:module? #t) (list source-path) output-dir-arg))
