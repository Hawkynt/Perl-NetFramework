#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Threading::Thread;
require System::Threading::ThreadStateException;
require System::TimeSpan;
require System::String;

# Import thread constants - they are defined as constants in the module
use constant Unstarted => 0;
use constant Running => 1;
use constant WaitSleepJoin => 2;
use constant Stopped => 3;
use constant Aborted => 8;
use constant Highest => 4;
use constant AboveNormal => 3;

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

print "1..80\n"; # We'll have approximately 80 tests

# Test 1-10: Basic Thread construction and properties
my $thread = System::Threading::Thread->new(sub { 
  my ($param) = @_;
  return "Hello $param";
});

test_ok(defined($thread), 'Thread construction with CODE reference');
test_ok($thread->isa('System::Threading::Thread'), 'Thread isa Thread');
test_ok($thread->ThreadState() == Unstarted, 'Initial state is Unstarted');
test_ok(!$thread->IsAlive(), 'Thread not alive initially');

# Test Name property
$thread->Name('Test Thread');
test_ok($thread->Name() eq 'Test Thread', 'Thread name setter/getter');

# Test IsBackground property
$thread->IsBackground(1);
test_ok($thread->IsBackground(), 'Thread IsBackground setter/getter true');
$thread->IsBackground(0);
test_ok(!$thread->IsBackground(), 'Thread IsBackground setter/getter false');

# Test Priority property
$thread->Priority(Highest);
test_ok($thread->Priority() == Highest, 'Thread priority setter/getter');

test_ok($thread->ToString() =~ /Test Thread/, 'Thread ToString includes name');

# Test 11-20: Thread construction errors
test_exception(
  sub { System::Threading::Thread->new(undef); },
  'ArgumentNullException',
  'Thread constructor with null throws ArgumentNullException'
);

test_exception(
  sub { System::Threading::Thread->new("not a code ref"); },
  'ArgumentException',
  'Thread constructor with non-CODE throws ArgumentException'
);

test_exception(
  sub { $thread->Priority(-1); },
  'ArgumentOutOfRangeException',
  'Invalid thread priority throws ArgumentOutOfRangeException'
);

test_exception(
  sub { $thread->Priority(10); },
  'ArgumentOutOfRangeException',
  'Invalid high thread priority throws ArgumentOutOfRangeException'
);

# Test 21-35: Basic thread execution
my $executed = 0;
my $param_received = '';
my $simple_thread = System::Threading::Thread->new(sub {
  my ($param) = @_;
  $executed = 1;
  $param_received = $param || '';
  return "execution result";
});

$simple_thread->Start("test parameter");
test_ok($simple_thread->ThreadState() == Running, 'Thread state is Running after Start');

# Give thread time to execute
my $join_result = $simple_thread->Join(5000);  # 5 second timeout
test_ok($join_result, 'Thread joined successfully');
test_ok($executed == 1, 'Thread code was executed');
test_ok($param_received eq 'test parameter', 'Thread received correct parameter');

my $result = $simple_thread->GetResult();
test_ok($result eq 'execution result', 'Thread returned correct result');

# Test multiple starts
test_exception(
  sub { $simple_thread->Start(); },
  'ThreadStateException',
  'Starting already started thread throws ThreadStateException'
);

# Test 36-50: Thread Sleep and static methods
my $sleep_start = time();
System::Threading::Thread->Sleep(100);  # 100ms
my $sleep_duration = (time() - $sleep_start) * 1000;
test_ok($sleep_duration >= 90 && $sleep_duration <= 200, 'Thread.Sleep works approximately correctly');

# Test Sleep with TimeSpan
my $timespan = System::TimeSpan->new(0, 0, 0, 0, 50);  # 50ms
$sleep_start = time();
System::Threading::Thread->Sleep($timespan);
$sleep_duration = (time() - $sleep_start) * 1000;
test_ok($sleep_duration >= 40 && $sleep_duration <= 100, 'Thread.Sleep with TimeSpan works');

