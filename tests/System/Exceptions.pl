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

# Test ArgumentException hierarchy
sub test_argument_exceptions {
    # Test ArgumentException creation and properties
    my $arg_ex = System::ArgumentException->new("Invalid argument");
    isa_ok($arg_ex, 'System::ArgumentException', 'ArgumentException created');
    isa_ok($arg_ex, 'System::Exception', 'ArgumentException inherits from Exception');
    is($arg_ex->Message(), "Invalid argument", 'ArgumentException message correct');
    
    # Test ArgumentException with parameter name
    my $arg_ex_param = System::ArgumentException->new("Invalid value", "paramName");
    isa_ok($arg_ex_param, 'System::ArgumentException', 'ArgumentException with param created');
    like($arg_ex_param->Message(), qr/Invalid value/, 'ArgumentException message contains main message');
    like($arg_ex_param->Message(), qr/paramName/, 'ArgumentException message contains parameter name');
    is($arg_ex_param->{ParamName}, "paramName", 'ArgumentException ParamName property set');
    
    # Test ArgumentException with inner exception
    my $inner = System::Exception->new("Inner error");
    my $arg_ex_inner = System::ArgumentException->new("Argument error", $inner);
    isa_ok($arg_ex_inner, 'System::ArgumentException', 'ArgumentException with inner exception created');
    is($arg_ex_inner->{InnerException}, $inner, 'ArgumentException inner exception set correctly');
    
    # Test ArgumentNullException
    my $null_ex = System::ArgumentNullException->new("paramName");
    isa_ok($null_ex, 'System::ArgumentNullException', 'ArgumentNullException created');
    isa_ok($null_ex, 'System::Exception', 'ArgumentNullException inherits from Exception');
    like($null_ex->Message(), qr/paramName/, 'ArgumentNullException contains parameter name');
    is($null_ex->{ParamName}, "paramName", 'ArgumentNullException ParamName property set');
    
    # Test ArgumentNullException with custom message
    my $null_ex_msg = System::ArgumentNullException->new("param", "Custom null message");
    like($null_ex_msg->Message(), qr/Custom null message/, 'ArgumentNullException custom message');
    like($null_ex_msg->Message(), qr/param/, 'ArgumentNullException parameter name in message');
    
    # Test ArgumentOutOfRangeException
    my $range_ex = System::ArgumentOutOfRangeException->new("index", 5);
    isa_ok($range_ex, 'System::ArgumentOutOfRangeException', 'ArgumentOutOfRangeException created');
    isa_ok($range_ex, 'System::Exception', 'ArgumentOutOfRangeException inherits from Exception');
    like($range_ex->Message(), qr/index/, 'ArgumentOutOfRangeException contains argument name');
    like($range_ex->Message(), qr/5/, 'ArgumentOutOfRangeException contains value');
    is($range_ex->{ArgumentName}, "index", 'ArgumentOutOfRangeException ArgumentName property set');
    is($range_ex->{Value}, 5, 'ArgumentOutOfRangeException Value property set');
}

