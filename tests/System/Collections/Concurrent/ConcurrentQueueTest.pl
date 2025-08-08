#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../../..";

require System::Collections::Concurrent::ConcurrentQueue;

# Test plan: comprehensive tests for ConcurrentQueue
plan tests => 44;

# Test 1-3: Constructor and initial state
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  ok(defined($queue), 'ConcurrentQueue constructor');
  is($queue->Count(), 0, 'Initial count is zero');
  ok($queue->IsEmpty(), 'Initial queue is empty');
}

# Test 4-10: Basic Enqueue operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  
  $queue->Enqueue('first');
  is($queue->Count(), 1, 'Count after first enqueue');
  ok(!$queue->IsEmpty(), 'Queue not empty after enqueue');
  
  $queue->Enqueue('second');
  $queue->Enqueue('third');
  is($queue->Count(), 3, 'Count after multiple enqueues');
  
  $queue->Enqueue(undef);
  is($queue->Count(), 4, 'Can enqueue undef value');
  
  $queue->Enqueue(42);
  $queue->Enqueue(3.14);
  $queue->Enqueue(0);
  is($queue->Count(), 7, 'Can enqueue various types');
}

# Test 11-20: TryDequeue operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  
  # Test dequeue from empty queue
  my $result;
  my $success = $queue->TryDequeue(\$result);
  ok(!$success, 'TryDequeue fails on empty queue');
  ok(!defined($result), 'Result is undef when dequeue fails');
  
  # Add items and test FIFO behavior
  $queue->Enqueue('first');
  $queue->Enqueue('second');
  $queue->Enqueue('third');
  
  $success = $queue->TryDequeue(\$result);
  ok($success, 'TryDequeue succeeds with items');
  is($result, 'first', 'FIFO: first item dequeued first');
  is($queue->Count(), 2, 'Count decreases after dequeue');
  
  $success = $queue->TryDequeue(\$result);
  is($result, 'second', 'FIFO: second item dequeued second');
  
  $success = $queue->TryDequeue(\$result);
  is($result, 'third', 'FIFO: third item dequeued third');
  
  is($queue->Count(), 0, 'Queue empty after all dequeues');
  ok($queue->IsEmpty(), 'IsEmpty returns true after all dequeues');
}

# Test 21-25: TryPeek operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  
  # Test peek on empty queue
  my $result;
  my $success = $queue->TryPeek(\$result);
  ok(!$success, 'TryPeek fails on empty queue');
  ok(!defined($result), 'Peek result is undef when fails');
  
  # Test peek with items
  $queue->Enqueue('peek_test');
  $queue->Enqueue('second');
  
  $success = $queue->TryPeek(\$result);
  ok($success, 'TryPeek succeeds with items');
  is($result, 'peek_test', 'Peek returns first item');
  is($queue->Count(), 2, 'Peek does not change count');
}

# Test 26-30: Clear operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  
  $queue->Enqueue('item1');
  $queue->Enqueue('item2');
  $queue->Enqueue('item3');
  
  is($queue->Count(), 3, 'Count before clear');
  $queue->Clear();
  is($queue->Count(), 0, 'Count after clear is zero');
  ok($queue->IsEmpty(), 'Queue is empty after clear');
  
  # Test that we can still use queue after clear
  $queue->Enqueue('after_clear');
  is($queue->Count(), 1, 'Can enqueue after clear');
  
  my $result;
  my $success = $queue->TryDequeue(\$result);
  ok($success && $result eq 'after_clear', 'Can dequeue after clear');
}

# Test 31-35: ToArray operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  
  my $array = $queue->ToArray();
  is(scalar(@$array), 0, 'ToArray returns empty array for empty queue');
  
  $queue->Enqueue('A');
  $queue->Enqueue('B');
  $queue->Enqueue('C');
  
  $array = $queue->ToArray();
  is(scalar(@$array), 3, 'ToArray returns correct size');
  is($array->[0], 'A', 'ToArray preserves order - first');
  is($array->[1], 'B', 'ToArray preserves order - second');
  is($array->[2], 'C', 'ToArray preserves order - third');
  
  # Verify ToArray is a snapshot
  $queue->Enqueue('D');
  is(scalar(@$array), 3, 'ToArray snapshot unchanged after modification');
}

# Test 36-40: CopyTo operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  $queue->Enqueue('X');
  $queue->Enqueue('Y');
  $queue->Enqueue('Z');
  
  my @target = (1, 2, 3, 4, 5);
  $queue->CopyTo(\@target, 1);
  
  is($target[0], 1, 'CopyTo preserves existing elements before index');
  is($target[1], 'X', 'CopyTo copies first element correctly');
  is($target[2], 'Y', 'CopyTo copies second element correctly');
  is($target[3], 'Z', 'CopyTo copies third element correctly');
  is($target[4], 5, 'CopyTo preserves existing elements after');
}

# Test 41-45: Enumerator operations
{
  my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
  $queue->Enqueue('enum1');
  $queue->Enqueue('enum2');
  $queue->Enqueue('enum3');
  
  my $enumerator = $queue->GetEnumerator();
  ok(defined($enumerator), 'GetEnumerator returns enumerator');
  
  my @items;
  while ($enumerator->MoveNext()) {
    push @items, $enumerator->Current();
  }
  
  is(scalar(@items), 3, 'Enumerator iterates correct number of items');
  is($items[0], 'enum1', 'Enumerator preserves order - first');
  is($items[1], 'enum2', 'Enumerator preserves order - second');
  is($items[2], 'enum3', 'Enumerator preserves order - third');
  
  # Test enumerator reset
  $enumerator->Reset();
  ok($enumerator->MoveNext(), 'Enumerator works after reset');
}

done_testing();