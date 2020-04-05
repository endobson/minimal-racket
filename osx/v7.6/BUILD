load(":files.bzl", "V76_OSX_ZOS")
load(":files.bzl", "V76_OSX_BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V76_OSX_ZOS + V76_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_7_6_osx//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)
