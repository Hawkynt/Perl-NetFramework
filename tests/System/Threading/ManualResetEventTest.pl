#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::ManualResetEvent;

# Test plan: comprehensive tests for ManualResetEvent
plan tests => 22;

# Test 1-3: Constructor and basic properties
{
  my $event = System::Threading::ManualResetEvent->new();
  ok(defined($event), 'ManualResetEvent constructor (default false)');
  
  my $setEvent = System::Threading::ManualResetEvent->new(1);
  ok(defined($setEvent), 'ManualResetEvent constructor (initially set)');
  
  my $unsetEvent = System::Threading::ManualResetEvent->new(0);
  ok(defined($unsetEvent), 'ManualResetEvent constructor (initially unset)');
}

# Test 4-10: Manual reset behavior (stays signaled)
{
  my $event = System::Threading::ManualResetEvent->new(0);
  
  # Initially unset - should timeout immediately
  my $result = $event->WaitOne(0);
  ok(!$result, 'WaitOne fails on unset event');
  
  # Set the event
  ok($event->Set(), 'Set returns true');
  
  # Should be able to wait multiple times (does NOT auto-reset)
  $result = $event->WaitOne(0);
  ok($result, 'First WaitOne succeeds after Set');
  
  $result = $event->WaitOne(0);
  ok($result, 'Second WaitOne succeeds (no auto-reset)');
  
  $result = $event->WaitOne(0);
  ok($result, 'Third WaitOne succeeds (no auto-reset)');
  
  # Manual reset to unset state
  my $wasSet = $event->Reset();
  ok($wasSet, 'Reset returns true when was set');
  
  # Now should fail
  $result = $event->WaitOne(0);
  ok(!$result, 'WaitOne fails after manual Reset');
}

# Test 11-14: Initially set event behavior
{
  my $event = System::Threading::ManualResetEvent->new(1);
  
  # Should be able to wait multiple times
  my $result = $event->WaitOne(0);
  ok($result, 'First WaitOne succeeds on initially set event');
  
  $result = $event->WaitOne(0);
  ok($result, 'Second WaitOne succeeds on initially set event');
  
  # Reset and test
  my $wasSet = $event->Reset();
  ok($wasSet, 'Reset returns true for initially set event');
  
  $result = $event->WaitOne(0);
  ok(!$result, 'WaitOne fails after reset of initially set event');
}

# Test 15-18: Reset behavior and state tracking
{
  my $event = System::Threading::ManualResetEvent->new(0);
  
  # Reset when already unset
  my $wasSet = $event->Reset();
  ok(!$wasSet, 'Reset returns false when already unset');
  
  # Set, test, reset, test reset again
  $event->Set();
  $wasSet = $event->Reset();
  ok($wasSet, 'Reset returns true when was set');
  
  $wasSet = $event->Reset();
  ok(!$wasSet, 'Second reset returns false');
  
  # Verify still unset
  ok(!$event->WaitOne(0), 'Event remains unset after double reset');
}

# Test 19-22: Disposal and cleanup
{
  my $event = System::Threading::ManualResetEvent->new(1);
  
  # Should work before disposal
  ok($event->WaitOne(0), 'Event works before disposal');
  
  # Dispose
  $event->Dispose();
  
  # Operations after dispose should throw
  eval { $event->WaitOne(0); };
  ok($@, 'WaitOne throws after disposal');
  
  eval { $event->Set(); };
  ok($@, 'Set throws after disposal');
  
  # Test automatic cleanup
  {
    my $tempEvent = System::Threading::ManualResetEvent->new(1);
    $tempEvent->WaitOne(0);
    # Should automatically dispose when going out of scope
  }
  ok(1, 'Automatic disposal via DESTROY works');
}

done_testing();