racket_src_file_extensions = [".rkt"]
racket_zo_file_extensions = [".zo"]

RacketInfo = provider(fields=["zos", "links", "data"])
racket_bootstrap_toolchain_type = "@minimal_racket//:racket_bootstrap_toolchain"
racket_toolchain_type = "@minimal_racket//:racket_toolchain"

# Implementation of racket_binary and racket_test rules
def _bin_impl(ctx):
  toolchain = ctx.toolchains[racket_toolchain_type]
  script_path = ctx.file.main_module.short_path

  link_files = depset(transitive=[dep[RacketInfo].links for dep in ctx.attr.deps])

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
       toolchain.target_racket_bin.short_path) +
    '-l racket/base ' +
    '-e "(define link-root \\"$RUNFILES/%s\\")" ' % ctx.workspace_name +
    "-e '%s' " % link_file_expression +
    '-u "$RUNFILES/%s/%s" "$@"\n'% (
       ctx.workspace_name,
       script_path)
  )

  stub_file = ctx.actions.declare_file(ctx.label.name)
  ctx.actions.write(
    output=stub_file,
    content=stub_script,
    is_executable=True
  )

  return [
    DefaultInfo(
      executable = stub_file,
      runfiles = ctx.runfiles(
        transitive_files = depset(
          transitive = [
            toolchain.target_core_racket.files,
            depset(transitive=[dep.files for dep in ctx.attr.data]),
            depset(transitive=[dep[RacketInfo].zos for dep in ctx.attr.deps]),
            depset(transitive=[dep[RacketInfo].links for dep in ctx.attr.deps]),
            depset(transitive=[dep[RacketInfo].data for dep in ctx.attr.deps]),
          ],
        ),
      )
    ),
  ]

def racket_compile(ctx, src_file, dep_infos, data_deps=depset(), compile_data_deps=depset()):
  src_name = src_file.basename
  if (not(src_name.endswith(".rkt"))):
    fail("Source file must end in .rkt")

  toolchain = ctx.toolchains[racket_toolchain_type]
  bazel_tool_links = toolchain.bazel_tools[RacketInfo].links.to_list()
  if (len(bazel_tool_links) != 1):
    fail("Only expecting one link in tools")
  bazel_tool_link = bazel_tool_links[0]

  output_zo = ctx.actions.declare_file("compiled/%s_rkt.zo" % src_name[:-4], sibling=src_file)

  dependency_zos = depset(transitive=[info.zos for info in dep_infos])
  dependency_links = depset(transitive=[info.links for info in dep_infos])
  dependency_data = depset(transitive=[info.data for info in dep_infos])

  file_args = ctx.actions.args()
  file_args.add("--links")
  file_args.add_joined(dependency_links, format_each='"%s"', join_with=" ", format_joined="(%s)",
                       omit_if_empty=False)
  file_args.add_all(["--file", '("%s" "%s" "%s")' % (src_file.path, src_file.short_path, src_file.root.path)])
  file_args.add_all(["--bin_dir", ctx.bin_dir.path])
  file_args.add_all(["--output_dir", output_zo.dirname])

  args_file = ctx.actions.declare_file("%s.args" % src_name, sibling=src_file)
  file_args.set_param_file_format('multiline')
  ctx.actions.write(args_file, file_args)

  compiler_args = ctx.actions.args()
  compiler_args.add("--no-user-path")
  compiler_args.add_all(
    ["-e", '(current-library-collection-links (list #f (build-path (current-directory) "%s")))'
           % bazel_tool_link.path])
  compiler_args.add_all(["-l", "bazel-tools/racket-compiler"])
  compiler_args.add("--")
  compiler_args.add("@" + args_file.path)

  ctx.actions.run(
    executable = toolchain.exec_racket_bin,
    arguments = [compiler_args],
    inputs = depset(
      direct = [src_file, args_file],
      transitive = [
        dependency_zos,
        dependency_links,
        dependency_data,
        data_deps,
        compile_data_deps,
        toolchain.exec_core_racket.files,
        toolchain.bazel_tools[RacketInfo].zos,
        toolchain.bazel_tools[RacketInfo].links,
        toolchain.bazel_tools[RacketInfo].data,
      ],
    ),
    tools = [toolchain.exec_racket_bin],
    outputs=[output_zo],
    execution_requirements = {
      "supports-workers" : "1",
    },
  )

  return [
    output_zo,
    RacketInfo(
      zos = depset(
        direct = [output_zo],
        transitive = [dependency_zos],
      ),
      links = dependency_links,
      data = depset(transitive=[dependency_data, data_deps]),
    ),
  ]



