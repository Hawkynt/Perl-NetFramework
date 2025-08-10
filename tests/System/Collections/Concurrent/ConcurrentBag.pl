#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../../..";

require System::Collections::Concurrent::ConcurrentBag;

# Test plan: comprehensive tests for ConcurrentBag
plan tests => 41;

# Test 1-3: Constructor and initial state
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  ok(defined($bag), 'ConcurrentBag constructor');
  is($bag->Count(), 0, 'Initial count is zero');
  ok($bag->IsEmpty(), 'Initial bag is empty');
}

# Test 4-10: Basic Add operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  
  $bag->Add('first');
  is($bag->Count(), 1, 'Count after first add');
  ok(!$bag->IsEmpty(), 'Bag not empty after add');
  
  $bag->Add('second');
  $bag->Add('third');
  is($bag->Count(), 3, 'Count after multiple adds');
  
  $bag->Add(undef);
  is($bag->Count(), 4, 'Can add undef value');
  
  $bag->Add(42);
  $bag->Add(3.14);
  $bag->Add(0);
  is($bag->Count(), 7, 'Can add various types');
  
  # Test adding duplicates (should be allowed in bag)
  $bag->Add('first');
  is($bag->Count(), 8, 'Can add duplicate items');
}

# Test 11-20: TryTake operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  
  # Test take from empty bag
  my $result;
  my $success = $bag->TryTake(\$result);
  ok(!$success, 'TryTake fails on empty bag');
  ok(!defined($result), 'Result is undef when take fails');
  
  # Add items and test taking
  $bag->Add('item1');
  $bag->Add('item2');
  $bag->Add('item3');
  
  $success = $bag->TryTake(\$result);
  ok($success, 'TryTake succeeds with items');
  ok(defined($result), 'TryTake returns some item');
  is($bag->Count(), 2, 'Count decreases after take');
  
  # Take all items to verify they can all be retrieved
  my @taken;
  push @taken, $result;
  
  while ($bag->TryTake(\$result)) {
    push @taken, $result;
  }
  
  is(scalar(@taken), 3, 'All items can be taken');
  is($bag->Count(), 0, 'Bag empty after taking all items');
  ok($bag->IsEmpty(), 'IsEmpty returns true after taking all');
  
  # Test that we can find all original items (order may vary)
  my %found = map { $_ => 1 } @taken;
  ok(exists($found{'item1'}) && exists($found{'item2'}) && exists($found{'item3'}), 
     'All original items were retrieved');
}

# Test 21-25: TryPeek operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  
  # Test peek on empty bag
  my $result;
  my $success = $bag->TryPeek(\$result);
  ok(!$success, 'TryPeek fails on empty bag');
  ok(!defined($result), 'Peek result is undef when fails');
  
  # Test peek with items
  $bag->Add('peek_test');
  $bag->Add('another_item');
  
  $success = $bag->TryPeek(\$result);
  ok($success, 'TryPeek succeeds with items');
  ok(defined($result), 'Peek returns some item');
  is($bag->Count(), 2, 'Peek does not change count');
}

# Test 26-30: Clear operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  
  $bag->Add('item1');
  $bag->Add('item2');
  $bag->Add('item3');
  
  is($bag->Count(), 3, 'Count before clear');
  $bag->Clear();
  is($bag->Count(), 0, 'Count after clear is zero');
  ok($bag->IsEmpty(), 'Bag is empty after clear');
  
  # Test that we can still use bag after clear
  $bag->Add('after_clear');
  is($bag->Count(), 1, 'Can add after clear');
  
  my $result;
  my $success = $bag->TryTake(\$result);
  ok($success && $result eq 'after_clear', 'Can take after clear');
}

# Test 31-35: ToArray operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  
  my $array = $bag->ToArray();
  is(scalar(@$array), 0, 'ToArray returns empty array for empty bag');
  
  $bag->Add('A');
  $bag->Add('B');
  $bag->Add('C');
  
  $array = $bag->ToArray();
  is(scalar(@$array), 3, 'ToArray returns correct size');
  
  # Verify all items are present (order may vary in bag)
  my %found = map { $_ => 1 } @$array;
  ok(exists($found{'A'}) && exists($found{'B'}) && exists($found{'C'}), 
     'ToArray contains all items');
  
  # Verify ToArray is a snapshot
  $bag->Add('D');
  is(scalar(@$array), 3, 'ToArray snapshot unchanged after modification');
  
  # Test with duplicates
  $bag->Clear();
  $bag->Add('dup');
  $bag->Add('dup');
  $bag->Add('unique');
  
  $array = $bag->ToArray();
  is(scalar(@$array), 3, 'ToArray includes duplicates');
}

# Test 36-40: CopyTo operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  $bag->Add('X');
  $bag->Add('Y');
  $bag->Add('Z');
  
  my @target = (1, 2, 3, 4, 5);
  $bag->CopyTo(\@target, 1);
  
  is($target[0], 1, 'CopyTo preserves existing elements before index');
  is($target[4], 5, 'CopyTo preserves existing elements after');
  
  # Verify all bag items were copied (order may vary)
  my %copied = map { $_ => 1 } @target[1..3];
  ok(exists($copied{'X'}) && exists($copied{'Y'}) && exists($copied{'Z'}), 
     'CopyTo copies all items correctly');
}

# Test 41-45: Enumerator operations
{
  my $bag = System::Collections::Concurrent::ConcurrentBag->new();
  $bag->Add('enum1');
  $bag->Add('enum2');
  $bag->Add('enum3');
  
  my $enumerator = $bag->GetEnumerator();
  ok(defined($enumerator), 'GetEnumerator returns enumerator');
  
  my @items;
  while ($enumerator->MoveNext()) {
    push @items, $enumerator->Current();
  }
  
  is(scalar(@items), 3, 'Enumerator iterates correct number of items');
  
  # Verify all items are present (order may vary)
  my %found = map { $_ => 1 } @items;
  ok(exists($found{'enum1'}) && exists($found{'enum2'}) && exists($found{'enum3'}), 
     'Enumerator returns all items');
  
  # Test enumerator reset
  $enumerator->Reset();
  ok($enumerator->MoveNext(), 'Enumerator works after reset');
  ok(defined($enumerator->Current()), 'Current has value after reset and MoveNext');
}

done_testing();