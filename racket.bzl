racket_src_file_type = FileType([".rkt"])
racket_zo_file_type = FileType([".zo"])

# TODO add allowed fields once they are supported.
RacketInfo = provider()

# Implementation of racket_binary and racket_test rules
def _bin_impl(ctx):
  script_path = ctx.file.main_module.short_path

  link_files = depset()
  for target in ctx.attr.deps:
    link_files += target[RacketInfo].transitive_links

  link_file_expression = "(let ([cur (current-directory)]) (current-library-collection-links (list #f "
  for link_file in link_files.to_list():
    link_file_expression += "(build-path cur link-root \"%s\") " % link_file.short_path
  link_file_expression += ")))"

  stub_script = (
    "#!/bin/bash\n" +
    'unset PLTCOMPILEDROOTS\n' +
    'exec "${BASH_SOURCE[0]}.runfiles/%s/%s" --no-user-path ' % (
       ctx.workspace_name,
       ctx.executable._racket_bin.short_path) +
    '-l racket/base ' +
    '-e "(define link-root \\"${BASH_SOURCE[0]}.runfiles/%s\\")" ' % ctx.workspace_name +
    "-e '%s' " % link_file_expression +
    '-u "${BASH_SOURCE[0]}.runfiles/%s/%s" "$@"\n'% (
       ctx.workspace_name,
       script_path)
  )

  ctx.file_action(
    output=ctx.outputs.executable,
    content=stub_script,
    executable=True
  )

  runfiles_files = ctx.attr._core_racket.files

  for target in ctx.attr.deps:
    runfiles_files += target[RacketInfo].transitive_zos
    runfiles_files += target[RacketInfo].transitive_links

  runfiles = ctx.runfiles(
    transitive_files=runfiles_files,
    collect_data=True,
  )

  return [
    DefaultInfo(
      runfiles = runfiles
    ),
  ]

def racket_compile(ctx, src_file, output_file, link_files, inputs):
  arguments = []
  arguments += ["--no-user-path"]

  links = ctx.attr._bazel_tools[RacketInfo].transitive_links.to_list()
  if (len(links) != 1):
    fail("Only expecting one link in tools")
  link_file_expression = (
    '(current-library-collection-links (list #f (build-path (current-directory) "%s")))'
    % links[0].path)

  arguments += ["-e", link_file_expression]
  arguments += ["-l", "bazel-tools/racket-compiler"]
  arguments += ["--"]
  arguments += ["--links", 
                "(" + " ".join(['"%s"' % link_file.path for link_file in link_files.to_list()]) + ")"]
  arguments += ["--file", '("%s" "%s" "%s")' % (src_file.path, src_file.short_path, src_file.root.path)]
  arguments += ["--bin_dir", ctx.bin_dir.path]
  arguments += ["--output_dir", output_file.dirname]

  ctx.action(
    executable = ctx.executable._racket_bin,
    arguments = arguments,
    inputs = (inputs + ctx.attr._core_racket.files +
       ctx.attr._bazel_tools[RacketInfo].transitive_zos +
       ctx.attr._bazel_tools[RacketInfo].transitive_links) ,
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

  transitive_zos = depset()
  transitive_links = depset()
  for target in ctx.attr.deps:
    transitive_zos += target[RacketInfo].transitive_zos
    transitive_links += target[RacketInfo].transitive_links

  input_files = depset(ctx.files.srcs) + transitive_zos + transitive_links
  racket_compile(
    ctx,
    src_file = src_file,
    output_file = ctx.outputs.zo,
    link_files = transitive_links,
    inputs = input_files,
  )

  runfiles_files = depset([ctx.outputs.zo])

  for target in ctx.attr.data:
    runfiles_files = runfiles_files | depset(target.files)

  for target in ctx.attr.deps:
    runfiles_files = runfiles_files | depset(target.files)

  runfiles = ctx.runfiles(
    transitive_files=runfiles_files,
    collect_data=True,
  )

  return [
    DefaultInfo(
      runfiles = runfiles
    ),
    RacketInfo(
      transitive_zos = transitive_zos + depset([ctx.outputs.zo]),
      transitive_links = transitive_links
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

  arguments = []
  arguments += ["--no-user-path"]
  arguments += ["-l", "racket/base"]
  arguments += ["-l", "racket/file"]
  arguments += ["-l", "compiler/compiler"]

  if (src_file.root == ctx.bin_dir):
    fail("bootstrap_racket_lib doesn't support generated files")
  # The file needs to be in the same directory as the .zos because thats how the racket compiler works.
  arguments += [
    "-e",
    "(define gen-path (build-path \"%s\" \"%s\"))" %
         (ctx.bin_dir.path, src_file.short_path)]
  arguments += [
    "-e",
    "(define src-path gen-path)"]
  arguments += [
    "-e",
    "(begin" +
    "  (make-parent-directory* gen-path) " +
    "  (make-file-or-directory-link (path->complete-path \"%s\") gen-path))" % src_file.path]
  arguments += [
    "-e",
    "((compile-zos #f #:module? #t) (list src-path) \"%s\")" % ctx.outputs.zo.dirname]

  ctx.action(
    executable=ctx.executable._racket_bin,
    arguments = arguments,
    inputs= ctx.files.srcs + ctx.files._core_racket,
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

  transitive_zos = depset()
  transitive_links = depset()

  for target in ctx.attr.deps:
    transitive_zos += target[RacketInfo].transitive_zos
    transitive_links += target[RacketInfo].transitive_links

  return [
    RacketInfo(
      transitive_zos = transitive_zos,
      transitive_links = transitive_links + depset([ctx.outputs.links]),
    ),
  ]

_racket_bin_attrs = {
  "main_module": attr.label(
    mandatory=True,
    single_file=True,
    allow_files=racket_src_file_type,
  ),
  "data": attr.label_list(
    allow_files=True,
    cfg="data",
  ),
  "deps": attr.label_list(allow_files=racket_zo_file_type),
  "_core_racket": attr.label(
    default=Label("@minimal_racket//osx/v6.10:racket-src-osx"),
    cfg="data"
  ),
  "_racket_bin": attr.label(
    default=Label("@minimal_racket//osx/v6.10:bin/racket"),
    executable=True,
    allow_files=True,
    cfg="data"
  ),
}

_racket_lib_attrs = {
  "srcs": attr.label_list(
    allow_files=racket_src_file_type,
    mandatory=True,
    non_empty=True
  ),
  "data": attr.label_list(
    allow_files=True,
    cfg="data",
  ),
  "deps": attr.label_list(
    providers = [RacketInfo],
  ),
  "_core_racket": attr.label(
    default=Label("@minimal_racket//osx/v6.10:racket-src-osx"),
    cfg="host"
  ),
  "_racket_bin": attr.label(
    default=Label("@minimal_racket//osx/v6.10:bin/racket"),
    executable=True,
    allow_files=True,
    cfg="host",
  ),
  "_bazel_tools": attr.label(
    default=Label("@minimal_racket//build_rules:bazel-tools"),
    cfg="host",
  ),
}

_racket_bootstrap_lib_attrs = {
  "srcs": attr.label_list(
    allow_files=racket_src_file_type,
    mandatory=True,
    non_empty=True
  ),
  "_core_racket": attr.label(
    default=Label("@minimal_racket//osx/v6.10:racket-src-osx"),
    cfg="host"
  ),
  "_racket_bin": attr.label(
    default=Label("@minimal_racket//osx/v6.10:bin/racket"),
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
