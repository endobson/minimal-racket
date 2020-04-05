load(":files.bzl", "ZOS", "BINARIES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = ZOS + BINARIES,
  srcs = ["@racket_minimal_x86_64_7_5_osx//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)
