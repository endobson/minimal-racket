workspace(name = "minimal_racket")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load(":releases.bzl", "racket_releases")
racket_releases()

http_archive(
  name = "platforms",
  sha256 = "8d08b89d730e5ef2dfa76ee1aae4ca9e08d770e8b8467ba03c1aa1394b27f616",
  strip_prefix = "platforms-753ad895fe8bb37ab2818d3fd2e9b48c56fc7fde",
  urls = ["https://github.com/bazelbuild/platforms/archive/753ad895fe8bb37ab2818d3fd2e9b48c56fc7fde.tar.gz"],
)

register_toolchains(
  '@minimal_racket//:osx_osx_racket_toolchain',
  '@minimal_racket//:linux_linux_racket_toolchain',
  '@minimal_racket//:osx_linux_racket_toolchain',
  '@minimal_racket//:linux_osx_racket_toolchain',
)
