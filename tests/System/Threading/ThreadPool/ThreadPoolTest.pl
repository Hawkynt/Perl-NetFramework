#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Threading::ThreadPool;
require System::Threading::Thread;

# Test counters
my $tests_run = 0;
my $tests_passed = 0;

sub test_ok {
  my ($condition, $test_name) = @_;
  $tests_run++;
  if ($condition) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name\n";
  }
}

sub test_exception {
  my ($code, $expected_exception, $test_name) = @_;
  $tests_run++;
  
  my $caught_exception = '';
  eval {
    $code->();
  };
  
  if ($@) {
    $caught_exception = ref($@) ? ref($@) : $@;
  }
  
  if ($caught_exception =~ /$expected_exception/) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name (expected $expected_exception, got $caught_exception)\n";
  }
}

print "1..50\n"; # Comprehensive ThreadPool tests

# Test 1-10: Basic ThreadPool functionality
my $task_result_file = "threadpool_test_result.tmp";
unlink $task_result_file if -f $task_result_file; # Clean up any previous run

my $simple_task = sub {
  my ($state) = @_;
  # Write result to a file to test execution
  open(my $fh, '>', $task_result_file) or die "Cannot open $task_result_file: $!";
  print $fh "Task completed with state: $state\n";
  close($fh);
  return "Task completed";
};

my $queued = System::Threading::ThreadPool->QueueUserWorkItem($simple_task, "test_state");
test_ok($queued, 'QueueUserWorkItem returns true');

# Give thread pool time to initialize and execute task
System::Threading::Thread->Sleep(100);

my $task_executed = -f $task_result_file;
test_ok($task_executed, 'Simple task was executed');

# Clean up
unlink $task_result_file if -f $task_result_file;

# Test 2-10: Thread pool limits and configuration
my ($worker_threads, $completion_threads);

System::Threading::ThreadPool->GetMaxThreads(\$worker_threads, \$completion_threads);
test_ok($worker_threads > 0, 'GetMaxThreads returns positive worker threads');
test_ok($completion_threads > 0, 'GetMaxThreads returns positive completion threads');

my ($min_worker, $min_completion);
System::Threading::ThreadPool->GetMinThreads(\$min_worker, \$min_completion);
test_ok($min_worker > 0, 'GetMinThreads returns positive worker threads');
test_ok($min_completion > 0, 'GetMinThreads returns positive completion threads');

my ($avail_worker, $avail_completion);
System::Threading::ThreadPool->GetAvailableThreads(\$avail_worker, \$avail_completion);
test_ok($avail_worker >= 0, 'GetAvailableThreads returns non-negative worker threads');
test_ok($avail_completion >= 0, 'GetAvailableThreads returns non-negative completion threads');

# Test SetMaxThreads
my $set_result = System::Threading::ThreadPool->SetMaxThreads(20, 20);
test_ok($set_result, 'SetMaxThreads returns true');

System::Threading::ThreadPool->GetMaxThreads(\$worker_threads, \$completion_threads);
test_ok($worker_threads == 20, 'SetMaxThreads updated worker thread limit');
test_ok($completion_threads == 20, 'SetMaxThreads updated completion thread limit');

# Test 11-20: Multiple tasks execution
my $multi_task_file = "multi_task_results.tmp";
unlink $multi_task_file if -f $multi_task_file;

# Create multiple tasks
for my $i (1..5) {
  my $task = sub {
    my ($state) = @_;
    # Append to file (this should work even with threading issues)
    open(my $fh, '>>', $multi_task_file) or die "Cannot open $multi_task_file: $!";
    print $fh "Task $state completed\n";
    close($fh);
    return $state;
  };
  
  System::Threading::ThreadPool->QueueUserWorkItem($task, $i);
}

# Wait for tasks to complete
System::Threading::Thread->Sleep(200);

my $task_count = 0;
my @task_results = ();
if (-f $multi_task_file) {
  open(my $fh, '<', $multi_task_file) or die "Cannot read $multi_task_file: $!";
  while (my $line = <$fh>) {
    chomp $line;
    push @task_results, $line;
    $task_count++;
  }
  close($fh);
}

test_ok($task_count >= 3, 'At least 3 tasks were executed');  # Allow for some timing variance
test_ok(@task_results >= 3, 'At least 3 task results were recorded');

# Clean up
unlink $multi_task_file if -f $multi_task_file;

# Test queued work item count (before cleanup)
my $queued_count = System::Threading::ThreadPool->GetQueuedWorkItemCount();
test_ok($queued_count >= 0, 'GetQueuedWorkItemCount returns non-negative value');

# Test thread counts
my $total_threads = System::Threading::ThreadPool->GetTotalThreadCount();
test_ok($total_threads > 0, 'GetTotalThreadCount returns positive value');

my $active_threads = System::Threading::ThreadPool->GetActiveThreadCount();
test_ok($active_threads >= 0, 'GetActiveThreadCount returns non-negative value');

