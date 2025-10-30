"""Module extension for configuring kubectl binary download."""

load("//private:kubectl_download.bzl", "kubectl_download")

def _kubectl_extension_impl(module_ctx):
    """Implementation of kubectl extension."""

    # Default kubectl version
    kubectl_version = "1.31.0"

    # Process version configuration from modules
    for mod in module_ctx.modules:
        for tag in mod.tags.version:
            kubectl_version = tag.version

    # Download kubectl binary
    kubectl_download(
        name = "kubectl_binary",
        version = kubectl_version,
    )

# Tag for configuring kubectl version
_version_tag = tag_class(
    attrs = {
        "version": attr.string(
            doc = "kubectl version to download",
            default = "1.31.0",
        ),
    },
)

# Module extension definition
kubectl = module_extension(
    implementation = _kubectl_extension_impl,
    tag_classes = {
        "version": _version_tag,
    },
)
