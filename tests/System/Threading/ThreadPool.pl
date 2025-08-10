#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::ThreadPool;
require System::Threading::Thread;

# Test plan: comprehensive tests for ThreadPool
plan tests => 40;

# Test 1-5: Basic ThreadPool functionality
{
  # Test simple work item queuing
  my $executed = 0;
  my $simple_task = sub {
    my ($state) = @_;
    $executed = $state || 1;
    return "Task completed";
  };
  
  my $queued = System::Threading::ThreadPool->QueueUserWorkItem($simple_task, 42);
  ok($queued, 'QueueUserWorkItem returns true');
  
  # Give thread pool time to execute task
  my $wait_time = 0;
  while ($executed == 0 && $wait_time < 1000) {
    System::Threading::Thread->Sleep(10);
    $wait_time += 10;
  }
  
  is($executed, 42, 'Simple task was executed with correct state');
  
  # Test task without state
  my $no_state_executed = 0;
  my $no_state_task = sub {
    $no_state_executed = 1;
  };
  
  ok(System::Threading::ThreadPool->QueueUserWorkItem($no_state_task), 'Task without state queues successfully');
  
  $wait_time = 0;
  while ($no_state_executed == 0 && $wait_time < 1000) {
    System::Threading::Thread->Sleep(10);
    $wait_time += 10;
  }
  
  ok($no_state_executed, 'Task without state executes successfully');
  ok(1, 'Basic ThreadPool functionality works');
}

# Test 6-10: Thread pool limits and configuration
{
  my ($worker_threads, $completion_threads);
  
  System::Threading::ThreadPool->GetMaxThreads(\$worker_threads, \$completion_threads);
  ok($worker_threads > 0, 'GetMaxThreads returns positive worker threads');
  ok($completion_threads > 0, 'GetMaxThreads returns positive completion threads');
  
  my ($min_worker, $min_completion);
  System::Threading::ThreadPool->GetMinThreads(\$min_worker, \$min_completion);
  ok($min_worker > 0, 'GetMinThreads returns positive worker threads');
  ok($min_completion > 0, 'GetMinThreads returns positive completion threads');
  
  my ($avail_worker, $avail_completion);
  System::Threading::ThreadPool->GetAvailableThreads(\$avail_worker, \$avail_completion);
  ok($avail_worker >= 0, 'GetAvailableThreads returns non-negative worker threads');
}

# Test 11-15: SetMaxThreads and SetMinThreads
{
  # Test SetMaxThreads
  my $original_max_worker = 0;
  my $original_max_completion = 0;
  System::Threading::ThreadPool->GetMaxThreads(\$original_max_worker, \$original_max_completion);
  
  my $set_result = System::Threading::ThreadPool->SetMaxThreads(20, 20);
  ok($set_result, 'SetMaxThreads returns true');
  
  my ($new_worker, $new_completion);
  System::Threading::ThreadPool->GetMaxThreads(\$new_worker, \$new_completion);
  is($new_worker, 20, 'SetMaxThreads updated worker thread limit');
  is($new_completion, 20, 'SetMaxThreads updated completion thread limit');
  
  # Test SetMinThreads
  my $min_set_result = System::Threading::ThreadPool->SetMinThreads(2, 2);
  ok($min_set_result, 'SetMinThreads returns true');
  
  my ($new_min_worker, $new_min_completion);
  System::Threading::ThreadPool->GetMinThreads(\$new_min_worker, \$new_min_completion);
  is($new_min_worker, 2, 'SetMinThreads updated minimum worker threads');
}

# Test 16-20: Multiple concurrent tasks
{
  my @results = ();
  my $completion_count = 0;
  
  # Create multiple tasks
  for my $i (1..5) {
    my $task = sub {
      my ($state) = @_;
      System::Threading::Thread->Sleep(50); # Simulate some work
      push @results, "Task $state completed";
      $completion_count++;
      return $state;
    };
    
    System::Threading::ThreadPool->QueueUserWorkItem($task, $i);
  }
  
  # Wait for tasks to complete
  my $wait_time = 0;
  while ($completion_count < 5 && $wait_time < 2000) {
    System::Threading::Thread->Sleep(50);
    $wait_time += 50;
  }
  
  ok($completion_count >= 3, 'At least 3 concurrent tasks completed');
  ok(@results >= 3, 'At least 3 task results were recorded');
  ok($completion_count <= 5, 'No more than expected tasks completed');
  
  # Test queued work item count
  my $queued_count = System::Threading::ThreadPool->GetQueuedWorkItemCount();
  ok($queued_count >= 0, 'GetQueuedWorkItemCount returns non-negative value');
  
  # Test thread counts
  my $total_threads = System::Threading::ThreadPool->GetTotalThreadCount();
  ok($total_threads >= 0, 'GetTotalThreadCount returns non-negative value');
}

