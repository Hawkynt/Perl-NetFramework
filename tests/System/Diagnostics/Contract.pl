#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Diagnostics::Contracts::Contract;
require System::Exceptions;
require System;
require CSharp;

use Test::More;

# Start tests
my $test_count = 32;
plan tests => $test_count;

# Test 1-8: Requires method
{
    # Test that Requires method exists
    ok(defined(&System::Diagnostics::Contracts::Contract::Requires), 'Contract::Requires method exists');
    
    # Test Requires with true condition (should pass)
    eval {
        System::Diagnostics::Contracts::Contract->Requires(1, "Always true condition");
    };
    ok(!$@, 'Requires with true condition passes');
    
    # Test Requires with true condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Requires(1);
    };
    ok(!$@, 'Requires with true condition and no message passes');
    
    # Test Requires with false condition (should throw)
    eval {
        System::Diagnostics::Contracts::Contract->Requires(0, "Always false condition");
    };
    my $exception = $@;
    ok($exception, 'Requires with false condition throws exception');
    like($exception, qr/ContractException/, 'Requires exception is ContractException type');
    
    # Test Requires with false condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Requires(0);
    };
    $exception = $@;
    ok($exception, 'Requires with false condition and no message throws exception');
    like($exception, qr/Require/, 'Default Requires exception message contains "Require"');
    
    # Test Requires with custom message
    eval {
        System::Diagnostics::Contracts::Contract->Requires(0, "Custom require message");
    };
    $exception = $@;
    like($exception, qr/Custom require message/, 'Requires exception contains custom message');
}

# Test 9-16: Assert method
{
    # Test that Assert method exists
    ok(defined(&System::Diagnostics::Contracts::Contract::Assert), 'Contract::Assert method exists');
    
    # Test Assert with true condition (should pass)
    eval {
        System::Diagnostics::Contracts::Contract->Assert(1, "Always true assertion");
    };
    ok(!$@, 'Assert with true condition passes');
    
    # Test Assert with true condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Assert(1);
    };
    ok(!$@, 'Assert with true condition and no message passes');
    
    # Test Assert with false condition (should throw)
    eval {
        System::Diagnostics::Contracts::Contract->Assert(0, "Always false assertion");
    };
    my $exception = $@;
    ok($exception, 'Assert with false condition throws exception');
    like($exception, qr/ContractException/, 'Assert exception is ContractException type');
    
    # Test Assert with false condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Assert(0);
    };
    $exception = $@;
    ok($exception, 'Assert with false condition and no message throws exception');
    like($exception, qr/Assert/, 'Default Assert exception message contains "Assert"');
    
    # Test Assert with custom message
    eval {
        System::Diagnostics::Contracts::Contract->Assert(0, "Custom assert message");
    };
    $exception = $@;
    like($exception, qr/Custom assert message/, 'Assert exception contains custom message');
}

# Test 17-24: Assume method
{
    # Test that Assume method exists
    ok(defined(&System::Diagnostics::Contracts::Contract::Assume), 'Contract::Assume method exists');
    
    # Test Assume with true condition (should pass)
    eval {
        System::Diagnostics::Contracts::Contract->Assume(1, "Always true assumption");
    };
    ok(!$@, 'Assume with true condition passes');
    
    # Test Assume with true condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Assume(1);
    };
    ok(!$@, 'Assume with true condition and no message passes');
    
    # Test Assume with false condition (should throw)
    eval {
        System::Diagnostics::Contracts::Contract->Assume(0, "Always false assumption");
    };
    my $exception = $@;
    ok($exception, 'Assume with false condition throws exception');
    like($exception, qr/ContractException/, 'Assume exception is ContractException type');
    
    # Test Assume with false condition without message
    eval {
        System::Diagnostics::Contracts::Contract->Assume(0);
    };
    $exception = $@;
    ok($exception, 'Assume with false condition and no message throws exception');
    like($exception, qr/Assume/, 'Default Assume exception message contains "Assume"');
    
    # Test Assume with custom message
    eval {
        System::Diagnostics::Contracts::Contract->Assume(0, "Custom assume message");
    };
    $exception = $@;
    like($exception, qr/Custom assume message/, 'Assume exception contains custom message');
}

