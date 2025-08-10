#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Generic::List');
}

#===========================================
# CONSTRUCTION TESTS
#===========================================

sub test_construction {
    # Test 1: Default constructor
    my $list1 = System::Collections::Generic::List->new();
    isa_ok($list1, 'System::Collections::Generic::List', 'Default constructor creates List');
    is($list1->Count(), 0, 'Default constructor creates empty list');
    
    # Test 2: Constructor with initial items
    my $list2 = System::Collections::Generic::List->new("a", "b", "c");
    isa_ok($list2, 'System::Collections::Generic::List', 'Constructor with items creates List');
    is($list2->Count(), 3, 'Constructor with items has correct count');
    is($list2->Item(0), "a", 'Constructor items stored correctly');
    is($list2->Item(2), "c", 'Constructor items stored correctly');
    
    # Test 3: Constructor with empty list of items
    my $list3 = System::Collections::Generic::List->new();
    is($list3->Count(), 0, 'Constructor with no items creates empty list');
}

#===========================================
# COUNT AND CAPACITY TESTS
#===========================================

sub test_count_and_capacity {
    my $list = System::Collections::Generic::List->new();
    
    # Test 4: Initial count and capacity
    is($list->Count(), 0, 'Empty list has count 0');
    ok($list->Capacity() >= 0, 'Capacity is non-negative');
    
    # Test 5: Count increases with Add
    $list->Add("item1");
    is($list->Count(), 1, 'Count increases after Add');
    
    $list->Add("item2");
    $list->Add("item3");
    is($list->Count(), 3, 'Count correct after multiple Adds');
    
    # Test 6: Capacity management
    my $initial_capacity = $list->Capacity();
    $list->Capacity($initial_capacity + 10);
    is($list->Capacity(), $initial_capacity + 10, 'Can set capacity');
    
    # Test 7: Capacity cannot be less than Count
    eval { $list->Capacity(1); }; # List has 3 items, capacity can't be 1
    like($@, qr/ArgumentOutOfRangeException|cannot be less than Count/, 'Capacity less than Count throws exception');
}

#===========================================
# ADD TESTS
#===========================================

sub test_add {
    my $list = System::Collections::Generic::List->new();
    
    # Test 8: Add single item
    $list->Add("first");
    is($list->Count(), 1, 'Add increases count');
    is($list->Item(0), "first", 'Added item accessible via Item');
    
    # Test 9: Add multiple items
    $list->Add("second");
    $list->Add("third");
    is($list->Count(), 3, 'Multiple adds work');
    is($list->Item(1), "second", 'Second item correct');
    is($list->Item(2), "third", 'Third item correct');
    
    # Test 10: Add null value
    $list->Add(undef);
    is($list->Count(), 4, 'Can add null value');
    ok(!defined($list->Item(3)), 'Null value stored correctly');
    
    # Test 11: Add different types
    $list->Add(42);
    $list->Add(3.14);
    is($list->Count(), 6, 'Can add different types');
    is($list->Item(4), 42, 'Integer added correctly');
    is($list->Item(5), 3.14, 'Float added correctly');
}

#===========================================
# ITEM INDEXER TESTS
#===========================================

