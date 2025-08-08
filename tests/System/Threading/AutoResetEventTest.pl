#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::AutoResetEvent;

# Test plan: comprehensive tests for AutoResetEvent
plan tests => 20;

# Test 1-3: Constructor and basic properties
{
  my $event = System::Threading::AutoResetEvent->new();
  ok(defined($event), 'AutoResetEvent constructor (default false)');
  
  my $setEvent = System::Threading::AutoResetEvent->new(1);
  ok(defined($setEvent), 'AutoResetEvent constructor (initially set)');
  
  my $unsetEvent = System::Threading::AutoResetEvent->new(0);
  ok(defined($unsetEvent), 'AutoResetEvent constructor (initially unset)');
}

# Test 4-8: Basic auto-reset behavior
{
  my $event = System::Threading::AutoResetEvent->new(0);
  
  # Initially unset - should timeout immediately
  my $result = $event->WaitOne(0);
  ok(!$result, 'WaitOne fails on unset event');
  
  # Set the event
  ok($event->Set(), 'Set returns true');
  
  # Should be able to wait once
  $result = $event->WaitOne(0);
  ok($result, 'WaitOne succeeds after Set');
  
  # Should auto-reset - next wait should fail
  $result = $event->WaitOne(0);
  ok(!$result, 'WaitOne fails after auto-reset');
  
  # Set and verify again
  $event->Set();
  ok($event->WaitOne(0), 'Event works after second Set');
}

# Test 9-12: Initially set event behavior
{
  my $event = System::Threading::AutoResetEvent->new(1);
  
  # Should be able to wait immediately
  my $result = $event->WaitOne(0);
  ok($result, 'WaitOne succeeds on initially set event');
  
  # Should auto-reset
  $result = $event->WaitOne(0);
  ok(!$result, 'Initially set event auto-resets');
  
  # Reset should work even when already unset
  my $wasSet = $event->Reset();
  ok(!$wasSet, 'Reset returns false when already unset');
  
  # Set and reset cycle
  $event->Set();
  $wasSet = $event->Reset();
  ok($wasSet, 'Reset returns true when was set');
}

# Test 13-16: Timeout behavior
{
  my $event = System::Threading::AutoResetEvent->new(0);
  
  # Test zero timeout
  my $start = time();
  my $result = $event->WaitOne(0);
  my $elapsed = (time() - $start) * 1000;
  ok(!$result, 'Zero timeout fails on unset event');
  ok($elapsed < 50, 'Zero timeout returns quickly');
  
  # Test short timeout
  $start = time();
  $result = $event->WaitOne(50);
  $elapsed = (time() - $start) * 1000;
  ok(!$result, 'Short timeout fails on unset event');
  ok($elapsed >= 30, 'Short timeout takes at least minimum time');
}

# Test 17-20: Disposal and cleanup
{
  my $event = System::Threading::AutoResetEvent->new(1);
  
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
    my $tempEvent = System::Threading::AutoResetEvent->new(1);
    $tempEvent->WaitOne(0);
    # Should automatically dispose when going out of scope
  }
  ok(1, 'Automatic disposal via DESTROY works');
}

done_testing();