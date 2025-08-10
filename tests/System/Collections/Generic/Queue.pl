#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Generic::Queue');
}

#===========================================
# CONSTRUCTION TESTS
#===========================================

sub test_construction {
    # Test 1: Default constructor
    my $queue1 = System::Collections::Generic::Queue->new();
    isa_ok($queue1, 'System::Collections::Generic::Queue', 'Default constructor creates Queue');
    is($queue1->Count(), 0, 'Default constructor creates empty queue');
    
    # Test 2: Constructor with capacity
    my $queue2 = System::Collections::Generic::Queue->new(20);
    isa_ok($queue2, 'System::Collections::Generic::Queue', 'Constructor with capacity creates Queue');
    is($queue2->Count(), 0, 'Constructor with capacity creates empty queue');
    
    # Test 3: Constructor with zero capacity
    my $queue3 = System::Collections::Generic::Queue->new(0);
    isa_ok($queue3, 'System::Collections::Generic::Queue', 'Constructor with zero capacity works');
    is($queue3->Count(), 0, 'Zero capacity queue is empty');
}

#===========================================
# ENQUEUE AND COUNT TESTS
#===========================================

sub test_enqueue_and_count {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 4: Count on empty queue
    is($queue->Count(), 0, 'Empty queue has count 0');
    
    # Test 5: Single enqueue
    $queue->Enqueue("first");
    is($queue->Count(), 1, 'Count increases after enqueue');
    
    # Test 6: Multiple enqueues
    $queue->Enqueue("second");
    $queue->Enqueue("third");
    is($queue->Count(), 3, 'Count correct after multiple enqueues');
    
    # Test 7: Enqueue null value
    $queue->Enqueue(undef);
    is($queue->Count(), 4, 'Can enqueue null value');
    
    # Test 8: Enqueue different types
    $queue->Enqueue(42);
    $queue->Enqueue(3.14);
    is($queue->Count(), 6, 'Can enqueue different data types');
}

#===========================================
# DEQUEUE TESTS
#===========================================

sub test_dequeue {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 9: Dequeue from empty queue throws exception
    eval { $queue->Dequeue(); };
    like($@, qr/InvalidOperationException|Queue is empty/, 'Dequeue from empty queue throws exception');
    
    # Test 10: FIFO behavior (First In, First Out)
    $queue->Enqueue("first");
    $queue->Enqueue("second");
    $queue->Enqueue("third");
    
    my $item1 = $queue->Dequeue();
    is($item1, "first", 'First item dequeued correctly (FIFO)');
    is($queue->Count(), 2, 'Count decreases after dequeue');
    
    my $item2 = $queue->Dequeue();
    is($item2, "second", 'Second item dequeued correctly (FIFO)');
    is($queue->Count(), 1, 'Count correct after second dequeue');
    
    my $item3 = $queue->Dequeue();
    is($item3, "third", 'Third item dequeued correctly (FIFO)');
    is($queue->Count(), 0, 'Queue empty after all items dequeued');
    
    # Test 11: Dequeue after queue becomes empty
    eval { $queue->Dequeue(); };
    like($@, qr/InvalidOperationException|Queue is empty/, 'Dequeue from emptied queue throws exception');
}

#===========================================
# PEEK TESTS
#===========================================

sub test_peek {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 12: Peek on empty queue throws exception
    eval { $queue->Peek(); };
    like($@, qr/InvalidOperationException|Queue is empty/, 'Peek on empty queue throws exception');
    
    # Test 13: Peek returns front item without removing it
    $queue->Enqueue("first");
    $queue->Enqueue("second");
    
    my $peeked = $queue->Peek();
    is($peeked, "first", 'Peek returns front item');
    is($queue->Count(), 2, 'Peek does not change count');
    
    # Test 14: Peek consistency
    my $peeked2 = $queue->Peek();
    is($peeked2, "first", 'Peek returns same item consistently');
    
    # Test 15: Peek after dequeue
    $queue->Dequeue();
    my $peeked3 = $queue->Peek();
    is($peeked3, "second", 'Peek returns correct item after dequeue');
    
    # Test 16: Peek on single-item queue
    $queue->Dequeue(); # Remove "second"
    $queue->Enqueue("only");
    my $peeked4 = $queue->Peek();
    is($peeked4, "only", 'Peek works on single-item queue');
}

#===========================================
# CLEAR TESTS
#===========================================

sub test_clear {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 17: Clear empty queue
    $queue->Clear();
    is($queue->Count(), 0, 'Clear on empty queue works');
    
    # Test 18: Clear populated queue
    $queue->Enqueue("item1");
    $queue->Enqueue("item2");
    $queue->Enqueue("item3");
    is($queue->Count(), 3, 'Queue has items before clear');
    
    $queue->Clear();
    is($queue->Count(), 0, 'Queue is empty after clear');
    
    # Test 19: Operations after clear
    eval { $queue->Peek(); };
    like($@, qr/InvalidOperationException|Queue is empty/, 'Peek throws exception after clear');
    
    eval { $queue->Dequeue(); };
    like($@, qr/InvalidOperationException|Queue is empty/, 'Dequeue throws exception after clear');
    
    # Test 20: Can enqueue after clear
    $queue->Enqueue("after_clear");
    is($queue->Count(), 1, 'Can enqueue after clear');
    is($queue->Peek(), "after_clear", 'Item enqueued after clear works correctly');
}

