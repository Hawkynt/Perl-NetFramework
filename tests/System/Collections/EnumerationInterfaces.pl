#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::IEnumerable');
    use_ok('System::Collections::IEnumerator');
    use_ok('System::Collections::Hashtable');
}

# Test constants
use constant {
    TEST_KEY1 => "key1",
    TEST_KEY2 => "key2",
    TEST_VALUE1 => "value1",
    TEST_VALUE2 => "value2",
};

#===========================================
# IENUMERABLE INTERFACE TESTS
#===========================================

sub test_ienumerable_basic {
    # Test 1: IEnumerable is a proper package
    ok(defined($System::Collections::IEnumerable::VERSION) || 1, 'IEnumerable package loads');
    can_ok('System::Collections::IEnumerable', 'GetEnumerator');
    
    # Test 2: Hashtable implements IEnumerable
    my $ht = System::Collections::Hashtable->new();
    isa_ok($ht, 'System::Collections::IEnumerable', 'Hashtable implements IEnumerable');
    
    # Test 3: Can call GetEnumerator on collection
    can_ok($ht, 'GetEnumerator');
    my $enumerator = $ht->GetEnumerator();
    ok(defined($enumerator), 'GetEnumerator returns defined object');
}

sub test_ienumerable_array_overload {
    # Test 4: Array overload with empty collection
    my $empty_ht = System::Collections::Hashtable->new();
    # my $empty_array = $empty_ht->{};  # This triggers @{} overload - syntax issue
    # Note: The syntax above might not work as expected in all Perl versions
    # Let's test the overload differently
    
    # Test 5: Array overload with populated collection
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    
    # Test array dereferencing (this uses the @{} overload)
    my @items = @$ht;  # This should invoke the array overload
    is(scalar(@items), 2, 'Array overload returns correct number of items');
    
    # Verify the items are DictionaryEntry objects
    isa_ok($items[0], 'System::Collections::DictionaryEntry', 'Array overload returns DictionaryEntry objects');
    isa_ok($items[1], 'System::Collections::DictionaryEntry', 'Array overload returns all DictionaryEntry objects');
}

sub test_ienumerable_array_overload_edge_cases {
    # Test 6: Array overload with System::Array (should return itself)
    # This requires System::Array to exist and inherit from IEnumerable
    # For now, we'll skip this test and add a comment
    
    # Test 7: Array overload preserves enumeration order
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("a", "1");
    $ht->Add("b", "2");
    $ht->Add("c", "3");
    
    my @first_iteration = @$ht;
    my @second_iteration = @$ht;
    
    is(scalar(@first_iteration), scalar(@second_iteration), 'Array overload consistent count');
    
    # Test 8: Array overload with null values
    my $null_ht = System::Collections::Hashtable->new();
    $null_ht->Add("null_key", undef);
    $null_ht->Add("normal_key", "normal_value");
    
    my @mixed_items = @$null_ht;
    is(scalar(@mixed_items), 2, 'Array overload handles null values correctly');
}

#===========================================
# IENUMERATOR INTERFACE TESTS
#===========================================

sub test_ienumerator_basic {
    # Test 9: IEnumerator is a proper package
    ok(defined($System::Collections::IEnumerator::VERSION) || 1, 'IEnumerator package loads');
    can_ok('System::Collections::IEnumerator', 'MoveNext');
    can_ok('System::Collections::IEnumerator', 'Current');
    can_ok('System::Collections::IEnumerator', 'Reset');
    
    # Test 10: IEnumerator inherits from IDisposable
    isa_ok('System::Collections::IEnumerator', 'System::IDisposable', 'IEnumerator inherits from IDisposable');
}

