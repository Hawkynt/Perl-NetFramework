#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Buffers::ArrayPool;

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

print "1..70\n"; # Comprehensive ArrayPool tests

# Test 1-10: Basic ArrayPool construction and properties
my $pool = System::Buffers::ArrayPool->new();
test_ok(defined($pool), 'ArrayPool construction without parameters');
test_ok($pool->isa('System::Buffers::ArrayPool'), 'ArrayPool isa ArrayPool');

# Test statistics for empty pool
my $stats = $pool->GetStatistics();
test_ok(defined($stats), 'GetStatistics returns statistics');
test_ok($stats->{TotalRented} == 0, 'Initial TotalRented is 0');
test_ok($stats->{TotalReturned} == 0, 'Initial TotalReturned is 0');
test_ok($stats->{CurrentlyRented} == 0, 'Initial CurrentlyRented is 0');
test_ok($stats->{TotalPooledArrays} == 0, 'Initial TotalPooledArrays is 0');
test_ok($stats->{MaxArrayLength} == 1048576, 'Default MaxArrayLength is 1MB');
test_ok($stats->{MaxArraysPerBucket} == 50, 'Default MaxArraysPerBucket is 50');

# Test ToString
my $str = $pool->ToString();
test_ok($str =~ /ArrayPool/, 'ToString contains ArrayPool');

# Test 11-20: Basic rent and return operations
my $array1 = $pool->Rent(10);
test_ok(defined($array1), 'Rent returns an array');
test_ok(ref($array1) eq 'ARRAY', 'Rented array is an ARRAY reference');
test_ok(scalar(@$array1) >= 10, 'Rented array size is at least minimum requested');

# Check statistics after rent
$stats = $pool->GetStatistics();
test_ok($stats->{TotalRented} == 1, 'TotalRented incremented after rent');
test_ok($stats->{CurrentlyRented} == 1, 'CurrentlyRented shows 1 array rented');

# Modify the array to test it's working
$array1->[0] = 'test_value';
$array1->[5] = 42;
test_ok($array1->[0] eq 'test_value', 'Can write to rented array');
test_ok($array1->[5] == 42, 'Array stores values correctly');

# Return the array
$pool->Return($array1, 1);  # Clear on return
$stats = $pool->GetStatistics();
test_ok($stats->{TotalReturned} == 1, 'TotalReturned incremented after return');
test_ok($stats->{CurrentlyRented} == 0, 'CurrentlyRented back to 0 after return');

# Test 21-30: Array reuse from pool
my $array2 = $pool->Rent(10);
$stats = $pool->GetStatistics();
test_ok($stats->{TotalRented} == 2, 'Second rent increments TotalRented');
test_ok($stats->{TotalPooledArrays} >= 0, 'Pool tracks pooled arrays');

# The returned array should be cleared (due to clearArray=1)
my $allUndef = 1;
for my $i (0..9) {
  if (defined($array2->[$i])) {
    $allUndef = 0;
    last;
  }
}
test_ok($allUndef, 'Returned array was cleared when clearArray=1');

# Test different sizes to trigger different buckets
my $smallArray = $pool->Rent(5);
my $mediumArray = $pool->Rent(100);
my $largeArray = $pool->Rent(1000);

test_ok(scalar(@$smallArray) >= 5, 'Small array size is adequate');
test_ok(scalar(@$mediumArray) >= 100, 'Medium array size is adequate');
test_ok(scalar(@$largeArray) >= 1000, 'Large array size is adequate');

$stats = $pool->GetStatistics();
test_ok($stats->{CurrentlyRented} == 4, 'Multiple arrays rented correctly tracked'); # array2, smallArray, mediumArray, largeArray

# Test 31-40: Return arrays without clearing
$pool->Return($smallArray, 0);  # Don't clear
$pool->Return($mediumArray, 0);
$pool->Return($largeArray, 0);

$stats = $pool->GetStatistics();
test_ok($stats->{TotalReturned} == 4, 'Multiple returns tracked correctly');
test_ok($stats->{CurrentlyRented} == 1, 'Only array2 still rented'); # Only array2 left

# Test array reuse - rent same sizes again
my $reusedSmall = $pool->Rent(5);
my $reusedMedium = $pool->Rent(100);

# These should potentially be the same arrays (reused from pool)
test_ok(defined($reusedSmall), 'Reused small array is defined');
test_ok(defined($reusedMedium), 'Reused medium array is defined');

# Test bucket size calculation
my $array16 = $pool->Rent(16);
my $array17 = $pool->Rent(17);  # Should get next bucket size (32)
test_ok(scalar(@$array16) >= 16, 'Array for size 16 is adequate');
test_ok(scalar(@$array17) >= 17, 'Array for size 17 is adequate');
test_ok(scalar(@$array17) >= 32, 'Array for size 17 gets next bucket (32)');

