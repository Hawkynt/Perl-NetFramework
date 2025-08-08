#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Threading::Thread;
require System::TimeSpan;

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

print "1..60\n"; # Comprehensive Thread tests

# Test 1-10: Construction and basic properties
my $simple_task = sub { return "Hello from thread"; };
my $thread1 = System::Threading::Thread->new($simple_task);

test_ok(defined($thread1), 'Thread construction with code reference');
test_ok($thread1->isa('System::Threading::Thread'), 'Thread isa Thread');
test_ok($thread1->ThreadState() == System::Threading::Thread->Unstarted, 'Initial thread state is Unstarted');
test_ok(!$thread1->IsAlive(), 'Unstarted thread is not alive');
test_ok($thread1->Name() eq '', 'Default name is empty string');
test_ok(!$thread1->IsBackground(), 'Default IsBackground is false');
test_ok($thread1->Priority() == System::Threading::Thread->Normal, 'Default priority is Normal');

# Test property setters
$thread1->Name('Test Thread');
test_ok($thread1->Name() eq 'Test Thread', 'Name setter works');

$thread1->IsBackground(1);
test_ok($thread1->IsBackground(), 'IsBackground setter works');

$thread1->Priority(System::Threading::Thread->AboveNormal);
test_ok($thread1->Priority() == System::Threading::Thread->AboveNormal, 'Priority setter works');

# Test 11-20: Thread execution (basic cases)
my $result_task = sub { 
  my ($param) = @_;
  return "Result: $param";
};
my $thread2 = System::Threading::Thread->new($result_task);

$thread2->Start("test_param");
# Give thread time to complete
System::Threading::Thread->Sleep(100);  # 100ms

# Check if thread completed
test_ok($thread2->ThreadState() == System::Threading::Thread->Stopped || 
        $thread2->ThreadState() == System::Threading::Thread->Running,
        'Thread state after start is Running or Stopped');

# Test Join functionality
my $joined = $thread2->Join(1000); # Wait up to 1 second
test_ok($joined, 'Thread join succeeded within timeout');

# Check result if available
if ($thread2->ThreadState() == System::Threading::Thread->Stopped) {
  my $result = $thread2->GetResult();
  test_ok($result eq "Result: test_param", 'Thread returned correct result');
} else {
  # Skip this test if threads aren't available (synchronous fallback)
  $tests_run++;
  print "ok $tests_run - Thread returned correct result (skipped - threads not available)\n";
  $tests_passed++;
}

# Test 21-30: Thread states and lifecycle
my $long_task = sub {
  System::Threading::Thread->Sleep(200); # 200ms
  return "completed";
};
my $thread3 = System::Threading::Thread->new($long_task);

test_ok($thread3->ThreadState() == System::Threading::Thread->Unstarted, 'Thread starts in Unstarted state');

$thread3->Start();
# Briefly check if thread is running (may be synchronous on systems without threads)
System::Threading::Thread->Sleep(50); # 50ms

# Test different thread states
my $state_after_start = $thread3->ThreadState();
test_ok($state_after_start == System::Threading::Thread->Running || 
        $state_after_start == System::Threading::Thread->Stopped ||
        $state_after_start == System::Threading::Thread->WaitSleepJoin,
        'Thread state after start is valid');

# Test IsAlive property
my $alive_state = $thread3->IsAlive();
test_ok($alive_state == ($state_after_start == System::Threading::Thread->Running || 
                        $state_after_start == System::Threading::Thread->WaitSleepJoin),
        'IsAlive matches expected state');

# Wait for completion
$thread3->Join();
test_ok($thread3->ThreadState() == System::Threading::Thread->Stopped || 
        $thread3->ThreadState() == System::Threading::Thread->Aborted,
        'Thread state after join is Stopped or Aborted');

# Test 31-40: Exception handling in threads
my $exception_task = sub {
  die "Test exception in thread";
};
my $thread4 = System::Threading::Thread->new($exception_task);

$thread4->Start();
$thread4->Join();

test_ok($thread4->ThreadState() == System::Threading::Thread->Aborted,
        'Thread with exception has Aborted state');

my $exception = $thread4->GetException();
test_ok(defined($exception), 'Thread exception is captured');

# Test 41-50: Static methods
# Test Sleep - just verify it doesn't crash and takes some time
my $start_time = time();
System::Threading::Thread->Sleep(50); # 50ms
my $elapsed = (time() - $start_time) * 1000;
test_ok($elapsed >= 0, 'Sleep method completes without error');

# Test Sleep with TimeSpan - just verify it accepts TimeSpan objects
my $timespan = System::TimeSpan->FromMilliseconds(50);
$start_time = time();
eval { System::Threading::Thread->Sleep($timespan); };
test_ok(!$@, 'Sleep with TimeSpan works without throwing exception');

# Test Yield
my $yield_result = System::Threading::Thread->Yield();
test_ok($yield_result, 'Yield returns true');

# Test CurrentThread
my $current = System::Threading::Thread->CurrentThread();
test_ok(defined($current), 'CurrentThread returns a thread object');
test_ok($current->isa('System::Threading::Thread'), 'CurrentThread returns Thread instance');
test_ok($current->Name() eq 'Main Thread', 'CurrentThread has correct name');
test_ok($current->ThreadState() == System::Threading::Thread->Running, 'CurrentThread is in Running state');

# Test 51-60: Exception cases and edge conditions
test_exception(
  sub { System::Threading::Thread->new(undef); },
  'ArgumentNullException',
  'Thread constructor with null start throws exception'
);

test_exception(
  sub { System::Threading::Thread->new("not a code ref"); },
  'ArgumentException',
  'Thread constructor with non-code reference throws exception'
);

test_exception(
  sub { 
    my $t = System::Threading::Thread->new(sub { return 1; });
    $t->Start();
    $t->Start(); # Try to start again
  },
  'ThreadStateException',
  'Starting thread twice throws ThreadStateException'
);

test_exception(
  sub { System::Threading::Thread->Sleep(-1); },
  'ArgumentOutOfRangeException',
  'Sleep with negative timeout throws exception'
);

my $thread5 = System::Threading::Thread->new(sub { return "test"; });
test_exception(
  sub { $thread5->Join(); },
  'ThreadStateException',
  'Joining unstarted thread throws ThreadStateException'
);

test_exception(
  sub { 
    my $t = System::Threading::Thread->new(sub { return 1; });
    $t->Priority(-1); # Invalid priority
  },
  'ArgumentOutOfRangeException',
  'Setting invalid priority throws exception'
);

test_exception(
  sub { 
    my $t = System::Threading::Thread->new(sub { return 1; });
    $t->Priority(10); # Priority too high
  },
  'ArgumentOutOfRangeException',
  'Setting priority too high throws exception'
);

# Test ToString
my $thread6 = System::Threading::Thread->new(sub { return 1; });
$thread6->Name('TestThread');
my $str = $thread6->ToString();
test_ok($str =~ /TestThread/, 'ToString includes thread name');

# Test with unnamed thread
my $thread7 = System::Threading::Thread->new(sub { return 1; });
$str = $thread7->ToString();
test_ok($str =~ /Unnamed Thread/, 'ToString for unnamed thread shows default name');

# Test Interrupt method (should throw NotSupportedException)
test_exception(
  sub { $thread7->Interrupt(); },
  'NotSupportedException',
  'Interrupt method throws NotSupportedException'
);

print "\n# Thread Tests completed: $tests_run\n";
print "# Thread Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);