def racket_releases():
  native.http_file(
    name = "racket_minimal_x86_64_6_2_1",
    url = "http://mirror.racket-lang.org/installers/6.2.1/racket-minimal-6.2.1-x86_64-linux-debian-squeeze.sh",
    sha256 = "b6d8c2f935035bd32b9b6e93001cddc6c23f63b298b64fb0383d1bda2296e031"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_2_1_osx",
    url = "http://mirror.racket-lang.org/installers/6.2.1/racket-minimal-6.2.1-x86_64-macosx.dmg",
    sha256 = "84929d97299089a0078c3cbe4b9cb930713e0e055de9071d9b6f1667c9878d56"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_4_osx",
    url = "http://mirror.racket-lang.org/installers/6.4/racket-minimal-6.4-x86_64-macosx.dmg",
    sha256 = "0301c5c70ac7363f00e7e90bb55bc7d772eb0b668e013631c46a6bbe73445730"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_5_osx",
    url = "http://mirror.racket-lang.org/installers/6.5/racket-minimal-6.5-x86_64-macosx.tgz",
    sha256 = "3dae7a3420f8fbc8489db48629193ebe94b466cba1687df20dfafffe1a0e041f"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_6_osx",
    url = "http://mirror.racket-lang.org/installers/6.6/racket-minimal-6.6-x86_64-macosx.tgz",
    sha256 = "4689ae798bdd39e1559ee000267529b08a5d75a6968e380e86477e129ecea95f"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_10_osx",
    url = "http://mirror.racket-lang.org/installers/6.10/racket-minimal-6.10-x86_64-macosx.tgz",
    sha256 = "0cdd6aeb4986602ccfa9c5910d8fc6a8b0325a5153aedd3d72b6127abfb0a70e"
  )

  native.http_file(
    name = "racket_minimal_x86_64_6_10_1_linux",
    url = "https://download.racket-lang.org/releases/6.10.1/installers/racket-minimal-6.10.1-x86_64-linux.tgz",
    sha256 = "9fc37904923c99577d763e98e0563c2e24a33e287052403b4692345d3e4917d6",
  )

def rackunit_releases():
  native.http_file(
    name = "racket_rackunit_lib_6_4",
    url = "http://mirror.racket-lang.org/releases/6.4/pkgs/rackunit-lib.zip",
    sha256 = "3b08ca933d00a6602985d9d90721f9c035b46236ad53e1adda46082ba04bd344"
  )

  native.http_file(
    name = "racket_rackunit_lib_6_5",
    url = "http://mirror.racket-lang.org/releases/6.5/pkgs/rackunit-lib.zip",
    sha256 = "50430ab9bfae55abc141694c561def34ea6467d21419b2fa7a33230043fcdc7a"
  )

  native.http_file(
    name = "racket_rackunit_lib_6_6",
    url = "http://mirror.racket-lang.org/releases/6.6/pkgs/rackunit-lib.zip",
    sha256 = "0f4e6316d81bc0fe36154b3de5c6dd51e7c008d97947962e8874a591fd39222c"
  )
