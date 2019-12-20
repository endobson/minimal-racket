load(":files.bzl", "V75_LINUX_ZOS")
load(":files.bzl", "V75_LINUX_BINARIES")
genrule(
  name = "racket-src-linux",
  visibility = ["//visibility:public"],
  outs = V75_LINUX_ZOS + V75_LINUX_BINARIES,
  srcs = ["@racket_minimal_x86_64_7_5_linux//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)
