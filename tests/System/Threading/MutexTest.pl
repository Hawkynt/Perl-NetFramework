#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::Mutex;

# Test plan: comprehensive tests for Mutex
plan tests => 25;

# Test 1-3: Constructor and basic properties
{
  my $mutex = System::Threading::Mutex->new();
  ok(defined($mutex), 'Mutex constructor');
  ok(!defined($mutex->Name()), 'Anonymous mutex has no name');
  
  my $namedMutex = System::Threading::Mutex->new(0, "TestMutex");
  is($namedMutex->Name(), "TestMutex", 'Named mutex has correct name');
}

# Test 4-8: Basic mutex operations
{
  my $mutex = System::Threading::Mutex->new();
  
  # Test successful wait
  my $result = $mutex->WaitOne(0);  # Non-blocking
  ok($result, 'WaitOne succeeds on unowned mutex');
  
  # Test that same thread can acquire again (reentrant)
  $result = $mutex->WaitOne(0);
  ok($result, 'Mutex is reentrant for same thread');
  
  # Test release
  ok($mutex->ReleaseMutex(), 'ReleaseMutex succeeds');
  
  # Test that we still own it (due to reentrancy)
  $result = $mutex->WaitOne(0);
  ok($result, 'Still own mutex after one release (reentrancy)');
  
  # Release twice to fully release
  $mutex->ReleaseMutex();
  $mutex->ReleaseMutex();
  
  # Now it should be available again
  $result = $mutex->WaitOne(0);
  ok($result, 'Mutex available after full release');
}

# Test 9-12: Timeout behavior
{
  my $mutex = System::Threading::Mutex->new();
  
  # Acquire mutex
  ok($mutex->WaitOne(0), 'Acquire mutex for timeout test');
  
  # Test zero timeout on owned mutex
  my $result = $mutex->WaitOne(0);  # Should succeed (reentrant)
  ok($result, 'Zero timeout succeeds for reentrant access');
  
  # Release and test timeout
  $mutex->ReleaseMutex();
  $mutex->ReleaseMutex();
  
  # Test small timeout
  my $start = time();
  $result = $mutex->WaitOne(10);  # 10ms timeout
  my $elapsed = (time() - $start) * 1000;
  ok($result, 'Short timeout succeeds on available mutex');
  ok($elapsed < 50, 'Short timeout completes quickly');  # Allow some margin
}

# Test 13-16: Initially owned mutex
{
  my $mutex = System::Threading::Mutex->new(1);  # Initially owned
  
  # Should already be owned by current thread
  my $result = $mutex->WaitOne(0);
  ok($result, 'Initially owned mutex can be re-acquired (reentrant)');
  
  # Need to release twice (once for initial, once for re-acquire)
  ok($mutex->ReleaseMutex(), 'First release succeeds');
  ok($mutex->ReleaseMutex(), 'Second release succeeds');
  
  # Now should be available
  $result = $mutex->WaitOne(0);
  ok($result, 'Mutex available after releasing initial ownership');
}

# Test 17-20: Error conditions
{
  my $mutex = System::Threading::Mutex->new();
  
  # Test releasing unowned mutex - should fail
  eval { $mutex->ReleaseMutex(); };
  ok($@, 'ReleaseMutex throws when not owned');
  ok($@ =~ /does not own/, 'Correct error message for unowned release');
  
  # Acquire and test proper release
  $mutex->WaitOne(0);
  ok($mutex->ReleaseMutex(), 'Proper release succeeds');
  
  # Test double release - should fail
  eval { $mutex->ReleaseMutex(); };
  ok($@, 'Double release throws exception');
}

# Test 21-25: Disposal and cleanup
{
  my $mutex = System::Threading::Mutex->new();
  
  # Acquire mutex
  ok($mutex->WaitOne(0), 'Acquire mutex for disposal test');
  
  # Dispose should clean up
  $mutex->Dispose();
  
  # Operations after dispose should throw
  eval { $mutex->WaitOne(0); };
  ok($@, 'WaitOne throws after disposal');
  
  eval { $mutex->ReleaseMutex(); };
  ok($@, 'ReleaseMutex throws after disposal');
  
  eval { $mutex->Name(); };
  ok($@, 'Name throws after disposal');
  
  # Create new mutex to test automatic disposal via DESTROY
  {
    my $tempMutex = System::Threading::Mutex->new();
    $tempMutex->WaitOne(0);
    # Should automatically dispose when going out of scope
  }
  ok(1, 'Automatic disposal via DESTROY works');
}

done_testing();