# Test 25-32: Advanced scenarios and edge cases
{
    # Test with complex boolean expressions
    eval {
        my $x = 10;
        my $y = 20;
        System::Diagnostics::Contracts::Contract->Requires($x < $y, "x should be less than y");
        System::Diagnostics::Contracts::Contract->Assert($x + $y == 30, "Sum should be 30");
        System::Diagnostics::Contracts::Contract->Assume($y - $x == 10, "Difference should be 10");
    };
    ok(!$@, 'Complex boolean expressions in contracts work correctly');
    
    # Test with string comparisons
    eval {
        my $str1 = "hello";
        my $str2 = "world";
        System::Diagnostics::Contracts::Contract->Requires(length($str1) > 0, "String should not be empty");
        System::Diagnostics::Contracts::Contract->Assert($str1 ne $str2, "Strings should be different");
    };
    ok(!$@, 'String comparisons in contracts work correctly');
    
    # Test with array and hash checks
    eval {
        my @array = (1, 2, 3);
        my %hash = (key => 'value');
        System::Diagnostics::Contracts::Contract->Requires(@array > 0, "Array should not be empty");
        System::Diagnostics::Contracts::Contract->Assert(exists($hash{key}), "Hash should contain key");
    };
    ok(!$@, 'Array and hash checks in contracts work correctly');
    
    # Test with undefined values
    eval {
        my $defined_var = "test";
        my $undefined_var = undef;
        System::Diagnostics::Contracts::Contract->Requires(defined($defined_var), "Variable should be defined");
    };
    ok(!$@, 'Defined value check passes');
    
    eval {
        my $undefined_var = undef;
        System::Diagnostics::Contracts::Contract->Requires(defined($undefined_var), "Variable should be defined");
    };
    my $exception = $@;
    ok($exception, 'Undefined value check throws exception');
    
    # Test method chaining and multiple contracts
    eval {
        my $value = 42;
        System::Diagnostics::Contracts::Contract->Requires($value > 0, "Value must be positive");
        System::Diagnostics::Contracts::Contract->Assert($value < 100, "Value must be less than 100");
        System::Diagnostics::Contracts::Contract->Assume($value != 0, "Value must not be zero");
    };
    ok(!$@, 'Multiple contract checks in sequence work correctly');
    
    # Test that exceptions are proper System::ContractException objects
    eval {
        System::Diagnostics::Contracts::Contract->Requires(0, "Test exception type");
    };
    $exception = $@;
    # Check if it's the expected exception type (may vary based on implementation)
    ok(ref($exception) || $exception =~ /ContractException/, 'Exception is proper ContractException object or contains ContractException');
    
    # Test direct method calls (without object syntax)
    eval {
        System::Diagnostics::Contracts::Contract::Requires(1, "Direct call test");
        System::Diagnostics::Contracts::Contract::Assert(1, "Direct assert test");
        System::Diagnostics::Contracts::Contract::Assume(1, "Direct assume test");
    };
    ok(!$@, 'Direct method calls work correctly');
    
    # Test integration with typical validation patterns
    sub validate_age {
        my $age = shift;
        System::Diagnostics::Contracts::Contract->Requires(defined($age), "Age must be defined");
        System::Diagnostics::Contracts::Contract->Requires($age >= 0, "Age must be non-negative");
        System::Diagnostics::Contracts::Contract->Requires($age <= 150, "Age must be reasonable");
        return $age;
    }
    
    eval {
        my $valid_age = validate_age(25);
        ok($valid_age == 25, 'Valid age validation passes');
    };
    ok(!$@, 'Function with contract validation works correctly');
    
    # Test invalid age to ensure contracts work in functions
    eval {
        validate_age(-5);
    };
    $exception = $@;
    ok($exception, 'Invalid age validation throws exception as expected');
}

# Clean up and exit
done_testing();
exit(0);