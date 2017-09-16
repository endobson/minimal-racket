load("@minimal_racket//:racket.bzl", "bootstrap_racket_library", "racket_collection")

exports_files(["racket-compiler.rkt"])

bootstrap_racket_library(
    name = "racket-compiler",
    srcs = ["racket-compiler.rkt"],
    visibility = ["//visibility:public"],
)

racket_collection(
    name = "bazel-tools",
    deps = [
        ":racket-compiler"
    ],
    visibility = ["//visibility:public"],
)

