#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Exceptions;

BEGIN {
    use_ok('System::Exceptions');
}

sub test_core_exceptions {
    # Test ArgumentNullException
    my $ex = System::ArgumentNullException->new('paramName');
    isa_ok($ex, 'System::ArgumentNullException', 'ArgumentNullException creation');
    like($ex->Message(), qr/paramName/, 'ArgumentNullException includes parameter name');
    
    # Test ArgumentOutOfRangeException
    $ex = System::ArgumentOutOfRangeException->new('value', 42);
    isa_ok($ex, 'System::ArgumentOutOfRangeException', 'ArgumentOutOfRangeException creation');
    like($ex->Message(), qr/value/, 'ArgumentOutOfRangeException includes argument name');
    
    # Test FormatException
    $ex = System::FormatException->new('Invalid format');
    isa_ok($ex, 'System::FormatException', 'FormatException creation');
    like($ex->Message(), qr/Invalid format/, 'FormatException has correct message');
    
    # Test OverflowException
    $ex = System::OverflowException->new();
    isa_ok($ex, 'System::OverflowException', 'OverflowException creation');
    like($ex->Message(), qr/overflow/i, 'OverflowException has default message');
}

sub test_io_exceptions {
    # Test PathTooLongException
    my $ex = System::IO::PathTooLongException->new();
    isa_ok($ex, 'System::IO::PathTooLongException', 'PathTooLongException creation');
    isa_ok($ex, 'System::IOException', 'PathTooLongException inherits from IOException');
    like($ex->Message(), qr/too long/i, 'PathTooLongException has correct message');
    
    # Test EndOfStreamException
    $ex = System::IO::EndOfStreamException->new();
    isa_ok($ex, 'System::IO::EndOfStreamException', 'EndOfStreamException creation');
    isa_ok($ex, 'System::IOException', 'EndOfStreamException inherits from IOException');
    like($ex->Message(), qr/end of.*stream/i, 'EndOfStreamException has correct message');
    
    # Test UnauthorizedAccessException
    $ex = System::UnauthorizedAccessException->new();
    isa_ok($ex, 'System::UnauthorizedAccessException', 'UnauthorizedAccessException creation');
    like($ex->Message(), qr/access.*denied/i, 'UnauthorizedAccessException has correct message');
}

sub test_threading_exceptions {
    # Test ThreadStateException
    my $ex = System::Threading::ThreadStateException->new();
    isa_ok($ex, 'System::Threading::ThreadStateException', 'ThreadStateException creation');
    like($ex->Message(), qr/invalid state/i, 'ThreadStateException has correct message');
    
    # Test ThreadAbortException  
    $ex = System::Threading::ThreadAbortException->new();
    isa_ok($ex, 'System::Threading::ThreadAbortException', 'ThreadAbortException creation');
    like($ex->Message(), qr/aborted/i, 'ThreadAbortException has correct message');
    
    # Test OperationCanceledException
    $ex = System::OperationCanceledException->new();
    isa_ok($ex, 'System::OperationCanceledException', 'OperationCanceledException creation');
    like($ex->Message(), qr/cancelled/i, 'OperationCanceledException has correct message');
}

sub test_aggregate_exception {
    # Test AggregateException with inner exceptions
    my @innerExceptions = (
        System::InvalidOperationException->new('test', 'First error'),
        System::ArgumentNullException->new('param2')
    );
    
    my $aggEx = System::AggregateException->new(\@innerExceptions, 'Multiple errors occurred');
    isa_ok($aggEx, 'System::AggregateException', 'AggregateException creation');
    like($aggEx->Message(), qr/Multiple errors/, 'AggregateException has correct message');
    
    my $innerExs = $aggEx->InnerExceptions();
    is(scalar(@$innerExs), 2, 'AggregateException has correct number of inner exceptions');
    isa_ok($innerExs->[0], 'System::InvalidOperationException', 'First inner exception type');
    isa_ok($innerExs->[1], 'System::ArgumentNullException', 'Second inner exception type');
}

sub test_network_exceptions {
    # Test HttpException
    my $ex = System::Net::HttpException->new('HTTP 404 Not Found', 404);
    isa_ok($ex, 'System::Net::HttpException', 'HttpException creation');
    isa_ok($ex, 'System::Net::NetworkException', 'HttpException inherits from NetworkException');
    like($ex->Message(), qr/404/i, 'HttpException includes status code in message');
    is($ex->{StatusCode}, 404, 'HttpException stores status code');
    
    # Test NetworkException
    $ex = System::Net::NetworkException->new('Network timeout');
    isa_ok($ex, 'System::Net::NetworkException', 'NetworkException creation');
    like($ex->Message(), qr/timeout/i, 'NetworkException has correct message');
}

sub test_other_exceptions {
    # Test TimeoutException
    my $ex = System::TimeoutException->new();
    isa_ok($ex, 'System::TimeoutException', 'TimeoutException creation');
    like($ex->Message(), qr/timed out/i, 'TimeoutException has correct message');
    
    # Test SecurityException
    $ex = System::SecurityException->new('Access denied');
    isa_ok($ex, 'System::SecurityException', 'SecurityException creation');
    like($ex->Message(), qr/Access denied/, 'SecurityException has correct message');
    
    # Test Data::DataException
    $ex = System::Data::DataException->new('Data corruption detected');
    isa_ok($ex, 'System::Data::DataException', 'DataException creation');
    like($ex->Message(), qr/corruption/, 'DataException has correct message');
    
    # Test SerializationException
    $ex = System::Runtime::Serialization::SerializationException->new();
    isa_ok($ex, 'System::Runtime::Serialization::SerializationException', 'SerializationException creation');
    like($ex->Message(), qr/serialization/i, 'SerializationException has correct message');
}

sub test_exception_inheritance {
    # Verify inheritance chains
    ok(System::IO::PathTooLongException->new()->isa('System::IOException'), 'PathTooLongException isa IOException');
    ok(System::IOException->new()->isa('System::Exception'), 'IOException isa Exception');
    ok(System::ArgumentNullException->new()->isa('System::Exception'), 'ArgumentNullException isa Exception');
    ok(System::Net::HttpException->new()->isa('System::Net::NetworkException'), 'HttpException isa NetworkException');
    ok(System::Net::NetworkException->new()->isa('System::Exception'), 'NetworkException isa Exception');
}

# Run all tests
test_core_exceptions();
test_io_exceptions();
test_threading_exceptions();
test_aggregate_exception();
test_network_exceptions();
test_other_exceptions();
test_exception_inheritance();

done_testing();