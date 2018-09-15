# TODO Re-enable docker image support
# load(
#     "@io_bazel_rules_docker//lang:image.bzl",
#     "dep_layer",
# )

racket_src_file_extensions = [".rkt"]
racket_zo_file_extensions = [".zo"]

# TODO add allowed fields once they are supported.
RacketInfo = provider()

# Implementation of racket_binary and racket_test rules
def _bin_impl(ctx):
  script_path = ctx.file.main_module.short_path

  link_files = depset(transitive=[dep[RacketInfo].transitive_links for dep in ctx.attr.deps])

  link_file_expression = "(let ([cur (current-directory)]) (current-library-collection-links (list #f "
  for link_file in link_files.to_list():
    link_file_expression += "(build-path (if (absolute-path? link-root) link-root (build-path cur link-root)) \"%s\") " % link_file.short_path
  link_file_expression += ")))"

  stub_script = (
    "#!/bin/bash\n" +
    'unset PLTCOMPILEDROOTS\n' +
    'RUNFILES="$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}").runfiles"\n' +
    'exec "$RUNFILES/%s/%s" --no-user-path ' % (
       ctx.workspace_name,
       ctx.executable._racket_bin.short_path) +
    '-l racket/base ' +
    '-e "(define link-root \\"$RUNFILES/%s\\")" ' % ctx.workspace_name +
    "-e '%s' " % link_file_expression +
    '-u "$RUNFILES/%s/%s" "$@"\n'% (
       ctx.workspace_name,
       script_path)
  )

  ctx.actions.write(
    output=ctx.outputs.executable,
    content=stub_script,
    is_executable=True
  )

  runfiles = ctx.runfiles(
    transitive_files = depset(
      transitive = [ctx.attr._core_racket.files] +
                   [dep[RacketInfo].transitive_zos for dep in ctx.attr.deps] +
                   [dep[RacketInfo].transitive_links for dep in ctx.attr.deps],
    ),
    collect_data = True,
  )

  return [
    DefaultInfo(
      runfiles = runfiles
    ),
  ]

def racket_compile(ctx, src_file, output_file, link_files, inputs):
  links = ctx.attr._bazel_tools[RacketInfo].transitive_links.to_list()
  if (len(links) != 1):
    fail("Only expecting one link in tools")
  link_file_expression = (
    '(current-library-collection-links (list #f (build-path (current-directory) "%s")))'
    % links[0].path)

  args = ctx.actions.args()
  args.add("--no-user-path")
  args.add_all(["-e", link_file_expression])
  args.add_all(["-l", "bazel-tools/racket-compiler"])
  args.add("--")
  args.add("--links")
  args.add_joined(link_files, format_each='"%s"', join_with=" ", format_joined="(%s)", omit_if_empty=False)
  args.add_all(["--file", '("%s" "%s" "%s")' % (src_file.path, src_file.short_path, src_file.root.path)])
  args.add_all(["--bin_dir", ctx.bin_dir.path])
  args.add_all(["--output_dir", output_file.dirname])

  ctx.actions.run(
    executable = ctx.executable._racket_bin,
    arguments = [args],
    inputs = depset(
      transitive = [inputs,
                    ctx.attr._core_racket.files,
                    ctx.attr._bazel_tools[RacketInfo].transitive_zos,
                    ctx.attr._bazel_tools[RacketInfo].transitive_links],
    ),
    tools = [ctx.executable._racket_bin],
    outputs=[output_file],
  )

def _lib_impl(ctx):
  if (len(ctx.attr.srcs) != 1):
    fail("Must supply exactly one source file: Got %s" % len(ctx.attr.srcs), "srcs")
  src_file = ctx.files.srcs[0]
  src_name = src_file.basename
  if (not(src_name.endswith(".rkt"))):
    fail("Source file must end in .rkt", "srcs")
  if (not(src_name.rpartition(".rkt")[0] == ctx.label.name)):
    fail("Source file must match rule name", "srcs")

  dependency_zos = depset(transitive=[dep[RacketInfo].transitive_zos for dep in ctx.attr.deps])
  dependency_links = depset(transitive=[dep[RacketInfo].transitive_links for dep in ctx.attr.deps])

  racket_compile(
    ctx,
    src_file = src_file,
    output_file = ctx.outputs.zo,
    link_files = dependency_links,
    inputs = depset(
      direct = ctx.files.srcs,
      transitive = [dependency_zos, dependency_links],
    ),
  )

  return [
    DefaultInfo(
      runfiles = ctx.runfiles(
        transitive_files = depset(
          direct = [ctx.outputs.zo],
          transitive = [data.files for data in ctx.attr.data] +
                       [dep.files for dep in ctx.attr.deps],
        ),
        collect_data = True,
      ),
    ),
    RacketInfo(
      transitive_zos = depset(
        direct = [ctx.outputs.zo],
        transitive = [dependency_zos],
      ),
      transitive_links = dependency_links,
    )
  ]

