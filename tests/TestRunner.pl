#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Spec;
use Term::ANSIColor qw(colored);
use lib '.';

print colored("Perl .NET Framework Comprehensive Test Runner\n", 'bold blue');
print colored("=" x 60, 'blue') . "\n\n";

my %results = (
    modules_found => 0,
    modules_compiled => 0,
    modules_failed_compilation => 0,
    test_files_found => 0,
    test_files_missing => 0,
    methods_total => 0,
    methods_with_happy_tests => 0,
    methods_with_exception_tests => 0,
    methods_missing_tests => 0,
    total_tests => 0,
    total_passed => 0,
    total_failed => 0,
    failed_modules => [],
    missing_test_files => [],
    methods_missing_coverage => []
);

# Step 1: Find all .pm modules in System directory
print colored("Step 1: Discovering System modules...\n", 'bold cyan');
my @modules = ();
find(sub {
    return unless /\.pm$/;
    return if $File::Find::dir =~ /tests/i;  # Skip test directories
    return if $File::Find::name =~ /Filter/; # Skip Filter modules (C# transformation)
    
    my $full_path = $File::Find::name;
    $full_path =~ s/\\/\//g;  # Normalize path separators
    push @modules, $full_path;
}, './System');

$results{modules_found} = @modules;
print "Found " . colored($results{modules_found}, 'green') . " modules\n\n";

# Step 2: Test module compilation
print colored("Step 2: Testing module compilation...\n", 'bold cyan');
my @compiled_modules = ();
my @failed_compilation = ();

foreach my $module_path (sort @modules) {
    my $module_name = $module_path;
    $module_name =~ s/^\.\///;  # Remove leading ./
    $module_name =~ s/\.pm$//;  # Remove .pm extension
    $module_name =~ s/[\/\\]/::/g;  # Convert path separators to ::
    
    print sprintf("%-50s", "Compiling $module_name...");
    
    # Try to compile the module
    my $result = eval "use lib '.'; require '$module_path'; 1;";
    
    if ($result) {
        print colored(" ✓ PASS\n", 'green');
        $results{modules_compiled}++;
        push @compiled_modules, {
            path => $module_path,
            name => $module_name
        };
    } else {
        print colored(" ✗ FAIL\n", 'red');
        $results{modules_failed_compilation}++;
        my $error = $@ || "Unknown error";
        $error =~ s/\s+/ /g;  # Normalize whitespace
        $error =~ s/at \(eval \d+\) line \d+\.\s*$//;  # Remove eval line info
        
        push @failed_compilation, {
            path => $module_path,
            name => $module_name,
            error => $error
        };
    }
}

print "\nCompilation Results: " . 
      colored($results{modules_compiled}, 'green') . " passed, " . 
      colored($results{modules_failed_compilation}, 'red') . " failed\n\n";

# Step 3: Check for corresponding test files
print colored("Step 3: Checking for corresponding test files...\n", 'bold cyan');
my @modules_with_tests = ();
my @modules_missing_tests = ();

foreach my $module (@compiled_modules) {
    my $module_path = $module->{path};
    my $module_name = $module->{name};
    
    # Look for corresponding test file in both tests/ and Tests/ directories
    my $test_file_path = undef;
    my @possible_test_paths = (
        "tests/" . $module_path,
        "Tests/" . $module_path,
        "tests/" . $module_name . ".pl",
        "Tests/" . $module_name . ".pl"
    );
    
    # Replace .pm with .pl
    foreach my $path (@possible_test_paths) {
        $path =~ s/\.pm$/.pl/;
        if (-f $path) {
            $test_file_path = $path;
            last;
        }
    }
    
    print sprintf("%-50s", "Checking $module_name...");
    
    if ($test_file_path) {
        print colored(" ✓ TEST FOUND\n", 'green');
        $results{test_files_found}++;
        push @modules_with_tests, {
            %$module,
            test_path => $test_file_path
        };
    } else {
        print colored(" ✗ NO TEST FILE\n", 'red');
        $results{test_files_missing}++;
        push @modules_missing_tests, $module;
    }
}

print "\nTest File Status: " . 
      colored($results{test_files_found}, 'green') . " found, " . 
      colored($results{test_files_missing}, 'red') . " missing\n\n";

# Step 4: Analyze method coverage
print colored("Step 4: Analyzing method coverage...\n", 'bold cyan');

