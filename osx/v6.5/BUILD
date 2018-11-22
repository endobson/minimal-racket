load(":files.bzl", "V65_OSX_FILES")
load(":files.bzl", "RACKUNIT_FILES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V65_OSX_FILES,
  srcs = ["@racket_minimal_x86_64_6_5_osx//file"],
  cmd = "tar xfz $< -C $(@D) --strip-components 1"
)

genrule(
  name = "rackunit",
  visibility = ["//visibility:public"],
  outs = RACKUNIT_FILES,
  srcs = ["@racket_rackunit_lib_6_5//file"],
  cmd = "unzip -q $< 'rackunit/*' -d $(@D)/collects"
)
