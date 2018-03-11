load(":files.bzl", "V612_OSX_ZOS")
load(":files.bzl", "V612_OSX_BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V612_OSX_ZOS + V612_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_6_12_osx//file"],
  cmd = "tar xfz $< -C $(@D) -s /^racket.//"
)