sub test_file_system_exceptions {
    # Test FileNotFoundException
    my $file_ex = System::FileNotFoundException->new();
    isa_ok($file_ex, 'System::FileNotFoundException', 'FileNotFoundException created');
    isa_ok($file_ex, 'System::Exception', 'FileNotFoundException inherits from Exception');
    ok(defined($file_ex->Message()), 'FileNotFoundException has default message');
    
    # Test FileNotFoundException with filename
    my $file_ex_name = System::FileNotFoundException->new(undef, "test.txt");
    like($file_ex_name->Message(), qr/test\.txt/, 'FileNotFoundException message contains filename');
    is($file_ex_name->{FileName}, "test.txt", 'FileNotFoundException FileName property set');
    
    # Test FileNotFoundException with custom message and filename
    my $file_ex_custom = System::FileNotFoundException->new("File missing", "missing.dat");
    is($file_ex_custom->Message(), "File missing", 'FileNotFoundException custom message');
    is($file_ex_custom->{FileName}, "missing.dat", 'FileNotFoundException custom filename');
    
    # Test DirectoryNotFoundException
    my $dir_ex = System::DirectoryNotFoundException->new();
    isa_ok($dir_ex, 'System::DirectoryNotFoundException', 'DirectoryNotFoundException created');
    isa_ok($dir_ex, 'System::Exception', 'DirectoryNotFoundException inherits from Exception');
    ok(defined($dir_ex->Message()), 'DirectoryNotFoundException has default message');
    
    # Test DirectoryNotFoundException with path
    my $dir_ex_path = System::DirectoryNotFoundException->new(undef, "/nonexistent");
    like($dir_ex_path->Message(), qr/\/nonexistent/, 'DirectoryNotFoundException message contains path');
    is($dir_ex_path->{Path}, "/nonexistent", 'DirectoryNotFoundException Path property set');
    
    # Test IOException
    my $io_ex = System::IOException->new();
    isa_ok($io_ex, 'System::IOException', 'IOException created');
    isa_ok($io_ex, 'System::Exception', 'IOException inherits from Exception');
    like($io_ex->Message(), qr/I\/O error/, 'IOException has default I/O message');
    
    my $io_ex_custom = System::IOException->new("Read failed");
    like($io_ex_custom->Message(), qr/Read failed/, 'IOException custom message');
    is($io_ex_custom->{IOMessage}, "Read failed", 'IOException IOMessage property set');
}

sub test_operation_exceptions {
    # Test InvalidOperationException
    my $invalid_op = System::InvalidOperationException->new("GetNext");
    isa_ok($invalid_op, 'System::InvalidOperationException', 'InvalidOperationException created');
    isa_ok($invalid_op, 'System::Exception', 'InvalidOperationException inherits from Exception');
    like($invalid_op->Message(), qr/GetNext/, 'InvalidOperationException contains operation name');
    is($invalid_op->{OperationName}, "GetNext", 'InvalidOperationException OperationName property set');
    
    # Test InvalidOperationException with description
    my $invalid_op_desc = System::InvalidOperationException->new("Move", "Collection was modified");
    like($invalid_op_desc->Message(), qr/Move/, 'InvalidOperationException with description contains operation');
    like($invalid_op_desc->Message(), qr/Collection was modified/, 'InvalidOperationException with description contains description');
    is($invalid_op_desc->{Description}, "Collection was modified", 'InvalidOperationException Description property set');
    
    # Test NotSupportedException
    my $not_supported = System::NotSupportedException->new("ReadOnly");
    isa_ok($not_supported, 'System::NotSupportedException', 'NotSupportedException created');
    isa_ok($not_supported, 'System::Exception', 'NotSupportedException inherits from Exception');
    like($not_supported->Message(), qr/ReadOnly/, 'NotSupportedException contains operation name');
    is($not_supported->{Name}, "ReadOnly", 'NotSupportedException Name property set');
    
    # Test NotImplementedException
    my $not_impl = System::NotImplementedException->new("NewFeature");
    isa_ok($not_impl, 'System::NotImplementedException', 'NotImplementedException created');
    isa_ok($not_impl, 'System::Exception', 'NotImplementedException inherits from Exception');
    like($not_impl->Message(), qr/NewFeature/, 'NotImplementedException contains feature name');
    is($not_impl->{Name}, "NewFeature", 'NotImplementedException Name property set');
    
    # Test NotImplementedException without name
    my $not_impl_generic = System::NotImplementedException->new();
    isa_ok($not_impl_generic, 'System::NotImplementedException', 'NotImplementedException created without name');
    ok(defined($not_impl_generic->Message()), 'NotImplementedException has default message');
}

