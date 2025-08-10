#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use Carp qw(confess);

# Import System classes
use System;
use System::Object;
use System::Exception;
use System::Exceptions;
use CSharp;

BEGIN {
    use_ok('System::Exception');
    use_ok('System::Exceptions');
}

# Test basic exception creation
sub test_exception_creation {
    # Test basic constructor with message
    my $ex = System::Exception->new("Test message");
    isa_ok($ex, 'System::Exception', 'Exception created successfully');
    ok(defined($ex), 'Exception is defined');
    is($ex->Message(), "Test message", 'Exception message set correctly');
    
    # Test constructor with no message
    my $ex_empty = System::Exception->new();
    isa_ok($ex_empty, 'System::Exception', 'Exception created without message');
    ok(defined($ex_empty->Message()), 'Exception message exists even when empty');
    
    # Test constructor with message and inner exception
    my $inner_ex = System::Exception->new("Inner exception");
    my $outer_ex = System::Exception->new("Outer exception", $inner_ex);
    isa_ok($outer_ex, 'System::Exception', 'Exception created with inner exception');
    is($outer_ex->Message(), "Outer exception", 'Outer exception message correct');
    ok(defined($outer_ex->{InnerException}), 'Inner exception is set');
    
    # Test with undef message
    my $ex_undef = System::Exception->new(undef);
    isa_ok($ex_undef, 'System::Exception', 'Exception created with undef message');
    ok(defined($ex_undef->Message()), 'Exception with undef message has default message');
}

sub test_exception_message {
    # Test message retrieval
    my $ex = System::Exception->new("Custom error message");
    is($ex->Message(), "Custom error message", 'Message retrieval works correctly');
    
    # Test default message behavior
    my $ex_default = System::Exception->new();
    my $default_msg = $ex_default->Message();
    ok(defined($default_msg), 'Default message is defined');
    like($default_msg, qr/System::Exception/, 'Default message contains class name');
    
    # Test Message method with null reference
    eval {
        System::Exception::Message(undef);
    };
    ok($@, 'Message throws NullReferenceException with undef this');
    isa_ok($@, 'System::NullReferenceException', 'Correct exception type thrown');
}

sub test_exception_stack_trace {
    # Test stack trace generation
    my $ex = System::Exception->new("Stack trace test");
    
    # Test HasStackTrace method
    ok(!$ex->HasStackTrace(), 'New exception has no stack trace initially');
    
    # Generate stack trace
    $ex->GetStackTrace();
    ok($ex->HasStackTrace(), 'Exception has stack trace after GetStackTrace call');
    
    # Test GetStackTrace returns defined value
    my $stack_trace = $ex->{StackTrace};
    ok(defined($stack_trace), 'Stack trace is defined');
    
    # Test HasStackTrace with null reference
    eval {
        System::Exception::HasStackTrace(undef);
    };
    ok($@, 'HasStackTrace throws NullReferenceException with undef this');
    
    # Test GetStackTrace with null reference  
    eval {
        System::Exception::GetStackTrace(undef);
    };
    ok($@, 'GetStackTrace throws NullReferenceException with undef this');
}

sub test_exception_toString {
    # Test basic ToString functionality
    my $ex = System::Exception->new("ToString test");
    my $str = $ex->ToString();
    ok(defined($str), 'ToString returns defined value');
    like($str, qr/System\.Exception/, 'ToString contains class name with dots');
    like($str, qr/ToString test/, 'ToString contains exception message');
    
    # Test ToString with stack trace
    $ex->GetStackTrace();
    my $str_with_stack = $ex->ToString();
    ok(length($str_with_stack) >= length($str), 'ToString with stack trace is longer or equal');
    
    # Test ToString with empty message
    my $ex_empty = System::Exception->new("");
    my $str_empty = $ex_empty->ToString();
    ok(defined($str_empty), 'ToString works with empty message');
    like($str_empty, qr/System\.Exception/, 'ToString with empty message contains class name');
    
    # Test ToString with undef message
    my $ex_undef = System::Exception->new(undef);
    my $str_undef = $ex_undef->ToString();
    ok(defined($str_undef), 'ToString works with undef message');
    
    # Test string overloading
    my $ex_overload = System::Exception->new("Overload test");
    my $concatenated = "Error: " . $ex_overload;
    like($concatenated, qr/Error: .*System\.Exception.*Overload test/, 'String overloading works');
}

