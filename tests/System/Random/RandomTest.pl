#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Random;
require System::String;

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

print "1..50\n"; # We'll have approximately 50 tests

# Test 1-10: Basic Random construction
my $random1 = System::Random->new();
test_ok(defined($random1), 'Random construction without seed');
test_ok($random1->isa('System::Random'), 'Random isa Random');

my $random2 = System::Random->new(42);
test_ok(defined($random2), 'Random construction with seed');

my $random3 = System::Random->new(System::Int32->new(123));
test_ok(defined($random3), 'Random construction with Int32 seed');

# Test ToString
test_ok($random2->ToString() =~ /42/, 'ToString includes seed');

# Test 11-20: Basic Next() methods
my $next1 = $random2->Next();
test_ok($next1 >= 0, 'Next() returns non-negative');
test_ok($next1 < 2147483647, 'Next() returns value less than Int32.MaxValue');

my $next2 = $random2->Next(10);
test_ok($next2 >= 0 && $next2 < 10, 'Next(max) returns value in range');

my $next3 = $random2->Next(5, 15);
test_ok($next3 >= 5 && $next3 < 15, 'Next(min, max) returns value in range');

# Test edge cases
my $next4 = $random2->Next(0, 1);
test_ok($next4 == 0, 'Next(0, 1) always returns 0');

# Test 21-30: NextDouble and other basic methods
my $double1 = $random2->NextDouble();
test_ok($double1 >= 0.0 && $double1 < 1.0, 'NextDouble returns value between 0 and 1');

my $single1 = $random2->NextSingle();
test_ok($single1 >= 0.0 && $single1 < 1.0, 'NextSingle returns value between 0 and 1');

my $bool1 = $random2->NextBoolean();
test_ok($bool1 == 0 || $bool1 == 1, 'NextBoolean returns 0 or 1');

# Test NextBytes with array reference
my @buffer = (0) x 10;
$random2->NextBytes(\@buffer);
my $allZero = 1;
for my $byte (@buffer) {
  if ($byte != 0) {
    $allZero = 0;
    last;
  }
}
test_ok(!$allZero, 'NextBytes filled array with non-zero values');

# Test all bytes are in valid range (0-255)
my $validBytes = 1;
for my $byte (@buffer) {
  if ($byte < 0 || $byte > 255) {
    $validBytes = 0;
    last;
  }
}
test_ok($validBytes, 'NextBytes fills array with valid byte values');

# Test 31-40: Advanced methods
my $string1 = $random2->NextString(8);
test_ok(length($string1) == 8, 'NextString returns correct length');
test_ok($string1 =~ /^[A-Za-z0-9]+$/, 'NextString returns alphanumeric characters');

my $string2 = $random2->NextString(5, "ABC123");
test_ok(length($string2) == 5, 'NextString with custom charset correct length');
test_ok($string2 =~ /^[ABC123]+$/, 'NextString uses custom charset');

# Test Gaussian distribution (just basic functionality)
my $gaussian1 = $random2->NextGaussian();
test_ok(defined($gaussian1), 'NextGaussian returns a value');

my $gaussian2 = $random2->NextGaussian(10, 2);
test_ok(defined($gaussian2), 'NextGaussian with mean/stddev returns a value');

# Test 41-50: Array operations and static methods
my @testArray = (1, 2, 3, 4, 5);
my $sample = $random2->Sample(\@testArray);
my $found = 0;
for my $item (@testArray) {
  if ($item == $sample) {
    $found = 1;
    last;
  }
}
test_ok($found, 'Sample returns element from array');

# Test Shuffle
my @originalArray = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
my @shuffleArray = @originalArray;
$random2->Shuffle(\@shuffleArray);

# Check that all original elements are still present
my $allPresent = 1;
for my $orig (@originalArray) {
  my $found = 0;
  for my $shuffled (@shuffleArray) {
    if ($orig == $shuffled) {
      $found = 1;
      last;
    }
  }
  if (!$found) {
    $allPresent = 0;
    last;
  }
}
test_ok($allPresent, 'Shuffle preserves all elements');

# Test Shared instance
my $shared1 = System::Random->Shared();
my $shared2 = System::Random->Shared();
test_ok($shared1 eq $shared2, 'Shared returns same instance');

# Test exception cases
test_exception(
  sub { $random2->Next(-1); },
  'ArgumentOutOfRangeException',
  'Next with negative max throws exception'
);

test_exception(
  sub { $random2->Next(10, 5); },
  'ArgumentOutOfRangeException',
  'Next with min > max throws exception'
);

test_exception(
  sub { $random2->NextBytes(undef); },
  'ArgumentNullException',
  'NextBytes with null buffer throws exception'
);

test_exception(
  sub { $random2->Sample([]); },
  'ArgumentException',
  'Sample with empty array throws exception'
);

# Test SetSeed
$random2->SetSeed(999);
test_ok($random2->ToString() =~ /999/, 'SetSeed changes seed');

# Test deterministic behavior with same seed
my $det1 = System::Random->new(555);
my $det2 = System::Random->new(555);

my $val1 = $det1->Next();
my $val2 = $det2->Next();
test_ok($val1 == $val2, 'Same seed produces same sequence');

print "\n# Random Tests completed: $tests_run\n";
print "# Random Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);