def _bootstrap_lib_impl(ctx):
  if (len(ctx.attr.srcs) != 1):
    fail("Must supply exactly one source file: Got %s" % len(ctx.attr.srcs), "srcs")
  src_file = ctx.files.srcs[0]
  src_name = src_file.basename
  if (not(src_name.endswith(".rkt"))):
    fail("Source file must end in .rkt", "srcs")
  if (not(src_name.rpartition(".rkt")[0] == ctx.label.name)):
    fail("Source file must match rule name", "srcs")

  args = ctx.actions.args()

  args.add("--no-user-path")
  args.add_all(["-l", "racket/base"])
  args.add_all(["-l", "racket/file"])
  args.add_all(["-l", "compiler/compiler"])

  if (src_file.root == ctx.bin_dir):
    fail("bootstrap_racket_lib doesn't support generated files")
  # The file needs to be in the same directory as the .zos because thats how the racket compiler works.
  args.add_all([
    "-e",
    "(define gen-path (build-path \"%s\" \"%s\"))" %
         (ctx.bin_dir.path, src_file.short_path)])
  args.add_all([
    "-e",
    "(define src-path gen-path)"])
  args.add_all([
    "-e",
    "(begin" +
    "  (make-parent-directory* gen-path) " +
    "  (make-file-or-directory-link (path->complete-path \"%s\") gen-path))" % src_file.path])
  args.add_all([
    "-e",
    "((compile-zos #f #:module? #t) (list src-path) \"%s\")" % ctx.outputs.zo.dirname])

  ctx.actions.run(
    executable=ctx.executable._racket_bin,
    arguments = [args],
    inputs= ctx.files.srcs + ctx.files._core_racket,
    tools = [ctx.executable._racket_bin],
    outputs=[ctx.outputs.zo],
  )

  return [
    RacketInfo(
      transitive_zos = depset([ctx.outputs.zo]),
      transitive_links = depset([])
    )
  ]

def _collection_impl(ctx):
  ctx.actions.write(
    output = ctx.outputs.links,
    content = "((\"%s\" \".\"))" % ctx.attr.name,
  )

  return [
    RacketInfo(
      transitive_zos = depset(
        transitive = [dep[RacketInfo].transitive_zos for dep in ctx.attr.deps]
      ),
      transitive_links = depset(
        direct = [ctx.outputs.links],
        transitive = [dep[RacketInfo].transitive_links for dep in ctx.attr.deps]
      )
    ),
  ]

_osx_core_racket = "@minimal_racket//osx/v6.12:racket-src-osx"
_osx_racket_bin ="@minimal_racket//osx/v6.12:bin/racket"

_racket_bin_attrs = {
  "main_module": attr.label(
    mandatory=True,
    single_file=True,
    allow_files=racket_src_file_extensions,
  ),
  "data": attr.label_list(
    allow_files=True,
  ),
  "deps": attr.label_list(allow_files=racket_zo_file_extensions),
  "_core_racket": attr.label(
    default=Label(_osx_core_racket),
    cfg="host"
  ),
  "_racket_bin": attr.label(
    default=Label(_osx_racket_bin),
    executable=True,
    allow_files=True,
    cfg="host"
  ),
}

_racket_lib_attrs = {
  "srcs": attr.label_list(
    allow_files=racket_src_file_extensions,
    mandatory=True,
    non_empty=True
  ),
  "data": attr.label_list(
    allow_files=True,
  ),
  "deps": attr.label_list(
    providers = [RacketInfo],
  ),
  "_core_racket": attr.label(
    default=Label(_osx_core_racket),
    cfg="host"
  ),
  "_racket_bin": attr.label(
    default=Label(_osx_racket_bin),
    executable=True,
    allow_files=True,
    cfg="host",
  ),
  "_bazel_tools": attr.label(
    default=Label("@minimal_racket//build_rules:bazel-tools"),
    providers = [RacketInfo],
    cfg="host",
  ),
}

_racket_bootstrap_lib_attrs = {
  "srcs": attr.label_list(
    allow_files=racket_src_file_extensions,
    mandatory=True,
    non_empty=True
  ),
  "_core_racket": attr.label(
    default=Label(_osx_core_racket),
    cfg="host"
  ),
  "_racket_bin": attr.label(
    default=Label(_osx_racket_bin),
    executable=True,
    allow_files=True,
    cfg="host",
  ),
}


_racket_collection_attrs = {
  "deps": attr.label_list(
    providers = [RacketInfo],
  ),
}

_racket_bundle_attrs = {
  "deps": attr.label_list(
    providers = [RacketInfo],
  ),
}

racket_test = rule(
  implementation=_bin_impl,
  test=True,
  executable=True,
  attrs = _racket_bin_attrs
)

racket_binary = rule(
  implementation=_bin_impl,
  executable=True,
  attrs = _racket_bin_attrs
)

racket_library = rule(
  implementation=_lib_impl,
  outputs = {
    "zo": "compiled/%{name}_rkt.zo",
  },
  attrs = _racket_lib_attrs
)

bootstrap_racket_library = rule(
  implementation=_bootstrap_lib_impl,
  outputs = {
    "zo": "compiled/%{name}_rkt.zo",
  },
  attrs = _racket_bootstrap_lib_attrs
)

racket_collection = rule(
  implementation = _collection_impl,
  outputs = {
    "links": "%{name}_links.rktd",
  },
  attrs = _racket_collection_attrs,
)
