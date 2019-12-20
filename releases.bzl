load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def racket_releases():
  http_file(
    name = "racket_minimal_x86_64_6_10_osx",
    urls = ["http://mirror.racket-lang.org/installers/6.10/racket-minimal-6.10-x86_64-macosx.tgz"],
    sha256 = "0cdd6aeb4986602ccfa9c5910d8fc6a8b0325a5153aedd3d72b6127abfb0a70e"
  )

  http_file(
    name = "racket_minimal_x86_64_6_12_osx",
    urls = ["http://mirror.racket-lang.org/installers/6.12/racket-minimal-6.12-x86_64-macosx.tgz"],
    sha256 = "c22fcab24049ca6e36b7ced8185429f34851cf9860c0a1d95b6b63c363802ad5"
  )

  http_file(
    name = "racket_minimal_x86_64_7_0_osx",
    urls = ["https://download.racket-lang.org/releases/7.0/installers/racket-minimal-7.0-x86_64-macosx.tgz"],
    sha256 = "128437e775e95db02aaa857c8b06bbb2ee9409bf2f7935f06659de6316a4d6d4"
  )

  http_file(
    name = "racket_minimal_x86_64_7_5_osx",
    urls = ["https://download.racket-lang.org/releases/7.5/installers/racket-minimal-7.5-x86_64-macosx.tgz"],
    sha256 = "d718342c84b238101515385d568eaae97198e3af6fc9248cd3482de9bc7e9af8"
  )

  http_file(
    name = "racket_minimal_x86_64_7_0_linux",
    urls = ["https://download.racket-lang.org/releases/7.0/installers/racket-minimal-7.0-x86_64-linux.tgz"],
    sha256 = "bc144c57717b05b2f92d8a53a26a2453f1d0430315ffe74800aab2f56f54a7f8"
  )

  http_file(
    name = "racket_minimal_x86_64_7_5_linux",
    urls = ["https://download.racket-lang.org/releases/7.5/installers/racket-minimal-7.5-x86_64-linux.tgz"],
    sha256 = "5a216de21fb20f554dd5eacd546ed709b5e1b4c3faf9bda20523be99ca05d29b"
  )