foreach my $module (@modules_with_tests) {
    print sprintf("%-50s", "Analyzing $module->{name}...");
    
    # Parse module to find public methods
    my @methods = parse_module_methods($module->{path});
    $results{methods_total} += @methods;
    
    if (@methods == 0) {
        print colored(" NO METHODS\n", 'yellow');
        next;
    }
    
    # Parse test file to find test coverage
    my $coverage = analyze_test_coverage($module->{test_path}, \@methods);
    
    my $happy_count = keys %{$coverage->{happy}};
    my $exception_count = keys %{$coverage->{exception}};
    my $missing_count = @methods - $happy_count;
    
    $results{methods_with_happy_tests} += $happy_count;
    $results{methods_with_exception_tests} += $exception_count;
    $results{methods_missing_tests} += $missing_count;
    
    if ($missing_count == 0) {
        print colored(" ✓ FULL COVERAGE\n", 'green');
    } else {
        print colored(" ⚠ PARTIAL ($happy_count/${\scalar(@methods)})\n", 'yellow');
        
        foreach my $method (@methods) {
            if (!exists $coverage->{happy}->{$method}) {
                push @{$results{methods_missing_coverage}}, {
                    module => $module->{name},
                    method => $method,
                    missing_happy => !exists $coverage->{happy}->{$method},
                    missing_exception => !exists $coverage->{exception}->{$method}
                };
            }
        }
    }
}

print "\nMethod Coverage: " . 
      colored($results{methods_with_happy_tests}, 'green') . " with happy tests, " . 
      colored($results{methods_with_exception_tests}, 'green') . " with exception tests, " . 
      colored($results{methods_missing_tests}, 'red') . " missing tests\n\n";

# Step 5: Execute all test files
print colored("Step 5: Executing test files...\n", 'bold cyan');

foreach my $module (@modules_with_tests) {
    my $test_path = $module->{test_path};
    print sprintf("%-50s", "Running $test_path...");
    
    # Execute the test file
    my $output = `perl -I. "$test_path" 2>&1`;
    my $exit_code = $? >> 8;
    
    # Parse test results
    my ($tests, $passed, $failed) = parse_test_output($output);
    $results{total_tests} += $tests;
    $results{total_passed} += $passed;
    $results{total_failed} += $failed;
    
    if ($exit_code == 0 && $failed == 0 && $passed > 0) {
        print colored(" ✓ PASS ($passed/$tests)\n", 'green');
    } else {
        print colored(" ✗ FAIL ($passed/$tests)\n", 'red');
        push @{$results{failed_modules}}, {
            module => $module->{name},
            test_path => $test_path,
            tests => $tests,
            passed => $passed,
            failed => $failed,
            output => $output
        };
    }
}

# Step 6: Generate comprehensive report
print "\n" . colored("=" x 60, 'blue') . "\n";
print colored("COMPREHENSIVE TEST RESULTS SUMMARY\n", 'bold');
print colored("=" x 60, 'blue') . "\n";

print colored("\nMODULE COMPILATION:\n", 'bold yellow');
printf "  Total modules found:     %s\n", colored($results{modules_found}, 'cyan');
printf "  Compilation passed:      %s\n", colored($results{modules_compiled}, 'green');
printf "  Compilation failed:      %s\n", colored($results{modules_failed_compilation}, 'red');
printf "  Compilation success:     %s%%\n", colored(sprintf("%.1f", ($results{modules_compiled} / $results{modules_found}) * 100), 'green');

print colored("\nTEST FILE COVERAGE:\n", 'bold yellow');
printf "  Test files found:        %s\n", colored($results{test_files_found}, 'green');
printf "  Test files missing:      %s\n", colored($results{test_files_missing}, 'red');
printf "  Test file coverage:      %s%%\n", colored(sprintf("%.1f", ($results{test_files_found} / $results{modules_compiled}) * 100), 'green');

print colored("\nMETHOD TEST COVERAGE:\n", 'bold yellow');
printf "  Total methods found:     %s\n", colored($results{methods_total}, 'cyan');
printf "  Methods with happy tests:%s\n", colored($results{methods_with_happy_tests}, 'green');
printf "  Methods with exception:  %s\n", colored($results{methods_with_exception_tests}, 'green');
printf "  Methods missing tests:   %s\n", colored($results{methods_missing_tests}, 'red');
printf "  Method coverage:         %s%%\n", colored(sprintf("%.1f", ($results{methods_with_happy_tests} / $results{methods_total}) * 100), 'green');

print colored("\nTEST EXECUTION:\n", 'bold yellow');
printf "  Total tests executed:    %s\n", colored($results{total_tests}, 'cyan');
printf "  Tests passed:            %s\n", colored($results{total_passed}, 'green');
printf "  Tests failed:            %s\n", colored($results{total_failed}, 'red');
printf "  Test success rate:       %s%%\n", colored(sprintf("%.1f", ($results{total_passed} / $results{total_tests}) * 100), 'green');

# Report failures and missing coverage
if (@failed_compilation > 0) {
    print colored("\nFAILED COMPILATIONS:\n", 'bold red');
    foreach my $failure (@failed_compilation) {
        print "  ✗ $failure->{name}\n";
        print "    Error: $failure->{error}\n";
    }
}

if (@modules_missing_tests > 0) {
    print colored("\nMISSING TEST FILES:\n", 'bold red');
    foreach my $module (@modules_missing_tests) {
        print "  ✗ $module->{name} (no corresponding .pl file)\n";
    }
}

