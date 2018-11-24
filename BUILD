package(
  default_visibility = ["//visibility:public"],
)
exports_files(["releases.bzl", "racket.bzl"])

load(":racket.bzl", "racket_toolchain")

toolchain_type(name = "racket_toolchain")

racket_toolchain(
    name = "osx_osx_racket_toolchain_impl",
    exec_core_racket = "//osx/v7.0:racket-src-osx",
    exec_racket_bin = "//osx/v7.0:bin/racket",
    target_core_racket = "//osx/v7.0:racket-src-osx",
    target_racket_bin = "//osx/v7.0:bin/racket",
)

racket_toolchain(
    name = "linux_linux_racket_toolchain_impl",
    exec_core_racket = "//linux/v7.0:racket-src-linux",
    exec_racket_bin = "//linux/v7.0:bin/racket",
    target_core_racket = "//linux/v7.0:racket-src-linux",
    target_racket_bin = "//linux/v7.0:bin/racket",
)

racket_toolchain(
    name = "osx_linux_racket_toolchain_impl",
    exec_core_racket = "//osx/v7.0:racket-src-osx",
    exec_racket_bin = "//osx/v7.0:bin/racket",
    target_core_racket = "//linux/v7.0:racket-src-linux",
    target_racket_bin = "//linux/v7.0:bin/racket",
)

racket_toolchain(
    name = "linux_osx_racket_toolchain_impl",
    exec_core_racket = "//linux/v7.0:racket-src-linux",
    exec_racket_bin = "//linux/v7.0:bin/racket",
    target_core_racket = "//osx/v7.0:racket-src-osx",
    target_racket_bin = "//osx/v7.0:bin/racket",
)


toolchain(
    name = "osx_osx_racket_toolchain",
    exec_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":osx_osx_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)

toolchain(
    name = "linux_linux_racket_toolchain",
    exec_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":linux_linux_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)

toolchain(
    name = "osx_linux_racket_toolchain",
    exec_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":osx_linux_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)

toolchain(
    name = "linux_osx_racket_toolchain",
    exec_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":linux_osx_racket_toolchain_impl",
    toolchain_type = ":racket_toolchain",
)