#===========================================
# CONTAINS TESTS
#===========================================

sub test_contains {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 21: Contains on empty queue
    ok(!$queue->Contains("anything"), 'Empty queue does not contain anything');
    
    # Test 22: Contains existing item
    $queue->Enqueue("apple");
    $queue->Enqueue("banana");
    $queue->Enqueue("cherry");
    
    ok($queue->Contains("banana"), 'Queue contains existing item');
    ok($queue->Contains("apple"), 'Queue contains first item');
    ok($queue->Contains("cherry"), 'Queue contains last item');
    
    # Test 23: Contains non-existing item
    ok(!$queue->Contains("grape"), 'Queue does not contain non-existing item');
    
    # Test 24: Contains null value
    $queue->Enqueue(undef);
    ok($queue->Contains(undef), 'Queue contains null value');
    
    # Test 25: Contains after dequeue
    $queue->Dequeue(); # Remove "apple"
    ok(!$queue->Contains("apple"), 'Queue does not contain dequeued item');
    ok($queue->Contains("banana"), 'Queue still contains remaining items');
}

#===========================================
# TOARRAY TESTS
#===========================================

sub test_toArray {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 26: ToArray on empty queue
    my $empty_array = $queue->ToArray();
    is(scalar(@$empty_array), 0, 'ToArray on empty queue returns empty array');
    
    # Test 27: ToArray with items in queue order
    $queue->Enqueue("first");
    $queue->Enqueue("second");
    $queue->Enqueue("third");
    
    my $array = $queue->ToArray();
    is(scalar(@$array), 3, 'ToArray returns correct size array');
    is($array->[0], "first", 'ToArray preserves queue order - first item');
    is($array->[1], "second", 'ToArray preserves queue order - second item');
    is($array->[2], "third", 'ToArray preserves queue order - third item');
    
    # Test 28: ToArray does not modify queue
    is($queue->Count(), 3, 'ToArray does not change queue count');
    is($queue->Peek(), "first", 'ToArray does not change queue state');
    
    # Test 29: Array independence
    $array->[0] = "modified";
    is($queue->Peek(), "first", 'Modifying ToArray result does not affect queue');
}

#===========================================
# TRIMEXCESS TESTS
#===========================================

sub test_trimExcess {
    my $queue = System::Collections::Generic::Queue->new(100); # Large initial capacity
    
    # Test 30: TrimExcess on empty queue
    $queue->TrimExcess();
    is($queue->Count(), 0, 'TrimExcess preserves count on empty queue');
    
    # Test 31: TrimExcess with items
    $queue->Enqueue("item1");
    $queue->Enqueue("item2");
    is($queue->Count(), 2, 'Queue has items before TrimExcess');
    
    $queue->TrimExcess();
    is($queue->Count(), 2, 'TrimExcess preserves count');
    is($queue->Peek(), "item1", 'TrimExcess preserves queue state');
    
    # Test 32: Operations after TrimExcess
    $queue->Enqueue("item3");
    is($queue->Count(), 3, 'Can enqueue after TrimExcess');
    
    my $dequeued = $queue->Dequeue();
    is($dequeued, "item1", 'Can dequeue after TrimExcess');
}

#===========================================
# ENUMERATOR TESTS
#===========================================

sub test_enumerator {
    my $queue = System::Collections::Generic::Queue->new();
    $queue->Enqueue("a");
    $queue->Enqueue("b");
    $queue->Enqueue("c");
    
    # Test 33: GetEnumerator returns enumerator
    my $enumerator = $queue->GetEnumerator();
    ok(defined($enumerator), 'GetEnumerator returns defined enumerator');
    can_ok($enumerator, 'MoveNext');
    can_ok($enumerator, 'Current');
    
    # Test 34: Enumeration in queue order
    my @enumerated;
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    
    is(scalar(@enumerated), 3, 'Enumerator visits all items');
    is_deeply(\@enumerated, ["a", "b", "c"], 'Enumerator preserves queue order');
    
    # Test 35: Enumerator on empty queue
    my $empty_queue = System::Collections::Generic::Queue->new();
    my $empty_enum = $empty_queue->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'Enumerator on empty queue returns false for MoveNext');
}

#===========================================
# NULL REFERENCE EXCEPTION TESTS
#===========================================