if (@{$results{methods_missing_coverage}} > 0) {
    print colored("\nMETHODS MISSING TEST COVERAGE:\n", 'bold red');
    foreach my $missing (@{$results{methods_missing_coverage}}) {
        print "  ⚠ $missing->{module}::$missing->{method}\n";
        print "    Missing: ";
        my @missing_types = ();
        push @missing_types, "happy path" if $missing->{missing_happy};
        push @missing_types, "exception" if $missing->{missing_exception};
        print join(", ", @missing_types) . " tests\n";
    }
}

if (@{$results{failed_modules}} > 0) {
    print colored("\nFAILED TEST EXECUTIONS:\n", 'bold red');
    foreach my $failure (@{$results{failed_modules}}) {
        print "  ✗ $failure->{module} ($failure->{passed}/$failure->{tests} passed)\n";
        print "    Test file: $failure->{test_path}\n";
        
        # Show first few lines of error output
        if ($failure->{output}) {
            my @lines = split /\n/, $failure->{output};
            my $show_lines = 3;
            if (@lines > $show_lines) {
                @lines = (@lines[0..$show_lines-1], "... (truncated)");
            }
            print "    Output: " . join("\n            ", @lines) . "\n";
        }
    }
}

# Final assessment
my $overall_success = (
    $results{modules_failed_compilation} == 0 && 
    $results{test_files_missing} == 0 && 
    $results{methods_missing_tests} == 0 && 
    $results{total_failed} == 0
);

print "\n" . colored("OVERALL ASSESSMENT: ", 'bold');
if ($overall_success) {
    print colored("✓ EXCELLENT - All modules compile, have tests, and pass\n", 'bold green');
    exit 0;
} else {
    print colored("⚠ NEEDS IMPROVEMENT - See issues above\n", 'bold yellow');
    exit 1;
}

# Helper functions
sub parse_module_methods {
    my ($module_path) = @_;
    my @methods = ();
    
    open my $fh, '<', $module_path or return ();
    my $content = do { local $/; <$fh> };
    close $fh;
    
    # Find public subroutines (not starting with _)
    while ($content =~ /^\s*sub\s+([A-Za-z][A-Za-z0-9]*)\s*[\{\(]/gm) {
        my $method = $1;
        next if $method =~ /^_/;  # Skip private methods
        next if $method eq 'new'; # Skip constructor (usually tested separately)
        push @methods, $method;
    }
    
    return @methods;
}

sub analyze_test_coverage {
    my ($test_path, $methods) = @_;
    my $coverage = { happy => {}, exception => {} };
    
    open my $fh, '<', $test_path or return $coverage;
    my $content = do { local $/; <$fh> };
    close $fh;
    
    # Look for test patterns for each method
    foreach my $method (@$methods) {
        # Happy path tests (various patterns)
        if ($content =~ /\b$method\b.*(?:ok|is|like|pass)/i ||
            $content =~ /test.*$method.*happy/i ||
            $content =~ /test.*$method.*normal/i ||
            $content =~ /test.*$method.*valid/i) {
            $coverage->{happy}->{$method} = 1;
        }
        
        # Exception tests
        if ($content =~ /\b$method\b.*(?:eval|exception|error|die|fail)/i ||
            $content =~ /test.*$method.*exception/i ||
            $content =~ /test.*$method.*error/i ||
            $content =~ /test.*$method.*invalid/i ||
            $content =~ /test.*$method.*null/i) {
            $coverage->{exception}->{$method} = 1;
        }
    }
    
    return $coverage;
}

sub parse_test_output {
    my ($output) = @_;
    my $tests = 0;
    my $passed = 0;
    my $failed = 0;
    
    # Look for Test::More summary line like "1..15"
    if ($output =~ /^1\.\.(\d+)/m) {
        $tests = $1;
    }
    
    # Count ok/not ok lines
    my @lines = split /\n/, $output;
    for my $line (@lines) {
        if ($line =~ /^ok \d+/) {
            $passed++;
        } elsif ($line =~ /^not ok \d+/) {
            $failed++;
        }
    }
    
    # Alternative parsing for different formats
    if ($output =~ /Tests: (\d+), Passed: (\d+), Failed: (\d+)/) {
        $tests = $1;
        $passed = $2;
        $failed = $3;
    } elsif ($output =~ /(\d+) tests?, (\d+) passed, (\d+) failed/) {
        $tests = $1;
        $passed = $2;
        $failed = $3;
    } elsif ($output =~ /All (\d+) tests? passed/) {
        $tests = $1;
        $passed = $1;
        $failed = 0;
    }
    
    # If no explicit count, infer from ok/not ok lines
    if ($tests == 0) {
        $tests = $passed + $failed;
    }
    
    return ($tests, $passed, $failed);
}