def _lib_impl(ctx):
  if (len(ctx.attr.srcs) != 1):
    fail("Must supply exactly one source file: Got %s" % len(ctx.attr.srcs), "srcs")
  src_file = ctx.files.srcs[0]
  if (not(src_file.basename.rpartition(".rkt")[0] == ctx.label.name)):
    fail("Source file must match rule name", "srcs")

  [output_zo, racket_info] = racket_compile(
    ctx,
    src_file = src_file,
    data_deps = depset(transitive = [dep.files for dep in ctx.attr.data]),
    dep_infos = [dep[RacketInfo] for dep in ctx.attr.deps]
  )

  return [
    DefaultInfo(
      files = depset([output_zo]),
    ),
    racket_info,
  ]

def _bootstrap_lib_impl(ctx):
  toolchain = ctx.toolchains[racket_bootstrap_toolchain_type]
  if (len(ctx.attr.srcs) != 1):
    fail("Must supply exactly one source file: Got %s" % len(ctx.attr.srcs), "srcs")
  src_file = ctx.files.srcs[0]
  src_name = src_file.basename
  if (not(src_name.endswith(".rkt"))):
    fail("Source file must end in .rkt", "srcs")
  if (not(src_name.rpartition(".rkt")[0] == ctx.label.name)):
    fail("Source file must match rule name", "srcs")

  output_zo = ctx.actions.declare_file("compiled/%s_rkt.zo" % ctx.attr.name)

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
    "((compile-zos #f #:module? #t) (list src-path) \"%s\")" % output_zo.dirname])

  ctx.actions.run(
    executable=toolchain.exec_racket_bin,
    arguments = [args],
    inputs = depset(
      direct = ctx.files.srcs,
      transitive = [toolchain.exec_core_racket.files],
    ),
    tools = [toolchain.exec_racket_bin],
    outputs=[output_zo],
  )

  return [
    DefaultInfo(
      files = depset([output_zo]),
    ),
    RacketInfo(
      zos = depset([output_zo]),
      links = depset(),
      data = depset(),
    )
  ]

def _collection_impl(ctx):
  output_links = ctx.actions.declare_file("%s_links.rktd" % ctx.attr.name)

  ctx.actions.write(
    output = output_links,
    content = "((\"%s\" \".\"))" % ctx.attr.name,
  )

  return [
    DefaultInfo(
      files = depset([output_links]),
    ),
    RacketInfo(
      zos = depset(
        transitive = [dep[RacketInfo].zos for dep in ctx.attr.deps]
      ),
      links = depset(
        direct = [output_links],
        transitive = [dep[RacketInfo].links for dep in ctx.attr.deps]
      ),
      data = depset(
        transitive = [dep[RacketInfo].data for dep in ctx.attr.deps]
      ),
    ),
  ]

def _racket_bootstrap_toolchain_impl(ctx):
  return [
    platform_common.ToolchainInfo(
      exec_core_racket = ctx.attr.exec_core_racket,
      exec_racket_bin = ctx.executable.exec_racket_bin,
    ),
  ]

def _racket_toolchain_impl(ctx):
  return [
    platform_common.ToolchainInfo(
      exec_core_racket = ctx.attr.exec_core_racket,
      exec_racket_bin = ctx.executable.exec_racket_bin,
      target_core_racket = ctx.attr.target_core_racket,
      target_racket_bin = ctx.executable.target_racket_bin,
      bazel_tools = ctx.attr.bazel_tools,
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
  "deps": attr.label_list(
    allow_files=racket_zo_file_extensions
  ),
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
  toolchains = [racket_toolchain_type],
  attrs = _racket_lib_attrs
)

bootstrap_racket_library = rule(
  implementation=_bootstrap_lib_impl,
  toolchains = [racket_bootstrap_toolchain_type],
  attrs = _racket_bootstrap_lib_attrs
)

racket_collection = rule(
  implementation = _collection_impl,
  attrs = _racket_collection_attrs,
)

racket_bootstrap_toolchain = rule(
  implementation = _racket_bootstrap_toolchain_impl,
  attrs = {
    'exec_core_racket': attr.label(mandatory=True, cfg="host"),
    'exec_racket_bin':
        attr.label(mandatory=True, executable=True, allow_files=True,
                   cfg="host"),
  }
)

racket_toolchain = rule(
  implementation = _racket_toolchain_impl,
  attrs = {
    'exec_core_racket': attr.label(mandatory=True, cfg="host"),
    'exec_racket_bin':
        attr.label(mandatory=True, executable=True, allow_files=True,
                   cfg="host"),
    'target_core_racket': attr.label(mandatory=True, cfg="target"),
    'target_racket_bin':
        attr.label(mandatory=True, executable=True, allow_files=True,
                   cfg="target"),
    'bazel_tools': attr.label(mandatory=True, cfg="host"),
  }
)
