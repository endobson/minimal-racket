load("@minimal_racket//:racket.bzl",
     "racket_binary", "racket_library", "racket_test")
load("@io_bazel_rules_docker//docker:docker.bzl", "docker_image",)
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

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

# TODO Re-enable docker image support
# racket_image(
#     name = "hello-world-server-image",
#     main_module = "hello-world-server.rkt",
#     workspace_name = "minimal_racket",
#     deps = [
#       ":hello-world-server",
#     ]
# )
