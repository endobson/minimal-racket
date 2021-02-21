workspace(name = "minimal_racket")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load(":releases.bzl", "racket_releases")
racket_releases()

http_archive(
  name = "platforms",
  sha256 = "5d7fc1ec2dc230873ceef88d4a0cc3daa9ba89a932051a4df10a6fce1cb988f4",
  strip_prefix = "platforms-d87d2b43046778da7b09d032f49a0028f3b4d321",
  urls = ["https://github.com/bazelbuild/platforms/archive/d87d2b43046778da7b09d032f49a0028f3b4d321.tar.gz"],
)

register_toolchains(
  '@minimal_racket//:osx_racket_bootstrap_toolchain',
  '@minimal_racket//:linux_racket_bootstrap_toolchain',
  '@minimal_racket//:osx_osx_racket_toolchain',
  '@minimal_racket//:linux_linux_racket_toolchain',
  '@minimal_racket//:osx_linux_racket_toolchain',
  '@minimal_racket//:linux_osx_racket_toolchain',
)
