# Instructions for updating

1. Add new lines in MODULE.bazel, with blank sha256 entries.
1. Run `bazel build \@<rule\_name>//file:file` and copy over sha256 entries
1. Copy over version specific BUILD files and renumber names.
1. Run `extract-files.rkt` on downloaded file and write to files.bzl.
    * Then copy over binaries section.
1. Update toolchain in root BUILD file.
1. Test by running:
    * `bazel build //...`
    * `bazel test //...`