sub test_item_indexer {
    my $list = System::Collections::Generic::List->new("a", "b", "c");
    
    # Test 12: Item getter
    is($list->Item(0), "a", 'Item getter works for first element');
    is($list->Item(1), "b", 'Item getter works for middle element');
    is($list->Item(2), "c", 'Item getter works for last element');
    
    # Test 13: Item setter
    $list->Item(1, "modified");
    is($list->Item(1), "modified", 'Item setter modifies element');
    is($list->Count(), 3, 'Item setter does not change count');
    
    # Test 14: Item with invalid index
    eval { $list->Item(-1); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Negative index throws exception');
    
    eval { $list->Item(10); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Index beyond bounds throws exception');
    
    eval { $list->Item(-1, "value"); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Setter with negative index throws exception');
    
    eval { $list->Item(10, "value"); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Setter with index beyond bounds throws exception');
}

#===========================================
# INSERT TESTS
#===========================================

sub test_insert {
    my $list = System::Collections::Generic::List->new("a", "c");
    
    # Test 15: Insert in middle
    $list->Insert(1, "b");
    is($list->Count(), 3, 'Insert increases count');
    is($list->Item(0), "a", 'Insert preserves existing items - before');
    is($list->Item(1), "b", 'Insert places item at correct index');
    is($list->Item(2), "c", 'Insert preserves existing items - after');
    
    # Test 16: Insert at beginning
    $list->Insert(0, "first");
    is($list->Count(), 4, 'Insert at beginning increases count');
    is($list->Item(0), "first", 'Insert at beginning places item correctly');
    is($list->Item(1), "a", 'Insert at beginning shifts other items');
    
    # Test 17: Insert at end
    $list->Insert($list->Count(), "last");
    is($list->Count(), 5, 'Insert at end increases count');
    is($list->Item(4), "last", 'Insert at end places item correctly');
    
    # Test 18: Insert with invalid index
    eval { $list->Insert(-1, "invalid"); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Insert with negative index throws exception');
    
    eval { $list->Insert($list->Count() + 1, "invalid"); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Insert beyond valid range throws exception');
}

#===========================================
# REMOVE TESTS
#===========================================

sub test_remove {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "b");
    
    # Test 19: Remove existing item (removes first occurrence)
    my $removed = $list->Remove("b");
    ok($removed, 'Remove returns true for existing item');
    is($list->Count(), 3, 'Remove decreases count');
    is($list->Item(1), "c", 'Remove shifts remaining items');
    is($list->Item(2), "b", 'Remove only removes first occurrence');
    
    # Test 20: Remove non-existing item
    my $not_removed = $list->Remove("z");
    ok(!$not_removed, 'Remove returns false for non-existing item');
    is($list->Count(), 3, 'Remove of non-existing item does not change count');
    
    # Test 21: Remove null value
    $list->Add(undef);
    my $null_removed = $list->Remove(undef);
    ok($null_removed, 'Can remove null value');
    is($list->Count(), 3, 'Remove null decreases count');
}

#===========================================
# REMOVEAT TESTS
#===========================================

sub test_removeAt {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "d");
    
    # Test 22: RemoveAt valid index
    $list->RemoveAt(1); # Remove "b"
    is($list->Count(), 3, 'RemoveAt decreases count');
    is($list->Item(0), "a", 'RemoveAt preserves items before index');
    is($list->Item(1), "c", 'RemoveAt shifts items after index');
    is($list->Item(2), "d", 'RemoveAt shifts all items correctly');
    
    # Test 23: RemoveAt first element
    $list->RemoveAt(0);
    is($list->Count(), 2, 'RemoveAt first element decreases count');
    is($list->Item(0), "c", 'RemoveAt first element shifts remaining items');
    
    # Test 24: RemoveAt last element
    $list->RemoveAt($list->Count() - 1);
    is($list->Count(), 1, 'RemoveAt last element decreases count');
    is($list->Item(0), "c", 'RemoveAt last element leaves correct item');
    
    # Test 25: RemoveAt with invalid index
    eval { $list->RemoveAt(-1); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'RemoveAt negative index throws exception');
    
    eval { $list->RemoveAt(10); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'RemoveAt index beyond bounds throws exception');
}

#===========================================
# REMOVERANGE TESTS
#===========================================

sub test_removeRange {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "d", "e");
    
    # Test 26: RemoveRange from middle
    $list->RemoveRange(1, 2); # Remove "b", "c"
    is($list->Count(), 3, 'RemoveRange decreases count correctly');
    is($list->Item(0), "a", 'RemoveRange preserves items before range');
    is($list->Item(1), "d", 'RemoveRange removes items in range');
    is($list->Item(2), "e", 'RemoveRange preserves items after range');
    
    # Test 27: RemoveRange from beginning
    $list = System::Collections::Generic::List->new("a", "b", "c", "d", "e");
    $list->RemoveRange(0, 2);
    is($list->Count(), 3, 'RemoveRange from beginning decreases count');
    is($list->Item(0), "c", 'RemoveRange from beginning shifts remaining items');
    
    # Test 28: RemoveRange with invalid parameters
    eval { $list->RemoveRange(-1, 1); };
    like($@, qr/ArgumentOutOfRangeException|within bounds/, 'RemoveRange negative index throws exception');
    
    eval { $list->RemoveRange(0, -1); };
    like($@, qr/ArgumentOutOfRangeException|within bounds/, 'RemoveRange negative count throws exception');
    
    eval { $list->RemoveRange(0, $list->Count() + 1); };
    like($@, qr/ArgumentOutOfRangeException|within bounds/, 'RemoveRange count beyond bounds throws exception');
}

#===========================================
# CLEAR TESTS
#===========================================

sub test_clear {
    my $list = System::Collections::Generic::List->new("a", "b", "c");
    
    # Test 29: Clear populated list
    is($list->Count(), 3, 'List has items before clear');
    $list->Clear();
    is($list->Count(), 0, 'List is empty after clear');
    
    # Test 30: Access after clear throws exception
    eval { $list->Item(0); };
    like($@, qr/ArgumentOutOfRangeException|out of range/, 'Item access throws after clear');
    
    # Test 31: Can add after clear
    $list->Add("after_clear");
    is($list->Count(), 1, 'Can add after clear');
    is($list->Item(0), "after_clear", 'Item added after clear works');
    
    # Test 32: Clear empty list
    $list->Clear();
    $list->Clear(); # Second clear should not cause issues
    is($list->Count(), 0, 'Clear on empty list works');
}

#===========================================
# CONTAINS TESTS
#===========================================

sub test_contains {
    my $list = System::Collections::Generic::List->new("apple", "banana", "cherry");
    
    # Test 33: Contains existing item
    ok($list->Contains("banana"), 'List contains existing item');
    ok($list->Contains("apple"), 'List contains first item');
    ok($list->Contains("cherry"), 'List contains last item');
    
    # Test 34: Contains non-existing item
    ok(!$list->Contains("grape"), 'List does not contain non-existing item');
    
    # Test 35: Contains null value
    $list->Add(undef);
    ok($list->Contains(undef), 'List contains null value');
    
    # Test 36: Contains case sensitivity
    ok(!$list->Contains("Apple"), 'Contains is case sensitive');
}

#===========================================
# INDEXOF TESTS
#===========================================

sub test_indexOf {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "b", "d");
    
    # Test 37: IndexOf existing item (first occurrence)
    is($list->IndexOf("b"), 1, 'IndexOf returns first occurrence');
    is($list->IndexOf("a"), 0, 'IndexOf returns correct index for first item');
    is($list->IndexOf("d"), 4, 'IndexOf returns correct index for last item');
    
    # Test 38: IndexOf non-existing item
    is($list->IndexOf("z"), -1, 'IndexOf returns -1 for non-existing item');
    
    # Test 39: IndexOf with start index
    is($list->IndexOf("b", 2), 3, 'IndexOf with start index finds later occurrence');
    is($list->IndexOf("a", 1), -1, 'IndexOf with start index does not find earlier item');
    
    # Test 40: IndexOf with start index and count
    is($list->IndexOf("b", 0, 2), 1, 'IndexOf with count finds item within range');
    is($list->IndexOf("b", 0, 1), -1, 'IndexOf with count does not find item outside range');
    
    # Test 41: IndexOf null value
    $list->Add(undef);
    is($list->IndexOf(undef), 5, 'IndexOf finds null value');
}

#===========================================
# LASTINDEXOF TESTS
#===========================================

sub test_lastIndexOf {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "b", "d");
    
    # Test 42: LastIndexOf existing item (last occurrence)
    is($list->LastIndexOf("b"), 3, 'LastIndexOf returns last occurrence');
    is($list->LastIndexOf("a"), 0, 'LastIndexOf returns correct index for unique item');
    
    # Test 43: LastIndexOf non-existing item
    is($list->LastIndexOf("z"), -1, 'LastIndexOf returns -1 for non-existing item');
    
    # Test 44: LastIndexOf with start index
    is($list->LastIndexOf("b", 2), 1, 'LastIndexOf with start index finds earlier occurrence');
    is($list->LastIndexOf("d", 3), -1, 'LastIndexOf with start index does not find later item');
    
    # Test 45: LastIndexOf null value
    $list->Add(undef);
    $list->Add(undef);
    is($list->LastIndexOf(undef), 6, 'LastIndexOf finds last null value');
}

#===========================================
# ADDRANGE TESTS
#===========================================

sub test_addRange {
    my $list = System::Collections::Generic::List->new("a", "b");
    
    # Test 46: AddRange with array
    my @array = ("c", "d", "e");
    $list->AddRange(\@array);
    is($list->Count(), 5, 'AddRange with array increases count');
    is($list->Item(2), "c", 'AddRange items added correctly');
    is($list->Item(4), "e", 'AddRange items added in order');
    
    # Test 47: AddRange with another List
    my $other_list = System::Collections::Generic::List->new("f", "g");
    $list->AddRange($other_list);
    is($list->Count(), 7, 'AddRange with List increases count');
    is($list->Item(5), "f", 'AddRange from List works');
    
    # Test 48: AddRange with null collection throws exception
    eval { $list->AddRange(undef); };
    like($@, qr/ArgumentNullException|collection/, 'AddRange with null throws exception');
}

#===========================================
# REVERSE TESTS
#===========================================

sub test_reverse {
    my $list = System::Collections::Generic::List->new("a", "b", "c", "d", "e");
    
    # Test 49: Reverse entire list
    $list->Reverse();
    is($list->Count(), 5, 'Reverse does not change count');
    is($list->Item(0), "e", 'Reverse reverses order - first item');
    is($list->Item(2), "c", 'Reverse reverses order - middle item');
    is($list->Item(4), "a", 'Reverse reverses order - last item');
    
    # Test 50: Reverse portion of list
    $list = System::Collections::Generic::List->new("a", "b", "c", "d", "e");
    $list->Reverse(1, 3); # Reverse "b", "c", "d"
    is($list->Item(0), "a", 'Partial reverse preserves items outside range - before');
    is($list->Item(1), "d", 'Partial reverse reverses items in range');
    is($list->Item(2), "c", 'Partial reverse reverses items in range');
    is($list->Item(3), "b", 'Partial reverse reverses items in range');
    is($list->Item(4), "e", 'Partial reverse preserves items outside range - after');
}

#===========================================
# SORT TESTS
#===========================================

sub test_sort {
    my $list = System::Collections::Generic::List->new("c", "a", "d", "b");
    
    # Test 51: Sort without comparer (default sort)
    $list->Sort();
    is($list->Count(), 4, 'Sort does not change count');
    is($list->Item(0), "a", 'Sort arranges items correctly');
    is($list->Item(1), "b", 'Sort arranges items correctly');
    is($list->Item(2), "c", 'Sort arranges items correctly');
    is($list->Item(3), "d", 'Sort arranges items correctly');
    
    # Test 52: Sort with custom comparer
    my $reverse_comparer = sub { return $_[1] cmp $_[0]; }; # Reverse order
    $list->Sort($reverse_comparer);
    is($list->Item(0), "d", 'Sort with comparer works - reverse order');
    is($list->Item(3), "a", 'Sort with comparer works - reverse order');
}

#===========================================
# TOARRAY TESTS
#===========================================

sub test_toArray {
    my $list = System::Collections::Generic::List->new("a", "b", "c");
    
    # Test 53: ToArray returns correct array
    my $array = $list->ToArray();
    is(scalar(@$array), 3, 'ToArray returns array of correct size');
    is($array->[0], "a", 'ToArray preserves order and content');
    is($array->[1], "b", 'ToArray preserves order and content');
    is($array->[2], "c", 'ToArray preserves order and content');
    
    # Test 54: ToArray on empty list
    my $empty_list = System::Collections::Generic::List->new();
    my $empty_array = $empty_list->ToArray();
    is(scalar(@$empty_array), 0, 'ToArray on empty list returns empty array');
    
    # Test 55: Array independence
    $array->[0] = "modified";
    is($list->Item(0), "a", 'Modifying ToArray result does not affect list');
}

#===========================================
# TRIMEXCESS TESTS
#===========================================

sub test_trimExcess {
    my $list = System::Collections::Generic::List->new();
    $list->Capacity(100); # Set large capacity
    $list->Add("a");
    $list->Add("b");
    
    # Test 56: TrimExcess reduces capacity to count
    $list->TrimExcess();
    is($list->Count(), 2, 'TrimExcess preserves count');
    is($list->Capacity(), 2, 'TrimExcess reduces capacity to count');
    is($list->Item(0), "a", 'TrimExcess preserves content');
    
    # Test 57: Operations work after TrimExcess
    $list->Add("c");
    is($list->Count(), 3, 'Can add after TrimExcess');
    ok($list->Capacity() >= 3, 'Capacity expands as needed after TrimExcess');
}

#===========================================
# PREDICATE METHODS TESTS
#===========================================

sub test_predicate_methods {
    my $list = System::Collections::Generic::List->new("apple", "banana", "apricot", "cherry");
    
    # Test 58: Exists
    ok($list->Exists(sub { $_[0] =~ /^ap/ }), 'Exists returns true when predicate matches');
    ok(!$list->Exists(sub { $_[0] =~ /^z/ }), 'Exists returns false when predicate does not match');
    
    # Test 59: Find
    my $found = $list->Find(sub { $_[0] =~ /^ap/ });
    is($found, "apple", 'Find returns first matching item');
    
    my $not_found = $list->Find(sub { $_[0] =~ /^z/ });
    ok(!defined($not_found), 'Find returns undef when no match');
    
    # Test 60: FindAll
    my $all_ap = $list->FindAll(sub { $_[0] =~ /^ap/ });
    is($all_ap->Count(), 2, 'FindAll returns correct count of matches');
    is($all_ap->Item(0), "apple", 'FindAll returns matching items');
    is($all_ap->Item(1), "apricot", 'FindAll returns matching items');
    
    # Test 61: FindIndex
    my $index = $list->FindIndex(sub { $_[0] =~ /^ap/ });
    is($index, 0, 'FindIndex returns index of first match');
    
    my $no_index = $list->FindIndex(sub { $_[0] =~ /^z/ });
    is($no_index, -1, 'FindIndex returns -1 when no match');
    
    # Test 62: ForEach
    my $concat = "";
    $list->ForEach(sub { $concat .= $_[0] . "|"; });
    is($concat, "apple|banana|apricot|cherry|", 'ForEach executes action on all items');
    
    # Test 63: ConvertAll
    my $lengths = $list->ConvertAll(sub { return length($_[0]); });
    is($lengths->Count(), 4, 'ConvertAll returns list of same size');
    is($lengths->Item(0), 5, 'ConvertAll transforms items correctly'); # "apple" -> 5
    is($lengths->Item(1), 6, 'ConvertAll transforms items correctly'); # "banana" -> 6
}

#===========================================
# NULL REFERENCE EXCEPTION TESTS
#===========================================

sub test_null_reference_exceptions {
    my $null_list = undef;
    
    # Test 64-80: All methods should throw on null reference
    my @methods_to_test = (
        ['Count', sub { $null_list->Count(); }],
        ['Add', sub { $null_list->Add("item"); }],
        ['Item getter', sub { $null_list->Item(0); }],
        ['Item setter', sub { $null_list->Item(0, "value"); }],
        ['Insert', sub { $null_list->Insert(0, "item"); }],
        ['Remove', sub { $null_list->Remove("item"); }],
        ['RemoveAt', sub { $null_list->RemoveAt(0); }],
        ['Clear', sub { $null_list->Clear(); }],
        ['Contains', sub { $null_list->Contains("item"); }],
        ['IndexOf', sub { $null_list->IndexOf("item"); }],
        ['ToArray', sub { $null_list->ToArray(); }],
        ['GetEnumerator', sub { $null_list->GetEnumerator(); }]
    );
    
    for my $method_test (@methods_to_test) {
        my ($method_name, $test_sub) = @$method_test;
        eval { $test_sub->(); };
        like($@, qr/NullReferenceException|Can't call method/, "$method_name throws on null reference");
    }
}

#===========================================
# ENUMERATOR TESTS
#===========================================

sub test_enumerator {
    my $list = System::Collections::Generic::List->new("a", "b", "c");
    
    # Test 81: GetEnumerator returns enumerator
    my $enumerator = $list->GetEnumerator();
    ok(defined($enumerator), 'GetEnumerator returns defined enumerator');
    can_ok($enumerator, 'MoveNext');
    can_ok($enumerator, 'Current');
    
    # Test 82: Enumeration visits all items in order
    my @enumerated;
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    
    is(scalar(@enumerated), 3, 'Enumerator visits all items');
    is_deeply(\@enumerated, ["a", "b", "c"], 'Enumerator preserves order');
    
    # Test 83: Enumerator on empty list
    my $empty_list = System::Collections::Generic::List->new();
    my $empty_enum = $empty_list->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'Enumerator on empty list returns false for MoveNext');
}

#===========================================
# STRESS TESTS
#===========================================

sub test_stress_conditions {
    # Test 84: Large number of items
    my $list = System::Collections::Generic::List->new();
    
    # Add many items
    for my $i (1..1000) {
        $list->Add("item_$i");
    }
    is($list->Count(), 1000, 'Can handle large number of items');
    
    # Random access
    is($list->Item(499), "item_500", 'Random access works with large list');
    
    # Remove some items
    for my $i (1..100) {
        $list->Remove("item_$i");
    }
    is($list->Count(), 900, 'Removal works with large list');
    
    # Test 85: Large data items
    my $large_data = "x" x 10000;
    $list->Add($large_data);
    my $retrieved = $list->Item($list->Count() - 1);
    is(length($retrieved), 10000, 'Can handle large data items');
}

# Run all tests
test_construction();
test_count_and_capacity();
test_add();
test_item_indexer();
test_insert();
test_remove();
test_removeAt();
test_removeRange();
test_clear();
test_contains();
test_indexOf();
test_lastIndexOf();
test_addRange();
test_reverse();
test_sort();
test_toArray();
test_trimExcess();
test_predicate_methods();
test_null_reference_exceptions();
test_enumerator();
test_stress_conditions();

done_testing();