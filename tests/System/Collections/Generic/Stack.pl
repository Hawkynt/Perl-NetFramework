#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Generic::Stack');
}

#===========================================
# CONSTRUCTION TESTS
#===========================================

sub test_construction {
    # Test 1: Default constructor
    my $stack1 = System::Collections::Generic::Stack->new();
    isa_ok($stack1, 'System::Collections::Generic::Stack', 'Default constructor creates Stack');
    is($stack1->Count(), 0, 'Default constructor creates empty stack');
    
    # Test 2: Constructor with capacity
    my $stack2 = System::Collections::Generic::Stack->new(20);
    isa_ok($stack2, 'System::Collections::Generic::Stack', 'Constructor with capacity creates Stack');
    is($stack2->Count(), 0, 'Constructor with capacity creates empty stack');
    
    # Test 3: Constructor with zero capacity
    my $stack3 = System::Collections::Generic::Stack->new(0);
    isa_ok($stack3, 'System::Collections::Generic::Stack', 'Constructor with zero capacity works');
    is($stack3->Count(), 0, 'Zero capacity stack is empty');
}

#===========================================
# PUSH AND COUNT TESTS
#===========================================

sub test_push_and_count {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 4: Count on empty stack
    is($stack->Count(), 0, 'Empty stack has count 0');
    
    # Test 5: Single push
    $stack->Push("first");
    is($stack->Count(), 1, 'Count increases after push');
    
    # Test 6: Multiple pushes
    $stack->Push("second");
    $stack->Push("third");
    is($stack->Count(), 3, 'Count correct after multiple pushes');
    
    # Test 7: Push null value
    $stack->Push(undef);
    is($stack->Count(), 4, 'Can push null value');
    
    # Test 8: Push different types
    $stack->Push(42);
    $stack->Push(3.14);
    is($stack->Count(), 6, 'Can push different data types');
}

#===========================================
# POP TESTS
#===========================================

sub test_pop {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 9: Pop from empty stack throws exception
    eval { $stack->Pop(); };
    like($@, qr/InvalidOperationException|Stack is empty/, 'Pop from empty stack throws exception');
    
    # Test 10: LIFO behavior (Last In, First Out)
    $stack->Push("first");
    $stack->Push("second");
    $stack->Push("third");
    
    my $item1 = $stack->Pop();
    is($item1, "third", 'Last item popped correctly (LIFO)');
    is($stack->Count(), 2, 'Count decreases after pop');
    
    my $item2 = $stack->Pop();
    is($item2, "second", 'Second-to-last item popped correctly (LIFO)');
    is($stack->Count(), 1, 'Count correct after second pop');
    
    my $item3 = $stack->Pop();
    is($item3, "first", 'First item popped correctly (LIFO)');
    is($stack->Count(), 0, 'Stack empty after all items popped');
    
    # Test 11: Pop after stack becomes empty
    eval { $stack->Pop(); };
    like($@, qr/InvalidOperationException|Stack is empty/, 'Pop from emptied stack throws exception');
}

#===========================================
# PEEK TESTS
#===========================================

sub test_peek {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 12: Peek on empty stack throws exception
    eval { $stack->Peek(); };
    like($@, qr/InvalidOperationException|Stack is empty/, 'Peek on empty stack throws exception');
    
    # Test 13: Peek returns top item without removing it
    $stack->Push("first");
    $stack->Push("second");
    
    my $peeked = $stack->Peek();
    is($peeked, "second", 'Peek returns top item');
    is($stack->Count(), 2, 'Peek does not change count');
    
    # Test 14: Peek consistency
    my $peeked2 = $stack->Peek();
    is($peeked2, "second", 'Peek returns same item consistently');
    
    # Test 15: Peek after pop
    $stack->Pop();
    my $peeked3 = $stack->Peek();
    is($peeked3, "first", 'Peek returns correct item after pop');
    
    # Test 16: Peek on single-item stack
    $stack->Pop(); # Remove "first"
    $stack->Push("only");
    my $peeked4 = $stack->Peek();
    is($peeked4, "only", 'Peek works on single-item stack');
}

#===========================================
# CLEAR TESTS
#===========================================

sub test_clear {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 17: Clear empty stack
    $stack->Clear();
    is($stack->Count(), 0, 'Clear on empty stack works');
    
    # Test 18: Clear populated stack
    $stack->Push("item1");
    $stack->Push("item2");
    $stack->Push("item3");
    is($stack->Count(), 3, 'Stack has items before clear');
    
    $stack->Clear();
    is($stack->Count(), 0, 'Stack is empty after clear');
    
    # Test 19: Operations after clear
    eval { $stack->Peek(); };
    like($@, qr/InvalidOperationException|Stack is empty/, 'Peek throws exception after clear');
    
    eval { $stack->Pop(); };
    like($@, qr/InvalidOperationException|Stack is empty/, 'Pop throws exception after clear');
    
    # Test 20: Can push after clear
    $stack->Push("after_clear");
    is($stack->Count(), 1, 'Can push after clear');
    is($stack->Peek(), "after_clear", 'Item pushed after clear works correctly');
}

