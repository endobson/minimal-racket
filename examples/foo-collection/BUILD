load(
    "@minimal_racket//:racket.bzl",
    "racket_collection",
    "racket_library",
)


racket_library(
    name = "foo",
    srcs  = ["foo.rkt"],
)

racket_collection(
    name = "foo-collection",
    deps = [
        ":foo",
    ],
    visibility = ["//visibility:public"],
)
