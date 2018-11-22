workspace(name = "minimal_racket")

load(":releases.bzl", "racket_releases")
racket_releases()

register_toolchains(
  '@minimal_racket//:osx_racket_toolchain',
  '@minimal_racket//:linux_racket_toolchain',
)