sub test_null_reference_exceptions {
    my $null_queue = undef;
    
    # Test 36: Count on null reference
    eval { $null_queue->Count(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Count throws on null reference');
    
    # Test 37: Enqueue on null reference
    eval { $null_queue->Enqueue("item"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Enqueue throws on null reference');
    
    # Test 38: Dequeue on null reference
    eval { $null_queue->Dequeue(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Dequeue throws on null reference');
    
    # Test 39: Peek on null reference
    eval { $null_queue->Peek(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Peek throws on null reference');
    
    # Test 40: Clear on null reference
    eval { $null_queue->Clear(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Clear throws on null reference');
    
    # Test 41: Contains on null reference
    eval { $null_queue->Contains("item"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Contains throws on null reference');
    
    # Test 42: ToArray on null reference
    eval { $null_queue->ToArray(); };
    like($@, qr/NullReferenceException|Can't call method/, 'ToArray throws on null reference');
    
    # Test 43: GetEnumerator on null reference
    eval { $null_queue->GetEnumerator(); };
    like($@, qr/NullReferenceException|Can't call method/, 'GetEnumerator throws on null reference');
}

#===========================================
# MIXED OPERATIONS TESTS
#===========================================

sub test_mixed_operations {
    my $queue = System::Collections::Generic::Queue->new();
    
    # Test 44: Interleaved enqueue and dequeue
    $queue->Enqueue("a");
    $queue->Enqueue("b");
    
    my $first = $queue->Dequeue();
    is($first, "a", 'First dequeue in mixed operations');
    
    $queue->Enqueue("c");
    is($queue->Count(), 2, 'Count correct after mixed operations');
    
    my $peek_result = $queue->Peek();
    is($peek_result, "b", 'Peek correct after mixed operations');
    
    # Test 45: Multiple cycles of fill and drain
    for my $cycle (1..3) {
        # Fill
        for my $i (1..5) {
            $queue->Enqueue("cycle${cycle}_item${i}");
        }
        
        # Partial drain
        for my $i (1..3) {
            my $item = $queue->Dequeue();
            like($item, qr/cycle${cycle}_item/, 'Dequeued item from correct cycle');
        }
    }
    
    # Should have some items remaining from all cycles
    ok($queue->Count() > 0, 'Queue has remaining items after cycles');
}

#===========================================
# STRESS TESTS
#===========================================

sub test_stress_conditions {
    # Test 46: Large number of items
    my $queue = System::Collections::Generic::Queue->new();
    
    # Enqueue many items
    for my $i (1..1000) {
        $queue->Enqueue("item_$i");
    }
    is($queue->Count(), 1000, 'Can handle large number of items');
    
    # Verify order is maintained
    my $first_item = $queue->Peek();
    is($first_item, "item_1", 'Order maintained with large number of items');
    
    # Dequeue all items and verify order
    for my $i (1..1000) {
        my $item = $queue->Dequeue();
        is($item, "item_$i", "Item $i dequeued in correct order");
    }
    is($queue->Count(), 0, 'All items dequeued successfully');
    
    # Test 47: Large data items
    my $large_data = "x" x 10000;
    $queue->Enqueue($large_data);
    my $retrieved = $queue->Dequeue();
    is(length($retrieved), 10000, 'Can handle large data items');
}

#===========================================
# EDGE CASES
#===========================================

sub test_edge_cases {
    # Test 48: Queue with only null values
    my $queue = System::Collections::Generic::Queue->new();
    $queue->Enqueue(undef);
    $queue->Enqueue(undef);
    $queue->Enqueue(undef);
    
    is($queue->Count(), 3, 'Queue can contain multiple null values');
    ok($queue->Contains(undef), 'Queue contains null values');
    
    my $null_item = $queue->Dequeue();
    ok(!defined($null_item), 'Can dequeue null value');
    
    # Test 49: Mixed null and non-null values
    $queue->Clear();
    $queue->Enqueue("real");
    $queue->Enqueue(undef);
    $queue->Enqueue("also_real");
    
    my $array = $queue->ToArray();
    is($array->[0], "real", 'ToArray handles mixed null/non-null - first');
    ok(!defined($array->[1]), 'ToArray handles mixed null/non-null - null');
    is($array->[2], "also_real", 'ToArray handles mixed null/non-null - last');
    
    # Test 50: Empty string handling
    $queue->Clear();
    $queue->Enqueue("");
    $queue->Enqueue("   ");
    
    ok($queue->Contains(""), 'Queue contains empty string');
    ok($queue->Contains("   "), 'Queue contains whitespace string');
    
    my $empty_str = $queue->Dequeue();
    is($empty_str, "", 'Can dequeue empty string');
    
    my $space_str = $queue->Dequeue();
    is($space_str, "   ", 'Can dequeue whitespace string');
}

# Run all tests
test_construction();
test_enqueue_and_count();
test_dequeue();
test_peek();
test_clear();
test_contains();
test_toArray();
test_trimExcess();
test_enumerator();
test_null_reference_exceptions();
test_mixed_operations();
test_stress_conditions();
test_edge_cases();

done_testing();