load(":files.bzl", "V70_LINUX_ZOS")
load(":files.bzl", "V70_LINUX_BINARIES")
genrule(
  name = "racket-src-linux",
  visibility = ["//visibility:public"],
  outs = V70_LINUX_ZOS + V70_LINUX_BINARIES,
  srcs = ["@racket_minimal_x86_64_7_0_linux//file"],
  cmd = "tar xfz $< -C $(@D) -s /^racket.//"
)