#===========================================
# CONTAINS TESTS
#===========================================

sub test_contains {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 21: Contains on empty stack
    ok(!$stack->Contains("anything"), 'Empty stack does not contain anything');
    
    # Test 22: Contains existing item
    $stack->Push("apple");
    $stack->Push("banana");
    $stack->Push("cherry");
    
    ok($stack->Contains("banana"), 'Stack contains existing item');
    ok($stack->Contains("apple"), 'Stack contains bottom item');
    ok($stack->Contains("cherry"), 'Stack contains top item');
    
    # Test 23: Contains non-existing item
    ok(!$stack->Contains("grape"), 'Stack does not contain non-existing item');
    
    # Test 24: Contains null value
    $stack->Push(undef);
    ok($stack->Contains(undef), 'Stack contains null value');
    
    # Test 25: Contains after pop
    $stack->Pop(); # Remove null
    $stack->Pop(); # Remove "cherry"
    ok(!$stack->Contains("cherry"), 'Stack does not contain popped item');
    ok($stack->Contains("banana"), 'Stack still contains remaining items');
}

#===========================================
# TOARRAY TESTS
#===========================================

sub test_toArray {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 26: ToArray on empty stack
    my $empty_array = $stack->ToArray();
    is(scalar(@$empty_array), 0, 'ToArray on empty stack returns empty array');
    
    # Test 27: ToArray with items in stack order (top to bottom)
    $stack->Push("first");
    $stack->Push("second");
    $stack->Push("third");
    
    my $array = $stack->ToArray();
    is(scalar(@$array), 3, 'ToArray returns correct size array');
    is($array->[0], "third", 'ToArray preserves stack order - top item first');
    is($array->[1], "second", 'ToArray preserves stack order - middle item');
    is($array->[2], "first", 'ToArray preserves stack order - bottom item last');
    
    # Test 28: ToArray does not modify stack
    is($stack->Count(), 3, 'ToArray does not change stack count');
    is($stack->Peek(), "third", 'ToArray does not change stack state');
    
    # Test 29: Array independence
    $array->[0] = "modified";
    is($stack->Peek(), "third", 'Modifying ToArray result does not affect stack');
}

#===========================================
# TRIMEXCESS TESTS
#===========================================

sub test_trimExcess {
    my $stack = System::Collections::Generic::Stack->new(100); # Large initial capacity
    
    # Test 30: TrimExcess on empty stack
    $stack->TrimExcess();
    is($stack->Count(), 0, 'TrimExcess preserves count on empty stack');
    
    # Test 31: TrimExcess with items
    $stack->Push("item1");
    $stack->Push("item2");
    is($stack->Count(), 2, 'Stack has items before TrimExcess');
    
    $stack->TrimExcess();
    is($stack->Count(), 2, 'TrimExcess preserves count');
    is($stack->Peek(), "item2", 'TrimExcess preserves stack state');
    
    # Test 32: Operations after TrimExcess
    $stack->Push("item3");
    is($stack->Count(), 3, 'Can push after TrimExcess');
    
    my $popped = $stack->Pop();
    is($popped, "item3", 'Can pop after TrimExcess');
}

#===========================================
# ENUMERATOR TESTS
#===========================================

sub test_enumerator {
    my $stack = System::Collections::Generic::Stack->new();
    $stack->Push("a");
    $stack->Push("b");
    $stack->Push("c");
    
    # Test 33: GetEnumerator returns enumerator
    my $enumerator = $stack->GetEnumerator();
    ok(defined($enumerator), 'GetEnumerator returns defined enumerator');
    can_ok($enumerator, 'MoveNext');
    can_ok($enumerator, 'Current');
    
    # Test 34: Enumeration in stack order (top to bottom)
    my @enumerated;
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    
    is(scalar(@enumerated), 3, 'Enumerator visits all items');
    is_deeply(\@enumerated, ["c", "b", "a"], 'Enumerator preserves stack order (top to bottom)');
    
    # Test 35: Enumerator on empty stack
    my $empty_stack = System::Collections::Generic::Stack->new();
    my $empty_enum = $empty_stack->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'Enumerator on empty stack returns false for MoveNext');
}

#===========================================
# NULL REFERENCE EXCEPTION TESTS
#===========================================

