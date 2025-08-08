#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Threading::Tasks::Task;
require System::Threading::Tasks::TaskAwaiter;
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

print "1..60\n"; # Comprehensive Task tests

# Test 1-10: Basic Task construction and properties
my $simple_action = sub { return "Task completed"; };
my $task1 = System::Threading::Tasks::Task->new($simple_action);

test_ok(defined($task1), 'Task construction with action');
test_ok($task1->isa('System::Threading::Tasks::Task'), 'Task isa Task');
test_ok($task1->Status() == System::Threading::Tasks::Task->Created, 'Initial task status is Created');
test_ok(!$task1->IsCompleted(), 'New task is not completed');
test_ok(!$task1->IsCompletedSuccessfully(), 'New task is not completed successfully');
test_ok(!$task1->IsCanceled(), 'New task is not canceled');
test_ok(!$task1->IsFaulted(), 'New task is not faulted');
test_ok($task1->Id() > 0, 'Task has positive ID');

# Test task with state parameter
my $task_with_state = System::Threading::Tasks::Task->new(
  sub { my ($state) = @_; return "Result: $state"; }, 
  "test_state"
);
test_ok(defined($task_with_state), 'Task construction with state parameter');

# Test ToString
my $str = $task1->ToString();
test_ok($str =~ /Task \d+/, 'ToString includes task ID and status');

# Test 11-20: Task execution and lifecycle
$task1->Start();
test_ok($task1->Status() >= System::Threading::Tasks::Task->WaitingToRun, 'Task status after Start');

# Wait for completion
my $wait_result = $task1->Wait(1000); # 1 second timeout
test_ok($wait_result, 'Task completed within timeout');
test_ok($task1->IsCompleted(), 'Task is completed after Wait');
test_ok($task1->IsCompletedSuccessfully(), 'Task completed successfully');

# Check result
my $result = $task1->Result();
test_ok($result eq "Task completed", 'Task returned correct result');

# Test task with state execution
$task_with_state->Start();
$task_with_state->Wait(1000);
my $state_result = $task_with_state->Result();
test_ok($state_result eq "Result: test_state", 'Task with state returned correct result');

# Test 21-30: Task.Run factory method
my $run_task_file = "run_task_test.tmp";
unlink $run_task_file if -f $run_task_file;

my $run_task = System::Threading::Tasks::Task->Run(sub {
  open(my $fh, '>', $run_task_file) or die "Cannot open $run_task_file: $!";
  print $fh "Run task executed\n";
  close($fh);
  return "Run completed";
});

test_ok(defined($run_task), 'Task.Run creates task');
test_ok($run_task->Status() >= System::Threading::Tasks::Task->WaitingToRun, 'Run task is started automatically');

$run_task->Wait(1000);
my $run_executed = -f $run_task_file;
test_ok($run_executed, 'Task.Run executed action');
test_ok($run_task->Result() eq "Run completed", 'Task.Run returned correct result');

# Clean up
unlink $run_task_file if -f $run_task_file;

# Test 31-40: Task.FromResult
my $from_result_task = System::Threading::Tasks::Task->FromResult("Immediate result");
test_ok($from_result_task->IsCompleted(), 'FromResult task is immediately completed');
test_ok($from_result_task->IsCompletedSuccessfully(), 'FromResult task completed successfully');
test_ok($from_result_task->Result() eq "Immediate result", 'FromResult task has correct result');

# Test 41-50: Exception handling
my $faulted_task = System::Threading::Tasks::Task->new(sub {
  die "Test exception in task";
});

$faulted_task->Start();
$faulted_task->Wait(1000);

test_ok($faulted_task->IsCompleted(), 'Faulted task is completed');
test_ok($faulted_task->IsFaulted(), 'Faulted task is faulted');
test_ok(!$faulted_task->IsCompletedSuccessfully(), 'Faulted task is not completed successfully');
test_ok(defined($faulted_task->Exception()), 'Faulted task has exception');

# Test accessing result of faulted task throws exception
test_exception(
  sub { $faulted_task->Result(); },
  'AggregateException',
  'Accessing result of faulted task throws exception'
);

