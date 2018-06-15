load(":files.bzl", "V690_OSX_ZOS")
load(":files.bzl", "V690_OSX_BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V690_OSX_ZOS + V690_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_6_90_osx//file"],
  cmd = "tar xfz $< -C $(@D) -s /^racket.//"
)