sub test_null_reference_exceptions {
    my $null_stack = undef;
    
    # Test 36: Count on null reference
    eval { $null_stack->Count(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Count throws on null reference');
    
    # Test 37: Push on null reference
    eval { $null_stack->Push("item"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Push throws on null reference');
    
    # Test 38: Pop on null reference
    eval { $null_stack->Pop(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Pop throws on null reference');
    
    # Test 39: Peek on null reference
    eval { $null_stack->Peek(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Peek throws on null reference');
    
    # Test 40: Clear on null reference
    eval { $null_stack->Clear(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Clear throws on null reference');
    
    # Test 41: Contains on null reference
    eval { $null_stack->Contains("item"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Contains throws on null reference');
    
    # Test 42: ToArray on null reference
    eval { $null_stack->ToArray(); };
    like($@, qr/NullReferenceException|Can't call method/, 'ToArray throws on null reference');
    
    # Test 43: GetEnumerator on null reference
    eval { $null_stack->GetEnumerator(); };
    like($@, qr/NullReferenceException|Can't call method/, 'GetEnumerator throws on null reference');
}

#===========================================
# MIXED OPERATIONS TESTS
#===========================================

sub test_mixed_operations {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 44: Interleaved push and pop
    $stack->Push("a");
    $stack->Push("b");
    
    my $first_pop = $stack->Pop();
    is($first_pop, "b", 'First pop in mixed operations (LIFO)');
    
    $stack->Push("c");
    is($stack->Count(), 2, 'Count correct after mixed operations');
    
    my $peek_result = $stack->Peek();
    is($peek_result, "c", 'Peek correct after mixed operations');
    
    # Test 45: Multiple cycles of fill and drain
    for my $cycle (1..3) {
        # Fill
        for my $i (1..5) {
            $stack->Push("cycle${cycle}_item${i}");
        }
        
        # Partial drain (pop 3 out of 5)
        for my $i (1..3) {
            my $item = $stack->Pop();
            like($item, qr/cycle${cycle}_item/, 'Popped item from correct cycle');
        }
    }
    
    # Should have some items remaining from all cycles
    ok($stack->Count() > 0, 'Stack has remaining items after cycles');
}

#===========================================
# STRESS TESTS
#===========================================

sub test_stress_conditions {
    # Test 46: Large number of items
    my $stack = System::Collections::Generic::Stack->new();
    
    # Push many items
    for my $i (1..1000) {
        $stack->Push("item_$i");
    }
    is($stack->Count(), 1000, 'Can handle large number of items');
    
    # Verify LIFO order is maintained
    my $top_item = $stack->Peek();
    is($top_item, "item_1000", 'Order maintained with large number of items (LIFO)');
    
    # Pop all items and verify order
    for my $i (reverse 1..1000) {
        my $item = $stack->Pop();
        is($item, "item_$i", "Item $i popped in correct LIFO order");
    }
    is($stack->Count(), 0, 'All items popped successfully');
    
    # Test 47: Large data items
    my $large_data = "x" x 10000;
    $stack->Push($large_data);
    my $retrieved = $stack->Pop();
    is(length($retrieved), 10000, 'Can handle large data items');
}

#===========================================
# EDGE CASES
#===========================================

sub test_edge_cases {
    # Test 48: Stack with only null values
    my $stack = System::Collections::Generic::Stack->new();
    $stack->Push(undef);
    $stack->Push(undef);
    $stack->Push(undef);
    
    is($stack->Count(), 3, 'Stack can contain multiple null values');
    ok($stack->Contains(undef), 'Stack contains null values');
    
    my $null_item = $stack->Pop();
    ok(!defined($null_item), 'Can pop null value');
    
    # Test 49: Mixed null and non-null values
    $stack->Clear();
    $stack->Push("first");
    $stack->Push(undef);
    $stack->Push("last");
    
    my $array = $stack->ToArray();
    is($array->[0], "last", 'ToArray handles mixed null/non-null - top');
    ok(!defined($array->[1]), 'ToArray handles mixed null/non-null - null');
    is($array->[2], "first", 'ToArray handles mixed null/non-null - bottom');
    
    # Test 50: Empty string handling
    $stack->Clear();
    $stack->Push("");
    $stack->Push("   ");
    
    ok($stack->Contains(""), 'Stack contains empty string');
    ok($stack->Contains("   "), 'Stack contains whitespace string');
    
    my $space_str = $stack->Pop();
    is($space_str, "   ", 'Can pop whitespace string');
    
    my $empty_str = $stack->Pop();
    is($empty_str, "", 'Can pop empty string');
}

#===========================================
# COMPARE WITH QUEUE (LIFO vs FIFO)
#===========================================

sub test_stack_vs_queue_behavior {
    my $stack = System::Collections::Generic::Stack->new();
    
    # Test 51: Verify LIFO behavior vs FIFO
    $stack->Push("first_in");
    $stack->Push("second_in");
    $stack->Push("third_in");
    
    # In a stack (LIFO), the last item pushed should be first to come out
    my $first_out = $stack->Pop();
    is($first_out, "third_in", 'Stack follows LIFO: last in, first out');
    
    my $second_out = $stack->Pop();
    is($second_out, "second_in", 'Stack LIFO continues correctly');
    
    my $third_out = $stack->Pop();
    is($third_out, "first_in", 'Stack LIFO completes correctly');
    
    # Test 52: Peek always shows the "top" (most recently added)
    $stack->Push("bottom");
    $stack->Push("middle");
    $stack->Push("top");
    
    is($stack->Peek(), "top", 'Peek shows most recently pushed item');
    $stack->Pop();
    is($stack->Peek(), "middle", 'Peek updates after pop to show new top');
}

# Run all tests
test_construction();
test_push_and_count();
test_pop();
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
test_stack_vs_queue_behavior();

done_testing();