# kubectl_tools Bazel Module

## Overview

The `kubectl_tools` module provides a simple, hermetic way to integrate kubectl operations directly into Bazel build workflows. It allows you to create Bazel targets for common kubectl operations like applying, deleting, and executing commands in Kubernetes clusters.

## Features

- Platform-agnostic kubectl binary download
- Simple Bazel macros for kubectl operations
- Flexible configuration options
- Supports `get`, `apply`, `delete`, `exec`, and `wait` operations
- Hermetic execution via `sh_binary` targets

## Installation

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "kubectl_tools", version = "1.0.0")

# Optional: Configure kubectl version
kubectl_extension = use_extension("@kubectl_tools//:extensions.bzl", "kubectl_extension")
kubectl_extension.version(version = "1.29.0")  # Optional, defaults to 1.31.0
use_repo(kubectl_extension, "kubectl_binary")
```

## Public API

### kubectl_apply

Apply Kubernetes resources from YAML files:

```python
load("@kubectl_tools//:defs.bzl", "kubectl_apply")

kubectl_apply(
    name = "deploy_app",
    resources = ["deployment.yaml", "service.yaml"],
    context = "my-cluster",              # REQUIRED: Kubernetes context
    namespace = "default",               # Optional
    kubeconfig = "/path/to/config"       # Optional
)

# Run with:
# bazel run //:deploy_app
```

### kubectl_delete

Delete Kubernetes resources:

```python
load("@kubectl_tools//:defs.bzl", "kubectl_delete")

# Delete from YAML files
kubectl_delete(
    name = "remove_app",
    resources = ["deployment.yaml"],
    context = "my-cluster"       # REQUIRED: Kubernetes context
)

# Delete all resources of a type
kubectl_delete(
    name = "delete_deployments",
    resource_type = "deployment",
    context = "my-cluster",      # REQUIRED: Kubernetes context
    namespace = "default"
)
```

### kubectl_exec

Execute commands in a Kubernetes pod:

```python
load("@kubectl_tools//:defs.bzl", "kubectl_exec")

# Execute a single command
kubectl_exec(
    name = "pod_command",
    pod = "my-pod",
    command = "ls /app",
    context = "my-cluster",      # REQUIRED: Kubernetes context
    namespace = "default",
    container = "app"            # Optional: specify container
)

# Execute multiple command arguments
kubectl_exec(
    name = "pod_script",
    pod = "my-pod",
    command = ["bash", "-c", "echo Hello && date"],
    context = "my-cluster"       # REQUIRED: Kubernetes context
)
```

### kubectl_get

List or get Kubernetes resources, now using `genrule` to create a file output for downstream processing:

```python
load("@kubectl_tools//:defs.bzl", "kubectl_get")

# List all pods in a namespace, creating a file output
kubectl_get(
    name = "list_pods",
    kind = "pods",
    context = "my-cluster",      # REQUIRED: Kubernetes context
    namespace = "default",
    output = "yaml"              # Specify output format to create a file
)

# Get a specific deployment, output to a file
kubectl_get(
    name = "get_deployment",
    kind = "deployment",
    resource_name = "my-app",
    context = "my-cluster",      # REQUIRED: Kubernetes context
    namespace = "production",
    output = "json"              # Creates a JSON file that can be used by other rules
)

# Example of consuming the output in another rule
genrule(
    name = "process_pods",
    srcs = [":list_pods"],  # The file output from kubectl_get
    outs = ["processed_pods.txt"],
    cmd = "cat $(location :list_pods) | grep 'name:' > $@"
)
```

#### Behavioral Changes

- `kubectl_get` now creates a `genrule` that outputs the resource information to a file
- Supports `output` formats: "yaml", "json", "wide"
- The output file can be used as a source for other Bazel rules
- Enables complex data processing and filtering workflows

Supported options:
- `kind`: Resource type (e.g., "pods", "deployments", "services")
- `output`: Output format for file creation ("json", "yaml", "wide")
- `resource_name`: Optional specific resource name
- `namespace`: Optional namespace
- `context`: **REQUIRED** Kubernetes context
- `kubeconfig`: Optional kubeconfig file path

#### Best Practices
- Use the output file for further processing in other Bazel rules
- Specify an output format to create a file
- The output can be consumed by other genrules, scripts, or custom rules

### kubectl_wait

Wait for a Kubernetes resource to exist and reach a specified condition. Unlike native `kubectl wait`, this implementation includes retry logic to handle resources that don't exist yet (e.g., CRDs being installed asynchronously by operators).

```python
load("@kubectl_tools//:defs.bzl", "kubectl_wait")

# Wait for a CRD to be established
kubectl_wait(
    name = "wait_for_crd",
    kind = "crd",
    resource_name = "myresources.example.com",
    condition = "Established",
    context = "my-cluster",      # REQUIRED: Kubernetes context
    timeout = "120",             # Optional: timeout in seconds (default: 60)
    interval = "5",              # Optional: retry interval in seconds (default: 5)
)

# Wait for a deployment to be available
kubectl_wait(
    name = "wait_for_deployment",
    kind = "deployment",
    resource_name = "my-app",
    condition = "Available",
    context = "my-cluster",
    namespace = "default",
)

# Wait for pods matching a label selector
kubectl_wait(
    name = "wait_for_pods",
    kind = "pod",
    selector = "app=nginx",
    condition = "Ready",
    context = "my-cluster",
    namespace = "default",
)
```

Supported options:
- `kind`: Resource type (e.g., "pod", "deployment", "crd")
- `condition`: Condition to wait for (e.g., "Ready", "Available", "Established")
- `resource_name`: Optional specific resource name
- `selector`: Optional label selector (e.g., "app=nginx")
- `namespace`: Optional namespace
- `context`: **REQUIRED** Kubernetes context
- `timeout`: Timeout in seconds (default: "60")
- `interval`: Retry interval in seconds (default: "5")
- `kubeconfig`: Optional kubeconfig file path

## Version Configuration

Configure the kubectl version using the module extension:

```python
kubectl_extension.version(version = "1.29.0")
```

Supported versions depend on the available binaries. The default is 1.31.0.

## Limitations

- Requires a working kubeconfig
- No built-in cluster management (use kind_tools for that)
- Targets are statically defined at build time

## Best Practices

1. **Always provide context**: The `context` parameter is mandatory for all kubectl operations to ensure explicit cluster selection
2. Use absolute paths for kubeconfig
3. Keep sensitive information out of BUILD files
4. Use namespace for clarity when working with multiple namespaces
5. Test kubectl targets before running in production

## Contributing

- Follow functional programming principles
- Add comprehensive tests
- Maintain Starlark compatibility
- Keep the implementation minimal and focused

## License

[Your License Here]