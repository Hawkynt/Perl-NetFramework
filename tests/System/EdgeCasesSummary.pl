#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;

# Summary test runner for all edge case tests
BEGIN {
    print "=== Perl .NET Framework Edge Case Test Suite Summary ===\n";
    print "Running comprehensive edge case tests for System core classes\n\n";
}

# Test file information
my @edge_case_tests = (
    {
        file => 'ObjectEdgeCases.pl',
        description => 'System::Object comprehensive edge cases',
        category => 'Core Objects',
    },
    {
        file => 'StringEdgeCases.pl', 
        description => 'System::String comprehensive edge cases',
        category => 'Core Objects',
    },
    {
        file => 'ArrayEdgeCases.pl',
        description => 'System::Array comprehensive edge cases', 
        category => 'Core Objects',
    },
    {
        file => 'OperatorOverloadingEdgeCases.pl',
        description => 'Operator overloading comprehensive tests',
        category => 'Operators',
    },
    {
        file => 'MemoryPerformanceEdgeCases.pl',
        description => 'Memory pressure and performance tests',
        category => 'Performance',
    },
    {
        file => 'CrossPlatformEdgeCases.pl',
        description => 'Cross-platform compatibility tests',
        category => 'Compatibility',
    },
);

# Basic tests for comparison
my @basic_tests = (
    {
        file => 'Object.pl',
        description => 'System::Object basic functionality',
        category => 'Basic',
    },
    {
        file => 'String.pl',
        description => 'System::String basic functionality', 
        category => 'Basic',
    },
    {
        file => 'Array.pl',
        description => 'System::Array basic functionality',
        category => 'Basic',
    },
);

sub run_test_file {
    my ($test_file, $timeout) = @_;
    $timeout ||= 30;
    
    return unless -f $test_file;
    
    my $start_time = time();
    my $cmd = "timeout ${timeout} perl \"$test_file\" 2>&1";
    my $output = `$cmd`;
    my $exit_code = $?;
    my $duration = time() - $start_time;
    
    # Parse test results from TAP output
    my $total_tests = 0;
    my $passed_tests = 0;
    my $failed_tests = 0;
    my $skipped_tests = 0;
    
    for my $line (split /\n/, $output) {
        if ($line =~ /^1\.\.(\d+)/) {
            $total_tests = $1;
        } elsif ($line =~ /^ok \d+/) {
            $passed_tests++;
        } elsif ($line =~ /^not ok \d+/) {
            $failed_tests++;
        } elsif ($line =~ /^ok \d+ # skip/i) {
            $skipped_tests++;
            $passed_tests--; # Don't double count
        }
    }
    
    # Check for timeout or other issues
    my $status = 'PASS';
    if ($exit_code != 0) {
        if ($exit_code == 31744) {  # Timeout exit code
            $status = 'TIMEOUT';
        } elsif ($failed_tests > 0) {
            $status = 'FAIL';
        } else {
            $status = 'ERROR';
        }
    } elsif ($failed_tests > 0) {
        $status = 'FAIL';
    }
    
    my $pass_rate = $total_tests > 0 ? sprintf("%.1f", ($passed_tests / $total_tests) * 100) : 0;
    
    return {
        file => $test_file,
        status => $status,
        total => $total_tests,
        passed => $passed_tests,
        failed => $failed_tests,
        skipped => $skipped_tests,
        pass_rate => $pass_rate,
        duration => sprintf("%.2f", $duration),
        exit_code => $exit_code,
    };
}

sub print_test_result {
    my ($result, $description) = @_;
    
    my $status_symbol = {
        'PASS' => '✓',
        'FAIL' => '✗', 
        'ERROR' => '⚠',
        'TIMEOUT' => '⏰',
        'SKIP' => '-',
    }->{$result->{status}} || '?';
    
    printf "%-6s %s %-35s %3d/%3d (%5s%%) [%5ss]\n",
        $status_symbol,
        $result->{status},
        $description,
        $result->{passed},
        $result->{total},
        $result->{pass_rate},
        $result->{duration};
}

