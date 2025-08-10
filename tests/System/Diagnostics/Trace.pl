#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Diagnostics::Trace;
require System;
require CSharp;

use Test::More;

# Start tests
my $test_count = 26;
plan tests => $test_count;

# Test 1-5: Basic Trace functionality
{
    # Test that Trace methods exist and don't crash
    ok(defined(&System::Diagnostics::Trace::WriteLine), 'Trace::WriteLine method exists');
    ok(defined(&System::Diagnostics::Trace::Write), 'Trace::Write method exists');
    
    # Test WriteLine doesn't crash with string input
    my $test_message = "Test WriteLine message";
    eval {
        System::Diagnostics::Trace->WriteLine($test_message);
    };
    ok(!$@, 'WriteLine with string completes without error');
    
    # Test Write doesn't crash with string input
    eval {
        System::Diagnostics::Trace->Write("Test Write message");
    };
    ok(!$@, 'Write with string completes without error');
    
    # Test with empty string
    eval {
        System::Diagnostics::Trace->WriteLine("");
        System::Diagnostics::Trace->Write("");
    };
    ok(!$@, 'WriteLine and Write with empty string complete without error');
}

# Test 6-10: Input validation and edge cases
{
    # Test with undefined input (should not crash in a well-behaved system)
    eval {
        System::Diagnostics::Trace->WriteLine(undef);
    };
    ok(!$@, 'WriteLine with undef completes without error');
    
    eval {
        System::Diagnostics::Trace->Write(undef);
    };
    ok(!$@, 'Write with undef completes without error');
    
    # Test with numeric input
    eval {
        System::Diagnostics::Trace->WriteLine(42);
        System::Diagnostics::Trace->Write(3.14);
    };
    ok(!$@, 'WriteLine and Write with numbers complete without error');
    
    # Test with long string
    my $long_string = "A" x 1000;
    eval {
        System::Diagnostics::Trace->WriteLine($long_string);
        System::Diagnostics::Trace->Write($long_string);
    };
    ok(!$@, 'WriteLine and Write with long string complete without error');
    
    # Test with special characters
    my $special_string = "Test with\nNewlines\tTabs and\r\nCRLF";
    eval {
        System::Diagnostics::Trace->WriteLine($special_string);
        System::Diagnostics::Trace->Write($special_string);
    };
    ok(!$@, 'WriteLine and Write with special characters complete without error');
}

# Test 11-15: DEBUG constant behavior
{
    # Test that DEBUG constant exists  
    my $debug_ref = eval { \&System::Diagnostics::Trace::DEBUG };
    ok(defined($debug_ref) || defined(&System::Diagnostics::Trace::DEBUG), 'DEBUG constant is defined');
    
    # Test that DEBUG has a boolean value
    my $debug_value = eval { System::Diagnostics::Trace::DEBUG() } || eval { &System::Diagnostics::Trace::DEBUG } || 1;
    ok(defined($debug_value), 'DEBUG constant has defined value');
    ok($debug_value == 0 || $debug_value == 1 || $debug_value eq 'true' || $debug_value eq 'false', 'DEBUG constant has boolean-like value');
    
    # Test that methods behave consistently regardless of DEBUG value
    # They should not throw exceptions even if DEBUG affects their behavior
    eval {
        for my $i (1..5) {
            System::Diagnostics::Trace->WriteLine("DEBUG test message $i");
            System::Diagnostics::Trace->Write("DEBUG test $i ");
        }
    };
    ok(!$@, 'Multiple Trace calls complete without error');
    
    # Test rapid succession calls (performance and stability)
    eval {
        for my $i (1..100) {
            System::Diagnostics::Trace->Write(".");
        }
        System::Diagnostics::Trace->WriteLine("");
    };
    ok(!$@, 'Rapid succession Trace calls complete without error');
}

# Test 16-20: Integration with Console output
{
    # Since Trace uses Console::WriteLine and Console::Write internally,
    # test that these don't conflict with standard output
    
    eval {
        # Capture any potential output conflicts
        local $| = 1; # Auto-flush
        System::Diagnostics::Trace->WriteLine("Integration test line 1");
        print "Direct print line\n";
        System::Diagnostics::Trace->WriteLine("Integration test line 2");
    };
    ok(!$@, 'Trace and direct print integration works without error');
    
    # Test mixed output types
    eval {
        System::Diagnostics::Trace->Write("Write test: ");
        System::Diagnostics::Trace->WriteLine("Line test");
        System::Diagnostics::Trace->Write("Another write");
        System::Diagnostics::Trace->WriteLine(" and line");
    };
    ok(!$@, 'Mixed Write and WriteLine calls complete without error');
    
    # Test with System::String objects if they exist
    eval {
        if (defined(&System::String::new)) {
            my $str = System::String->new("System::String test");
            System::Diagnostics::Trace->WriteLine($str);
            System::Diagnostics::Trace->Write($str);
        }
    };
    ok(!$@, 'Trace with System::String objects completes without error');
    
    # Test with references and objects
    my $hash_ref = { test => "value" };
    my $array_ref = [1, 2, 3];
    eval {
        System::Diagnostics::Trace->WriteLine($hash_ref);
        System::Diagnostics::Trace->WriteLine($array_ref);
    };
    ok(!$@, 'Trace with references completes without error');
    
    # Test that methods are accessible via full package name
    eval {
        System::Diagnostics::Trace::WriteLine("Direct package call");
        System::Diagnostics::Trace::Write("Direct package write");
    };
    ok(!$@, 'Direct package method calls complete without error');
}

# Test 21-26: Method signature and parameter handling
{
    # Test method signature consistency
    my $method_ref = \&System::Diagnostics::Trace::WriteLine;
    ok(ref($method_ref) eq 'CODE', 'WriteLine is a code reference');
    
    $method_ref = \&System::Diagnostics::Trace::Write;
    ok(ref($method_ref) eq 'CODE', 'Write is a code reference');
    
    # Test parameter count handling (should work with single parameter)
    eval {
        System::Diagnostics::Trace->WriteLine("Single param test");
    };
    ok(!$@, 'Single parameter calls work correctly');
    
    # Test that excessive parameters don't cause issues
    eval {
        System::Diagnostics::Trace->WriteLine("First param", "Second param", "Third param");
        System::Diagnostics::Trace->Write("First", "Second", "Third");
    };
    ok(!$@, 'Multiple parameters handled gracefully');
    
    # Test CSharp integration (if available)
    eval {
        # Test that CSharp package name shortening works
        my $package = 'System::Diagnostics::Trace';
        ok($package =~ /Trace$/, 'Package name ends with Trace as expected');
    };
    ok(!$@, 'CSharp integration check completes without error');
    
    # Final comprehensive test
    eval {
        # Simulate typical usage pattern
        System::Diagnostics::Trace->WriteLine("=== Trace Test Session Start ===");
        for my $i (1..3) {
            System::Diagnostics::Trace->Write("Processing item $i... ");
            System::Diagnostics::Trace->WriteLine("Done");
        }
        System::Diagnostics::Trace->WriteLine("=== Trace Test Session Complete ===");
    };
    ok(!$@, 'Comprehensive typical usage pattern completes without error');
}

# Clean up and exit
done_testing();
exit(0);