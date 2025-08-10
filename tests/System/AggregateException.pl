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
use System::AggregateException;
use System::Exceptions;
use CSharp;

BEGIN {
    use_ok('System::AggregateException');
    use_ok('System::Exception');
    use_ok('System::Exceptions');
}

# Test basic AggregateException creation
sub test_aggregate_exception_creation {
    # Test basic constructor with no parameters
    my $agg_ex = System::AggregateException->new();
    isa_ok($agg_ex, 'System::AggregateException', 'AggregateException created successfully');
    isa_ok($agg_ex, 'System::Exception', 'AggregateException inherits from Exception');
    isa_ok($agg_ex, 'System::Object', 'AggregateException inherits from Object');
    ok(defined($agg_ex), 'AggregateException is defined');
    
    # Test default message
    like($agg_ex->Message(), qr/One or more errors occurred/, 'AggregateException has default message');
    
    # Test default inner exceptions (empty array)
    my $inner_exceptions = $agg_ex->InnerExceptions();
    isa_ok($inner_exceptions, 'ARRAY', 'InnerExceptions returns array reference');
    is(scalar(@$inner_exceptions), 0, 'Default AggregateException has no inner exceptions');
    
    # Test constructor with empty array
    my $agg_ex_empty = System::AggregateException->new([]);
    isa_ok($agg_ex_empty, 'System::AggregateException', 'AggregateException created with empty array');
    my $empty_inners = $agg_ex_empty->InnerExceptions();
    is(scalar(@$empty_inners), 0, 'AggregateException with empty array has no inner exceptions');
    
    # Test constructor with custom message
    my $agg_ex_msg = System::AggregateException->new([], "Custom aggregate error");
    is($agg_ex_msg->Message(), "Custom aggregate error", 'AggregateException with custom message');
    
    # Test constructor with message as first parameter
    my $agg_ex_msg2 = System::AggregateException->new(undef, "Another custom message");
    is($agg_ex_msg2->Message(), "Another custom message", 'AggregateException with message as second parameter');
}

sub test_aggregate_exception_with_single_exception {
    # Test with single inner exception
    my $inner = System::ArgumentException->new("Invalid argument");
    my $agg_ex = System::AggregateException->new([$inner]);
    
    isa_ok($agg_ex, 'System::AggregateException', 'AggregateException created with single inner exception');
    
    my $inner_exceptions = $agg_ex->InnerExceptions();
    is(scalar(@$inner_exceptions), 1, 'AggregateException has one inner exception');
    is($inner_exceptions->[0], $inner, 'Inner exception is correct');
    isa_ok($inner_exceptions->[0], 'System::ArgumentException', 'Inner exception is ArgumentException');
    
    # Test with custom message and single inner exception
    my $agg_ex_custom = System::AggregateException->new([$inner], "Single error occurred");
    is($agg_ex_custom->Message(), "Single error occurred", 'Custom message with single inner exception');
    is(scalar(@{$agg_ex_custom->InnerExceptions()}), 1, 'Custom message aggregate has one inner exception');
}

sub test_aggregate_exception_with_multiple_exceptions {
    # Test with multiple inner exceptions
    my $inner1 = System::ArgumentException->new("First error");
    my $inner2 = System::InvalidOperationException->new("Second", "Second error");
    my $inner3 = System::NullReferenceException->new("Third error");
    
    my $agg_ex = System::AggregateException->new([$inner1, $inner2, $inner3]);
    isa_ok($agg_ex, 'System::AggregateException', 'AggregateException created with multiple inner exceptions');
    
    my $inner_exceptions = $agg_ex->InnerExceptions();
    is(scalar(@$inner_exceptions), 3, 'AggregateException has three inner exceptions');
    
    # Test each inner exception
    is($inner_exceptions->[0], $inner1, 'First inner exception is correct');
    is($inner_exceptions->[1], $inner2, 'Second inner exception is correct');
    is($inner_exceptions->[2], $inner3, 'Third inner exception is correct');
    
    isa_ok($inner_exceptions->[0], 'System::ArgumentException', 'First inner is ArgumentException');
    isa_ok($inner_exceptions->[1], 'System::InvalidOperationException', 'Second inner is InvalidOperationException');
    isa_ok($inner_exceptions->[2], 'System::NullReferenceException', 'Third inner is NullReferenceException');
    
    # Test messages
    like($inner_exceptions->[0]->Message(), qr/First error/, 'First inner exception has correct message');
    like($inner_exceptions->[1]->Message(), qr/Second error/, 'Second inner exception has correct message');
    like($inner_exceptions->[2]->Message(), qr/Third error/, 'Third inner exception has correct message');
}