sub test_reference_and_bounds_exceptions {
    # Test NullReferenceException
    my $null_ref = System::NullReferenceException->new();
    isa_ok($null_ref, 'System::NullReferenceException', 'NullReferenceException created');
    isa_ok($null_ref, 'System::Exception', 'NullReferenceException inherits from Exception');
    ok(defined($null_ref->Message()), 'NullReferenceException has default message');
    
    # Test NullReferenceException with custom message
    my $null_ref_custom = System::NullReferenceException->new("Object reference not set");
    is($null_ref_custom->Message(), "Object reference not set", 'NullReferenceException custom message');
    
    # Test IndexOutOfBoundsException
    my $index_ex = System::IndexOutOfBoundsException->new(5);
    isa_ok($index_ex, 'System::IndexOutOfBoundsException', 'IndexOutOfBoundsException created');
    isa_ok($index_ex, 'System::Exception', 'IndexOutOfBoundsException inherits from Exception');
    like($index_ex->Message(), qr/5/, 'IndexOutOfBoundsException contains index value');
    is($index_ex->{Index}, 5, 'IndexOutOfBoundsException Index property set');
}

sub test_format_and_cast_exceptions {
    # Test FormatException
    my $format_ex = System::FormatException->new();
    isa_ok($format_ex, 'System::FormatException', 'FormatException created');
    isa_ok($format_ex, 'System::Exception', 'FormatException inherits from Exception');
    like($format_ex->Message(), qr/format/, 'FormatException has default format message');
    
    # Test FormatException with custom message
    my $format_ex_custom = System::FormatException->new("Invalid date format");
    is($format_ex_custom->Message(), "Invalid date format", 'FormatException custom message');
    
    # Test FormatException with inner exception
    my $inner = System::Exception->new("Parse error");
    my $format_ex_inner = System::FormatException->new("Format error", $inner);
    is($format_ex_inner->Message(), "Format error", 'FormatException with inner exception message');
    is($format_ex_inner->{InnerException}, $inner, 'FormatException inner exception set');
    
    # Test OverflowException
    my $overflow_ex = System::OverflowException->new();
    isa_ok($overflow_ex, 'System::OverflowException', 'OverflowException created');
    isa_ok($overflow_ex, 'System::Exception', 'OverflowException inherits from Exception');
    like($overflow_ex->Message(), qr/overflow/, 'OverflowException has default overflow message');
    
    # Test InvalidCastException
    my $cast_ex = System::InvalidCastException->new();
    isa_ok($cast_ex, 'System::InvalidCastException', 'InvalidCastException created');
    isa_ok($cast_ex, 'System::Exception', 'InvalidCastException inherits from Exception');
    like($cast_ex->Message(), qr/cast/, 'InvalidCastException has default cast message');
    
    my $cast_ex_custom = System::InvalidCastException->new("Cannot cast string to integer");
    is($cast_ex_custom->Message(), "Cannot cast string to integer", 'InvalidCastException custom message');
}

sub test_application_and_system_exceptions {
    # Test ApplicationException
    my $app_ex = System::ApplicationException->new();
    isa_ok($app_ex, 'System::ApplicationException', 'ApplicationException created');
    isa_ok($app_ex, 'System::Exception', 'ApplicationException inherits from Exception');
    like($app_ex->Message(), qr/Application/, 'ApplicationException has default application message');
    
    my $app_ex_custom = System::ApplicationException->new("Business logic error");
    is($app_ex_custom->Message(), "Business logic error", 'ApplicationException custom message');
    
    # Test ObjectDisposedException
    my $disposed_ex = System::ObjectDisposedException->new("MyObject");
    isa_ok($disposed_ex, 'System::ObjectDisposedException', 'ObjectDisposedException created');
    isa_ok($disposed_ex, 'System::Exception', 'ObjectDisposedException inherits from Exception');
    like($disposed_ex->Message(), qr/disposed/, 'ObjectDisposedException has default disposed message');
    is($disposed_ex->{ObjectName}, "MyObject", 'ObjectDisposedException ObjectName property set');
    
    # Test TimeoutException
    my $timeout_ex = System::TimeoutException->new();
    isa_ok($timeout_ex, 'System::TimeoutException', 'TimeoutException created');
    isa_ok($timeout_ex, 'System::Exception', 'TimeoutException inherits from Exception');
    like($timeout_ex->Message(), qr/timed out/, 'TimeoutException has default timeout message');
    
    # Test OperationCanceledException
    my $cancel_ex = System::OperationCanceledException->new();
    isa_ok($cancel_ex, 'System::OperationCanceledException', 'OperationCanceledException created');
    isa_ok($cancel_ex, 'System::Exception', 'OperationCanceledException inherits from Exception');
    like($cancel_ex->Message(), qr/cancelled/, 'OperationCanceledException has default cancelled message');
}