# Test 41-50: Shared pool functionality
my $sharedPool1 = System::Buffers::ArrayPool->Shared();
my $sharedPool2 = System::Buffers::ArrayPool->Shared();
test_ok(defined($sharedPool1), 'Shared pool returns a pool');
test_ok($sharedPool1 eq $sharedPool2, 'Shared pool returns same instance');

# Test shared pool with different element types
my $scalarShared = System::Buffers::ArrayPool->Shared('SCALAR');
my $stringShared = System::Buffers::ArrayPool->Shared('STRING');
test_ok(defined($scalarShared), 'Shared SCALAR pool created');
test_ok(defined($stringShared), 'Shared STRING pool created');
test_ok($scalarShared ne $stringShared, 'Different typed pools are different instances');

# Test Create factory method
my $customPool = System::Buffers::ArrayPool->Create(65536, 25);  # 64KB max, 25 per bucket
test_ok(defined($customPool), 'Create factory method works');

my $customStats = $customPool->GetStatistics();
test_ok($customStats->{MaxArrayLength} == 65536, 'Custom MaxArrayLength set correctly');
test_ok($customStats->{MaxArraysPerBucket} == 25, 'Custom MaxArraysPerBucket set correctly');

# Test 51-60: Pool management operations
# Clear pool
$pool->Clear();
$stats = $pool->GetStatistics();
test_ok($stats->{TotalPooledArrays} == 0, 'Clear removes all pooled arrays');
# Note: TotalRented/Returned counters are preserved, CurrentlyRented should be unchanged

# Test Trim functionality
my $trimPool = System::Buffers::ArrayPool->new();
# Rent and return many arrays to populate the pool
my @arrays = ();
for my $i (1..10) {
  push @arrays, $trimPool->Rent(64);
}
for my $array (@arrays) {
  $trimPool->Return($array, 0);
}

my $beforeTrim = $trimPool->GetStatistics();
my $trimmed = $trimPool->Trim(0.5);  # Keep only 50%
my $afterTrim = $trimPool->GetStatistics();

test_ok($trimmed >= 0, 'Trim returns number of trimmed arrays');
test_ok($afterTrim->{TotalPooledArrays} <= $beforeTrim->{TotalPooledArrays}, 'Trim reduces pooled arrays');

# Test Dispose
$trimPool->Dispose();
my $disposedStats = $trimPool->GetStatistics();
test_ok($disposedStats->{TotalPooledArrays} == 0, 'Dispose clears pool');

# Test 61-70: Typed array methods and edge cases
my $typedPool = System::Buffers::ArrayPool->new();

# Test typed array methods
my $byteArray = $typedPool->RentByteArray(20);
my $intArray = $typedPool->RentIntArray(15);
my $stringArray = $typedPool->RentStringArray(10);

test_ok(defined($byteArray), 'RentByteArray returns array');
test_ok(defined($intArray), 'RentIntArray returns array');
test_ok(defined($stringArray), 'RentStringArray returns array');
test_ok(scalar(@$byteArray) >= 20, 'Byte array has correct minimum size');
test_ok(scalar(@$intArray) >= 15, 'Int array has correct minimum size');
test_ok(scalar(@$stringArray) >= 10, 'String array has correct minimum size');

# Test edge cases and exception handling
test_exception(
  sub { $pool->Rent(-1); },
  'ArgumentOutOfRangeException',
  'Rent with negative size throws exception'
);

test_exception(
  sub { $pool->Return(undef); },
  'ArgumentNullException',
  'Return with null array throws exception'
);

test_exception(
  sub { $pool->Trim(-0.1); },
  'ArgumentOutOfRangeException',
  'Trim with negative factor throws exception'
);

test_exception(
  sub { $pool->Trim(1.1); },
  'ArgumentOutOfRangeException',
  'Trim with factor > 1 throws exception'
);

# Test returning array not from this pool (should warn but not crash)
my $foreignArray = [1, 2, 3, 4, 5];
eval {
  # Suppress warnings for this test
  local $SIG{__WARN__} = sub { };
  $pool->Return($foreignArray);
};
test_ok(!$@, 'Returning foreign array does not crash');

# Test zero-length array request
my $zeroArray = $pool->Rent(0);
test_ok(defined($zeroArray), 'Rent(0) returns array');
test_ok(scalar(@$zeroArray) >= 0, 'Zero-length request returns valid array');

# Test very large array request
my $largeRequest = $pool->Rent(10000);
test_ok(defined($largeRequest), 'Large array request succeeds');
test_ok(scalar(@$largeRequest) >= 10000, 'Large array has adequate size');

print "\n# ArrayPool Tests completed: $tests_run\n";
print "# ArrayPool Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);