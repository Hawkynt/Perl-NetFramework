#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Spec;
use Getopt::Long;
use Term::ANSIColor qw(colored);
use lib '.';

my $verbose = 0;
my $pattern = '*.pl';
my $help = 0;
my $run_embedded = 1;

GetOptions(
    'verbose|v' => \$verbose,
    'pattern|p=s' => \$pattern,
    'embedded|e!' => \$run_embedded,
    'help|h' => \$help,
) or die "Error in command line arguments\n";

if ($help) {
    print_help();
    exit 0;
}

print colored("Perl-NetFramework Comprehensive Test Runner\n", 'bold blue');
print colored("=" x 50, 'blue') . "\n\n";

my $total_tests = 0;
my $total_passed = 0;
my $total_failed = 0;
my $failed_files = [];

# 1. Run regular test files
my @test_files;
my $test_dir = File::Spec->catdir('tests');

if (-d $test_dir) {
    find(sub {
        if ($File::Find::name =~ /\Q$pattern\E$/ && -f $_) {
            push @test_files, $File::Find::name;
        }
    }, $test_dir);
    
    if (@test_files > 0) {
        print colored("Running " . scalar(@test_files) . " test file(s):\n", 'green');
        
        for my $test_file (sort @test_files) {
            print colored("Running: $test_file\n", 'cyan');
            
            my $cmd = "perl -I. \"$test_file\"";
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
    }
}

# 2. Run embedded tests in modules
if ($run_embedded) {
    print colored("\nSearching for embedded tests in modules...\n", 'bold yellow');
    
    my @modules;
    find(sub {
        if ($File::Find::name =~ /\.pm$/ && -f $_) {
            push @modules, $File::Find::name;
        }
    }, '.');
    
    my @embedded_test_modules;
    for my $module (sort @modules) {
        # Skip Filter modules and test directory
        next if $module =~ /Filter/ || $module =~ /tests/;
        
        open my $fh, '<', $module or next;
        my $content = do { local $/; <$fh> };
        close $fh;
        
        # Look for Test method
        if ($content =~ /sub\s+Test\s*\{/ || $content =~ /::Test\s*\(/) {
            push @embedded_test_modules, $module;
        }
    }
    
    if (@embedded_test_modules > 0) {
        print colored("Found " . scalar(@embedded_test_modules) . " module(s) with embedded tests:\n", 'green');
        
        for my $module (@embedded_test_modules) {
            print colored("Running embedded tests in: $module\n", 'cyan');
            
            # Convert file path to package name
            my $package = $module;
            $package =~ s/\.pm$//;
            $package =~ s/[\/\\]/::/g;
            
            my $test_code = "
                use lib '.';
                use $package;
                if ($package->can('Test')) {
                    eval { $package->Test(); };
                    if (\$@) {
                        print \"Error running embedded test: \$@\\n\";
                        exit 1;
                    } else {
                        print \"Embedded test completed successfully\\n\";
                        exit 0;
                    }
                } else {
                    print \"No Test method found in $package\\n\";
                    exit 1;
                }
            ";
            
            my $output = `perl -e "$test_code" 2>&1`;
            my $exit_code = $? >> 8;
            
            if ($verbose || $exit_code != 0) {
                print $output;
            }
            
            if ($exit_code == 0) {
                print colored("✓ PASSED", 'green');
                $total_passed++;
            } else {
                print colored("✗ FAILED", 'red');
                push @$failed_files, "$module (embedded)";
                $total_failed++;
            }
            $total_tests++;
            
            print "\n\n";
        }
    } else {
        print colored("No embedded tests found in modules.\n", 'yellow');
    }
}

print colored("=" x 50, 'blue') . "\n";
print colored("Test Summary:\n", 'bold');
print "Total test runs: $total_tests\n";
print colored("Passed: $total_passed\n", 'green');

if ($total_failed > 0) {
    print colored("Failed: $total_failed\n", 'red');
    print colored("\nFailed test runs:\n", 'red');
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
Perl-NetFramework Comprehensive Test Runner

Usage: perl run_all_tests.pl [options]

Options:
    -v, --verbose       Show detailed output from each test
    -p, --pattern=GLOB  Pattern to match test files (default: *.pl)
    -e, --[no-]embedded Enable/disable embedded test discovery (default: enabled)
    -h, --help          Show this help message

Examples:
    perl run_all_tests.pl                    # Run all tests including embedded
    perl run_all_tests.pl -v                 # Run all tests with verbose output
    perl run_all_tests.pl --no-embedded      # Run only file-based tests
    perl run_all_tests.pl -p "String*"       # Run only String-related file tests

The test runner will:
- Find and run all test files matching the pattern in tests/ directory
- Search for and run embedded Test() methods in modules
- Parse Test::More output for pass/fail counts
- Provide a comprehensive summary of results
- Exit with code 0 if all tests pass, 1 if any fail

Test files should use Test::More and follow the naming convention *.pl
Embedded tests should implement a Test() class method that runs test assertions
EOF
}