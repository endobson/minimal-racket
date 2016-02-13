load("files", "V64_OSX_FILES")
genrule(
  name = "racket-src-osx",
  visibility = ["//visibility:public"],
  outs = V64_OSX_FILES,
  srcs = ["@racket_minimal_x86_64_6_4_osx//file"],
  cmd = "7z x $< 'Racket v6.4/Racket v6.4/' -aoa -o$(@D) >/dev/null;" +
        "rm -rf \"$(@D)/v6.4\";" +
        "mv \"$(@D)/Racket v6.4/Racket v6.4/\" \"$(@D)/v6.4\";" +
        "rmdir \"$(@D)/Racket v6.4\";" +
        "cp -rfp $$(find $(@D)/v6.4 -depth 1) $(@D);" +
        "rm -rf \"$(@D)/v6.4\";"
)