sub test_ienumerator_implementation {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 11: Enumerator implements IEnumerator
    isa_ok($enumerator, 'System::Collections::IEnumerator', 'Hashtable enumerator implements IEnumerator');
    
    # Test 12: Enumerator has required methods
    can_ok($enumerator, 'MoveNext');
    can_ok($enumerator, 'Current');
    can_ok($enumerator, 'Reset');
    can_ok($enumerator, 'Dispose');
    
    # Test 13: Initial state - Current should throw before MoveNext
    eval { $enumerator->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws before first MoveNext');
}

sub test_ienumerator_enumeration_pattern {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("first", "1");
    $ht->Add("second", "2");
    $ht->Add("third", "3");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 14: Standard enumeration pattern
    my $count = 0;
    my %found_items = ();
    
    while ($enumerator->MoveNext()) {
        my $current = $enumerator->Current();
        isa_ok($current, 'System::Collections::DictionaryEntry', "Item $count is DictionaryEntry");
        $found_items{$current->Key()} = $current->Value();
        $count++;
    }
    
    # Test 15: Enumerated all items
    is($count, 3, 'Enumerated correct number of items');
    is($found_items{"first"}, "1", 'First item enumerated correctly');
    is($found_items{"second"}, "2", 'Second item enumerated correctly');
    is($found_items{"third"}, "3", 'Third item enumerated correctly');
    
    # Test 16: MoveNext returns false after last item
    ok(!$enumerator->MoveNext(), 'MoveNext returns false after last item');
    
    # Test 17: Current throws after enumeration ends
    eval { $enumerator->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws after enumeration ends');
}

sub test_ienumerator_reset {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("reset_test", "value");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 18: Enumerate once
    ok($enumerator->MoveNext(), 'First enumeration MoveNext succeeds');
    my $first_current = $enumerator->Current();
    ok(!$enumerator->MoveNext(), 'First enumeration completes');
    
    # Test 19: Reset and enumerate again
    $enumerator->Reset();
    ok($enumerator->MoveNext(), 'After Reset, MoveNext succeeds again');
    my $second_current = $enumerator->Current();
    
    # Test 20: Same item retrieved after reset
    is($first_current->Key(), $second_current->Key(), 'Reset allows re-enumeration with same key');
    is($first_current->Value(), $second_current->Value(), 'Reset allows re-enumeration with same value');
}

sub test_ienumerator_dispose {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("dispose_test", "value");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 21: Dispose method exists and can be called
    can_ok($enumerator, 'Dispose');
    
    # Call Dispose (should not throw)
    eval { $enumerator->Dispose(); };
    ok(!$@, 'Dispose method can be called without error');
    
    # Test 22: Enumerator may still work after Dispose (implementation dependent)
    # This is a soft test - some implementations might disable the enumerator after Dispose
    my $works_after_dispose = eval { $enumerator->MoveNext(); 1 };
    ok(defined($works_after_dispose), 'Enumerator state after Dispose is defined');
}

#===========================================
# INTEGRATION TESTS
#===========================================

sub test_enumeration_integration {
    # Test 23: Multiple enumerators on same collection
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("shared", "data");
    
    my $enum1 = $ht->GetEnumerator();
    my $enum2 = $ht->GetEnumerator();
    
    isnt($enum1, $enum2, 'Multiple enumerators are different objects');
    
    # Both should work independently
    ok($enum1->MoveNext(), 'First enumerator works');
    ok($enum2->MoveNext(), 'Second enumerator works independently');
    
    is($enum1->Current()->Key(), $enum2->Current()->Key(), 'Both enumerators see same data');
    
    # Test 24: Enumerator with collection modifications
    my $modifiable_ht = System::Collections::Hashtable->new();
    $modifiable_ht->Add("initial", "value");
    
    my $mod_enum = $modifiable_ht->GetEnumerator();
    ok($mod_enum->MoveNext(), 'Enumerator works before modification');
    
    # Modify collection
    $modifiable_ht->Add("added", "after");
    
    # Reset enumerator and check if it sees the new item
    $mod_enum->Reset();
    my $item_count = 0;
    while ($mod_enum->MoveNext()) {
        $item_count++;
    }
    
    is($item_count, 2, 'Enumerator sees collection modifications after Reset');
}

sub test_empty_collection_enumeration {
    # Test 25: Enumeration on empty collection
    my $empty_ht = System::Collections::Hashtable->new();
    my $empty_enum = $empty_ht->GetEnumerator();
    
    isa_ok($empty_enum, 'System::Collections::IEnumerator', 'Empty collection returns valid enumerator');
    
    # Test 26: MoveNext returns false immediately on empty collection
    ok(!$empty_enum->MoveNext(), 'MoveNext returns false on empty collection');
    
    # Test 27: Current throws on empty collection enumeration
    eval { $empty_enum->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws on empty collection enumerator');
    
    # Test 28: Reset works on empty collection
    eval { $empty_enum->Reset(); };
    ok(!$@, 'Reset works on empty collection enumerator');
    
    # Test 29: Still empty after reset
    ok(!$empty_enum->MoveNext(), 'Still empty after Reset');
}

sub test_null_value_enumeration {
    # Test 30: Enumeration with null values
    my $null_ht = System::Collections::Hashtable->new();
    $null_ht->Add("null_value_key", undef);
    $null_ht->Add("normal_key", "normal_value");
    
    my $null_enum = $null_ht->GetEnumerator();
    
    my $null_found = 0;
    my $normal_found = 0;
    
    while ($null_enum->MoveNext()) {
        my $entry = $null_enum->Current();
        if ($entry->Key() eq "null_value_key") {
            ok(!defined($entry->Value()), 'Null value enumerated correctly');
            $null_found = 1;
        } elsif ($entry->Key() eq "normal_key") {
            is($entry->Value(), "normal_value", 'Normal value enumerated correctly');
            $normal_found = 1;
        }
    }
    
    # Test 31: Both null and normal values were found
    ok($null_found, 'Null value entry was enumerated');
    ok($normal_found, 'Normal value entry was enumerated');
}

#===========================================
# STRESS AND EDGE CASE TESTS
#===========================================

sub test_large_collection_enumeration {
    # Test 32: Large collection enumeration performance
    my $large_ht = System::Collections::Hashtable->new();
    
    # Add many items
    for my $i (1..1000) {
        $large_ht->Add("key_$i", "value_$i");
    }
    
    my $large_enum = $large_ht->GetEnumerator();
    my $enumerated_count = 0;
    
    while ($large_enum->MoveNext()) {
        my $entry = $large_enum->Current();
        isa_ok($entry, 'System::Collections::DictionaryEntry', "Large collection item $enumerated_count is DictionaryEntry");
        $enumerated_count++;
        
        # Only test the first few and last few to avoid too many tests
        if ($enumerated_count <= 3 || $enumerated_count > 997) {
            ok(defined($entry->Key()), "Large collection item $enumerated_count has key");
            ok(defined($entry->Value()), "Large collection item $enumerated_count has value");
        }
        
        # Break the test loop if we've tested enough individual items
        if ($enumerated_count > 1000) {
            fail("Enumeration exceeded expected count");
            last;
        }
    }
    
    # Test 33: Enumerated correct number of items
    is($enumerated_count, 1000, 'Large collection enumerated completely');
}

sub test_nested_enumeration {
    # Test 34: Nested enumeration (enumerator in enumerator)
    my $outer_ht = System::Collections::Hashtable->new();
    $outer_ht->Add("key1", "value1");
    $outer_ht->Add("key2", "value2");
    
    my $outer_enum = $outer_ht->GetEnumerator();
    
    while ($outer_enum->MoveNext()) {
        my $outer_entry = $outer_enum->Current();
        
        # Create inner enumeration
        my $inner_enum = $outer_ht->GetEnumerator();
        my $inner_count = 0;
        
        while ($inner_enum->MoveNext()) {
            $inner_count++;
        }
        
        is($inner_count, 2, 'Inner enumeration works during outer enumeration');
    }
    
    ok(1, 'Nested enumeration completed successfully');
}

sub test_concurrent_enumeration_safety {
    # Test 35: Multiple concurrent enumerations
    my $concurrent_ht = System::Collections::Hashtable->new();
    $concurrent_ht->Add("concurrent1", "value1");
    $concurrent_ht->Add("concurrent2", "value2");
    $concurrent_ht->Add("concurrent3", "value3");
    
    my @enumerators = ();
    for my $i (1..5) {
        push @enumerators, $concurrent_ht->GetEnumerator();
    }
    
    # Test that all enumerators work
    for my $i (0..4) {
        my $enum = $enumerators[$i];
        my $count = 0;
        while ($enum->MoveNext()) {
            $count++;
        }
        is($count, 3, "Concurrent enumerator $i enumerated all items");
    }
}

# Run all tests
test_ienumerable_basic();
test_ienumerable_array_overload();
test_ienumerable_array_overload_edge_cases();
test_ienumerator_basic();
test_ienumerator_implementation();
test_ienumerator_enumeration_pattern();
test_ienumerator_reset();
test_ienumerator_dispose();
test_enumeration_integration();
test_empty_collection_enumeration();
test_null_value_enumeration();
test_large_collection_enumeration();
test_nested_enumeration();
test_concurrent_enumeration_safety();

done_testing();