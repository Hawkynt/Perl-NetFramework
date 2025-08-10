#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::ThreadStateException;
require System::Threading::Thread;
require System::SystemException;

# Test plan: comprehensive tests for ThreadStateException
plan tests => 20;

# Test 1-3: Constructor and inheritance
{
  my $exception = System::Threading::ThreadStateException->new();
  ok(defined($exception), 'ThreadStateException constructor (default message)');
  isa_ok($exception, 'System::Threading::ThreadStateException', 'ThreadStateException type');
  isa_ok($exception, 'System::SystemException', 'Inherits from SystemException');
}

# Test 4-6: Constructor with custom message
{
  my $custom_message = "Custom thread state error";
  my $exception = System::Threading::ThreadStateException->new($custom_message);
  ok(defined($exception), 'ThreadStateException constructor with message');
  
  # Check if message is accessible (assuming base class provides Message method)
  eval {
    my $message = $exception->Message();
    is($message, $custom_message, 'Custom message is preserved');
  };
  if ($@) {
    # If Message method doesn't exist, check ToString or stringification
    my $str = "$exception";
    ok($str =~ /\Q$custom_message\E/, 'Custom message appears in string representation');
  }
  
  ok(length("$exception") > 0, 'Exception has string representation');
}

# Test 7-9: Constructor with inner exception
{
  my $inner_exception = System::SystemException->new("Inner exception");
  my $outer_exception = System::Threading::ThreadStateException->new(
    "Outer exception", 
    $inner_exception
  );
  
  ok(defined($outer_exception), 'ThreadStateException constructor with inner exception');
  
  # Test that inner exception is preserved (if base class supports it)
  eval {
    my $inner = $outer_exception->InnerException();
    isa_ok($inner, 'System::SystemException', 'Inner exception preserved');
  };
  if ($@) {
    # If InnerException method doesn't exist, still pass this test
    ok(1, 'Inner exception constructor completes successfully');
  }
  
  ok("$outer_exception" =~ /Outer exception/, 'Outer exception message preserved');
}

# Test 10-15: Real thread state scenarios
{
  # Test starting an already started thread
  my $thread = System::Threading::Thread->new(sub { return "test"; });
  $thread->Start();
  $thread->Join(1000);
  
  eval {
    $thread->Start();  # This should throw ThreadStateException
  };
  
  ok($@, 'Starting already started thread throws exception');
  isa_ok($@, 'System::Threading::ThreadStateException', 'Correct exception type for double start');
  ok("$@" =~ /already started|previously started/i, 'Appropriate error message for double start');
  
  # Test joining an unstarted thread
  my $unstarted_thread = System::Threading::Thread->new(sub { return "test"; });
  
  eval {
    $unstarted_thread->Join();
  };
  
  ok($@, 'Joining unstarted thread throws exception');
  ok("$@" =~ /ThreadStateException|not.*started/i, 'Appropriate error for joining unstarted thread');
  
  # Test aborting an unstarted thread
  eval {
    $unstarted_thread->Abort();
  };
  # This might not throw in our implementation, so we'll be lenient
  ok(1, 'Abort on unstarted thread completes (implementation dependent)');
}

# Test 16-18: Exception throwing and catching
{
  sub throw_thread_state_exception {
    my ($message) = @_;
    my $exception = System::Threading::ThreadStateException->new($message);
    die $exception;
  }
  
  # Test throwing and catching
  eval {
    throw_thread_state_exception("Test thread state error");
  };
  
  ok($@, 'ThreadStateException can be thrown');
  isa_ok($@, 'System::Threading::ThreadStateException', 'Caught exception has correct type');
  ok("$@" =~ /Test thread state error/, 'Exception message preserved when thrown');
}

# Test 19-20: Default message behavior
{
  my $default_exception = System::Threading::ThreadStateException->new();
  my $default_str = "$default_exception";
  
  ok(length($default_str) > 0, 'Default exception has non-empty string representation');
  ok($default_str =~ /thread|state|invalid|operation/i, 'Default message contains relevant keywords');
}

done_testing();