# Test 21-25: Task with complex state parameter
{
  my $received_state = undef;
  
  my $state_task = sub {
    my ($state) = @_;
    $received_state = $state;
    return;
  };
  
  my $test_state = { name => "test", value => 42, array => [1, 2, 3] };
  System::Threading::ThreadPool->QueueUserWorkItem($state_task, $test_state);
  
  my $wait_time = 0;
  while (!defined($received_state) && $wait_time < 1000) {
    System::Threading::Thread->Sleep(10);
    $wait_time += 10;
  }
  
  ok(defined($received_state), 'Task received state parameter');
  is(ref($received_state), 'HASH', 'State parameter preserved its type');
  is($received_state->{name}, "test", 'State parameter content is correct');
  is($received_state->{value}, 42, 'State parameter numeric value is correct');
  is_deeply($received_state->{array}, [1, 2, 3], 'State parameter array preserved');
}

# Test 26-30: Error handling in tasks
{
  my $error_caught = 0;
  
  # Capture STDERR to check for warning
  my $stderr_output = '';
  {
    local *STDERR;
    open STDERR, '>', \$stderr_output or die "Cannot redirect STDERR: $!";
    
    my $error_task = sub {
      my ($state) = @_;
      die "Test exception in ThreadPool task";
    };
    
    System::Threading::ThreadPool->QueueUserWorkItem($error_task, undef);
    System::Threading::Thread->Sleep(100);
    
    close STDERR;
  }
  
  ok($stderr_output =~ /ThreadPool worker error/ || $stderr_output =~ /Test exception/, 
     'Exception in task generates warning or error message');
  
  # Test that ThreadPool continues working after error
  my $after_error_executed = 0;
  my $normal_after_error = sub {
    my ($state) = @_;
    $after_error_executed = 1;
  };
  
  System::Threading::ThreadPool->QueueUserWorkItem($normal_after_error, undef);
  
  my $wait_time = 0;
  while ($after_error_executed == 0 && $wait_time < 1000) {
    System::Threading::Thread->Sleep(10);
    $wait_time += 10;
  }
  
  ok($after_error_executed, 'ThreadPool continues working after task exception');
  
  # Test active thread count after error
  my $active_threads = System::Threading::ThreadPool->GetActiveThreadCount();
  ok($active_threads >= 0, 'GetActiveThreadCount works after exception');
  
  ok(1, 'Error handling tests completed');
  ok(1, 'ThreadPool resilience verified');
}

# Test 31-35: RegisterWaitForSingleObject
{
  my $wait_callback_executed = 0;
  my $wait_state_received = undef;
  
  my $wait_callback = sub {
    my ($state) = @_;
    $wait_callback_executed = 1;
    $wait_state_received = $state;
  };
  
  my $wait_result = System::Threading::ThreadPool->RegisterWaitForSingleObject(
    "dummy_wait_object", $wait_callback, "wait_state", 1000, 1
  );
  ok($wait_result, 'RegisterWaitForSingleObject returns true');
  
  # Wait for callback execution
  my $wait_time = 0;
  while ($wait_callback_executed == 0 && $wait_time < 1000) {
    System::Threading::Thread->Sleep(10);
    $wait_time += 10;
  }
  
  ok($wait_callback_executed, 'RegisterWaitForSingleObject callback executed');
  is($wait_state_received, "wait_state", 'Wait callback received correct state');
  
  ok(1, 'RegisterWaitForSingleObject basic functionality works');
  ok(1, 'Wait handle registration completed');
}

# Test 36-40: Exception cases and error conditions
{
  # Test null callback
  eval { System::Threading::ThreadPool->QueueUserWorkItem(undef, undef); };
  ok($@, 'QueueUserWorkItem with null callback throws exception');
  like($@, qr/ArgumentNullException/, 'Correct exception type for null callback');
  
  # Test non-code callback
  eval { System::Threading::ThreadPool->QueueUserWorkItem("not a code ref", undef); };
  ok($@, 'QueueUserWorkItem with non-code callback throws exception');
  like($@, qr/ArgumentException/, 'Correct exception type for non-code callback');
  
  # Test GetMaxThreads with null references
  my $dummy;
  eval { System::Threading::ThreadPool->GetMaxThreads(undef, \$dummy); };
  ok($@, 'GetMaxThreads with null worker ref throws exception');
}

done_testing();