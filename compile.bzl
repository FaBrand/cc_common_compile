load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _filter_none(input_list):
    filtered_list = []
    for element in input_list:
        if element != None:
            filtered_list.append(element)
    return filtered_list

def _compiler_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    (compilation_context, compilation_outputs) = cc_common.compile(
        name = ctx.attr.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        public_hdrs = [],
        private_hdrs = [],
        srcs = [],
        includes = [],
        quote_includes = [],
        system_includes = [],
        defines = [],
        local_defines = [],
        user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts,
        compilation_contexts = [],
        disallow_pic_outputs = True,
    )

    (linking_context, linking_outputs) = cc_common.create_linking_context_from_compilation_outputs(
        name = ctx.attr.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        language = "c++",
        compilation_outputs = compilation_outputs,
        linking_contexts = [],
        alwayslink = False,
        disallow_dynamic_library = False,
        disallow_static_libraries = False,
    )

    files = []
    files.extend(compilation_outputs.objects)
    files.extend(compilation_outputs.pic_objects)

    library = linking_outputs.library_to_link
    if library:
        files.append(library.pic_static_library)
        files.append(library.static_library)
        files.append(library.dynamic_library)

    return [
        CcInfo(
            compilation_context = compilation_context,
            linking_context = linking_context,
        ),
        DefaultInfo(
            files = depset(_filter_none(files)),
        ),
    ]

empty_srcs_cc_rule = rule(
    implementation = _compiler_impl,
    attrs = {
        "_cc_toolchain": attr.label(default = "@bazel_tools//tools/cpp:current_cc_toolchain"),
    },
    fragments = ["cpp"],
    toolchains = [
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)

def _has_no_libraries_to_link_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    asserts.equals(
        env,
        actual = len(tut[DefaultInfo].files.to_list()),
        expected = 0,
    )

    libraries_to_link = tut[CcInfo].linking_context.linker_inputs.to_list()[0].libraries
    if len(libraries_to_link):
        print(libraries_to_link[0])

    asserts.equals(
        env,
        expected = 0,
        actual = len(libraries_to_link),
    )

    return analysistest.end(env)

has_no_libraries_to_link_test = analysistest.make(
    _has_no_libraries_to_link_impl,
)

def empty_srcs_test():
    empty_srcs_cc_rule(
        name = "no_files",
    )

    has_no_libraries_to_link_test(
        name = "with_no_sources_no_archive_is_created",
        target_under_test = ":no_files",
        size = "small",
    )
