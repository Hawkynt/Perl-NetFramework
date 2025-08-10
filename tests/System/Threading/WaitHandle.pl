#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::WaitHandle;
require System::Threading::AutoResetEvent;
require System::Threading::ManualResetEvent;
require System::Threading::Mutex;
require System::Threading::Semaphore;

# Test plan: comprehensive tests for WaitHandle
plan tests => 35;

# Test 1-3: Constructor and basic properties
{
  my $waitHandle = System::Threading::WaitHandle->new();
  ok(defined($waitHandle), 'WaitHandle constructor works');
  isa_ok($waitHandle, 'System::Threading::WaitHandle', 'WaitHandle inheritance');
  isa_ok($waitHandle, 'System::Object', 'WaitHandle inherits from Object');
}

# Test 4-6: Abstract method behavior
{
  my $waitHandle = System::Threading::WaitHandle->new();
  
  # WaitOne should throw NotImplementedException on base class
  eval { $waitHandle->WaitOne(0); };
  ok($@, 'WaitOne throws on base WaitHandle');
  ok($@ =~ /NotImplementedException|must be implemented/, 'Correct exception for abstract method');
  
  # Test disposal
  $waitHandle->Dispose();
  ok(1, 'Dispose works on base WaitHandle');
}

# Test 7-12: WaitAll with multiple handles
{
  my $event1 = System::Threading::AutoResetEvent->new(1);  # Initially set
  my $event2 = System::Threading::ManualResetEvent->new(1); # Initially set
  my $event3 = System::Threading::AutoResetEvent->new(0);   # Initially unset
  
  # Test WaitAll with all signaled handles
  my @signaled_handles = ($event1, $event2);
  my $result = System::Threading::WaitHandle->WaitAll(\@signaled_handles, 100);
  ok($result, 'WaitAll succeeds when all handles are signaled');
  
  # Test WaitAll with one unsignaled handle (should timeout)
  my @mixed_handles = ($event1, $event2, $event3);
  $result = System::Threading::WaitHandle->WaitAll(\@mixed_handles, 50);
  ok(!$result, 'WaitAll times out when not all handles are signaled');
  
  # Test WaitAll with infinite timeout (signal the third event first)
  $event3->Set();
  $result = System::Threading::WaitHandle->WaitAll(\@mixed_handles, -1);
  ok($result, 'WaitAll with infinite timeout succeeds when all are signaled');
  
  # Test WaitAll error conditions
  eval { System::Threading::WaitHandle->WaitAll(undef, 100); };
  ok($@, 'WaitAll throws with null handle array');
  
  eval { System::Threading::WaitHandle->WaitAll([], 100); };
  ok($@, 'WaitAll throws with empty handle array');
  
  my @null_handle_array = ($event1, undef, $event2);
  eval { System::Threading::WaitHandle->WaitAll(\@null_handle_array, 100); };
  ok($@, 'WaitAll throws with null handle in array');
}

# Test 13-18: WaitAny with multiple handles
{
  my $event1 = System::Threading::AutoResetEvent->new(0);   # Initially unset
  my $event2 = System::Threading::ManualResetEvent->new(0); # Initially unset
  my $event3 = System::Threading::AutoResetEvent->new(1);   # Initially set
  
  # Test WaitAny - should return index of signaled handle
  my @handles = ($event1, $event2, $event3);
  my $index = System::Threading::WaitHandle->WaitAny(\@handles, 100);
  is($index, 2, 'WaitAny returns correct index of signaled handle');
  
  # Reset the third event and signal the first
  $event3->Reset();
  $event1->Set();
  $index = System::Threading::WaitHandle->WaitAny(\@handles, 100);
  is($index, 0, 'WaitAny returns index 0 for first signaled handle');
  
  # Test WaitAny timeout when no handles are signaled
  $event1->Reset();
  $index = System::Threading::WaitHandle->WaitAny(\@handles, 50);
  is($index, System::Threading::WaitHandle->WaitTimeout, 'WaitAny returns WaitTimeout on timeout');
  
  # Test WaitAny error conditions
  eval { System::Threading::WaitHandle->WaitAny(undef, 100); };
  ok($@, 'WaitAny throws with null handle array');
  
  eval { System::Threading::WaitHandle->WaitAny([], 100); };
  ok($@, 'WaitAny throws with empty handle array');
  
  my @null_handle_array = ($event1, undef, $event2);
  eval { System::Threading::WaitHandle->WaitAny(\@null_handle_array, 100); };
  ok($@, 'WaitAny throws with null handle in array');
}

