workspace(name = "minimal_racket")
load(":releases.bzl", "racket_releases", "rackunit_releases")

http_file(
  name = "libc_udeb",
  url = "http://http.us.debian.org/debian/pool/main/g/glibc/libc6-udeb_2.19-18+deb8u1_amd64.udeb",
  sha256 = "e6fc235ba3d43e3b1e06d0a73a8fe7a3558724db39c84146eb186b658d084532"
)

racket_releases()
rackunit_releases()