sub test_aggregate_exception_with_non_array_input {
    # Test constructor that converts single exception to array
    my $single_ex = System::FormatException->new("Format error");
    my $agg_ex = System::AggregateException->new($single_ex);
    
    isa_ok($agg_ex, 'System::AggregateException', 'AggregateException created with single exception (non-array)');
    
    my $inner_exceptions = $agg_ex->InnerExceptions();
    is(scalar(@$inner_exceptions), 1, 'Single exception converted to array with one element');
    is($inner_exceptions->[0], $single_ex, 'Single exception preserved correctly');
    isa_ok($inner_exceptions->[0], 'System::FormatException', 'Single exception type preserved');
}

sub test_aggregate_exception_get_base_exception {
    # Test GetBaseException with no inner exceptions
    my $agg_ex_empty = System::AggregateException->new([]);
    my $base_empty = $agg_ex_empty->GetBaseException();
    is($base_empty, $agg_ex_empty, 'GetBaseException returns self when no inner exceptions');
    
    # Test GetBaseException with single inner exception
    my $inner = System::IOException->new("IO error");
    my $agg_ex_single = System::AggregateException->new([$inner]);
    my $base_single = $agg_ex_single->GetBaseException();
    is($base_single, $inner, 'GetBaseException returns first inner exception');
    isa_ok($base_single, 'System::IOException', 'Base exception has correct type');
    
    # Test GetBaseException with multiple inner exceptions
    my $inner1 = System::ArgumentException->new("First error");
    my $inner2 = System::InvalidOperationException->new("Second", "Second error");
    my $inner3 = System::NullReferenceException->new("Third error");
    
    my $agg_ex_multiple = System::AggregateException->new([$inner1, $inner2, $inner3]);
    my $base_multiple = $agg_ex_multiple->GetBaseException();
    is($base_multiple, $inner1, 'GetBaseException returns first inner exception from multiple');
    isa_ok($base_multiple, 'System::ArgumentException', 'Base exception from multiple has correct type');
    
    # Test GetBaseException with null reference exception
    eval {
        System::AggregateException::GetBaseException(undef);
    };
    my $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'GetBaseException throws NullReferenceException for undef this');
}

