# Running
First version i noticed this with was 6.0.0
```
USE_BAZEL_VERSION=5.4.0 bazel test //... # Succeeds

USE_BAZEL_VERSION=6.1.1 bazel test //... # Fails
```

# Scenario

No sources are passed to cc_common.compile
Using cc_common.compile + cc_common.create_linking_context_from_compilation_outputs() and disallowing pic_outputs:

```Starlark
    disallow_pic_outputs = True,
```


# Expectation
No static/dynamic library outputs are generated (See Usage of DefaultInfo)


# Bazel 5.x
The expecation is met:
```
$ USE_BAZEL_VERSION=5.4.0 bazel build //:no_files
INFO: Invocation ID: 7bf5bc41-fe5a-441c-aa37-25e1c6950a7d
INFO: Analyzed target //:no_files (35 packages loaded, 151 targets configured).
INFO: Found 1 target...
Target //:no_files up-to-date (nothing to build)
INFO: Elapsed time: 2.728s, Critical Path: 0.04s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
```

# Bazel 6.1.1
The LibraryTo link contains a pic library that is being built:

```
$ USE_BAZEL_VERSION=6.1.1 bazel build //:no_files
Starting local Bazel server and connecting to it...
INFO: Invocation ID: 36f21fd1-f255-48d8-81a6-aae3065244db
INFO: Analyzed target //:no_files (35 packages loaded, 149 targets configured).
INFO: Found 1 target...
Target //:no_files up-to-date:
  bazel-bin/libno_files.a
  bazel-bin/_solib_k8/liblibno_Ufiles.so
INFO: Elapsed time: 6.414s, Critical Path: 0.05s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
```

However the archive is created without objects, which seems unintentional.

```
SUBCOMMAND: # //:no_files [action 'Linking libno_files.a', configuration: aa3ae758c1b2ad2957dce506a9041dd2edde1afefdae9debd4101e761230eb13, execution platform: @local_config_platform//:host]
(cd /home/user/.bazel/output_base/execroot/__main__ && \
  exec env - \
    PATH=/bin:/usr/bin:/usr/local/bin \
    PWD=/proc/self/cwd \
  /usr/bin/ar @bazel-out/k8-fastbuild/bin/libno_files.a-2.params)
# Configuration: aa3ae758c1b2ad2957dce506a9041dd2edde1afefdae9debd4101e761230eb13
# Execution platform: @local_config_platform//:host
Target //:no_files up-to-date:
  bazel-bin/libno_files.a
  bazel-bin/_solib_k8/liblibno_Ufiles.so
```

The param file only contains the archiver flags and the output file:
```
$ cat bazel-out/k8-fastbuild/bin/libno_files.a-2.params
rcsD
bazel-out/k8-fastbuild/bin/libno_files.a
```

## Research
I checked the issues on bazelbuild/bazel for `is:issue is:open cc_common` but could not find anything related