# Test 51-60: Task continuations
my $continuation_file = "continuation_test.tmp";
unlink $continuation_file if -f $continuation_file;

my $base_task = System::Threading::Tasks::Task->new(sub { return "Base result"; });

my $continuation_task = $base_task->ContinueWith(sub {
  my ($antecedent) = @_;
  open(my $fh, '>', $continuation_file) or die "Cannot open $continuation_file: $!";
  print $fh "Continuation executed\n";
  close($fh);
  return "Continuation result";
});

$base_task->Start();
$base_task->Wait(1000);
$continuation_task->Wait(1000);

my $continuation_executed = -f $continuation_file;
test_ok($continuation_executed, 'Continuation task executed');
test_ok($continuation_task->IsCompletedSuccessfully(), 'Continuation task completed successfully');

# Clean up
unlink $continuation_file if -f $continuation_file;

# Test Task.Delay
my $delay_start = time();
my $delay_task = System::Threading::Tasks::Task->Delay(100); # 100ms
$delay_task->Wait(1000);
my $delay_elapsed = (time() - $delay_start) * 1000;

test_ok($delay_task->IsCompletedSuccessfully(), 'Delay task completed successfully');
test_ok($delay_elapsed >= 50, 'Delay task waited approximately correct time'); # Allow some variance

# Test TaskAwaiter
my $awaiter = $base_task->GetAwaiter();
test_ok(defined($awaiter), 'GetAwaiter returns awaiter');
test_ok($awaiter->isa('System::Threading::Tasks::TaskAwaiter'), 'Awaiter is TaskAwaiter');
test_ok($awaiter->IsCompleted(), 'Awaiter shows task is completed');

# Test ConfigureAwait (simplified)
my $configured = $base_task->ConfigureAwait(0);
test_ok(defined($configured), 'ConfigureAwait returns task');

# Test exception cases
test_exception(
  sub { System::Threading::Tasks::Task->new(undef); },
  'ArgumentNullException',
  'Task constructor with null action throws exception'
);

test_exception(
  sub { System::Threading::Tasks::Task->new("not a code ref"); },
  'ArgumentException',
  'Task constructor with non-code action throws exception'
);

test_exception(
  sub { 
    my $t = System::Threading::Tasks::Task->new(sub { return 1; });
    $t->Start();
    $t->Start(); # Try to start again
  },
  'InvalidOperationException',
  'Starting task twice throws InvalidOperationException'
);

test_exception(
  sub { System::Threading::Tasks::Task->Run(undef); },
  'ArgumentNullException',
  'Task.Run with null action throws exception'
);

test_exception(
  sub { System::Threading::Tasks::Task->Delay(-1); },
  'ArgumentOutOfRangeException',
  'Task.Delay with negative delay throws exception'
);

# Test WhenAll (simplified test)
my @when_all_tasks = ();
for my $i (1..3) {
  my $when_all_task = System::Threading::Tasks::Task->new(sub { 
    my ($state) = @_; 
    System::Threading::Thread->Sleep(50);
    return "Task $state completed"; 
  }, $i);
  $when_all_task->Start();
  push @when_all_tasks, $when_all_task;
}

my $when_all_task = System::Threading::Tasks::Task->WhenAll(@when_all_tasks);
$when_all_task->Wait(2000);
test_ok($when_all_task->IsCompletedSuccessfully(), 'WhenAll task completed successfully');

# Test WhenAny
my @when_any_tasks = ();
for my $i (1..3) {
  my $when_any_task = System::Threading::Tasks::Task->new(sub { 
    my ($state) = @_; 
    System::Threading::Thread->Sleep($state * 50); # Different delays
    return "Task $state completed"; 
  }, $i);
  $when_any_task->Start();
  push @when_any_tasks, $when_any_task;
}

my $when_any_task = System::Threading::Tasks::Task->WhenAny(@when_any_tasks);
$when_any_task->Wait(1000);
test_ok($when_any_task->IsCompletedSuccessfully(), 'WhenAny task completed successfully');

# Test GetResult method
my $get_result = $base_task->GetResult();
test_ok($get_result eq "Base result", 'GetResult returns correct value');

print "\n# Task Tests completed: $tests_run\n";
print "# Task Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);