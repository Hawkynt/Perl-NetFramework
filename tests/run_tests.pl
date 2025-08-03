#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Spec;
use Getopt::Long;
use Term::ANSIColor qw(colored);

my $verbose = 0;
my $pattern = '*.pl';
my $help = 0;

GetOptions(
    'verbose|v' => \$verbose,
    'pattern|p=s' => \$pattern,
    'help|h' => \$help,
) or die "Error in command line arguments\n";

if ($help) {
    print_help();
    exit 0;
}

print colored("Perl-NetFramework Test Runner\n", 'bold blue');
print colored("=" x 40, 'blue') . "\n\n";

my @test_files;
my $test_dir = '.';

# Find all test files (excluding run_tests.pl itself)
find(sub {
    if ($_ =~ /\.pl$/ && -f $_ && $_ ne 'run_tests.pl') {
        push @test_files, $File::Find::name;
    }
}, $test_dir);

if (@test_files == 0) {
    print colored("No test files found matching pattern: $pattern\n", 'yellow');
    exit 1;
}

@test_files = sort @test_files;

print colored("Found " . scalar(@test_files) . " test file(s):\n", 'green');
if ($verbose) {
    for my $file (@test_files) {
        print "  $file\n";
    }
    print "\n";
}

my $total_tests = 0;
my $total_passed = 0;
my $total_failed = 0;
my $failed_files = [];

for my $test_file (@test_files) {
    print colored("Running: $test_file\n", 'cyan');
    
    my $cmd = "perl -I.. \"$test_file\"";
    my $output = `$cmd 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($verbose || $exit_code != 0) {
        print $output;
    }
    
    # Parse Test::More output
    my ($tests, $passed, $failed) = parse_test_output($output);
    $total_tests += $tests;
    $total_passed += $passed;
    $total_failed += $failed;
    
    if ($exit_code == 0 && $failed == 0) {
        print colored("✓ PASSED", 'green');
    } else {
        print colored("✗ FAILED", 'red');
        push @$failed_files, $test_file;
    }
    
    print " ($passed/$tests tests)\n\n";
}

print colored("=" x 40, 'blue') . "\n";
print colored("Test Summary:\n", 'bold');
print "Total tests: $total_tests\n";
print colored("Passed: $total_passed\n", 'green');

if ($total_failed > 0) {
    print colored("Failed: $total_failed\n", 'red');
    print colored("\nFailed files:\n", 'red');
    for my $file (@$failed_files) {
        print "  $file\n";
    }
    exit 1;
} else {
    print colored("Failed: 0\n", 'green');
    print colored("\nAll tests passed! 🎉\n", 'bold green');
    exit 0;
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
    
    # If no explicit count, infer from ok/not ok lines
    if ($tests == 0) {
        $tests = $passed + $failed;
    }
    
    return ($tests, $passed, $failed);
}

sub print_help {
    print <<'EOF';
Perl-NetFramework Test Runner

Usage: perl run_tests.pl [options]

Options:
    -v, --verbose       Show detailed output from each test
    -p, --pattern=GLOB  Pattern to match test files (default: *.pl)
    -h, --help          Show this help message

Examples:
    perl run_tests.pl                    # Run all tests
    perl run_tests.pl -v                 # Run all tests with verbose output
    perl run_tests.pl -p "String*"       # Run only String-related tests
    perl run_tests.pl -p "System/*.pl"   # Run only System namespace tests

The test runner will:
- Find all test files matching the pattern
- Execute each test file with perl
- Parse Test::More output for pass/fail counts
- Provide a summary of results
- Exit with code 0 if all tests pass, 1 if any fail

Test files should use Test::More and follow the naming convention *.pl
EOF
}