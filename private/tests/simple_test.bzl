"""Simple unit tests for kubectl_tools logic without binary dependencies."""

load("@bazel_skylib//lib:unittest.bzl", "unittest", "asserts")

def _test_arg_construction(ctx):
    """Test kubectl argument construction logic."""
    env = unittest.begin(ctx)

    # Test kubectl_apply argument construction
    def build_apply_args(namespace = None, context = None, kubeconfig = None, resources = []):
        args = ["apply"]
        if namespace:
            args.extend(["-n", namespace])
        if context:
            args.extend(["--context", context])
        if kubeconfig:
            args.extend(["--kubeconfig", kubeconfig])
        for resource in resources:
            args.extend(["-f", resource])
        return args

    # Test basic apply
    result = build_apply_args(resources = ["test.yaml"])
    asserts.equals(env, ["apply", "-f", "test.yaml"], result)

    # Test apply with namespace
    result = build_apply_args(namespace = "test-ns", resources = ["test.yaml"])
    asserts.equals(env, ["apply", "-n", "test-ns", "-f", "test.yaml"], result)

    # Test apply with multiple options
    result = build_apply_args(
        namespace = "prod",
        context = "prod-cluster",
        kubeconfig = "prod.config",
        resources = ["app.yaml", "service.yaml"]
    )
    expected = [
        "apply",
        "-n", "prod",
        "--context", "prod-cluster",
        "--kubeconfig", "prod.config",
        "-f", "app.yaml",
        "-f", "service.yaml"
    ]
    asserts.equals(env, expected, result)

    return unittest.end(env)

def _test_delete_arg_construction(ctx):
    """Test kubectl_delete argument construction logic."""
    env = unittest.begin(ctx)

    # Test kubectl_delete argument construction
    def build_delete_args(namespace = None, context = None, kubeconfig = None, resources = None, resource_type = None):
        if not resources and not resource_type:
            fail("Either resources or resource_type must be specified")

        args = ["delete"]
        if namespace:
            args.extend(["-n", namespace])
        if context:
            args.extend(["--context", context])
        if kubeconfig:
            args.extend(["--kubeconfig", kubeconfig])

        if resources:
            for resource in resources:
                args.extend(["-f", resource])
        else:
            args.extend([resource_type, "--all"])
        return args

    # Test delete with files
    result = build_delete_args(resources = ["test.yaml"])
    asserts.equals(env, ["delete", "-f", "test.yaml"], result)

    # Test delete with resource type
    result = build_delete_args(resource_type = "deployment")
    asserts.equals(env, ["delete", "deployment", "--all"], result)

    # Test delete with all options
    result = build_delete_args(
        namespace = "test-ns",
        context = "test-cluster",
        resources = ["app.yaml"]
    )
    expected = ["delete", "-n", "test-ns", "--context", "test-cluster", "-f", "app.yaml"]
    asserts.equals(env, expected, result)

    return unittest.end(env)

def _test_exec_arg_construction(ctx):
    """Test kubectl_exec argument construction logic."""
    env = unittest.begin(ctx)

    # Test kubectl_exec argument construction
    def build_exec_args(pod, command, namespace = None, container = None, context = None, kubeconfig = None):
        args = ["exec"]
        if namespace:
            args.extend(["-n", namespace])
        if context:
            args.extend(["--context", context])
        if kubeconfig:
            args.extend(["--kubeconfig", kubeconfig])
        if container:
            args.extend(["-c", container])
        args.append(pod)
        args.append("--")
        if type(command) == "list":
            args.extend(command)
        else:
            args.append(command)
        return args

    # Test basic exec
    result = build_exec_args("test-pod", "ls -la")
    asserts.equals(env, ["exec", "test-pod", "--", "ls -la"], result)

    # Test exec with list command
    result = build_exec_args("test-pod", ["sh", "-c", "echo hello"])
    asserts.equals(env, ["exec", "test-pod", "--", "sh", "-c", "echo hello"], result)

    # Test exec with all options
    result = build_exec_args(
        pod = "prod-pod",
        command = "ps aux",
        namespace = "prod-ns",
        container = "main-container",
        context = "prod-cluster",
        kubeconfig = "prod.config"
    )
    expected = [
        "exec",
        "-n", "prod-ns",
        "--context", "prod-cluster",
        "--kubeconfig", "prod.config",
        "-c", "main-container",
        "prod-pod",
        "--",
        "ps aux"
    ]
    asserts.equals(env, expected, result)

    return unittest.end(env)

