# Minimal Racket

This docker image is meant to be a very tiny image for running racket.
Currently it is built of two things: the libc Debian package and the racket
distribution.

## Building Instructions

1. Build the image and load it up into the local docker registry.

  ```sh
  bazel run //racket:minimal_racket
  ```
1. Create a container using the image.

  ```sh
  docker run -i -t bazel/racket:minimal_racket racket/bin/racket
  ```