sub test_security_and_contract_exceptions {
    # Test SecurityException
    my $security_ex = System::SecurityException->new();
    isa_ok($security_ex, 'System::SecurityException', 'SecurityException created');
    isa_ok($security_ex, 'System::Exception', 'SecurityException inherits from Exception');
    like($security_ex->Message(), qr/Security/, 'SecurityException has default security message');
    
    my $security_ex_custom = System::SecurityException->new("Access denied to resource");
    is($security_ex_custom->Message(), "Access denied to resource", 'SecurityException custom message');
    
    # Test UnauthorizedAccessException
    my $unauth_ex = System::UnauthorizedAccessException->new();
    isa_ok($unauth_ex, 'System::UnauthorizedAccessException', 'UnauthorizedAccessException created');
    isa_ok($unauth_ex, 'System::Exception', 'UnauthorizedAccessException inherits from Exception');
    like($unauth_ex->Message(), qr/denied/, 'UnauthorizedAccessException has default access denied message');
    
    # Test ContractException
    my $contract_ex = System::ContractException->new("Postcondition failed");
    isa_ok($contract_ex, 'System::ContractException', 'ContractException created');
    isa_ok($contract_ex, 'System::Exception', 'ContractException inherits from Exception');
    like($contract_ex->Message(), qr/Postcondition failed/, 'ContractException contains contract message');
}

sub test_specialized_exceptions {
    # Test UriFormatException
    my $uri_ex = System::UriFormatException->new();
    isa_ok($uri_ex, 'System::UriFormatException', 'UriFormatException created');
    isa_ok($uri_ex, 'System::Exception', 'UriFormatException inherits from Exception');
    like($uri_ex->Message(), qr/URI/, 'UriFormatException has default URI message');
    
    # Test SemaphoreFullException
    my $sem_ex = System::SemaphoreFullException->new();
    isa_ok($sem_ex, 'System::SemaphoreFullException', 'SemaphoreFullException created');
    isa_ok($sem_ex, 'System::Exception', 'SemaphoreFullException inherits from Exception');
    like($sem_ex->Message(), qr/semaphore/, 'SemaphoreFullException has default semaphore message');
    
    # Test WaitHandleCannotBeOpenedException
    my $wait_ex = System::WaitHandleCannotBeOpenedException->new();
    isa_ok($wait_ex, 'System::WaitHandleCannotBeOpenedException', 'WaitHandleCannotBeOpenedException created');
    isa_ok($wait_ex, 'System::Exception', 'WaitHandleCannotBeOpenedException inherits from Exception');
    like($wait_ex->Message(), qr/handle/, 'WaitHandleCannotBeOpenedException has default handle message');
}

sub test_namespace_specific_exceptions {
    # Test System::Data::DataException
    my $data_ex = System::Data::DataException->new();
    isa_ok($data_ex, 'System::Data::DataException', 'DataException created');
    isa_ok($data_ex, 'System::Exception', 'DataException inherits from Exception');
    like($data_ex->Message(), qr/data/, 'DataException has default data message');
    
    # Test System::Net::NetworkException
    my $net_ex = System::Net::NetworkException->new();
    isa_ok($net_ex, 'System::Net::NetworkException', 'NetworkException created');
    isa_ok($net_ex, 'System::Exception', 'NetworkException inherits from Exception');
    like($net_ex->Message(), qr/network/, 'NetworkException has default network message');
    
    # Test System::Net::HttpException
    my $http_ex = System::Net::HttpException->new();
    isa_ok($http_ex, 'System::Net::HttpException', 'HttpException created');
    isa_ok($http_ex, 'System::Net::NetworkException', 'HttpException inherits from NetworkException');
    isa_ok($http_ex, 'System::Exception', 'HttpException inherits from Exception');
    like($http_ex->Message(), qr/HTTP/, 'HttpException has default HTTP message');
    
    # Test HttpException with status code
    my $http_ex_status = System::Net::HttpException->new("Not Found", 404);
    is($http_ex_status->Message(), "Not Found", 'HttpException custom message');
    is($http_ex_status->{StatusCode}, 404, 'HttpException StatusCode property set');
    
    # Test System::IO::PathTooLongException
    my $path_ex = System::IO::PathTooLongException->new();
    isa_ok($path_ex, 'System::IO::PathTooLongException', 'PathTooLongException created');
    isa_ok($path_ex, 'System::IOException', 'PathTooLongException inherits from IOException');
    isa_ok($path_ex, 'System::Exception', 'PathTooLongException inherits from Exception');
    like($path_ex->Message(), qr/path/, 'PathTooLongException has default path message');
    
    # Test System::IO::EndOfStreamException
    my $eos_ex = System::IO::EndOfStreamException->new();
    isa_ok($eos_ex, 'System::IO::EndOfStreamException', 'EndOfStreamException created');
    isa_ok($eos_ex, 'System::IOException', 'EndOfStreamException inherits from IOException');
    like($eos_ex->Message(), qr/stream/, 'EndOfStreamException has default stream message');
}

