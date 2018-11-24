workspace(name = "minimal_racket")

load(":releases.bzl", "racket_releases")
racket_releases()

register_toolchains(
  '@minimal_racket//:osx_osx_racket_toolchain',
  '@minimal_racket//:linux_linux_racket_toolchain',
  '@minimal_racket//:osx_linux_racket_toolchain',
  '@minimal_racket//:linux_osx_racket_toolchain',
)
