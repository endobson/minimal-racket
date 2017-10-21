load("@io_bazel_rules_docker//docker:docker.bzl", "docker_build")

docker_build(
  name = "minimal_racket",
  base = "@distroless//base",
  entrypoint = ["/racket/bin/racket"],
  tars = ["@racket_minimal_x86_64_6_10_1_linux//file"],
)
