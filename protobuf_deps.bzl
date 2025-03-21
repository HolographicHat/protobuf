"""Load dependencies needed to compile the protobuf library as a 3rd-party consumer.

The consumers should use the following WORKSPACE snippet, which loads dependencies
and sets up the repositories protobuf needs:

```
http_archive(
    name = "protobuf",
    strip_prefix = "protobuf-VERSION",
    sha256 = ...,
    url = ...,
)

load("@protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//bazel/private:proto_bazel_features.bzl", "proto_bazel_features")  # buildifier: disable=bzl-visibility
load("//python/dist:python_downloads.bzl", "python_nuget_package", "python_source_archive")
load("//python/dist:system_python.bzl", "system_python")

PROTOBUF_MAVEN_ARTIFACTS = [
    "com.google.caliper:caliper:1.0-beta-3",
    "com.google.code.findbugs:jsr305:3.0.2",
    "com.google.code.gson:gson:2.8.9",
    "com.google.errorprone:error_prone_annotations:2.5.1",
    "com.google.j2objc:j2objc-annotations:2.8",
    "com.google.guava:guava:32.0.1-jre",
    "com.google.guava:guava-testlib:32.0.1-jre",
    "com.google.truth:truth:1.1.2",
    "junit:junit:4.13.2",
    "org.mockito:mockito-core:4.3.1",
    "biz.aQute.bnd:biz.aQute.bndlib:6.4.0",
    "info.picocli:picocli:4.6.3",
]

def _github_archive(repo, commit, **kwargs):
    repo_name = repo.split("/")[-1]
    http_archive(
        urls = [repo + "/archive/" + commit + ".zip"],
        strip_prefix = repo_name + "-" + commit,
        **kwargs
    )

def protobuf_deps():
    """Loads common dependencies needed to compile the protobuf library."""

    if not native.existing_rule("bazel_skylib"):
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            ],
            sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        )

    if not native.existing_rule("com_google_absl"):
        _github_archive(
            name = "com_google_absl",
            repo = "https://github.com/abseil/abseil-cpp",
            # TODO: use Layout::WithStaticSizes in SerialArenaChunk when we update
            # abseil to new release.
            commit = "4a2c63365eff8823a5221db86ef490e828306f9d",  # Abseil LTS 20240116.0
            sha256 = "f49929d22751bf70dd61922fb1fd05eb7aec5e7a7f870beece79a6e28f0a06c1",
        )

    if not native.existing_rule("zlib"):
        http_archive(
            name = "zlib",
            build_file = Label("//:third_party/zlib.BUILD"),
            sha256 = "38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32",
            strip_prefix = "zlib-1.3.1",
            urls = [
                "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz",
                "https://zlib.net/zlib-1.3.1.tar.xz",
            ],
        )

    if not native.existing_rule("jsoncpp"):
        _github_archive(
            name = "jsoncpp",
            repo = "https://github.com/open-source-parsers/jsoncpp",
            commit = "9059f5cad030ba11d37818847443a53918c327b1",  # 1.9.4
            sha256 = "c0c583c7b53a53bcd1f7385f15439dcdf0314d550362379e2db9919a918d1996",
            build_file = Label("//:third_party/jsoncpp.BUILD"),
        )

    if not native.existing_rule("rules_cc"):
        _github_archive(
            name = "rules_cc",
            repo = "https://github.com/bazelbuild/rules_cc",
            commit = "c8c38f8c710cbbf834283e4777916b68261b359c",  # 0.0.9
            sha256 = "5f862a44bbd032e1b48ed53c9c211ba2a1da60e10c5baa01c97369c249299ecb",
        )

    if not native.existing_rule("rules_java"):
        bazel_version = native.bazel_version or "999999.999999.999999"
        version_parts = bazel_version.split("-")[0].split(".")
        if len(version_parts) != 3:
            fail("invalid Bazel version '{}': got {} dot-separated segments, want 3".format(bazel_version, len(version_parts)))
        major_version_int = int(version_parts[0])
        minor_version_int = int(version_parts[1])

        if major_version_int < 6 or (major_version_int == 6 and minor_version_int <= 3):
            # Works with Bazel 6.3.0, but not higher
            http_archive(
                name = "rules_java",
                url = "https://github.com/bazelbuild/rules_java/releases/download/6.0.0/rules_java-6.0.0.tar.gz",
                sha256 = "469b7f3b580b4fcf8112f4d6d0d5a4ce8e1ad5e21fee67d8e8335d5f8b3debab",
            )
        else:
            # Version 6.5.2 works both with Bazel 6.4.0 and Bazel 7
            http_archive(
                name = "rules_java",
                url = "https://github.com/bazelbuild/rules_java/releases/download/6.5.0/rules_java-6.5.0.tar.gz",
                sha256 = "160d1ebf33763124766fb35316329d907ca67f733238aa47624a8e3ff3cf2ef4",
            )

    # TODO: remove after toolchain types are moved to protobuf
    if not native.existing_rule("rules_proto"):
        http_archive(
            name = "rules_proto",
            sha256 = "dc3fb206a2cb3441b485eb1e423165b231235a1ea9b031b4433cf7bc1fa460dd",
            strip_prefix = "rules_proto-5.3.0-21.7",
            urls = [
                "https://github.com/bazelbuild/rules_proto/archive/refs/tags/5.3.0-21.7.tar.gz",
            ],
        )

    if not native.existing_rule("proto_bazel_features"):
        proto_bazel_features(name = "proto_bazel_features")

    if not native.existing_rule("rules_python"):
        http_archive(
            name = "rules_python",
            sha256 = "d70cd72a7a4880f0000a6346253414825c19cdd40a28289bdf67b8e6480edff8",
            strip_prefix = "rules_python-0.28.0",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.28.0/rules_python-0.28.0.tar.gz",
        )

    if not native.existing_rule("system_python"):
        system_python(
            name = "system_python",
            minimum_python_version = "3.8",
        )

    if not native.existing_rule("rules_jvm_external"):
        # Version 6.0 is the lowest that works with rules_kotlin 1.9.0
        http_archive(
            name = "rules_jvm_external",
            strip_prefix = "rules_jvm_external-6.0",
            sha256 = "85fd6bad58ac76cc3a27c8e051e4255ff9ccd8c92ba879670d195622e7c0a9b7",
            url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/6.0/rules_jvm_external-6.0.tar.gz",
        )

    if not native.existing_rule("rules_pkg"):
        http_archive(
            name = "rules_pkg",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.7.0/rules_pkg-0.7.0.tar.gz",
                "https://github.com/bazelbuild/rules_pkg/releases/download/0.7.0/rules_pkg-0.7.0.tar.gz",
            ],
            sha256 = "8a298e832762eda1830597d64fe7db58178aa84cd5926d76d5b744d6558941c2",
        )

    if not native.existing_rule("build_bazel_rules_apple"):
        http_archive(
            name = "build_bazel_rules_apple",
            sha256 = "9c4f1e1ec4fdfeac5bddb07fa0e872c398e3d8eb0ac596af9c463f9123ace292",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/3.2.1/rules_apple.3.2.1.tar.gz",
        )

    if not native.existing_rule("build_bazel_apple_support"):
        http_archive(
            name = "build_bazel_apple_support",
            sha256 = "100d12617a84ebc7ee7a10ecf3b3e2fdadaebc167ad93a21f820a6cb60158ead",
            url = "https://github.com/bazelbuild/apple_support/releases/download/1.12.0/apple_support.1.12.0.tar.gz",
        )

    if not native.existing_rule("rules_kotlin"):
        # Version 1.9.0 is the lowest available on BCR
        http_archive(
            name = "rules_kotlin",
            sha256 = "5766f1e599acf551aa56f49dab9ab9108269b03c557496c54acaf41f98e2b8d6",
            url = "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.9.0/rules_kotlin-v1.9.0.tar.gz",
        )

    # Python Downloads
    python_source_archive(
        name = "python-3.8.0",
        sha256 = "f1069ad3cae8e7ec467aa98a6565a62a48ef196cb8f1455a245a08db5e1792df",
    )
    python_nuget_package(
        name = "nuget_python_i686_3.8.0",
        sha256 = "87a6481f5eef30b42ac12c93f06f73bd0b8692f26313b76a6615d1641c4e7bca",
    )
    python_nuget_package(
        name = "nuget_python_x86-64_3.8.0",
        sha256 = "96c61321ce90dd053c8a04f305a5f6cc6d91350b862db34440e4a4f069b708a0",
    )
    python_nuget_package(
        name = "nuget_python_i686_3.9.0",
        sha256 = "229abecbe49dc08fe5709e0b31e70edfb3b88f23335ebfc2904c44f940fd59b6",
    )
    python_nuget_package(
        name = "nuget_python_x86-64_3.9.0",
        sha256 = "6af58a733e7dfbfcdd50d55788134393d6ffe7ab8270effbf724bdb786558832",
    )
    python_nuget_package(
        name = "nuget_python_i686_3.10.0",
        sha256 = "e115e102eb90ce160ab0ef7506b750a8d7ecc385bde0a496f02a54337a8bc333",
    )
    python_nuget_package(
        name = "nuget_python_x86-64_3.10.0",
        sha256 = "4474c83c25625d93e772e926f95f4cd398a0abbb52793625fa30f39af3d2cc00",
    )
