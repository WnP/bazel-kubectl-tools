"""Integration tests for kubectl_tools - tests actual target generation."""

load("//:defs.bzl", "kubectl_apply", "kubectl_delete", "kubectl_exec", "kubectl_get")

def integration_test_targets():
    """Creates integration test targets that can be manually run to verify functionality."""

    # Create dummy YAML files for testing
    native.genrule(
        name = "test_deployment_yaml",
        outs = ["test-deployment.yaml"],
        cmd = """cat > $@ <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-container
        image: nginx:latest
        ports:
        - containerPort: 80
EOF""",
        tags = ["manual"],
    )

    native.genrule(
        name = "test_service_yaml",
        outs = ["test-service.yaml"],
        cmd = """cat > $@ <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: default
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF""",
        tags = ["manual"],
    )

    # Integration tests - these create real kubectl commands
    # Tagged as manual so they don't run automatically

    # Test kubectl_apply with single resource
    kubectl_apply(
        name = "integration_apply_single",
        resources = [":test-deployment.yaml"],
        tags = ["manual", "integration"],
    )

    # Test kubectl_apply with multiple resources and namespace
    kubectl_apply(
        name = "integration_apply_multi",
        resources = [":test-deployment.yaml", ":test-service.yaml"],
        namespace = "test-ns",
        tags = ["manual", "integration"],
    )

    # Test kubectl_delete with resources
    kubectl_delete(
        name = "integration_delete_files",
        resources = [":test-deployment.yaml", ":test-service.yaml"],
        namespace = "test-ns",
        tags = ["manual", "integration"],
    )

    # Test kubectl_delete with resource type
    kubectl_delete(
        name = "integration_delete_type",
        resource_type = "deployment",
        namespace = "test-ns",
        tags = ["manual", "integration"],
    )

    # Test kubectl_exec with string command
    kubectl_exec(
        name = "integration_exec_string",
        pod = "test-pod",
        command = "ls -la /tmp",
        namespace = "test-ns",
        tags = ["manual", "integration"],
    )

    # Test kubectl_exec with list command and container
    kubectl_exec(
        name = "integration_exec_list",
        pod = "test-pod",
        command = ["sh", "-c", "ps aux | grep nginx"],
        container = "test-container",
        namespace = "test-ns",
        tags = ["manual", "integration"],
    )

    # Test kubectl_get with basic kind (genrule output)
    kubectl_get(
        name = "integration_get_pods",
        kind = "pods",
        tags = ["manual", "integration"],
        # Outputs to integration_get_pods.out by default
    )

    # Test kubectl_get with specific resource name and custom output file
    kubectl_get(
        name = "integration_get_specific_pod",
        kind = "pod",
        resource_name = "test-pod",
        namespace = "test-ns",
        output_file = "test-pod.txt",
        tags = ["manual", "integration"],
    )

    # Test kubectl_get with output format and custom file
    kubectl_get(
        name = "integration_get_services_json",
        kind = "services",
        output = "json",
        namespace = "test-ns",
        output_file = "services.json",
        tags = ["manual", "integration"],
    )

    # Test kubectl_get with all parameters
    kubectl_get(
        name = "integration_get_deployments_full",
        kind = "deployment",
        resource_name = "test-app",
        output = "yaml",
        namespace = "test-ns",
        context = "test-context",
        output_file = "deployment.yaml",
        tags = ["manual", "integration"],
    )

    # Test that kubectl_get output can be consumed by other rules
    native.genrule(
        name = "integration_process_pods",
        srcs = [":integration_get_pods"],
        outs = ["pod_summary.txt"],
        cmd = """echo "Pod list from kubectl_get:" > $@ && \
                 echo "File: $(location :integration_get_pods)" >> $@ && \
                 echo "Size: $$(wc -c < $(location :integration_get_pods)) bytes" >> $@""",
        tags = ["manual", "integration"],
    )

    # Test that kubectl_get JSON output can be processed
    native.genrule(
        name = "integration_validate_json",
        srcs = [":integration_get_services_json"],
        outs = ["json_validation.txt"],
        cmd = """if command -v jq >/dev/null 2>&1; then \
                     echo "Valid JSON: $$(jq empty < $(location :integration_get_services_json) && echo 'YES' || echo 'NO')" > $@; \
                 else \
                     echo "jq not available, skipping JSON validation" > $@; \
                 fi""",
        tags = ["manual", "integration"],
    )

    # Test that kubectl_get YAML output can be processed
    native.genrule(
        name = "integration_validate_yaml",
        srcs = [":integration_get_deployments_full"],
        outs = ["yaml_validation.txt"],
        cmd = """if command -v yq >/dev/null 2>&1; then \
                     echo "Valid YAML: $$(yq eval 'length' $(location :integration_get_deployments_full) >/dev/null 2>&1 && echo 'YES' || echo 'NO')" > $@; \
                 else \
                     echo "yq not available, checking basic YAML structure" > $@ && \
                     grep -q 'apiVersion:' $(location :integration_get_deployments_full) && echo "Basic YAML structure found" >> $@ || echo "No YAML structure found" >> $@; \
                 fi""",
        tags = ["manual", "integration"],
    )

    # Return list of integration test targets
    return [
        ":integration_apply_single",
        ":integration_apply_multi",
        ":integration_delete_files",
        ":integration_delete_type",
        ":integration_exec_string",
        ":integration_exec_list",
        ":integration_get_pods",
        ":integration_get_specific_pod",
        ":integration_get_services_json",
        ":integration_get_deployments_full",
        ":integration_process_pods",
        ":integration_validate_json",
        ":integration_validate_yaml",
    ]
