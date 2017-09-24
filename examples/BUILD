load(
    "@minimal_racket//:racket.bzl",
    "racket_binary",
    "racket_library",
    "racket_test",
)


racket_library(
    name = "lib1",
    srcs  = ["lib1.rkt"],
)


racket_library(
    name = "binary-base",
    srcs  = ["binary-base.rkt"],
    deps = [
        ":lib1",
        "//examples/foo-collection",
    ]
)

racket_binary(
    name = "binary-example",
    main_module = "binary-base.rkt",
    deps = [
        ":binary-base"
    ]
)

racket_test(
    name = "test-example",
    main_module = "binary-base.rkt",
    deps = [
        ":binary-base"
    ]
)