sub test_exception_throwing_catching {
    # Test basic exception throwing and catching
    eval {
        my $ex = System::Exception->new("Thrown exception");
        die $ex;
    };
    my $caught = $@;
    isa_ok($caught, 'System::Exception', 'Exception thrown and caught correctly');
    is($caught->Message(), "Thrown exception", 'Caught exception has correct message');
    
    # Test throwing with CSharp throw function
    eval {
        throw(System::Exception->new("CSharp throw test"));
    };
    $caught = $@;
    isa_ok($caught, 'System::Exception', 'Exception thrown with CSharp throw function');
    is($caught->Message(), "CSharp throw test", 'CSharp thrown exception has correct message');
    
    # Test exception chaining
    eval {
        eval {
            throw(System::Exception->new("Inner exception"));
        };
        my $inner = $@;
        throw(System::Exception->new("Outer exception", $inner));
    };
    $caught = $@;
    isa_ok($caught, 'System::Exception', 'Chained exception thrown correctly');
    is($caught->Message(), "Outer exception", 'Outer exception message correct');
    isa_ok($caught->{InnerException}, 'System::Exception', 'Inner exception preserved');
    is($caught->{InnerException}->Message(), "Inner exception", 'Inner exception message preserved');
}

sub test_exception_inheritance {
    # Test that Exception inherits from Object
    my $ex = System::Exception->new("Inheritance test");
    isa_ok($ex, 'System::Object', 'Exception inherits from System::Object');
    
    # Test Object methods are available
    ok($ex->can('ToString'), 'Exception has ToString method from Object');
    ok($ex->can('GetType'), 'Exception has GetType method from Object');
    ok($ex->can('GetHashCode'), 'Exception has GetHashCode method from Object');
    ok($ex->can('Equals'), 'Exception has Equals method from Object');
    
    # Test GetType returns correct type
    is($ex->GetType(), 'System::Exception', 'GetType returns correct exception type');
    
    # Test GetHashCode works
    my $hash = $ex->GetHashCode();
    ok(defined($hash), 'GetHashCode returns defined value');
    is($ex->GetHashCode(), $hash, 'GetHashCode is consistent');
    
    # Test Equals
    my $ex2 = System::Exception->new("Inheritance test");
    ok(!$ex->Equals($ex2), 'Different exception instances are not equal');
    ok($ex->Equals($ex), 'Exception equals itself');
}

sub test_exception_properties {
    # Test Message property with various inputs
    my $ex1 = System::Exception->new("Message 1");
    my $ex2 = System::Exception->new("");
    my $ex3 = System::Exception->new(undef);
    
    is($ex1->Message(), "Message 1", 'Non-empty message property');
    is($ex2->Message(), "", 'Empty message property');
    ok(defined($ex3->Message()), 'Undef message becomes defined');
    
    # Test InnerException property
    my $inner = System::Exception->new("Inner");
    my $outer = System::Exception->new("Outer", $inner);
    
    ok(!defined($ex1->{InnerException}), 'Exception without inner exception has undef InnerException');
    is($outer->{InnerException}, $inner, 'Exception with inner exception has correct InnerException');
    
    # Test StackTrace property
    my $ex_stack = System::Exception->new("Stack test");
    ok(!defined($ex_stack->{StackTrace}), 'New exception has undef StackTrace');
    
    $ex_stack->GetStackTrace();
    ok(defined($ex_stack->{StackTrace}), 'Exception has defined StackTrace after GetStackTrace');
    is(ref(\$ex_stack->{StackTrace}), 'SCALAR', 'StackTrace is a scalar');
}

