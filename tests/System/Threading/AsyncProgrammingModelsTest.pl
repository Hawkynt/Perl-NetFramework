#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

# Load required modules for all async patterns
require System::IO::Stream;
require System::Net::WebClient;
require System::Threading::CallbackPatterns;
require System::Threading::Tasks::Task;
require System::Threading::Thread;

# Test plan: comprehensive tests for all four async programming models
plan tests => 24;

# Create a simple test stream (we'll need to create a concrete implementation)
package TestStream;
use base 'System::IO::Stream';

sub new {
  my ($class, $data) = @_;
  my $this = $class->SUPER::new();
  $this->{_data} = $data || '';
  $this->{_position} = 0;
  $this->{_canRead} = 1;
  return $this;
}

sub Read {
  my ($this, $buffer, $offset, $count) = @_;
  my $available = length($this->{_data}) - $this->{_position};
  my $toRead = $count < $available ? $count : $available;
  
  for my $i (0..$toRead-1) {
    $buffer->[$offset + $i] = ord(substr($this->{_data}, $this->{_position} + $i, 1));
  }
  
  $this->{_position} += $toRead;
  return $toRead;
}

sub Write { throw System::NotSupportedException->new('Write not supported'); }
sub Seek { throw System::NotSupportedException->new('Seek not supported'); }
sub SetLength { throw System::NotSupportedException->new('SetLength not supported'); }
sub Flush { }
sub Length { return length($_[0]->{_data}); }
sub Position { 
  my ($this, $value) = @_;
  return defined($value) ? ($this->{_position} = $value) : $this->{_position};
}

package main;

# ============================================================================
# 1. APM (Asynchronous Programming Model) Tests - Begin/End pattern
# ============================================================================

# Test 1-6: APM BeginRead/EndRead pattern
{
  my $testData = "Hello, APM World!";
  my $stream = TestStream->new($testData);
  my @buffer = (0) x 20;
  
  # Test APM BeginRead
  my $asyncResult = $stream->BeginRead(\@buffer, 0, 10, undef, "test_state");
  ok(defined($asyncResult), 'BeginRead returns IAsyncResult');
  ok($asyncResult->isa('System::Threading::AsyncResult'), 'AsyncResult has correct type');
  is($asyncResult->AsyncState(), "test_state", 'AsyncState preserved correctly');
  
  # Wait for completion and get result
  my $bytesRead = $stream->EndRead($asyncResult);
  ok($bytesRead > 0, 'EndRead returns bytes read');
  
  # Verify data was read correctly
  my $readData = pack('C*', @buffer[0..$bytesRead-1]);
  is($readData, substr($testData, 0, $bytesRead), 'APM read data matches expected');
  ok($asyncResult->IsCompleted(), 'AsyncResult marked as completed');
}

# ============================================================================
# 2. EAP (Event-based Asynchronous Pattern) Tests - XAsync/XCompleted events  
# ============================================================================

# Test 7-12: EAP DownloadStringAsync/DownloadStringCompleted pattern
{
  my $webClient = System::Net::WebClient->new();
  ok(defined($webClient), 'WebClient created successfully');
  ok(!$webClient->IsBusy(), 'WebClient initially not busy');
  
  my $downloadCompleted = 0;
  my $progressReported = 0;
  my $downloadResult;
  my $downloadError;
  
  # Set up event handlers
  $webClient->DownloadStringCompleted(sub {
    my ($sender, $args) = @_;
    $downloadCompleted = 1;
    eval {
      $downloadResult = $args->Result();
    };
    $downloadError = $@ if $@;
  });
  
  $webClient->DownloadProgressChanged(sub {
    my ($sender, $args) = @_;
    $progressReported = 1;
  });
  
  # Start async download
  $webClient->DownloadStringAsync("http://example.com", "user_token");
  ok($webClient->IsBusy(), 'WebClient becomes busy after starting async operation');
  
  # Wait for completion (with timeout)
  my $timeout = 50;  # 5 seconds
  while (!$downloadCompleted && $timeout > 0) {
    System::Threading::Thread->Sleep(100);
    $timeout--;
  }
  
  ok($downloadCompleted, 'EAP download completed');
  ok($progressReported, 'EAP progress was reported');
  ok(defined($downloadResult) && !$downloadError, 'EAP download succeeded without error');
}