# Test CurrentThread
my $current = System::Threading::Thread->CurrentThread();
test_ok(defined($current), 'CurrentThread returns a thread object');
test_ok($current->isa('System::Threading::Thread'), 'CurrentThread returns Thread object');
test_ok($current->Name() eq 'Main Thread', 'CurrentThread has correct name');

# Test Yield
my $yield_result = System::Threading::Thread->Yield();
test_ok($yield_result, 'Thread.Yield returns true');

# Test 51-65: Thread exception handling
my $exception_caught = 0;
my $exception_thread = System::Threading::Thread->new(sub {
  die "Test exception";
});

$exception_thread->Start();
$exception_thread->Join();

test_ok($exception_thread->ThreadState() == Aborted, 'Exception thread state is Aborted');

my $caught_exception = $exception_thread->GetException();
test_ok(defined($caught_exception), 'Thread caught exception');
test_ok($caught_exception =~ /Test exception/, 'Exception message preserved');

# Test 66-80: Advanced thread operations
# Test thread with longer execution
my $counter = 0;
my $long_thread = System::Threading::Thread->new(sub {
  for my $i (1..10) {
    $counter++;
    # Small sleep to ensure thread runs for a bit
    select(undef, undef, undef, 0.01);
  }
  return $counter;
});

$long_thread->Start();
test_ok($long_thread->IsAlive(), 'Long running thread is alive');

$long_thread->Join();
test_ok(!$long_thread->IsAlive(), 'Thread not alive after join');
test_ok($counter == 10, 'Long thread completed all iterations');
test_ok($long_thread->GetResult() == 10, 'Long thread returned correct result');

# Test thread timeout on Join
my $timeout_thread = System::Threading::Thread->new(sub {
  # This should complete quickly
  return "quick result";
});

$timeout_thread->Start();
my $join_with_timeout = $timeout_thread->Join(10000);  # 10 second timeout
test_ok($join_with_timeout, 'Join with timeout succeeded for quick thread');

# Test background thread
my $bg_thread = System::Threading::Thread->new(sub {
  return "background work";
});
$bg_thread->IsBackground(1);
$bg_thread->Start();
$bg_thread->Join();
test_ok($bg_thread->IsBackground(), 'Background thread property maintained');

# Test thread without parameters
my $no_param_thread = System::Threading::Thread->new(sub {
  return "no params";
});
$no_param_thread->Start();
$no_param_thread->Join();
test_ok($no_param_thread->GetResult() eq 'no params', 'Thread without parameters works');

# Test thread abort (if available)
my $abort_thread = System::Threading::Thread->new(sub {
  # Simulate long running task
  for my $i (1..1000) {
    select(undef, undef, undef, 0.001);
  }
  return "should not reach here";
});

$abort_thread->Start();
# Give it a moment to start
select(undef, undef, undef, 0.05);
$abort_thread->Abort();

test_ok($abort_thread->ThreadState() == Aborted, 'Aborted thread has correct state');

# Test thread properties after completion
my $completed_thread = System::Threading::Thread->new(sub { return "done"; });
$completed_thread->Name("Completed Test");
$completed_thread->Priority(AboveNormal);
$completed_thread->Start();
$completed_thread->Join();

test_ok($completed_thread->Name() eq 'Completed Test', 'Thread name preserved after completion');
test_ok($completed_thread->Priority() == AboveNormal, 'Thread priority preserved after completion');
test_ok($completed_thread->ThreadState() == Stopped, 'Completed thread has Stopped state');

# Test null reference exceptions on methods
test_exception(
  sub {
    my $null_thread = undef;
    $null_thread->Start();
  },
  'NullReferenceException',
  'Method call on null thread throws NullReferenceException'
);

# Final validation
test_ok($tests_run > 0, 'At least one test was run');

print "\n# Threading Tests completed: $tests_run\n";
print "# Threading Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);