load("@io_bazel_rules_docker//docker:docker.bzl", "docker_build")

docker_build(
  name = "minimal_racket",
  base = "@distroless//base:debug",
  entrypoint = ["/racket/bin/racket"],
  tars = ["@racket_minimal_x86_64_6_10_linux//file"],
  visibility = ["//visibility:public"],
)