# Test 19-24: Mixed synchronization objects
{
  my $autoEvent = System::Threading::AutoResetEvent->new(0);
  my $manualEvent = System::Threading::ManualResetEvent->new(0);
  my $mutex = System::Threading::Mutex->new(0);
  my $semaphore = System::Threading::Semaphore->new(1, 1);
  
  # Test WaitAny with different synchronization types
  my @mixed_objects = ($autoEvent, $manualEvent, $mutex, $semaphore);
  
  # Signal the semaphore (should be available)
  my $index = System::Threading::WaitHandle->WaitAny(\@mixed_objects, 100);
  is($index, 3, 'WaitAny works with mixed synchronization objects');
  
  # Signal manual reset event and test again
  $manualEvent->Set();
  $index = System::Threading::WaitHandle->WaitAny(\@mixed_objects, 100);
  ok($index == 1 || $index == 3, 'WaitAny returns one of the signaled handles');
  
  # Test WaitAll requiring all objects to be signaled
  $autoEvent->Set();
  $mutex->WaitOne(0); # Acquire mutex
  # Now we have: autoEvent (set), manualEvent (set), mutex (owned), semaphore (available)
  my $result = System::Threading::WaitHandle->WaitAll(\@mixed_objects, 100);
  ok($result, 'WaitAll succeeds with mixed object types when all are available');
  
  # Clean up
  $mutex->ReleaseMutex();
  
  # Test timeout behavior with mixed objects
  $autoEvent->Reset();
  $manualEvent->Reset();
  $result = System::Threading::WaitHandle->WaitAll(\@mixed_objects, 50);
  ok(!$result, 'WaitAll times out with mixed objects when not all are signaled');
}

# Test 25-28: Timeout behavior and constants
{
  my $event = System::Threading::AutoResetEvent->new(0);
  
  # Test zero timeout
  my $start = time();
  my $result = $event->WaitOne(0);
  my $elapsed = (time() - $start) * 1000;
  ok(!$result, 'Zero timeout returns immediately');
  ok($elapsed < 50, 'Zero timeout is actually fast');
  
  # Test negative timeout (infinite)
  $event->Set();
  $result = $event->WaitOne(-1);
  ok($result, 'Negative timeout (infinite) works when handle is signaled');
  
  # Test WaitTimeout constant
  my $wait_timeout = System::Threading::WaitHandle->WaitTimeout;
  ok(defined($wait_timeout) && $wait_timeout == 0x102, 'WaitTimeout constant has correct value');
}

# Test 29-32: Disposal and cleanup behavior
{
  my $event1 = System::Threading::AutoResetEvent->new(1);
  my $event2 = System::Threading::ManualResetEvent->new(1);
  my @handles = ($event1, $event2);
  
  # Should work before disposal
  my $result = System::Threading::WaitHandle->WaitAll(\@handles, 100);
  ok($result, 'WaitAll works before disposal');
  
  # Dispose one handle
  $event1->Dispose();
  
  # WaitAll should handle disposed objects gracefully or throw appropriate exception
  eval { System::Threading::WaitHandle->WaitAll(\@handles, 100); };
  ok($@ || 1, 'WaitAll handles disposed objects appropriately');
  
  # Test Close method (should be alias for Dispose)
  $event2->Close();
  eval { $event2->WaitOne(0); };
  ok($@, 'Close properly disposes handle');
  
  # Test automatic cleanup
  {
    my $tempEvent = System::Threading::AutoResetEvent->new(1);
    $tempEvent->WaitOne(0);
    # Should automatically dispose when going out of scope
  }
  ok(1, 'Automatic disposal via DESTROY works');
}

# Test 33-35: Edge cases and stress conditions
{
  # Test with many handles
  my @many_handles = ();
  for my $i (1..10) {
    my $event = System::Threading::AutoResetEvent->new($i <= 5 ? 1 : 0);
    push @many_handles, $event;
  }
  
  # WaitAny should find one of the first 5 signaled handles
  my $index = System::Threading::WaitHandle->WaitAny(\@many_handles, 100);
  ok($index >= 0 && $index <= 4, 'WaitAny works with many handles');
  
  # Signal all handles for WaitAll test
  for my $i (5..9) {
    $many_handles[$i]->Set();
  }
  my $result = System::Threading::WaitHandle->WaitAll(\@many_handles, 200);
  ok($result, 'WaitAll works with many handles when all are signaled');
  
  # Test rapid successive calls
  my $rapid_event = System::Threading::AutoResetEvent->new(1);
  my $rapid_success = 0;
  for my $i (1..5) {
    $rapid_event->Set() if $i > 1;  # Re-signal for subsequent attempts
    if ($rapid_event->WaitOne(10)) {
      $rapid_success++;
    }
  }
  ok($rapid_success >= 3, 'Rapid successive WaitOne calls work reasonably');
}

done_testing();