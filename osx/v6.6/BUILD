load("files", "V66_OSX_ZOS")
load("files", "V66_OSX_BINARIES")
load("files", "RACKUNIT_FILES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V66_OSX_ZOS + V66_OSX_BINARIES,
  srcs = ["@racket_minimal_x86_64_6_6_osx//file"],
  cmd = "tar xfz $< -C $(@D) -s /^racket.//"
)

genrule(
  name = "rackunit",
  visibility = ["//visibility:public"],
  outs = RACKUNIT_FILES,
  srcs = ["@racket_rackunit_lib_6_6//file"],
  cmd = "unzip -q $< 'rackunit/*' -d $(@D)/collects"
)
