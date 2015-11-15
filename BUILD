# This is my first build file
load("/tools/build_defs/docker/docker", "docker_build")


docker_build(
  name = "minimal_deb",
  visibility = ["//visibility:public"],
  debs = [":libc.deb"],
  tars = [":lib64-sym.tar"],
)

genrule(
  name = "libc-deb",
  outs = ["libc.deb"],
  srcs = ["@libc-udeb//file"],
  cmd = "cp $(location @libc-udeb//file) $@"
)


# This is done by hand since tar on osx doesn't support all the options needed.
# That makes it hard to make the script hermetic.
# genrule(
#   name = "lib64-sym",
#   outs = ["lib64-sym.tar"],
#   cmd = "ln -s lib lib64; " +
#         "TZ=UTC gnutar --numeric-owner --owner=0 --group=0 --mode 777" +
#         " --mtime=1970-1-1 -cf $@ lib64"
# )
