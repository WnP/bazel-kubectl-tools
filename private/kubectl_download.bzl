"""Platform-aware kubectl binary download implementation."""

def _kubectl_download_impl(repository_ctx):
    """Download kubectl binary for the current platform."""

    # Detect platform
    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac"):
        os_name = "darwin"
    elif os_name.startswith("windows"):
        os_name = "windows"
    else:
        os_name = "linux"

    # Detect architecture
    arch = repository_ctx.os.arch.lower()
    if arch == "x86_64" or arch == "amd64":
        arch = "amd64"
    elif arch == "aarch64" or arch == "arm64":
        arch = "arm64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    version = repository_ctx.attr.version

    # kubectl binary URL and filename
    binary_name = "kubectl"
    if os_name == "windows":
        binary_name = "kubectl.exe"

    url = "https://dl.k8s.io/release/v{}/bin/{}/{}/{}".format(
        version, os_name, arch, binary_name
    )

    # Download binary with a unique name to avoid conflicts
    downloaded_name = "kubectl_binary"
    repository_ctx.download(
        url = url,
        output = downloaded_name,
        executable = True,
    )

    # Create BUILD file
    # Export the binary file so it can be used as a source
    build_content = """# Generated kubectl binary
exports_files(["{downloaded_name}"], visibility = ["//visibility:public"])

alias(
    name = "kubectl",
    actual = ":{downloaded_name}",
    visibility = ["//visibility:public"],
)
""".format(downloaded_name = downloaded_name)

    repository_ctx.file("BUILD.bazel", build_content)

kubectl_download = repository_rule(
    implementation = _kubectl_download_impl,
    attrs = {
        "version": attr.string(
            doc = "kubectl version to download",
            mandatory = True,
        ),
    },
    doc = "Downloads kubectl binary for the current platform",
)
