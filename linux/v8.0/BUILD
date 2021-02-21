load(":files.bzl", "ZOS", "BINARIES")
genrule(
  name = "racket-src-linux",
  visibility = ["//visibility:public"],
  outs = ZOS + BINARIES,
  srcs = ["@racket_minimal_x86_64_8_0_linux//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)