sub test_threading_exceptions {
    # Test System::Threading::ThreadStateException
    my $thread_state_ex = System::Threading::ThreadStateException->new();
    isa_ok($thread_state_ex, 'System::Threading::ThreadStateException', 'ThreadStateException created');
    isa_ok($thread_state_ex, 'System::Exception', 'ThreadStateException inherits from Exception');
    like($thread_state_ex->Message(), qr/Thread/, 'ThreadStateException has default thread message');
    
    # Test System::Threading::ThreadAbortException
    my $thread_abort_ex = System::Threading::ThreadAbortException->new();
    isa_ok($thread_abort_ex, 'System::Threading::ThreadAbortException', 'ThreadAbortException created');
    isa_ok($thread_abort_ex, 'System::Exception', 'ThreadAbortException inherits from Exception');
    like($thread_abort_ex->Message(), qr/abort/, 'ThreadAbortException has default abort message');
}

sub test_reflection_and_serialization_exceptions {
    # Test System::Runtime::Serialization::SerializationException
    my $ser_ex = System::Runtime::Serialization::SerializationException->new();
    isa_ok($ser_ex, 'System::Runtime::Serialization::SerializationException', 'SerializationException created');
    isa_ok($ser_ex, 'System::Exception', 'SerializationException inherits from Exception');
    like($ser_ex->Message(), qr/Serialization/, 'SerializationException has default serialization message');
    
    # Test System::Reflection::TargetException
    my $target_ex = System::Reflection::TargetException->new();
    isa_ok($target_ex, 'System::Reflection::TargetException', 'TargetException created');
    isa_ok($target_ex, 'System::Exception', 'TargetException inherits from Exception');
    like($target_ex->Message(), qr/target/, 'TargetException has default target message');
}

sub test_exception_throwing_and_catching {
    # Test throwing and catching different exception types
    
    # ArgumentException
    eval {
        throw(System::ArgumentException->new("Bad argument", "param1"));
    };
    my $caught = $@;
    isa_ok($caught, 'System::ArgumentException', 'ArgumentException caught correctly');
    like($caught->Message(), qr/Bad argument/, 'Caught ArgumentException has correct message');
    
    # FileNotFoundException
    eval {
        throw(System::FileNotFoundException->new(undef, "missing.txt"));
    };
    $caught = $@;
    isa_ok($caught, 'System::FileNotFoundException', 'FileNotFoundException caught correctly');
    like($caught->Message(), qr/missing\.txt/, 'Caught FileNotFoundException has filename');
    
    # InvalidOperationException
    eval {
        throw(System::InvalidOperationException->new("Clear", "Cannot clear read-only collection"));
    };
    $caught = $@;
    isa_ok($caught, 'System::InvalidOperationException', 'InvalidOperationException caught correctly');
    like($caught->Message(), qr/Clear/, 'Caught InvalidOperationException has operation name');
    like($caught->Message(), qr/read-only/, 'Caught InvalidOperationException has description');
    
    # NullReferenceException
    eval {
        throw(System::NullReferenceException->new("Object reference not set to an instance"));
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'NullReferenceException caught correctly');
    is($caught->Message(), "Object reference not set to an instance", 'NullReferenceException custom message preserved');
}

