load(":files.bzl", "V621_OSX_FILES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V621_OSX_FILES,
  srcs = ["@racket_minimal_x86_64_6_2_1_osx//file"],
  cmd = "7z x $< 'Racket v6.2.1/Racket v6.2.1/' -aoa -o$(@D) >/dev/null;" +
        "rm -rf \"$(@D)/v6.2.1\";" +
        "mv \"$(@D)/Racket v6.2.1/Racket v6.2.1/\" \"$(@D)/v6.2.1\";" +
        "rmdir \"$(@D)/Racket v6.2.1\";" +
        "cp -rfp $$(find $(@D)/v6.2.1 -depth 1) $(@D);" +
        "rm -rf \"$(@D)/v6.2.1\";"
)