sub run_test_suite {
    my ($tests, $category_name) = @_;
    
    print "\n=== $category_name Tests ===\n";
    print "Status Test                                    Pass/Total (Rate)   [Time]\n";
    print "────── ─────────────────────────────────────── ─────────── ─────── ──────\n";
    
    my $total_passed = 0;
    my $total_tests = 0;
    my $total_failed = 0;
    my $suite_status = 'PASS';
    
    for my $test (@$tests) {
        my $result = run_test_file($test->{file}, 45);
        
        if ($result) {
            print_test_result($result, $test->{description});
            
            $total_passed += $result->{passed};
            $total_tests += $result->{total};
            $total_failed += $result->{failed};
            
            if ($result->{status} ne 'PASS' && $result->{status} ne 'SKIP') {
                $suite_status = 'FAIL';
            }
        } else {
            print "ERROR  Missing test file: $test->{file}\n";
            $suite_status = 'ERROR';
        }
    }
    
    my $suite_rate = $total_tests > 0 ? sprintf("%.1f", ($total_passed / $total_tests) * 100) : 0;
    
    print "────── ─────────────────────────────────────── ─────────── ─────── ──────\n";
    printf "%-6s %-35s %3d/%3d (%5s%%)\n",
        $suite_status eq 'PASS' ? '✓' : '✗',
        "$category_name Suite Total:",
        $total_passed,
        $total_tests,
        $suite_rate;
    
    return {
        status => $suite_status,
        total => $total_tests,
        passed => $total_passed,
        failed => $total_failed,
        rate => $suite_rate,
    };
}

# Run test suites
my $basic_results = run_test_suite(\@basic_tests, 'Basic Functionality');
my $edge_results = run_test_suite(\@edge_case_tests, 'Edge Case');

# Overall summary
print "\n=== Overall Test Summary ===\n";

my $grand_total = $basic_results->{total} + $edge_results->{total};
my $grand_passed = $basic_results->{passed} + $edge_results->{passed};
my $grand_failed = $basic_results->{failed} + $edge_results->{failed};
my $grand_rate = $grand_total > 0 ? sprintf("%.1f", ($grand_passed / $grand_total) * 100) : 0;

printf "Basic Functionality Tests:   %3d/%3d passed (%5s%%)\n",
    $basic_results->{passed}, $basic_results->{total}, $basic_results->{rate};
printf "Edge Case Tests:            %3d/%3d passed (%5s%%)\n", 
    $edge_results->{passed}, $edge_results->{total}, $edge_results->{rate};
print "─────────────────────────────────────────────────────────\n";
printf "TOTAL COMPREHENSIVE TESTS:  %3d/%3d passed (%5s%%)\n",
    $grand_passed, $grand_total, $grand_rate;

# Status assessment
my $overall_status = 'EXCELLENT';
if ($grand_rate < 50) {
    $overall_status = 'NEEDS MAJOR WORK';
} elsif ($grand_rate < 70) {
    $overall_status = 'NEEDS IMPROVEMENT';
} elsif ($grand_rate < 85) {
    $overall_status = 'GOOD';
} elsif ($grand_rate < 95) {
    $overall_status = 'VERY GOOD';
}

print "\nOverall Framework Status: $overall_status\n";

# Specific findings and recommendations
print "\n=== Key Findings ===\n";

if ($basic_results->{rate} >= 90) {
    print "• Core functionality is solid ($basic_results->{rate}% pass rate)\n";
} else {
    print "• Core functionality needs attention ($basic_results->{rate}% pass rate)\n";
}

if ($edge_results->{rate} >= 80) {
    print "• Edge case handling is robust ($edge_results->{rate}% pass rate)\n";
} else {
    print "• Edge case handling needs improvement ($edge_results->{rate}% pass rate)\n";
}

print "\n=== Recommendations ===\n";

if ($grand_rate < 85) {
    print "1. Focus on fixing failing basic tests first\n";
    print "2. Address null reference exception handling\n";
    print "3. Improve operator overloading implementation\n";
    print "4. Fix unicode string handling issues\n";
} elsif ($grand_rate < 95) {
    print "1. Polish remaining edge cases\n"; 
    print "2. Optimize performance for large data sets\n";
    print "3. Enhance cross-platform compatibility\n";
} else {
    print "1. Framework is in excellent shape\n";
    print "2. Consider adding more advanced features\n";
    print "3. Documentation and examples could be expanded\n";
}

# Test that this summary ran successfully
ok(1, 'Edge case test summary completed');
done_testing(1);