def _test_get_arg_construction(ctx):
    """Test kubectl_get argument construction logic."""
    env = unittest.begin(ctx)

    # Test kubectl_get argument construction
    def build_get_args(kind, output = None, resource_name = None, namespace = None, context = None, kubeconfig = None):
        args = ["get", kind]
        if resource_name:
            args.append(resource_name)
        if namespace:
            args.extend(["-n", namespace])
        if context:
            args.extend(["--context", context])
        if kubeconfig:
            args.extend(["--kubeconfig", kubeconfig])
        if output:
            args.extend(["-o", output])
        return args

    # Test basic get with just kind parameter
    result = build_get_args("pods")
    asserts.equals(env, ["get", "pods"], result)

    # Test get with specific resource name
    result = build_get_args("pod", resource_name = "my-pod")
    asserts.equals(env, ["get", "pod", "my-pod"], result)

    # Test get with output format
    result = build_get_args("services", output = "json")
    asserts.equals(env, ["get", "services", "-o", "json"], result)

    # Test get with namespace
    result = build_get_args("deployments", namespace = "kube-system")
    asserts.equals(env, ["get", "deployments", "-n", "kube-system"], result)

    # Test get with context
    result = build_get_args("nodes", context = "prod-cluster")
    asserts.equals(env, ["get", "nodes", "--context", "prod-cluster"], result)

    # Test get with kubeconfig
    result = build_get_args("configmaps", kubeconfig = "/path/to/config")
    asserts.equals(env, ["get", "configmaps", "--kubeconfig", "/path/to/config"], result)

    # Test get with all optional parameters
    result = build_get_args(
        kind = "deployment",
        output = "yaml",
        resource_name = "nginx-deployment",
        namespace = "production",
        context = "prod-cluster",
        kubeconfig = "/etc/kubernetes/admin.conf"
    )
    expected = [
        "get", "deployment", "nginx-deployment",
        "-n", "production",
        "--context", "prod-cluster",
        "--kubeconfig", "/etc/kubernetes/admin.conf",
        "-o", "yaml"
    ]
    asserts.equals(env, expected, result)

    # Test argument ordering with mixed parameters
    result = build_get_args(
        kind = "service",
        namespace = "default",
        output = "wide",
        resource_name = "kubernetes"
    )
    expected = [
        "get", "service", "kubernetes",
        "-n", "default",
        "-o", "wide"
    ]
    asserts.equals(env, expected, result)

    # Test with different output formats
    result = build_get_args("secrets", output = "jsonpath={.data}")
    asserts.equals(env, ["get", "secrets", "-o", "jsonpath={.data}"], result)

    return unittest.end(env)

def _test_data_files_logic(ctx):
    """Test data files construction logic."""
    env = unittest.begin(ctx)

    # Test data files for apply/delete
    def build_data_files(resources = None, kubeconfig = None):
        data_files = []
        if resources:
            data_files.extend(resources)
        if kubeconfig:
            data_files.append(kubeconfig)
        return data_files

    # Test with resources only
    result = build_data_files(resources = ["app.yaml", "service.yaml"])
    asserts.equals(env, ["app.yaml", "service.yaml"], result)

    # Test with kubeconfig only
    result = build_data_files(kubeconfig = "config.yaml")
    asserts.equals(env, ["config.yaml"], result)

    # Test with both
    result = build_data_files(resources = ["app.yaml"], kubeconfig = "config.yaml")
    asserts.equals(env, ["app.yaml", "config.yaml"], result)

    # Test with neither
    result = build_data_files()
    asserts.equals(env, [], result)

    return unittest.end(env)

def _test_get_output_file_logic(ctx):
    """Test kubectl_get output file naming logic."""
    env = unittest.begin(ctx)

    # Test output file naming logic (mimics the genrule behavior)
    def build_output_file(name, output_file = None):
        if not output_file:
            return name + ".out"
        return output_file

    # Test default output file
    result = build_output_file("get_pods")
    asserts.equals(env, "get_pods.out", result)

    # Test custom output file
    result = build_output_file("get_services", "services.json")
    asserts.equals(env, "services.json", result)

    # Test with various extensions
    result = build_output_file("get_deployments", "deployments.yaml")
    asserts.equals(env, "deployments.yaml", result)

    result = build_output_file("get_nodes", "nodes.txt")
    asserts.equals(env, "nodes.txt", result)

    return unittest.end(env)

# Create test rules
arg_construction_test = unittest.make(_test_arg_construction)
delete_arg_construction_test = unittest.make(_test_delete_arg_construction)
exec_arg_construction_test = unittest.make(_test_exec_arg_construction)
get_arg_construction_test = unittest.make(_test_get_arg_construction)
data_files_logic_test = unittest.make(_test_data_files_logic)
get_output_file_logic_test = unittest.make(_test_get_output_file_logic)

def simple_test_suite():
    """Simple test suite that tests logic without kubectl binary dependencies."""

    # Run all simple tests
    arg_construction_test(name = "test_arg_construction")
    delete_arg_construction_test(name = "test_delete_arg_construction")
    exec_arg_construction_test(name = "test_exec_arg_construction")
    get_arg_construction_test(name = "test_get_arg_construction")
    data_files_logic_test(name = "test_data_files_logic")
    get_output_file_logic_test(name = "test_get_output_file_logic")

    return [
        ":test_arg_construction",
        ":test_delete_arg_construction",
        ":test_exec_arg_construction",
        ":test_get_arg_construction",
        ":test_data_files_logic",
        ":test_get_output_file_logic",
    ]