sub test_aggregate_exception_flatten {
    # Test Flatten with simple case (no nested AggregateExceptions)
    my $inner1 = System::ArgumentException->new("Arg error");
    my $inner2 = System::FormatException->new("Format error");
    my $agg_ex = System::AggregateException->new([$inner1, $inner2], "Simple aggregate");
    
    my $flattened = $agg_ex->Flatten();
    isa_ok($flattened, 'System::AggregateException', 'Flatten returns AggregateException');
    isnt($flattened, $agg_ex, 'Flatten returns new instance');
    
    my $flat_inners = $flattened->InnerExceptions();
    is(scalar(@$flat_inners), 2, 'Flattened simple aggregate has same number of exceptions');
    is($flat_inners->[0], $inner1, 'First exception preserved in flatten');
    is($flat_inners->[1], $inner2, 'Second exception preserved in flatten');
    
    # Test Flatten with nested AggregateExceptions
    my $nested_inner1 = System::IOException->new("IO error");
    my $nested_inner2 = System::SecurityException->new("Security error");
    my $nested_agg = System::AggregateException->new([$nested_inner1, $nested_inner2]);
    
    my $outer_inner = System::TimeoutException->new("Timeout error");
    my $complex_agg = System::AggregateException->new([$outer_inner, $nested_agg], "Complex aggregate");
    
    my $complex_flattened = $complex_agg->Flatten();
    my $complex_flat_inners = $complex_flattened->InnerExceptions();
    
    # Should have 3 inner exceptions: outer_inner, nested_inner1, nested_inner2
    is(scalar(@$complex_flat_inners), 3, 'Flattened complex aggregate has correct number of exceptions');
    is($complex_flat_inners->[0], $outer_inner, 'First exception is outer inner');
    is($complex_flat_inners->[1], $nested_inner1, 'Second exception is first nested inner');
    is($complex_flat_inners->[2], $nested_inner2, 'Third exception is second nested inner');
    
    # Test deeply nested AggregateExceptions
    my $deep1 = System::NotSupportedException->new("Deep 1");
    my $deep2 = System::NotImplementedException->new("Deep 2");
    my $deep_agg1 = System::AggregateException->new([$deep1, $deep2]);
    
    my $deep3 = System::ContractException->new("Deep 3");
    my $deep_agg2 = System::AggregateException->new([$deep3, $deep_agg1]);
    
    my $deep_outer = System::ApplicationException->new("Deep outer");
    my $very_deep_agg = System::AggregateException->new([$deep_outer, $deep_agg2]);
    
    my $very_deep_flattened = $very_deep_agg->Flatten();
    my $very_deep_inners = $very_deep_flattened->InnerExceptions();
    
    # Should have 4 inner exceptions: deep_outer, deep3, deep1, deep2
    is(scalar(@$very_deep_inners), 4, 'Very deep flattened aggregate has correct number of exceptions');
    is($very_deep_inners->[0], $deep_outer, 'First exception correct in deep flatten');
    is($very_deep_inners->[1], $deep3, 'Second exception correct in deep flatten');
    is($very_deep_inners->[2], $deep1, 'Third exception correct in deep flatten');
    is($very_deep_inners->[3], $deep2, 'Fourth exception correct in deep flatten');
    
    # Test Flatten with null reference exception
    eval {
        System::AggregateException::Flatten(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'Flatten throws NullReferenceException for undef this');
}

sub test_aggregate_exception_handle {
    # Test Handle method with predicate that handles all exceptions
    my $inner1 = System::ArgumentException->new("Handled arg error");
    my $inner2 = System::FormatException->new("Handled format error");
    my $agg_ex = System::AggregateException->new([$inner1, $inner2]);
    
    my $handled_count = 0;
    my $handle_all = sub {
        my ($exception) = @_;
        $handled_count++;
        return 1; # Handle all exceptions
    };
    
    # Should not throw since all exceptions are handled
    eval {
        $agg_ex->Handle($handle_all);
    };
    ok(!$@, 'Handle with predicate that handles all exceptions does not throw');
    is($handled_count, 2, 'Handle predicate called for each inner exception');
    
    # Test Handle method with predicate that handles some exceptions
    my $inner3 = System::ArgumentException->new("Handled arg error 2");
    my $inner4 = System::IOException->new("Unhandled IO error");
    my $inner5 = System::ArgumentNullException->new("param", "Handled null error");
    my $mixed_agg = System::AggregateException->new([$inner3, $inner4, $inner5]);
    
    $handled_count = 0;
    my $handle_arg_exceptions = sub {
        my ($exception) = @_;
        $handled_count++;
        # Handle ArgumentException and its derived classes
        return $exception->isa('System::ArgumentException') || $exception->isa('System::ArgumentNullException');
    };
    
    # Should throw AggregateException with unhandled exceptions
    eval {
        $mixed_agg->Handle($handle_arg_exceptions);
    };
    my $caught = $@;
    isa_ok($caught, 'System::AggregateException', 'Handle throws AggregateException for unhandled exceptions');
    is($handled_count, 3, 'Handle predicate called for each inner exception in mixed case');
    
    # Check that unhandled exception is in the thrown AggregateException
    my $unhandled_inners = $caught->InnerExceptions();
    is(scalar(@$unhandled_inners), 1, 'Unhandled AggregateException has one inner exception');
    is($unhandled_inners->[0], $inner4, 'Unhandled exception is the IOException');
    
    # Test Handle with predicate that handles no exceptions
    my $handle_none = sub { return 0; };
    
    eval {
        $agg_ex->Handle($handle_none);
    };
    $caught = $@;
    isa_ok($caught, 'System::AggregateException', 'Handle throws AggregateException when no exceptions handled');
    
    my $none_handled_inners = $caught->InnerExceptions();
    is(scalar(@$none_handled_inners), 2, 'All exceptions remain when none handled');
    
    # Test Handle with null predicate
    eval {
        $agg_ex->Handle(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::ArgumentNullException', 'Handle throws ArgumentNullException for undef predicate');
    
    # Test Handle with null reference exception
    eval {
        System::AggregateException::Handle(undef, $handle_all);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'Handle throws NullReferenceException for undef this');
}

sub test_aggregate_exception_toString {
    # Test ToString with no inner exceptions
    my $agg_empty = System::AggregateException->new([]);
    my $str_empty = $agg_empty->ToString();
    ok(defined($str_empty), 'ToString returns defined value for empty aggregate');
    like($str_empty, qr/System\.AggregateException/, 'ToString contains class name');
    like($str_empty, qr/One or more errors occurred/, 'ToString contains default message');
    
    # Test ToString with single inner exception
    my $inner = System::ArgumentException->new("Single inner error");
    my $agg_single = System::AggregateException->new([$inner], "Single aggregate error");
    my $str_single = $agg_single->ToString();
    
    ok(defined($str_single), 'ToString returns defined value for single inner');
    like($str_single, qr/System\.AggregateException/, 'ToString contains AggregateException class name');
    like($str_single, qr/Single aggregate error/, 'ToString contains aggregate message');
    like($str_single, qr/Inner exceptions/, 'ToString mentions inner exceptions');
    like($str_single, qr/Exception 1/, 'ToString shows exception numbering');
    like($str_single, qr/Single inner error/, 'ToString contains inner exception message');
    
    # Test ToString with multiple inner exceptions
    my $inner1 = System::ArgumentException->new("First inner error");
    my $inner2 = System::FormatException->new("Second inner error");
    my $inner3 = System::IOException->new("Third inner error");
    
    my $agg_multiple = System::AggregateException->new([$inner1, $inner2, $inner3], "Multiple errors");
    my $str_multiple = $agg_multiple->ToString();
    
    ok(defined($str_multiple), 'ToString returns defined value for multiple inners');
    like($str_multiple, qr/Multiple errors/, 'ToString contains aggregate message');
    like($str_multiple, qr/Exception 1.*First inner error/, 'ToString shows first exception');
    like($str_multiple, qr/Exception 2.*Second inner error/, 'ToString shows second exception');
    like($str_multiple, qr/Exception 3.*Third inner error/, 'ToString shows third exception');
    
    # Test ToString with null reference exception
    eval {
        System::AggregateException::ToString(undef);
    };
    my $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'ToString throws NullReferenceException for undef this');
}

sub test_aggregate_exception_throwing_and_catching {
    # Test throwing and catching AggregateException
    my $inner1 = System::ArgumentException->new("Thrown arg error");
    my $inner2 = System::InvalidOperationException->new("Thrown", "Thrown op error");
    
    eval {
        my $agg = System::AggregateException->new([$inner1, $inner2], "Thrown aggregate");
        throw($agg);
    };
    
    my $caught = $@;
    isa_ok($caught, 'System::AggregateException', 'AggregateException thrown and caught correctly');
    is($caught->Message(), "Thrown aggregate", 'Caught AggregateException has correct message');
    
    my $caught_inners = $caught->InnerExceptions();
    is(scalar(@$caught_inners), 2, 'Caught AggregateException has correct number of inner exceptions');
    is($caught_inners->[0], $inner1, 'First caught inner exception correct');
    is($caught_inners->[1], $inner2, 'Second caught inner exception correct');
    
    # Test nested AggregateException throwing
    eval {
        eval {
            my $nested_inner = System::TimeoutException->new("Nested timeout");
            my $nested_agg = System::AggregateException->new([$nested_inner], "Nested aggregate");
            throw($nested_agg);
        };
        my $nested_caught = $@;
        
        my $outer_inner = System::SecurityException->new("Outer security");
        my $outer_agg = System::AggregateException->new([$outer_inner, $nested_caught], "Outer aggregate");
        throw($outer_agg);
    };
    
    $caught = $@;
    isa_ok($caught, 'System::AggregateException', 'Nested AggregateException caught');
    
    my $outer_inners = $caught->InnerExceptions();
    is(scalar(@$outer_inners), 2, 'Outer aggregate has two inner exceptions');
    isa_ok($outer_inners->[0], 'System::SecurityException', 'First outer inner is SecurityException');
    isa_ok($outer_inners->[1], 'System::AggregateException', 'Second outer inner is AggregateException');
}

sub test_aggregate_exception_inheritance_and_polymorphism {
    # Test inheritance chain
    my $agg = System::AggregateException->new([]);
    
    isa_ok($agg, 'System::AggregateException', 'AggregateException is AggregateException');
    isa_ok($agg, 'System::Exception', 'AggregateException inherits from Exception');
    isa_ok($agg, 'System::Object', 'AggregateException inherits from Object');
    
    # Test Object methods
    ok($agg->can('ToString'), 'AggregateException has ToString method');
    ok($agg->can('GetType'), 'AggregateException has GetType method');
    ok($agg->can('GetHashCode'), 'AggregateException has GetHashCode method');
    ok($agg->can('Equals'), 'AggregateException has Equals method');
    
    # Test GetType
    is($agg->GetType(), 'System::AggregateException', 'GetType returns correct type');
    
    # Test Exception methods
    ok($agg->can('Message'), 'AggregateException has Message method');
    ok($agg->can('HasStackTrace'), 'AggregateException has HasStackTrace method');
    ok($agg->can('GetStackTrace'), 'AggregateException has GetStackTrace method');
    
    # Test type checking
    ok($agg->Is('System::AggregateException'), 'AggregateException Is AggregateException');
    ok($agg->Is('System::Exception'), 'AggregateException Is Exception');
    ok($agg->Is('System::Object'), 'AggregateException Is Object');
    ok(!$agg->Is('System::ArgumentException'), 'AggregateException is not ArgumentException');
    
    # Test As method
    my $as_agg = $agg->As('System::AggregateException');
    is($as_agg, $agg, 'As AggregateException returns same object');
    
    my $as_ex = $agg->As('System::Exception');
    is($as_ex, $agg, 'As Exception returns same object');
    
    my $as_arg = $agg->As('System::ArgumentException');
    ok(!defined($as_arg), 'As ArgumentException returns undef');
}

sub test_aggregate_exception_edge_cases {
    # Test with very large number of inner exceptions
    my @many_inners = ();
    for my $i (1..100) {
        push @many_inners, System::Exception->new("Exception $i");
    }
    
    my $large_agg = System::AggregateException->new(\@many_inners, "Many exceptions");
    isa_ok($large_agg, 'System::AggregateException', 'AggregateException with many inners created');
    
    my $large_inners = $large_agg->InnerExceptions();
    is(scalar(@$large_inners), 100, 'Large aggregate has correct number of inner exceptions');
    
    # Test first and last to ensure they're preserved
    like($large_inners->[0]->Message(), qr/Exception 1/, 'First exception in large aggregate correct');
    like($large_inners->[99]->Message(), qr/Exception 100/, 'Last exception in large aggregate correct');
    
    # Test flattening large aggregate
    my $large_flattened = $large_agg->Flatten();
    my $large_flat_inners = $large_flattened->InnerExceptions();
    is(scalar(@$large_flat_inners), 100, 'Large flattened aggregate has correct count');
    
    # Test ToString with many exceptions (should not crash)
    my $large_str = $large_agg->ToString();
    ok(defined($large_str), 'ToString works with large aggregate');
    ok(length($large_str) > 0, 'ToString returns non-empty string for large aggregate');
    
    # Test with mixed exception types
    my @mixed_inners = (
        System::ArgumentException->new("Arg"),
        System::IOException->new("IO"),
        System::FormatException->new("Format"),
        System::TimeoutException->new("Timeout"),
        System::SecurityException->new("Security")
    );
    
    my $mixed_agg = System::AggregateException->new(\@mixed_inners, "Mixed types");
    my $mixed_inners_result = $mixed_agg->InnerExceptions();
    
    is(scalar(@$mixed_inners_result), 5, 'Mixed type aggregate has correct count');
    isa_ok($mixed_inners_result->[0], 'System::ArgumentException', 'First mixed inner correct type');
    isa_ok($mixed_inners_result->[1], 'System::IOException', 'Second mixed inner correct type');
    isa_ok($mixed_inners_result->[2], 'System::FormatException', 'Third mixed inner correct type');
    isa_ok($mixed_inners_result->[3], 'System::TimeoutException', 'Fourth mixed inner correct type');
    isa_ok($mixed_inners_result->[4], 'System::SecurityException', 'Fifth mixed inner correct type');
    
    # Test with circular reference in inner exceptions (edge case)
    my $circular1 = System::Exception->new("Circular 1");
    my $circular2 = System::Exception->new("Circular 2");
    
    # Create potential circular reference at object level (not AggregateException level)
    $circular1->{InnerException} = $circular2;
    $circular2->{InnerException} = $circular1;
    
    my $circular_agg = System::AggregateException->new([$circular1, $circular2], "Circular test");
    
    eval {
        my $circular_str = $circular_agg->ToString();
        ok(defined($circular_str), 'ToString handles circular inner exception references');
    };
    
    eval {
        my $circular_flattened = $circular_agg->Flatten();
        ok(defined($circular_flattened), 'Flatten handles circular inner exception references');
    };
}

sub test_aggregate_exception_null_reference_exceptions {
    # Test all methods that should throw NullReferenceException
    my @null_ref_tests = (
        ['InnerExceptions', sub { System::AggregateException::InnerExceptions(undef); }],
        ['GetBaseException', sub { System::AggregateException::GetBaseException(undef); }],
        ['Flatten', sub { System::AggregateException::Flatten(undef); }],
        ['Handle', sub { System::AggregateException::Handle(undef, sub { return 1; }); }],
        ['ToString', sub { System::AggregateException::ToString(undef); }],
    );
    
    for my $test (@null_ref_tests) {
        my ($method_name, $test_sub) = @$test;
        
        eval { $test_sub->(); };
        my $caught = $@;
        isa_ok($caught, 'System::NullReferenceException', "$method_name throws NullReferenceException for undef this");
    }
}

# Run all comprehensive AggregateException tests
test_aggregate_exception_creation();
test_aggregate_exception_with_single_exception();
test_aggregate_exception_with_multiple_exceptions();
test_aggregate_exception_with_non_array_input();
test_aggregate_exception_get_base_exception();
test_aggregate_exception_flatten();
test_aggregate_exception_handle();
test_aggregate_exception_toString();
test_aggregate_exception_throwing_and_catching();
test_aggregate_exception_inheritance_and_polymorphism();
test_aggregate_exception_edge_cases();
test_aggregate_exception_null_reference_exceptions();

done_testing();