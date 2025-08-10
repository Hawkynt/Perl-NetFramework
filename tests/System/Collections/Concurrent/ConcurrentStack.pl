#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../../..";

require System::Collections::Concurrent::ConcurrentStack;

# Test plan: comprehensive tests for ConcurrentStack
plan tests => 48;

# Test 1-3: Constructor and initial state
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  ok(defined($stack), 'ConcurrentStack constructor');
  is($stack->Count(), 0, 'Initial count is zero');
  ok($stack->IsEmpty(), 'Initial stack is empty');
}

# Test 4-10: Basic Push operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  $stack->Push('first');
  is($stack->Count(), 1, 'Count after first push');
  ok(!$stack->IsEmpty(), 'Stack not empty after push');
  
  $stack->Push('second');
  $stack->Push('third');
  is($stack->Count(), 3, 'Count after multiple pushes');
  
  $stack->Push(undef);
  is($stack->Count(), 4, 'Can push undef value');
  
  $stack->Push(42);
  $stack->Push(3.14);
  $stack->Push(0);
  is($stack->Count(), 7, 'Can push various types');
}

# Test 11-18: PushRange operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  $stack->PushRange('A', 'B', 'C');
  is($stack->Count(), 3, 'PushRange increases count correctly');
  
  $stack->PushRange('D', 'E');
  is($stack->Count(), 5, 'PushRange can be called multiple times');
  
  # Test that items are in correct order (last pushed should be on top)
  my $result;
  my $success = $stack->TryPop(\$result);
  ok($success && $result eq 'E', 'Last item from PushRange is on top');
  
  $success = $stack->TryPop(\$result);
  is($result, 'D', 'PushRange items in correct order');
  
  $success = $stack->TryPop(\$result);
  is($result, 'C', 'Original PushRange items accessible');
  
  $success = $stack->TryPop(\$result);
  is($result, 'B', 'PushRange maintains LIFO order');
  
  $success = $stack->TryPop(\$result);
  is($result, 'A', 'All PushRange items accessible in LIFO order');
}

# Test 19-28: TryPop operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  # Test pop from empty stack
  my $result;
  my $success = $stack->TryPop(\$result);
  ok(!$success, 'TryPop fails on empty stack');
  ok(!defined($result), 'Result is undef when pop fails');
  
  # Add items and test LIFO behavior
  $stack->Push('first');
  $stack->Push('second');
  $stack->Push('third');
  
  $success = $stack->TryPop(\$result);
  ok($success, 'TryPop succeeds with items');
  is($result, 'third', 'LIFO: last item popped first');
  is($stack->Count(), 2, 'Count decreases after pop');
  
  $success = $stack->TryPop(\$result);
  is($result, 'second', 'LIFO: second-to-last item popped second');
  
  $success = $stack->TryPop(\$result);
  is($result, 'first', 'LIFO: first item popped last');
  
  is($stack->Count(), 0, 'Stack empty after all pops');
  ok($stack->IsEmpty(), 'IsEmpty returns true after all pops');
}

# Test 29-35: TryPopRange operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  # Test pop range from empty stack
  my @items;
  my $count = $stack->TryPopRange(\@items, 3);
  is($count, 0, 'TryPopRange returns 0 for empty stack');
  is(scalar(@items), 0, 'No items returned from empty stack');
  
  # Add items and test range pop
  $stack->Push('A');
  $stack->Push('B');
  $stack->Push('C');
  $stack->Push('D');
  $stack->Push('E');
  
  $count = $stack->TryPopRange(\@items, 3);
  is($count, 3, 'TryPopRange returns correct count');
  is(scalar(@items), 3, 'Correct number of items returned');
  is($items[0], 'E', 'First popped item is top of stack');
  is($items[1], 'D', 'Items popped in LIFO order');
  is($items[2], 'C', 'Range pop maintains order');
  is($stack->Count(), 2, 'Stack count reduced correctly');
}

# Test 36-40: TryPeek operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  # Test peek on empty stack
  my $result;
  my $success = $stack->TryPeek(\$result);
  ok(!$success, 'TryPeek fails on empty stack');
  ok(!defined($result), 'Peek result is undef when fails');
  
  # Test peek with items
  $stack->Push('peek_test');
  $stack->Push('top_item');
  
  $success = $stack->TryPeek(\$result);
  ok($success, 'TryPeek succeeds with items');
  is($result, 'top_item', 'Peek returns top item');
  is($stack->Count(), 2, 'Peek does not change count');
}

# Test 41-45: ToArray operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  my $array = $stack->ToArray();
  is(scalar(@$array), 0, 'ToArray returns empty array for empty stack');
  
  $stack->Push('bottom');
  $stack->Push('middle');
  $stack->Push('top');
  
  $array = $stack->ToArray();
  is(scalar(@$array), 3, 'ToArray returns correct size');
  is($array->[0], 'top', 'ToArray returns items in stack order (top to bottom)');
  is($array->[1], 'middle', 'ToArray maintains stack order');
  is($array->[2], 'bottom', 'ToArray includes bottom items');
  
  # Verify ToArray is a snapshot
  $stack->Push('newer');
  is(scalar(@$array), 3, 'ToArray snapshot unchanged after modification');
}

# Test 46-50: Clear and enumerator operations
{
  my $stack = System::Collections::Concurrent::ConcurrentStack->new();
  
  $stack->Push('item1');
  $stack->Push('item2');
  $stack->Push('item3');
  
  is($stack->Count(), 3, 'Count before clear');
  $stack->Clear();
  is($stack->Count(), 0, 'Count after clear is zero');
  ok($stack->IsEmpty(), 'Stack is empty after clear');
  
  # Test enumerator
  $stack->Push('enum1');
  $stack->Push('enum2');
  
  my $enumerator = $stack->GetEnumerator();
  my @items;
  while ($enumerator->MoveNext()) {
    push @items, $enumerator->Current();
  }
  
  is(scalar(@items), 2, 'Enumerator iterates correct number of items');
  is($items[0], 'enum2', 'Enumerator returns items in stack order (top to bottom)');
}

done_testing();