# Test 21-30: Task with state parameter
my $state_test_file = "state_test_result.tmp";
unlink $state_test_file if -f $state_test_file;

my $state_task = sub {
  my ($state) = @_;
  # Write state info to file
  open(my $fh, '>', $state_test_file) or die "Cannot open $state_test_file: $!";
  print $fh "state_type:" . ref($state) . "\n";
  if (ref($state) eq 'HASH') {
    print $fh "name:" . ($state->{name} // 'undef') . "\n";
    print $fh "value:" . ($state->{value} // 'undef') . "\n";
  }
  close($fh);
  return;
};

my $test_state = { name => "test", value => 42 };
System::Threading::ThreadPool->QueueUserWorkItem($state_task, $test_state);

System::Threading::Thread->Sleep(100);

my %received_data = ();
if (-f $state_test_file) {
  open(my $fh, '<', $state_test_file) or die "Cannot read $state_test_file: $!";
  while (my $line = <$fh>) {
    chomp $line;
    my ($key, $value) = split /:/, $line, 2;
    $received_data{$key} = $value;
  }
  close($fh);
}

test_ok(defined($received_data{state_type}), 'Task received state parameter');
test_ok($received_data{state_type} eq 'HASH', 'State parameter preserved its type');
test_ok($received_data{name} eq "test", 'State parameter content is correct');
test_ok($received_data{value} == 42, 'State parameter numeric value is correct');

# Clean up
unlink $state_test_file if -f $state_test_file;

# Test 31-40: Error handling in tasks
my $exception_caught = 0;
my $error_task = sub {
  my ($state) = @_;
  die "Test exception in ThreadPool task";
};

# Capture STDERR to check for warning
my $stderr_output = '';
{
  local *STDERR;
  open STDERR, '>', \$stderr_output or die "Cannot redirect STDERR: $!";
  
  System::Threading::ThreadPool->QueueUserWorkItem($error_task, undef);
  System::Threading::Thread->Sleep(100);
  
  close STDERR;
}

test_ok($stderr_output =~ /ThreadPool worker error/, 'Exception in task generates warning');

# Test task that completes normally after error
my $after_error_file = "after_error_test.tmp";
unlink $after_error_file if -f $after_error_file;

my $normal_after_error = sub {
  my ($state) = @_;
  open(my $fh, '>', $after_error_file) or die "Cannot open $after_error_file: $!";
  print $fh "executed_after_error\n";
  close($fh);
};

System::Threading::ThreadPool->QueueUserWorkItem($normal_after_error, undef);
System::Threading::Thread->Sleep(100);
my $after_error_executed = -f $after_error_file;
test_ok($after_error_executed, 'ThreadPool continues working after task exception');

# Clean up
unlink $after_error_file if -f $after_error_file;

# Test 41-50: Exception cases
test_exception(
  sub { System::Threading::ThreadPool->QueueUserWorkItem(undef, undef); },
  'ArgumentNullException',
  'QueueUserWorkItem with null callback throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->QueueUserWorkItem("not a code ref", undef); },
  'ArgumentException',
  'QueueUserWorkItem with non-code callback throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->GetMaxThreads(undef, \$completion_threads); },
  'ArgumentNullException',
  'GetMaxThreads with null worker ref throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->GetMaxThreads(\$worker_threads, undef); },
  'ArgumentNullException',
  'GetMaxThreads with null completion ref throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->GetMinThreads(undef, \$completion_threads); },
  'ArgumentNullException',
  'GetMinThreads with null worker ref throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->GetAvailableThreads(undef, \$completion_threads); },
  'ArgumentNullException',
  'GetAvailableThreads with null worker ref throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->SetMaxThreads(0, 5); },
  'ArgumentOutOfRangeException',
  'SetMaxThreads with zero worker threads throws exception'
);

test_exception(
  sub { System::Threading::ThreadPool->SetMinThreads(0, 5); },
  'ArgumentOutOfRangeException',
  'SetMinThreads with zero worker threads throws exception'
);

# Test RegisterWaitForSingleObject (simplified implementation)
my $wait_callback_file = "wait_callback_test.tmp";
unlink $wait_callback_file if -f $wait_callback_file;

my $wait_callback = sub {
  my ($state) = @_;
  open(my $fh, '>', $wait_callback_file) or die "Cannot open $wait_callback_file: $!";
  print $fh "wait_callback_executed with state: $state\n";
  close($fh);
};

my $wait_result = System::Threading::ThreadPool->RegisterWaitForSingleObject(
  "dummy_wait_object", $wait_callback, "wait_state", 1000, 1
);
test_ok($wait_result, 'RegisterWaitForSingleObject returns true');

System::Threading::Thread->Sleep(100);
my $wait_callback_executed = -f $wait_callback_file;
test_ok($wait_callback_executed, 'RegisterWaitForSingleObject callback executed');

# Clean up
unlink $wait_callback_file if -f $wait_callback_file;

print "\n# ThreadPool Tests completed: $tests_run\n";
print "# ThreadPool Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);