load("/tools/build_defs/docker/docker", "docker_build")

docker_build(
  name = "minimal_racket",
  base = "//debian-base:minimal_debian",
  tars = [":racket-src.tar.gz"],
  directory = "/racket"
)

# Turn the shell file of the release into a tar file by stripping out all the
# shell code.
genrule(
  name = "racket-src",
  outs = ["racket-src.tar.gz"],
  srcs = ["@racket-minimal-x86_64-6.2.1//file"],
  cmd = "tail +519 $< > $@"
)
