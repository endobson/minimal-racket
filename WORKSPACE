workspace(name = "minimal_racket")

http_archive(
    name = "io_bazel_rules_docker",
    strip_prefix = "rules_docker-cdd259b3ba67fd4ef814c88070a2ebc7bec28dc5",
    urls = ["https://github.com/bazelbuild/rules_docker/archive/cdd259b3ba67fd4ef814c88070a2ebc7bec28dc5.tar.gz"]
)

http_archive(
    name = "io_bazel_rules_go",
    urls = ["https://github.com/bazelbuild/rules_go/releases/download/0.15.3/rules_go-0.15.3.tar.gz"],
    sha256 = "97cf62bdef33519412167fd1e4b0810a318a7c234f5f8dc4f53e2da86241c492",
)
load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

http_archive(
  name = "distroless",
  sha256 = "b3dc40da225b6b2ec796cdaa5871df50620d4682a2e113e48a796b1450685587",
  strip_prefix = "distroless-b8d39117b525aec9e619a63e6fb711a7bded421f",
  urls = ["https://github.com/GoogleCloudPlatform/distroless/archive/b8d39117b525aec9e619a63e6fb711a7bded421f.tar.gz"]
)
load("@distroless//package_manager:package_manager.bzl",
    "package_manager_repositories",
    "dpkg_src",
    "dpkg_list",
)

package_manager_repositories()

dpkg_src(
    name = "debian_jessie",
    arch = "amd64",
    distro = "jessie",
    sha256 = "142cceae78a1343e66a0d27f1b142c406243d7940f626972c2c39ef71499ce61",
    snapshot = "20170821T035341Z",
    url = "http://snapshot.debian.org/archive",
)

dpkg_src(
    name = "debian_jessie_backports",
    arch = "amd64",
    distro = "jessie-backports",
    sha256 = "eba769f0a0bcaffbb82a8b61d4a9c8a0a3299d5111a68daeaf7e50cc0f76e0ab",
    snapshot = "20170821T035341Z",
    url = "http://snapshot.debian.org/archive",
)

dpkg_list(
    name = "package_bundle",
    packages = [
        "libc6",
        "ca-certificates",
        "openssl",
        "libssl1.0.0",
        "netbase",
        "tzdata",

        #java
        "zlib1g",
        "libgcc1",
        "libstdc++6",
        "openjdk-8-jre-headless",

        #python
        "libpython2.7-minimal",
        "python2.7-minimal",
        "libpython2.7-stdlib",

        #dotnet
        "libcurl3",
        "libgssapi-krb5-2",
        "libicu52",
        "liblttng-ust0",
        "libunwind8",
        "libuuid1",
        "liblzma5",
    ],
    sources = [
        "@debian_jessie//file:Packages.json",
        "@debian_jessie_backports//file:Packages.json",
    ],
)

http_archive(
    name = "runtimes_common",
    sha256 = "9f8fe8c6f8da6aae9071117286c31788ec54993c478b5fdd920b068bafba1a71",
    strip_prefix = "runtimes-common-eeaa7ffea5335576e3bf691d7916dae195cf544b",
    urls = ["https://github.com/GoogleCloudPlatform/runtimes-common/archive/eeaa7ffea5335576e3bf691d7916dae195cf544b.tar.gz"],
)

load(
    "@io_bazel_rules_docker//docker:docker.bzl",
    "docker_repositories",
)

http_file(
    name = "busybox",
    executable = True,
    sha256 = "b51b9328eb4e60748912e1c1867954a5cf7e9d5294781cae59ce225ed110523c",
    urls = ["http://busybox.net/downloads/binaries/1.27.1-i686/busybox"],
)

docker_repositories()

load(":releases.bzl", "racket_releases", "rackunit_releases")
racket_releases()
rackunit_releases()
