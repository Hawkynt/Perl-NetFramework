#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 35;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::AsyncCompletedEventArgs;
require System::Exception;
require System::OperationCanceledException;
require System::ArgumentException;
require System::Exceptions;

# Test 1-5: Basic construction and inheritance
{
    my $args = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, undef);
    isa_ok($args, 'System::ComponentModel::AsyncCompletedEventArgs', 'AsyncCompletedEventArgs construction');
    isa_ok($args, 'System::EventArgs', 'AsyncCompletedEventArgs inherits from EventArgs');
    can_ok($args, 'Error');
    can_ok($args, 'Cancelled');
    can_ok($args, 'UserState');
}

# Test 6-10: Construction with different parameter combinations
{
    # Test with no exception, not cancelled, no user state
    my $args1 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, undef);
    ok(!defined($args1->Error()), 'No exception when none provided');
    ok(!$args1->Cancelled(), 'Not cancelled when false provided');
    ok(!defined($args1->UserState()), 'No user state when none provided');
    
    # Test with exception
    my $exception = System::Exception->new('Test exception');
    my $args2 = System::ComponentModel::AsyncCompletedEventArgs->new($exception, false, undef);
    is($args2->Error(), $exception, 'Exception property set correctly');
    
    # Test with cancelled flag
    my $args3 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, true, undef);
    ok($args3->Cancelled(), 'Cancelled property set correctly');
}

# Test 11-15: UserState property handling
{
    # Test with string user state
    my $args1 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, 'string_state');
    is($args1->UserState(), 'string_state', 'String user state preserved');
    
    # Test with numeric user state
    my $args2 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, 42);
    is($args2->UserState(), 42, 'Numeric user state preserved');
    
    # Test with object user state
    my $object_state = { key => 'value', number => 123 };
    my $args3 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, $object_state);
    is_deeply($args3->UserState(), $object_state, 'Object user state preserved');
    
    # Test with array user state
    my $array_state = ['item1', 'item2', 'item3'];
    my $args4 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, $array_state);
    is_deeply($args4->UserState(), $array_state, 'Array user state preserved');
}

# Test 16-20: Error property behavior
{
    # Test with different exception types
    my $arg_exception = System::ArgumentException->new('Argument error');
    my $args1 = System::ComponentModel::AsyncCompletedEventArgs->new($arg_exception, false, undef);
    isa_ok($args1->Error(), 'System::ArgumentException', 'ArgumentException preserved');
    
    my $op_cancel_exception = System::OperationCanceledException->new('Operation cancelled');
    my $args2 = System::ComponentModel::AsyncCompletedEventArgs->new($op_cancel_exception, false, undef);
    isa_ok($args2->Error(), 'System::OperationCanceledException', 'OperationCanceledException preserved');
    
    # Test exception message preservation
    my $custom_exception = System::Exception->new('Custom error message');
    my $args3 = System::ComponentModel::AsyncCompletedEventArgs->new($custom_exception, false, undef);
    # Note: Assuming Exception has a Message method
    # is($args3->Error()->Message(), 'Custom error message', 'Exception message preserved');
}

# Test 21-25: Cancelled property behavior
{
    # Test boolean conversion for cancelled property
    my $args1 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, 1, undef);
    ok($args1->Cancelled(), 'Truthy value converted to true');
    
    my $args2 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, 0, undef);
    ok(!$args2->Cancelled(), 'Zero converted to false');
    
    my $args3 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, 'true', undef);
    ok($args3->Cancelled(), 'String "true" converted to true');
    
    my $args4 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, '', undef);
    ok(!$args4->Cancelled(), 'Empty string converted to false');
    
    my $args5 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, undef, undef);
    ok(!$args5->Cancelled(), 'Undefined value converted to false');
}

# Test 26-30: RaiseExceptionIfNecessary method
{
    # Test no exception raised when no error and not cancelled
    my $args1 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, undef);
    eval {
        $args1->RaiseExceptionIfNecessary();
    };
    ok(!$@, 'No exception raised when operation completed successfully');
    
    # Test OperationCanceledException raised when cancelled
    my $args2 = System::ComponentModel::AsyncCompletedEventArgs->new(undef, true, undef);
    eval {
        $args2->RaiseExceptionIfNecessary();
    };
    like($@, qr/OperationCanceledException/, 'OperationCanceledException raised when cancelled');
    
    # Test original exception raised when error occurred
    my $original_exception = System::ArgumentException->new('Original error');
    my $args3 = System::ComponentModel::AsyncCompletedEventArgs->new($original_exception, false, undef);
    eval {
        $args3->RaiseExceptionIfNecessary();
    };
    isa_ok($@, 'System::ArgumentException', 'Original exception raised when error occurred');
    
    # Test cancelled takes precedence over exception
    my $args4 = System::ComponentModel::AsyncCompletedEventArgs->new($original_exception, true, undef);
    eval {
        $args4->RaiseExceptionIfNecessary();
    };
    like($@, qr/OperationCanceledException/, 'OperationCanceledException takes precedence when both cancelled and error');
}

# Test 31-35: Null reference exceptions and edge cases
{
    # Test null reference exception on undefined object
    eval {
        my $null_args = undef;
        $null_args->Error();
    };
    like($@, qr/NullReferenceException/, 'Error throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->Cancelled();
    };
    like($@, qr/NullReferenceException/, 'Cancelled throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->UserState();
    };
    like($@, qr/NullReferenceException/, 'UserState throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->RaiseExceptionIfNecessary();
    };
    like($@, qr/NullReferenceException/, 'RaiseExceptionIfNecessary throws NullReferenceException on null object');
    
    # Test complex user state scenarios
    my $complex_state = {
        operation_id => 'async_op_123',
        started_at => time(),
        metadata => {
            retry_count => 2,
            timeout => 30
        }
    };
    
    my $complex_args = System::ComponentModel::AsyncCompletedEventArgs->new(undef, false, $complex_state);
    is_deeply($complex_args->UserState(), $complex_state, 'Complex user state preserved correctly');
}

done_testing();