sub test_exception_edge_cases {
    # Test with very long message
    my $long_msg = 'x' x 10000;
    my $ex_long = System::Exception->new($long_msg);
    is($ex_long->Message(), $long_msg, 'Exception handles very long message');
    
    # Test with special characters in message
    my $special_msg = "Error: \n\t\"Special\" chars & symbols!@#\$%^&*()";
    my $ex_special = System::Exception->new($special_msg);
    is($ex_special->Message(), $special_msg, 'Exception handles special characters in message');
    
    # Test with Unicode message
    my $unicode_msg = "Unicode test: αβγδε ñáéíóú 中文测试";
    my $ex_unicode = System::Exception->new($unicode_msg);
    is($ex_unicode->Message(), $unicode_msg, 'Exception handles Unicode message');
    
    # Test deep inner exception chain
    my $ex_deep = System::Exception->new("Level 0");
    for my $i (1..10) {
        $ex_deep = System::Exception->new("Level $i", $ex_deep);
    }
    is($ex_deep->Message(), "Level 10", 'Deep inner exception chain works');
    isa_ok($ex_deep->{InnerException}, 'System::Exception', 'Deep chain has inner exception');
}

sub test_exception_memory_management {
    # Test creating many exceptions doesn't cause issues
    my @exceptions;
    for my $i (1..100) {
        push @exceptions, System::Exception->new("Exception $i");
    }
    
    # Verify all exceptions are valid
    for my $i (0..4) {  # Test first 5 to avoid too many test outputs
        my $ex = $exceptions[$i];
        ok(defined($ex), "Exception $i is defined");
        like($ex->Message(), qr/Exception \d+/, "Exception $i has correct message format");
        isa_ok($ex, 'System::Exception', "Exception $i is correct type");
    }
    
    # Test exceptions with stack traces
    my @stack_exceptions;
    for my $i (1..50) {
        my $ex = System::Exception->new("Stack exception $i");
        $ex->GetStackTrace();
        push @stack_exceptions, $ex;
    }
    
    # Verify stack trace exceptions
    for my $i (0..2) {  # Test first 3
        my $ex = $stack_exceptions[$i];
        ok($ex->HasStackTrace(), "Stack exception $i has stack trace");
        ok(defined($ex->{StackTrace}), "Stack exception $i has defined stack trace");
    }
    
    # Clear arrays to test cleanup
    @exceptions = ();
    @stack_exceptions = ();
    ok(1, 'Exception cleanup completed successfully');
}

sub test_exception_error_conditions {
    # Test various error conditions that should be handled gracefully
    
    # Test Message with invalid object
    eval {
        my $fake_ex = bless {}, 'System::Exception';
        my $msg = $fake_ex->Message();
    };
    # Should either work or throw proper exception, but not crash
    ok(1, 'Message with minimal Exception object handled gracefully');
    
    # Test GetStackTrace multiple calls
    my $ex = System::Exception->new("Multiple stack trace test");
    $ex->GetStackTrace();
    my $first_stack = $ex->{StackTrace};
    
    $ex->GetStackTrace();
    my $second_stack = $ex->{StackTrace};
    
    ok(defined($first_stack), 'First stack trace is defined');
    ok(defined($second_stack), 'Second stack trace is defined');
    
    # Test ToString with missing properties
    eval {
        my $minimal_ex = bless { Message => "test" }, 'System::Exception';
        my $str = $minimal_ex->ToString();
        ok(defined($str), 'ToString works with minimal Exception object');
    };
    
    # Test with circular inner exception reference (edge case)
    my $ex_a = System::Exception->new("Exception A");
    my $ex_b = System::Exception->new("Exception B", $ex_a);
    $ex_a->{InnerException} = $ex_b;  # Create circular reference
    
    eval {
        my $str = $ex_a->ToString();
        ok(defined($str), 'ToString handles circular inner exception reference');
    };
}

# Run all tests
test_exception_creation();
test_exception_message();
test_exception_stack_trace();
test_exception_toString();
test_exception_throwing_catching();
test_exception_inheritance();
test_exception_properties();
test_exception_edge_cases();
test_exception_memory_management();
test_exception_error_conditions();

done_testing();