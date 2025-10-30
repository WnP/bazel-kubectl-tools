# kubectl_tools Tests

This directory contains tests for the kubectl_tools module.

## Test Structure

The test suite is designed to be simple and practical, matching the module's minimal design:

### Test Files

- **`simple_test.bzl`** - Unit tests for kubectl command argument construction logic
  - Tests `kubectl_apply` argument building
  - Tests `kubectl_delete` argument building  
  - Tests `kubectl_exec` argument building
  - Tests data file handling logic

- **`validation_test.bzl`** - Tests for validation and edge case logic
  - Tests kubectl_delete parameter validation
  - Tests command type handling (string vs list)
  - Tests data file inclusion logic

- **`integration_test.bzl`** - Integration tests (manual execution)
  - Creates actual kubectl command targets for manual testing
  - Tagged with `manual` to prevent automatic execution
  - Useful for validating that the macros generate working kubectl commands

- **`BUILD.bazel`** - Test configuration and test suites

## Running Tests

```bash
# Run all tests
bazel test //private/tests:all_tests

# Run specific test suites
bazel test //private/tests:simple_tests
bazel test //private/tests:validation_tests

# List integration tests (manual execution)
bazel query //private/tests:integration_tests

# Run a specific integration test (requires kubectl and cluster)
bazel run //private/tests:integration_apply_single
```

## Test Design Principles

1. **Simple and Fast** - Tests focus on logic validation without external dependencies
2. **No kubectl Binary Required** - Unit tests work without downloading kubectl
3. **Argument Validation** - Tests verify correct kubectl command construction
4. **Edge Case Coverage** - Tests handle validation and error conditions
5. **Integration Ready** - Manual integration tests available for end-to-end verification

## Test Coverage

- ✅ kubectl_apply macro argument construction
- ✅ kubectl_delete macro argument construction  
- ✅ kubectl_exec macro argument construction
- ✅ Parameter validation (required vs optional)
- ✅ Data file handling logic
- ✅ Command type detection (string vs list)
- ✅ Integration test targets (manual)

The tests validate that:
- Correct kubectl command arguments are generated
- Required parameters are validated
- Optional parameters are handled properly
- Data files are included correctly
- Error conditions are handled appropriately