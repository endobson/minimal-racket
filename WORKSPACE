workspace(name = "minimal_racket")

load(":releases.bzl", "racket_releases")
racket_releases()

register_toolchains(
  '//:osx_racket_toolchain',
  '//:linux_racket_toolchain',
)
