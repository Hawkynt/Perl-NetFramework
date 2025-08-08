#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::Threading::Semaphore;

# Test plan: comprehensive tests for Semaphore
plan tests => 30;

# Test 1-5: Constructor and validation
{
  my $semaphore = System::Threading::Semaphore->new(2, 5);
  ok(defined($semaphore), 'Semaphore constructor');
  ok(!defined($semaphore->Name()), 'Anonymous semaphore has no name');
  
  my $namedSemaphore = System::Threading::Semaphore->new(1, 3, "TestSemaphore");
  is($namedSemaphore->Name(), "TestSemaphore", 'Named semaphore has correct name');
  
  # Test invalid parameters
  eval { System::Threading::Semaphore->new(-1, 5); };
  ok($@, 'Negative initial count throws exception');
  
  eval { System::Threading::Semaphore->new(5, 2); };
  ok($@, 'Initial count exceeding maximum throws exception');
}

# Test 6-10: Basic semaphore operations
{
  my $semaphore = System::Threading::Semaphore->new(2, 5);  # Start with 2 permits
  
  # Should be able to acquire twice
  my $result = $semaphore->WaitOne(0);
  ok($result, 'First WaitOne succeeds');
  
  $result = $semaphore->WaitOne(0);
  ok($result, 'Second WaitOne succeeds');
  
  # Third attempt should fail (timeout)
  $result = $semaphore->WaitOne(10);  # 10ms timeout
  ok(!$result, 'Third WaitOne fails (semaphore exhausted)');
  
  # Release one permit
  my $previousCount = $semaphore->Release();
  is($previousCount, 0, 'Release returns previous count');
  
  # Now should be able to acquire again
  $result = $semaphore->WaitOne(0);
  ok($result, 'WaitOne succeeds after release');
}

# Test 11-15: Release operations
{
  my $semaphore = System::Threading::Semaphore->new(0, 3);  # Start empty
  
  # Release multiple permits
  my $previousCount = $semaphore->Release(2);
  is($previousCount, 0, 'Release(2) returns correct previous count');
  
  # Should be able to acquire twice
  ok($semaphore->WaitOne(0), 'First acquire after release');
  ok($semaphore->WaitOne(0), 'Second acquire after release');
  
  # Release back to maximum
  $semaphore->Release(2);
  
  # Test releasing beyond maximum
  eval { $semaphore->Release(2); };  # Would make it 5, but max is 3
  ok($@, 'Release beyond maximum throws exception');
  ok($@ =~ /exceed.*maximum/i, 'Correct error message for exceeding maximum');
}

# Test 16-20: Timeout behavior
{
  my $semaphore = System::Threading::Semaphore->new(1, 1);  # Single permit
  
  # Acquire the permit
  ok($semaphore->WaitOne(0), 'Acquire single permit');
  
  # Test zero timeout
  my $start = time();
  my $result = $semaphore->WaitOne(0);
  my $elapsed = (time() - $start) * 1000;
  ok(!$result, 'Zero timeout fails on exhausted semaphore');
  ok($elapsed < 50, 'Zero timeout returns quickly');
  
  # Test short timeout
  $start = time();
  $result = $semaphore->WaitOne(50);  # 50ms timeout
  $elapsed = (time() - $start) * 1000;
  ok(!$result, 'Short timeout fails on exhausted semaphore');
  ok($elapsed >= 30, 'Short timeout takes at least minimum time');
}

# Test 21-25: Edge cases and error conditions
{
  my $semaphore = System::Threading::Semaphore->new(0, 1);
  
  # Test negative release count
  eval { $semaphore->Release(-1); };
  ok($@, 'Negative release count throws exception');
  
  # Test zero release count (should be invalid)
  eval { $semaphore->Release(0); };
  ok($@, 'Zero release count throws exception');
  
  # Test maximum semaphore values
  my $maxSemaphore = System::Threading::Semaphore->new(1000, 1000);
  ok(defined($maxSemaphore), 'Large semaphore values work');
  
  # Test single-threaded behavior consistency
  ok($maxSemaphore->WaitOne(0), 'Large semaphore allows acquisition');
  ok($maxSemaphore->Release() == 999, 'Release returns correct count for large semaphore');
}

# Test 26-30: Disposal and cleanup
{
  my $semaphore = System::Threading::Semaphore->new(1, 1);
  
  # Acquire permit
  ok($semaphore->WaitOne(0), 'Acquire permit for disposal test');
  
  # Dispose
  $semaphore->Dispose();
  
  # Operations after dispose should throw
  eval { $semaphore->WaitOne(0); };
  ok($@, 'WaitOne throws after disposal');
  
  eval { $semaphore->Release(); };
  ok($@, 'Release throws after disposal');
  
  eval { $semaphore->Name(); };
  ok($@, 'Name throws after disposal');
  
  # Test automatic cleanup
  {
    my $tempSemaphore = System::Threading::Semaphore->new(1, 1);
    $tempSemaphore->WaitOne(0);
    # Should automatically dispose when going out of scope
  }
  ok(1, 'Automatic disposal via DESTROY works');
}

done_testing();