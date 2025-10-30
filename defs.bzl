"""Public API for kubectl_tools module.

Provides simple macros for common kubectl operations via sh_binary.
"""

def kubectl_apply(name, resources = None, urls = None, namespace = None, context = None, kubeconfig = None, **kwargs):
    """Create a sh_binary target that applies Kubernetes resources.

    Args:
        name: Name of the target
        resources: List of YAML files to apply (optional if urls is specified)
        urls: List of URLs to apply from (optional if resources is specified)
        namespace: Kubernetes namespace (optional)
        context: kubectl context to use (optional)
        kubeconfig: Path to kubeconfig file (optional)
        **kwargs: Additional arguments passed to sh_binary
    """
    if not resources and not urls:
        fail("Either resources or urls must be specified")

    # Build kubectl apply command arguments
    args = ["apply"]

    if namespace:
        args.extend(["-n", namespace])

    if context:
        args.extend(["--context", context])

    if kubeconfig:
        args.extend(["--kubeconfig", kubeconfig])

    # Add resource files with proper location expansion
    if resources:
        for resource in resources:
            args.extend(["-f", "$(location %s)" % resource])

    # Add URLs directly
    if urls:
        for url in urls:
            args.extend(["-f", url])

    # Merge default tags with user-provided tags
    default_tags = ["local", "no-remote", "no-cache"]
    merged_tags = list(default_tags + kwargs.pop("tags", []))

    # Create sh_binary target
    native.sh_binary(
        name = name,
        srcs = ["@kubectl_binary//:kubectl_binary"],
        args = args,
        data = (resources if resources else []) + ([kubeconfig] if kubeconfig else []),
        tags = merged_tags,
        **kwargs
    )

def kubectl_delete(name, resources = None, resource_type = None, namespace = None, context = None, kubeconfig = None, **kwargs):
    """Create a sh_binary target that deletes Kubernetes resources.

    Args:
        name: Name of the target
        resources: List of YAML files to delete (optional if resource_type is specified)
        resource_type: Resource type to delete (e.g., "deployment", "service")
        namespace: Kubernetes namespace (optional)
        context: kubectl context to use (optional)
        kubeconfig: Path to kubeconfig file (optional)
        **kwargs: Additional arguments passed to sh_binary
    """
    if not resources and not resource_type:
        fail("Either resources or resource_type must be specified")

    # Build kubectl delete command arguments
    args = ["delete"]

    if namespace:
        args.extend(["-n", namespace])

    if context:
        args.extend(["--context", context])

    if kubeconfig:
        args.extend(["--kubeconfig", kubeconfig])

    # Add resources or resource type
    if resources:
        for resource in resources:
            args.extend(["-f", resource])
        data_files = resources + ([kubeconfig] if kubeconfig else [])
    else:
        args.extend([resource_type, "--all"])
        data_files = [kubeconfig] if kubeconfig else []

    # Merge default tags with user-provided tags
    default_tags = ["local", "no-remote", "no-cache"]
    merged_tags = list(default_tags + kwargs.pop("tags", []))

    # Create sh_binary target
    native.sh_binary(
        name = name,
        srcs = ["@kubectl_binary//:kubectl_binary"],
        args = args,
        data = data_files,
        tags = merged_tags,
        **kwargs
    )

def kubectl_exec(name, pod, command, namespace = None, container = None, context = None, kubeconfig = None, **kwargs):
    """Create a sh_binary target that executes commands in a pod.

    Args:
        name: Name of the target
        pod: Pod name to execute command in
        command: Command to execute (as string or list)
        namespace: Kubernetes namespace (optional)
        container: Container name within pod (optional)
        context: kubectl context to use (optional)
        kubeconfig: Path to kubeconfig file (optional)
        **kwargs: Additional arguments passed to sh_binary
    """
    # Build kubectl exec command arguments
    args = ["exec"]

    if namespace:
        args.extend(["-n", namespace])

    if context:
        args.extend(["--context", context])

    if kubeconfig:
        args.extend(["--kubeconfig", kubeconfig])

    if container:
        args.extend(["-c", container])

    # Add pod name
    args.append(pod)

    # Add separator and command
    args.append("--")
    if type(command) == "list":
        args.extend(command)
    else:
        args.append(command)

    # Merge default tags with user-provided tags
    default_tags = ["local", "no-remote", "no-cache"]
    merged_tags = list(default_tags + kwargs.pop("tags", []))

    # Create sh_binary target
    native.sh_binary(
        name = name,
        srcs = ["@kubectl_binary//:kubectl_binary"],
        args = args,
        data = [kubeconfig] if kubeconfig else [],
        tags = merged_tags,
        **kwargs
    )

def kubectl_get(name, kind, output_file = None, output = None, resource_name = None, namespace = None, context = None, kubeconfig = None, **kwargs):
    """Create a genrule target that gets Kubernetes resources and writes to file.

    Args:
        name: Name of the target
        kind: Resource kind to get (e.g., "pods", "services", "deployments")
        output_file: Output file name (default: {name}.out)
        output: Output format (e.g., "json", "yaml", "wide") (optional)
        resource_name: Specific resource name to get (optional)
        namespace: Kubernetes namespace (optional)
        context: kubectl context to use (optional)
        kubeconfig: Path to kubeconfig file (optional)
        **kwargs: Additional arguments passed to genrule
    """
    if not output_file:
        output_file = name + ".out"

    # Build kubectl get command arguments
    cmd_args = ["get", kind]

    if resource_name:
        cmd_args.append(resource_name)

    if namespace:
        cmd_args.extend(["-n", namespace])

    if context:
        cmd_args.extend(["--context", context])

    if kubeconfig:
        cmd_args.extend(["--kubeconfig", "$$PWD/" + kubeconfig])

    if output:
        cmd_args.extend(["-o", output])

    # Build the command string
    cmd = "$(location @kubectl_binary//:kubectl_binary) " + " ".join([
        "'" + arg + "'" if " " in arg else arg
        for arg in cmd_args
    ]) + " > $@"

    # Merge default tags with user-provided tags
    default_tags = ["local", "no-remote", "no-cache"]
    merged_tags = list(default_tags + kwargs.pop("tags", []))

    # Create genrule target
    native.genrule(
        name = name,
        outs = [output_file],
        cmd = cmd,
        tools = ["@kubectl_binary//:kubectl_binary"],
        srcs = [kubeconfig] if kubeconfig else [],
        tags = merged_tags,
        **kwargs
    )
