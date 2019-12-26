load("@minimal_racket//:racket.bzl",
     "racket_binary", "racket_library", "racket_test")

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

racket_library(
    name = "hello-world-server",
    srcs = ["hello-world-server.rkt"],
)

racket_binary(
    name = "hello-world-server-bin",
    main_module = "hello-world-server.rkt",
    deps = [
        ":hello-world-server",
    ]
)

racket_library(
    name = "data-example",
    srcs  = ["data-example.rkt"],
    data = ["test-data1"],
)

racket_test(
    name = "data-example_test",
    main_module = "data-example.rkt",
    deps = [
        ":data-example"
    ],
    data = ["test-data2"],
)
