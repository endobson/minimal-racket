racket_src_file_extensions = [".rkt"]
racket_zo_file_extensions = [".zo"]

RacketInfo = provider(fields=["transitive_zos", "transitive_links"])
racket_toolchain_type = "@minimal_racket//:racket_toolchain"

# Implementation of racket_binary and racket_test rules
def _bin_impl(ctx):
  toolchain = ctx.toolchains[racket_toolchain_type]
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
       toolchain.racket_bin.short_path) +
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
      transitive = [toolchain.core_racket.files] +
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
  toolchain = ctx.toolchains[racket_toolchain_type]
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
    executable = toolchain.racket_bin,
    arguments = [args],
    inputs = depset(
      transitive = [inputs,
                    toolchain.core_racket.files,
                    ctx.attr._bazel_tools[RacketInfo].transitive_zos,
                    ctx.attr._bazel_tools[RacketInfo].transitive_links],
    ),
    tools = [toolchain.racket_bin],
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
  toolchain = ctx.toolchains[racket_toolchain_type]
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
    executable=toolchain.racket_bin,
    arguments = [args],
    inputs = depset(
      direct = ctx.files.srcs,
      transitive = [toolchain.core_racket.files],
    ),
    tools = [toolchain.racket_bin],
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

def _racket_toolchain_impl(ctx):
  return [
    platform_common.ToolchainInfo(
      core_racket = ctx.attr.core_racket,
      racket_bin = ctx.executable.racket_bin,
    ),
  ]

_racket_bin_attrs = {
  "main_module": attr.label(
    mandatory=True,
    allow_single_file=racket_src_file_extensions,
  ),
  "data": attr.label_list(
    allow_files=True,
  ),
  "deps": attr.label_list(allow_files=racket_zo_file_extensions),
}

_racket_lib_attrs = {
  "srcs": attr.label_list(
    allow_files=racket_src_file_extensions,
    mandatory=True,
    allow_empty=False
  ),
  "data": attr.label_list(
    allow_files=True,
  ),
  "deps": attr.label_list(
    providers = [RacketInfo],
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
    allow_empty=False
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
  toolchains = [racket_toolchain_type],
  attrs = _racket_bin_attrs
)

racket_binary = rule(
  implementation=_bin_impl,
  executable=True,
  toolchains = [racket_toolchain_type],
  attrs = _racket_bin_attrs
)

racket_library = rule(
  implementation=_lib_impl,
  outputs = {
    "zo": "compiled/%{name}_rkt.zo",
  },
  toolchains = [racket_toolchain_type],
  attrs = _racket_lib_attrs
)

bootstrap_racket_library = rule(
  implementation=_bootstrap_lib_impl,
  outputs = {
    "zo": "compiled/%{name}_rkt.zo",
  },
  toolchains = [racket_toolchain_type],
  attrs = _racket_bootstrap_lib_attrs
)

racket_collection = rule(
  implementation = _collection_impl,
  outputs = {
    "links": "%{name}_links.rktd",
  },
  attrs = _racket_collection_attrs,
)

racket_toolchain = rule(
  implementation = _racket_toolchain_impl,
  attrs = {
    'core_racket': attr.label(mandatory=True),
    'racket_bin': attr.label(mandatory=True, executable=True, allow_files=True,
                             cfg="target"),
  }
)