sub test_exception_hierarchy_comprehensive {
    # Test complete inheritance hierarchy for all exception types
    my @exception_tests = (
        ['System::ArgumentException', ['System::Exception']],
        ['System::ArgumentNullException', ['System::Exception']],
        ['System::ArgumentOutOfRangeException', ['System::Exception']],
        ['System::FileNotFoundException', ['System::Exception']],
        ['System::DirectoryNotFoundException', ['System::Exception']],
        ['System::IOException', ['System::Exception']],
        ['System::InvalidOperationException', ['System::Exception']],
        ['System::NotSupportedException', ['System::Exception']],
        ['System::NotImplementedException', ['System::Exception']],
        ['System::NullReferenceException', ['System::Exception']],
        ['System::IndexOutOfBoundsException', ['System::Exception']],
        ['System::FormatException', ['System::Exception']],
        ['System::OverflowException', ['System::Exception']],
        ['System::InvalidCastException', ['System::Exception']],
        ['System::ApplicationException', ['System::Exception']],
        ['System::Net::HttpException', ['System::Net::NetworkException', 'System::Exception']],
        ['System::IO::PathTooLongException', ['System::IOException', 'System::Exception']],
        ['System::IO::EndOfStreamException', ['System::IOException', 'System::Exception']],
    );
    
    for my $test (@exception_tests) {
        my ($exception_class, $parent_classes) = @$test;
        
        # Create instance and test inheritance
        my $ex = eval { $exception_class->new(); };
        next unless defined $ex;  # Skip if creation fails
        
        isa_ok($ex, $exception_class, "$exception_class creation");
        
        for my $parent (@$parent_classes) {
            isa_ok($ex, $parent, "$exception_class inherits from $parent");
        }
    }
}

sub test_exception_edge_cases {
    # Test edge cases for various exception types
    
    # Test exceptions with empty or undef parameters
    my $arg_ex_empty = System::ArgumentException->new("", "");
    isa_ok($arg_ex_empty, 'System::ArgumentException', 'ArgumentException with empty strings');
    
    my $null_ex_empty = System::ArgumentNullException->new("");
    isa_ok($null_ex_empty, 'System::ArgumentNullException', 'ArgumentNullException with empty parameter name');
    
    # Test exceptions with very long parameters
    my $long_param = 'x' x 1000;
    my $arg_ex_long = System::ArgumentException->new("Long parameter test", $long_param);
    isa_ok($arg_ex_long, 'System::ArgumentException', 'ArgumentException with long parameter name');
    is($arg_ex_long->{ParamName}, $long_param, 'Long parameter name preserved');
    
    # Test numeric parameters
    my $range_ex_negative = System::ArgumentOutOfRangeException->new("index", -5);
    is($range_ex_negative->{Value}, -5, 'ArgumentOutOfRangeException with negative value');
    
    my $range_ex_zero = System::ArgumentOutOfRangeException->new("count", 0);
    is($range_ex_zero->{Value}, 0, 'ArgumentOutOfRangeException with zero value');
    
    # Test special characters in messages and parameters
    my $special_chars = "Special chars: \n\t\"'\\/@#$%^&*()[]{}";
    my $arg_ex_special = System::ArgumentException->new($special_chars, "param");
    is($arg_ex_special->Message() =~ /$special_chars/, 1, 'ArgumentException handles special characters');
}

# Run all comprehensive exception tests
test_argument_exceptions();
test_file_system_exceptions();
test_operation_exceptions();
test_reference_and_bounds_exceptions();
test_format_and_cast_exceptions();
test_application_and_system_exceptions();
test_security_and_contract_exceptions();
test_specialized_exceptions();
test_namespace_specific_exceptions();
test_threading_exceptions();
test_reflection_and_serialization_exceptions();
test_exception_throwing_and_catching();
test_exception_hierarchy_comprehensive();
test_exception_edge_cases();

done_testing();