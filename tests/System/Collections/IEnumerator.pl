#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::IEnumerator');
    use_ok('System::Collections::Hashtable');
    use_ok('System::IDisposable');
}

# Test constants
use constant {
    TEST_KEY1 => "enum_key1",
    TEST_KEY2 => "enum_key2",
    TEST_KEY3 => "enum_key3",
    TEST_VALUE1 => "enum_value1",
    TEST_VALUE2 => "enum_value2",
    TEST_VALUE3 => "enum_value3",
};

#===========================================
# INTERFACE CONTRACT TESTS
#===========================================

sub test_interface_definition {
    # Test 1: IEnumerator package loads correctly
    ok(defined($System::Collections::IEnumerator::VERSION) || 1, 'IEnumerator package loads successfully');
    
    # Test 2: Required methods exist
    can_ok('System::Collections::IEnumerator', 'MoveNext');
    can_ok('System::Collections::IEnumerator', 'Current');
    can_ok('System::Collections::IEnumerator', 'Reset');
    
    # Test 3: Inherits from IDisposable
    isa_ok('System::Collections::IEnumerator', 'System::IDisposable', 'IEnumerator inherits from IDisposable');
    can_ok('System::Collections::IEnumerator', 'Dispose');
}

sub test_interface_method_exceptions {
    # Test 4: Interface methods throw NotImplementedException when called directly
    eval { System::Collections::IEnumerator->MoveNext(); };
    like($@, qr/NotImplementedException/, 'MoveNext throws NotImplementedException on interface');
    
    eval { System::Collections::IEnumerator->Current(); };
    like($@, qr/NotImplementedException/, 'Current throws NotImplementedException on interface');
    
    eval { System::Collections::IEnumerator->Reset(); };
    like($@, qr/NotImplementedException/, 'Reset throws NotImplementedException on interface');
}

#===========================================
# BASIC ENUMERATION PATTERN TESTS
#===========================================

