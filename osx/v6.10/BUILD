load(":files.bzl", "V610_OSX_ZOS")
load(":files.bzl", "V610_OSX_BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V610_OSX_ZOS + V610_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_6_10_osx//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)
