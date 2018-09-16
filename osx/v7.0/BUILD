load(":files.bzl", "V70_OSX_ZOS")
load(":files.bzl", "V70_OSX_BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V70_OSX_ZOS + V70_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_7_0_osx//file"],
  cmd = "tar xfz $< -C $(@D) -s /^racket.//"
)