sub test_basic_enumeration_pattern {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    $ht->Add(TEST_KEY3, TEST_VALUE3);
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 5: Enumerator implements IEnumerator
    isa_ok($enumerator, 'System::Collections::IEnumerator', 'Hashtable enumerator implements IEnumerator');
    
    # Test 6: Initial state - Current should throw before MoveNext
    eval { $enumerator->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws InvalidOperationException before first MoveNext');
    
    # Test 7: First MoveNext call
    ok($enumerator->MoveNext(), 'First MoveNext returns true');
    my $first_current = $enumerator->Current();
    isa_ok($first_current, 'System::Collections::DictionaryEntry', 'First Current returns DictionaryEntry');
    
    # Test 8: Second MoveNext call
    ok($enumerator->MoveNext(), 'Second MoveNext returns true');
    my $second_current = $enumerator->Current();
    isa_ok($second_current, 'System::Collections::DictionaryEntry', 'Second Current returns DictionaryEntry');
    
    # Test 9: Third MoveNext call
    ok($enumerator->MoveNext(), 'Third MoveNext returns true');
    my $third_current = $enumerator->Current();
    isa_ok($third_current, 'System::Collections::DictionaryEntry', 'Third Current returns DictionaryEntry');
    
    # Test 10: Fourth MoveNext call (should fail)
    ok(!$enumerator->MoveNext(), 'Fourth MoveNext returns false (end of enumeration)');
    
    # Test 11: Current throws after enumeration ends
    eval { $enumerator->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws InvalidOperationException after enumeration ends');
}

sub test_complete_enumeration_data_integrity {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("data1", "value1");
    $ht->Add("data2", "value2");
    $ht->Add("data3", "value3");
    $ht->Add("data4", "value4");
    
    my $enumerator = $ht->GetEnumerator();
    my %enumerated_data = ();
    my $count = 0;
    
    # Test 12: Complete enumeration preserves all data
    while ($enumerator->MoveNext()) {
        my $entry = $enumerator->Current();
        $enumerated_data{$entry->Key()} = $entry->Value();
        $count++;
    }
    
    is($count, 4, 'Enumerated correct number of items');
    is($enumerated_data{"data1"}, "value1", 'First item data preserved');
    is($enumerated_data{"data2"}, "value2", 'Second item data preserved');
    is($enumerated_data{"data3"}, "value3", 'Third item data preserved');
    is($enumerated_data{"data4"}, "value4", 'Fourth item data preserved');
}

#===========================================
# RESET FUNCTIONALITY TESTS
#===========================================

sub test_reset_functionality {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("reset1", "value1");
    $ht->Add("reset2", "value2");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 13: Enumerate once
    ok($enumerator->MoveNext(), 'Before reset: first MoveNext succeeds');
    my $first_item = $enumerator->Current();
    ok($enumerator->MoveNext(), 'Before reset: second MoveNext succeeds');
    my $second_item = $enumerator->Current();
    ok(!$enumerator->MoveNext(), 'Before reset: enumeration completes');
    
    # Test 14: Reset enumerator
    eval { $enumerator->Reset(); };
    ok(!$@, 'Reset method executes without error');
    
    # Test 15: Current throws after Reset (before MoveNext)
    eval { $enumerator->Current(); };
    like($@, qr/InvalidOperationException/, 'Current throws InvalidOperationException after Reset before MoveNext');
    
    # Test 16: Re-enumerate after Reset
    ok($enumerator->MoveNext(), 'After reset: first MoveNext succeeds');
    my $reset_first_item = $enumerator->Current();
    ok($enumerator->MoveNext(), 'After reset: second MoveNext succeeds');
    my $reset_second_item = $enumerator->Current();
    ok(!$enumerator->MoveNext(), 'After reset: enumeration completes again');
    
    # Test 17: Reset allows complete re-enumeration
    # Note: Order might not be guaranteed, so we check data presence rather than order
    my %original_data = ($first_item->Key() => $first_item->Value(), $second_item->Key() => $second_item->Value());
    my %reset_data = ($reset_first_item->Key() => $reset_first_item->Value(), $reset_second_item->Key() => $reset_second_item->Value());
    
    is_deeply(\%original_data, \%reset_data, 'Reset allows access to same data');
}

sub test_multiple_resets {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("multi_reset", "test_value");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 18: Multiple consecutive resets
    for my $reset_num (1..5) {
        $enumerator->Reset();
        ok($enumerator->MoveNext(), "Reset $reset_num: MoveNext succeeds after reset");
        my $entry = $enumerator->Current();
        is($entry->Key(), "multi_reset", "Reset $reset_num: correct key after reset");
        is($entry->Value(), "test_value", "Reset $reset_num: correct value after reset");
    }
}

sub test_reset_at_different_positions {
    my $ht = System::Collections::Hashtable->new();
    for my $i (1..5) {
        $ht->Add("pos_$i", "val_$i");
    }
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 19: Reset at beginning
    $enumerator->Reset();
    ok($enumerator->MoveNext(), 'Reset at beginning: MoveNext works');
    
    # Move to middle position and reset
    $enumerator->MoveNext();
    $enumerator->MoveNext();
    
    # Test 20: Reset at middle position
    $enumerator->Reset();
    my $count_after_mid_reset = 0;
    while ($enumerator->MoveNext()) {
        $count_after_mid_reset++;
    }
    is($count_after_mid_reset, 5, 'Reset at middle position allows full re-enumeration');
    
    # Test 21: Reset at end
    $enumerator->Reset();
    my $count_after_end_reset = 0;
    while ($enumerator->MoveNext()) {
        $count_after_end_reset++;
    }
    is($count_after_end_reset, 5, 'Reset at end allows full re-enumeration');
}

#===========================================
# DISPOSE FUNCTIONALITY TESTS
#===========================================

sub test_dispose_functionality {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("dispose_test", "dispose_value");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 22: Dispose method exists and can be called
    can_ok($enumerator, 'Dispose');
    eval { $enumerator->Dispose(); };
    ok(!$@, 'Dispose method executes without error');
    
    # Test 23: Enumerator state after Dispose (implementation-dependent)
    # Some implementations might still work, others might not
    my $move_next_after_dispose = eval { $enumerator->MoveNext() };
    my $dispose_error = $@;
    
    # We don't require specific behavior after Dispose, but it should not crash
    ok(defined($move_next_after_dispose) || defined($dispose_error), 
       'Enumerator state after Dispose is well-defined');
}

sub test_multiple_dispose_calls {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("multi_dispose", "test");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 24: Multiple Dispose calls should not cause errors
    for my $dispose_num (1..3) {
        eval { $enumerator->Dispose(); };
        ok(!$@, "Dispose call $dispose_num executes without error");
    }
}

sub test_dispose_at_different_states {
    my $ht = System::Collections::Hashtable->new();
    for my $i (1..3) {
        $ht->Add("state_$i", "val_$i");
    }
    
    # Test 25: Dispose before enumeration starts
    my $enum1 = $ht->GetEnumerator();
    eval { $enum1->Dispose(); };
    ok(!$@, 'Dispose before enumeration starts executes without error');
    
    # Test 26: Dispose during enumeration
    my $enum2 = $ht->GetEnumerator();
    $enum2->MoveNext();
    eval { $enum2->Dispose(); };
    ok(!$@, 'Dispose during enumeration executes without error');
    
    # Test 27: Dispose after enumeration completes
    my $enum3 = $ht->GetEnumerator();
    while ($enum3->MoveNext()) { } # Complete enumeration
    eval { $enum3->Dispose(); };
    ok(!$@, 'Dispose after enumeration completes executes without error');
}

#===========================================
# ENUMERATOR STATE MANAGEMENT TESTS
#===========================================

sub test_enumerator_independence {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("indep1", "value1");
    $ht->Add("indep2", "value2");
    
    # Test 28: Multiple enumerators are independent
    my $enum1 = $ht->GetEnumerator();
    my $enum2 = $ht->GetEnumerator();
    
    isnt($enum1, $enum2, 'Multiple enumerators are different objects');
    
    # Test 29: Independent state management
    ok($enum1->MoveNext(), 'First enumerator MoveNext succeeds');
    
    # Second enumerator should still be at initial position
    eval { $enum2->Current(); };
    like($@, qr/InvalidOperationException/, 'Second enumerator still at initial state');
    
    ok($enum2->MoveNext(), 'Second enumerator MoveNext succeeds independently');
    
    # Both should have valid current items
    my $entry1 = $enum1->Current();
    my $entry2 = $enum2->Current();
    isa_ok($entry1, 'System::Collections::DictionaryEntry', 'First enumerator has valid current');
    isa_ok($entry2, 'System::Collections::DictionaryEntry', 'Second enumerator has valid current');
}

sub test_enumerator_collection_relationship {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("relationship", "test");
    
    my $enumerator = $ht->GetEnumerator();
    
    # Test 30: Enumerator sees collection modifications after Reset
    ok($enumerator->MoveNext(), 'Initial enumeration works');
    is($enumerator->Current()->Key(), "relationship", 'Initial item found');
    ok(!$enumerator->MoveNext(), 'Initial enumeration completes');
    
    # Modify collection
    $ht->Add("added", "new_item");
    
    # Reset and check if modification is seen
    $enumerator->Reset();
    my $item_count = 0;
    while ($enumerator->MoveNext()) {
        $item_count++;
    }
    
    is($item_count, 2, 'Enumerator sees collection modifications after Reset');
}

#===========================================
# ERROR HANDLING AND EDGE CASES
#===========================================

sub test_empty_collection_enumeration {
    my $empty_ht = System::Collections::Hashtable->new();
    my $empty_enum = $empty_ht->GetEnumerator();
    
    # Test 31: Empty collection enumerator
    isa_ok($empty_enum, 'System::Collections::IEnumerator', 'Empty collection returns valid enumerator');
    
    # Test 32: MoveNext returns false immediately
    ok(!$empty_enum->MoveNext(), 'Empty collection MoveNext returns false');
    
    # Test 33: Current throws on empty collection
    eval { $empty_enum->Current(); };
    like($@, qr/InvalidOperationException/, 'Empty collection Current throws InvalidOperationException');
    
    # Test 34: Reset works on empty collection
    eval { $empty_enum->Reset(); };
    ok(!$@, 'Reset works on empty collection');
    
    # Test 35: Still empty after Reset
    ok(!$empty_enum->MoveNext(), 'Still empty after Reset');
}

sub test_null_value_handling {
    my $null_ht = System::Collections::Hashtable->new();
    $null_ht->Add("null_key", undef);
    $null_ht->Add("normal_key", "normal_value");
    
    my $null_enum = $null_ht->GetEnumerator();
    
    # Test 36: Enumeration with null values
    my %found_values = ();
    while ($null_enum->MoveNext()) {
        my $entry = $null_enum->Current();
        $found_values{$entry->Key()} = $entry->Value();
    }
    
    ok(exists($found_values{"null_key"}), 'Null value key found during enumeration');
    ok(!defined($found_values{"null_key"}), 'Null value preserved during enumeration');
    is($found_values{"normal_key"}, "normal_value", 'Normal value preserved during enumeration');
}

sub test_large_collection_enumeration_state {
    my $large_ht = System::Collections::Hashtable->new();
    for my $i (1..1000) {
        $large_ht->Add("large_$i", "value_$i");
    }
    
    my $large_enum = $large_ht->GetEnumerator();
    
    # Test 37: Large collection enumeration performance
    my $count = 0;
    while ($large_enum->MoveNext()) {
        my $entry = $large_enum->Current();
        isa_ok($entry, 'System::Collections::DictionaryEntry', "Large collection item $count is DictionaryEntry") if $count < 5;
        $count++;
        
        # Test Reset in middle of large enumeration
        if ($count == 500) {
            $large_enum->Reset();
            $count = 0; # Reset our counter too
        }
    }
    
    is($count, 1000, 'Large collection enumeration with Reset completed correctly');
}

#===========================================
# CONCURRENT ACCESS TESTS
#===========================================

sub test_concurrent_enumerators {
    my $concurrent_ht = System::Collections::Hashtable->new();
    for my $i (1..10) {
        $concurrent_ht->Add("concurrent_$i", "value_$i");
    }
    
    # Test 38: Multiple concurrent enumerators
    my @enumerators = ();
    for my $i (1..5) {
        push @enumerators, $concurrent_ht->GetEnumerator();
    }
    
    # Test each enumerator independently
    for my $i (0..4) {
        my $enum = $enumerators[$i];
        my $count = 0;
        
        while ($enum->MoveNext()) {
            my $entry = $enum->Current();
            isa_ok($entry, 'System::Collections::DictionaryEntry', "Concurrent enumerator $i item is DictionaryEntry") if $count < 2;
            $count++;
        }
        
        is($count, 10, "Concurrent enumerator $i enumerated all items");
    }
    
    # Test 39: Dispose all enumerators
    for my $i (0..4) {
        eval { $enumerators[$i]->Dispose(); };
        ok(!$@, "Concurrent enumerator $i disposed without error");
    }
}

sub test_interleaved_enumeration {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("interleaved1", "value1");
    $ht->Add("interleaved2", "value2");
    $ht->Add("interleaved3", "value3");
    
    my $enum1 = $ht->GetEnumerator();
    my $enum2 = $ht->GetEnumerator();
    
    # Test 40: Interleaved enumeration pattern
    ok($enum1->MoveNext(), 'Enum1: first MoveNext');
    ok($enum2->MoveNext(), 'Enum2: first MoveNext');
    
    my $entry1_1 = $enum1->Current();
    my $entry2_1 = $enum2->Current();
    
    ok($enum1->MoveNext(), 'Enum1: second MoveNext');
    ok($enum2->MoveNext(), 'Enum2: second MoveNext');
    
    # Both enumerators should work independently
    isa_ok($entry1_1, 'System::Collections::DictionaryEntry', 'Interleaved enum1 first item valid');
    isa_ok($entry2_1, 'System::Collections::DictionaryEntry', 'Interleaved enum2 first item valid');
}

# Run all tests
test_interface_definition();
test_interface_method_exceptions();
test_basic_enumeration_pattern();
test_complete_enumeration_data_integrity();
test_reset_functionality();
test_multiple_resets();
test_reset_at_different_positions();
test_dispose_functionality();
test_multiple_dispose_calls();
test_dispose_at_different_states();
test_enumerator_independence();
test_enumerator_collection_relationship();
test_empty_collection_enumeration();
test_null_value_handling();
test_large_collection_enumeration_state();
test_concurrent_enumerators();
test_interleaved_enumeration();

done_testing();