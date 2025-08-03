# Perl-NetFramework Test Suite

This directory contains the comprehensive test suite for the Perl-NetFramework project, providing unit tests for all major components of the .NET Framework Base Class Library (BCL) implementation in Perl.

## Overview

The test suite has been designed to replace the embedded test methods that were previously scattered throughout the individual module files. All tests now use the standard Perl testing framework [Test::More](https://metacpan.org/pod/Test::More) for consistency and better reporting.

## Directory Structure

```
tests/
├── README.md                    # This file
├── run_tests.pl                 # Test runner script
├── System/                      # Core System namespace tests
│   ├── Object.pl                # System::Object tests
│   ├── String.pl                # System::String tests (extracted from original)
│   ├── Array.pl                 # System::Array tests
│   ├── Collections/             # Collections namespace tests
│   │   └── Hashtable.pl        # System::Collections::Hashtable tests
│   ├── Linq/                    # LINQ tests
│   │   └── Linq.pl             # LINQ operations tests
│   ├── IO/                      # Input/Output tests
│   │   └── File.pl             # System::IO::File tests
│   ├── Threading/               # Threading tests (to be added)
│   ├── Diagnostics/             # Diagnostics tests
│   │   └── Stopwatch.pl        # System::Diagnostics::Stopwatch tests
│   ├── Windows/Forms/           # Windows Forms tests (to be added)
│   └── DirectoryServices/       # Directory Services tests (to be added)
└── ...
```

## Running Tests

### Basic Usage

To run all tests, use the provided test runner:

```bash
cd tests
perl run_tests.pl
```

### Advanced Options

The test runner supports several command-line options:

```bash
# Run with verbose output (shows detailed test results)
perl run_tests.pl --verbose

# Run only specific test files using patterns
perl run_tests.pl --pattern "String*"
perl run_tests.pl --pattern "System/Collections/*"
perl run_tests.pl --pattern "*.pl"

# Show help
perl run_tests.pl --help
```

### Running Individual Tests

You can also run individual test files directly:

```bash
perl -I../../ System/String.pl
perl -I../../ System/Collections/Hashtable.pl
```

Note: The `-I../../` is required to add the project root to Perl's module search path.

## Test Framework

All tests use **Test::More**, Perl's standard testing framework. Each test file follows this structure:

```perl
#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';  # Adjust path as needed for subdirectories
use Test::More;
use System;       # Load the main System module

BEGIN {
    use_ok('Module::Name');  # Test that module loads
}

# Test functions
sub test_feature_name {
    # Test implementation using Test::More functions:
    # is(), isnt(), ok(), like(), isa_ok(), etc.
}

# Call test functions
test_feature_name();

done_testing();  # Indicates end of tests
```

## Test Coverage

The test suite covers the following areas:

### Core System Types
- **System::Object**: Base object functionality, ToString, Equals, GetHashCode
- **System::String**: String manipulation, formatting, comparison, splitting
- **System::Array**: Array operations, enumeration, LINQ integration

### Collections
- **System::Collections::Hashtable**: Key-value storage, enumeration, operations
- **System::Collections::IEnumerable**: Interface implementation testing

### LINQ (Language Integrated Query)
- **Where**: Filtering operations
- **Select**: Projection operations  
- **OrderBy/OrderByDescending**: Sorting operations
- **First/Last**: Element selection
- **Any/All**: Condition testing
- **Count**: Aggregation
- **Skip/Take**: Pagination
- **Distinct**: Uniqueness operations
- **Method Chaining**: Complex query combinations

### I/O Operations
- **System::IO::File**: File reading, writing, copying, moving, deletion
- **File Attributes**: Size, timestamps, existence checking

### Diagnostics
- **System::Diagnostics::Stopwatch**: Timing operations, start/stop/reset functionality

### Exception Handling
- **System::Exception**: Exception throwing and catching (integrated into other tests)
- **CSharp Module**: Try/catch/finally blocks

## Test Guidelines

When adding new tests, follow these guidelines:

### 1. File Naming
- Test files should end with `.pl` extension
- Name should match the module being tested (e.g., `String.pl` for `System::String`)
- Place in appropriate subdirectory matching namespace structure

### 2. Test Organization
- Group related tests into functions with descriptive names
- Use descriptive test descriptions in `is()`, `ok()`, etc.
- Test both positive and negative cases
- Include edge cases and error conditions

### 3. Module Loading
- Always include `use lib` directive with correct relative path
- Use `use_ok()` in BEGIN block to test module loading
- Load `System` module to get access to constants like `true`, `false`, `null`

### 4. Test Data
- Use temporary files/directories for I/O tests (see File::Temp usage in File.t)
- Clean up test artifacts when possible
- Use predictable test data for consistent results

### 5. Exception Testing
- Test that appropriate exceptions are thrown for invalid inputs
- Verify exception types and messages when possible

## Dependencies

The test suite requires the following Perl modules:

### Core Testing
- **Test::More**: Standard testing framework (usually included with Perl)

### Additional Modules (for specific tests)
- **File::Temp**: Temporary file/directory creation (for I/O tests)
- **Time::HiRes**: High-resolution timing (for Stopwatch tests)
- **Term::ANSIColor**: Colored output (for test runner)
- **Getopt::Long**: Command-line option parsing (for test runner)

Most of these are part of Perl's core distribution. If any are missing, install them using:

```bash
cpan Test::More File::Temp Time::HiRes Term::ANSIColor Getopt::Long
```

## Adding New Tests

To add tests for a new module:

1. **Create the test file** in the appropriate subdirectory
2. **Follow the standard test file structure** shown above
3. **Include comprehensive test coverage**:
   - Constructor/creation methods
   - All public methods and properties
   - Static methods
   - Exception handling
   - Edge cases and boundary conditions
4. **Update this README** if adding new test categories
5. **Run the test suite** to ensure new tests integrate properly

### Example Test Addition

```perl
#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';  # Adjust based on subdirectory depth
use Test::More;
use System;

BEGIN {
    use_ok('System::New::Module');
}

sub test_basic_functionality {
    my $obj = System::New::Module->new();
    isa_ok($obj, 'System::New::Module', 'Object creation');
    
    # Add specific tests here
}

test_basic_functionality();
done_testing();
```

## Integration with Development Workflow

The test suite integrates with the development workflow as follows:

1. **Before making changes**: Run relevant tests to establish baseline
2. **During development**: Run specific tests repeatedly as you implement features
3. **After changes**: Run full test suite to ensure no regressions
4. **Before committing**: Ensure all tests pass

## Future Enhancements

Planned improvements to the test suite include:

- **Code Coverage Analysis**: Integration with Devel::Cover to measure test coverage
- **Performance Testing**: Benchmarking tests for performance-critical operations
- **Integration Tests**: Higher-level tests that exercise multiple components together
- **Continuous Integration**: Automated test running on code changes
- **Mock Objects**: Testing components in isolation using Test::MockObject
- **Property-Based Testing**: Using Test::QuickCheck for property-based tests

## Troubleshooting

### Common Issues

**Module not found errors**:
- Ensure the `use lib` path is correct relative to the test file location
- Check that the Perl-NetFramework modules are in the expected location

**Test failures**:
- Run with `--verbose` flag to see detailed output
- Check that all dependencies are installed
- Verify that the module being tested hasn't changed its API

**Permission errors** (especially on Windows):
- Ensure test directory is writable
- Some I/O tests may require elevated permissions

### Getting Help

If you encounter issues with the test suite:

1. Check this README for common solutions
2. Review the test file structure and compare with working examples
3. Run individual tests with verbose output to isolate problems
4. Check that all required Perl modules are installed

## Contributing

When contributing to the test suite:

1. Follow the established patterns and conventions
2. Ensure new tests are comprehensive and well-documented
3. Run the full test suite before submitting changes
4. Update this README if adding new test categories or changing structure

The test suite is a critical part of maintaining the quality and reliability of the Perl-NetFramework project. Comprehensive testing helps ensure that the .NET BCL implementation behaves correctly and consistently across different environments and use cases.