# ============================================================================
# 3. CB (Callback-Based) Tests - Completion callbacks
# ============================================================================

# Test 13-18: Callback-based async execution
{
  my $callbackExecuted = 0;
  my $callbackResult;
  my $callbackException;
  my $callbackState;
  
  # Define operation that returns a result
  my $operation = sub {
    my ($state) = @_;
    return "Callback result with state: $state";
  };
  
  # Define completion callback
  my $callback = sub {
    my ($result, $exception, $state) = @_;
    $callbackExecuted = 1;
    $callbackResult = $result;
    $callbackException = $exception;
    $callbackState = $state;
  };
  
  # Execute async with callback
  System::Threading::CallbackPatterns->ExecuteAsync($operation, $callback, "test_state");
  
  # Wait for callback execution
  my $timeout = 50;
  while (!$callbackExecuted && $timeout > 0) {
    System::Threading::Thread->Sleep(100);
    $timeout--;
  }
  
  ok($callbackExecuted, 'Callback was executed');
  ok(defined($callbackResult), 'Callback received result');
  ok(!defined($callbackException), 'Callback had no exception');
  is($callbackState, "test_state", 'Callback received correct state');
  like($callbackResult, qr/Callback result with state: test_state/, 'Callback result is correct');
  
  # Test multiple operations in parallel
  my $multiCompleted = 0;
  my @multiResults;
  my @multiExceptions;
  
  my @operations = (
    sub { return "Result 1"; },
    sub { return "Result 2"; }, 
    sub { return "Result 3"; },
  );
  
  System::Threading::CallbackPatterns->ExecuteAllAsync(\@operations, sub {
    my ($results, $exceptions, $state) = @_;
    $multiCompleted = 1;
    @multiResults = @$results;
    @multiExceptions = @$exceptions;
  }, "multi_state");
  
  # Wait for completion
  $timeout = 50;
  while (!$multiCompleted && $timeout > 0) {
    System::Threading::Thread->Sleep(100);
    $timeout--;
  }
  
  ok($multiCompleted, 'Multiple callback operations completed');
}

# ============================================================================  
# 4. TPL (Task Parallel Library) Tests - Task-based async/await
# ============================================================================

# Test 19-24: TPL Task.Run and async patterns
{
  # Test Task.Run
  my $task = System::Threading::Tasks::Task->Run(sub {
    return "Task result";
  });
  
  ok(defined($task), 'Task.Run creates task');
  
  # Wait for completion
  $task->Wait();
  ok($task->IsCompleted(), 'Task completed successfully');
  is($task->Result(), "Task result", 'Task returned correct result');
  
  # Test Task.Delay
  my $start_time = time();
  my $delayTask = System::Threading::Tasks::Task->Delay(200);
  $delayTask->Wait();
  my $elapsed = (time() - $start_time) * 1000;
  
  ok($elapsed >= 150, 'Task.Delay waited appropriate time');  # Allow some tolerance
  
  # Test multiple tasks with WhenAll
  my @tasks = (
    System::Threading::Tasks::Task->Run(sub { return "Task 1"; }),
    System::Threading::Tasks::Task->Run(sub { return "Task 2"; }),
    System::Threading::Tasks::Task->Run(sub { return "Task 3"; }),
  );
  
  my $allTask = System::Threading::Tasks::Task->WhenAll(@tasks);
  $allTask->Wait();
  
  ok($allTask->IsCompleted(), 'WhenAll task completed');
  
  # Verify all individual tasks completed
  my $allCompleted = 1;
  for my $task (@tasks) {
    $allCompleted = 0 unless $task->IsCompleted();
  }
  ok($allCompleted, 'All individual tasks in WhenAll completed');
}

done_testing();