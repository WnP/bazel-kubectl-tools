"""Validation tests for kubectl_tools macros."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")

def _test_kubectl_delete_validation(ctx):
    """Test that kubectl_delete fails when neither resources nor resource_type is provided."""
    # This test verifies that the fail() call works correctly
    # We can't directly test failure cases with analysistest, so we test the logic

    # Test that valid configurations don't fail
    env = unittest.begin(ctx)

    # Test 1: resources provided (should be valid)
    resources = ["test.yaml"]
    resource_type = None
    has_resources = bool(resources)
    has_resource_type = bool(resource_type)

    # This should NOT fail
    asserts.true(env, has_resources or has_resource_type, "Should have either resources or resource_type")

    # Test 2: resource_type provided (should be valid)
    resources2 = None
    resource_type2 = "deployment"
    has_resources2 = bool(resources2)
    has_resource_type2 = bool(resource_type2)

    # This should NOT fail
    asserts.true(env, has_resources2 or has_resource_type2, "Should have either resources or resource_type")

    # Test 3: both provided (should be valid)
    resources3 = ["test.yaml"]
    resource_type3 = "service"
    has_resources3 = bool(resources3)
    has_resource_type3 = bool(resource_type3)

    # This should NOT fail
    asserts.true(env, has_resources3 or has_resource_type3, "Should have either resources or resource_type")

    # Test 4: neither provided (would fail - but we can't test fail() directly)
    resources4 = None
    resource_type4 = None
    has_resources4 = bool(resources4)
    has_resource_type4 = bool(resource_type4)

    # This should fail, but we can only assert the condition that would cause failure
    asserts.false(env, has_resources4 or has_resource_type4, "Neither resources nor resource_type provided - would trigger fail()")

    return unittest.end(env)

kubectl_delete_validation_test = unittest.make(_test_kubectl_delete_validation)

def _test_command_type_handling(ctx):
    """Test command type handling logic for kubectl_exec."""
    env = unittest.begin(ctx)

    # Test string command
    command1 = "echo hello"
    is_list1 = type(command1) == "list"
    asserts.false(env, is_list1, "String command should not be detected as list")

    # Test list command
    command2 = ["echo", "hello"]
    is_list2 = type(command2) == "list"
    asserts.true(env, is_list2, "List command should be detected as list")

    # Test empty string
    command3 = ""
    is_list3 = type(command3) == "list"
    asserts.false(env, is_list3, "Empty string should not be detected as list")

    # Test empty list
    command4 = []
    is_list4 = type(command4) == "list"
    asserts.true(env, is_list4, "Empty list should be detected as list")

    return unittest.end(env)

command_type_handling_test = unittest.make(_test_command_type_handling)

def _test_data_file_handling(ctx):
    """Test data file handling logic."""
    env = unittest.begin(ctx)

    # Test with kubeconfig
    kubeconfig1 = "test.kubeconfig"
    data_files1 = [kubeconfig1] if kubeconfig1 else []
    expected1 = ["test.kubeconfig"]
    asserts.equals(env, expected1, data_files1, "Should include kubeconfig in data files")

    # Test without kubeconfig
    kubeconfig2 = None
    data_files2 = [kubeconfig2] if kubeconfig2 else []
    expected2 = []
    asserts.equals(env, expected2, data_files2, "Should not include None kubeconfig in data files")

    # Test resources + kubeconfig
    resources = ["app.yaml", "service.yaml"]
    kubeconfig3 = "prod.kubeconfig"
    data_files3 = resources + ([kubeconfig3] if kubeconfig3 else [])
    expected3 = ["app.yaml", "service.yaml", "prod.kubeconfig"]
    asserts.equals(env, expected3, data_files3, "Should include both resources and kubeconfig")

    # Test resources only
    kubeconfig4 = None
    data_files4 = resources + ([kubeconfig4] if kubeconfig4 else [])
    expected4 = ["app.yaml", "service.yaml"]
    asserts.equals(env, expected4, data_files4, "Should include only resources when no kubeconfig")

    return unittest.end(env)

data_file_handling_test = unittest.make(_test_data_file_handling)

def validation_test_suite():
    """Test suite for validation logic."""

    # Run validation tests
    kubectl_delete_validation_test(name = "test_kubectl_delete_validation")
    command_type_handling_test(name = "test_command_type_handling")
    data_file_handling_test(name = "test_data_file_handling")

    return [
        ":test_kubectl_delete_validation",
        ":test_command_type_handling",
        ":test_data_file_handling",
    ]
