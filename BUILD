package(
  default_visibility = ["//visibility:public"],
)
exports_files(["releases.bzl", "racket.bzl"])

load(":racket.bzl", "racket_toolchain")

toolchain_type(name = "racket_toolchain")

racket_toolchain(
    name = "osx_racket_toolchain_impl",
    core_racket = "//osx/v7.0:racket-src-osx",
    racket_bin = "//osx/v7.0:bin/racket",
)

toolchain(
    name = "osx_racket_toolchain",
    target_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":osx_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)

racket_toolchain(
    name = "linux_racket_toolchain_impl",
    core_racket = "//linux/v7.0:racket-src-linux",
    racket_bin = "//linux/v7.0:bin/racket",
)

toolchain(
    name = "linux_racket_toolchain",
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":linux_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)
