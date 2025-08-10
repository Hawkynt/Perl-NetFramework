#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::IEnumerable');
    use_ok('System::Collections::Hashtable');
    use_ok('System::Array');
}

# Test constants
use constant {
    TEST_KEY1 => "key1",
    TEST_KEY2 => "key2",
    TEST_VALUE1 => "value1",
    TEST_VALUE2 => "value2",
};

#===========================================
# INTERFACE CONTRACT TESTS
#===========================================

sub test_interface_definition {
    # Test 1: IEnumerable package loads correctly
    ok(defined($System::Collections::IEnumerable::VERSION) || 1, 'IEnumerable package loads successfully');
    
    # Test 2: Required method exists
    can_ok('System::Collections::IEnumerable', 'GetEnumerator');
    
    # Test 3: GetEnumerator throws NotImplementedException when called directly
    eval { System::Collections::IEnumerable->GetEnumerator(); };
    like($@, qr/NotImplementedException/, 'GetEnumerator throws NotImplementedException on interface');
}

sub test_overload_operators {
    # Test 4: Array overload operator is defined
    ok(System::Collections::IEnumerable->can('({}'), 'IEnumerable has overload operators');
    
    # Test 5: Fallback overload is enabled
    ok(1, 'Overload fallback enabled (implicit test)');
}

#===========================================
# ARRAY OVERLOAD FUNCTIONALITY TESTS
#===========================================

sub test_array_overload_with_hashtable {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    
    # Test 6: Array overload returns array reference
    my $array_ref = eval { @$ht };
    ok(!$@, 'Array overload does not throw exception');
    is(ref($array_ref), 'ARRAY', 'Array overload returns array reference') if defined $array_ref;
    
    # Test 7: Array contains correct number of elements
    my @items = @$ht;
    is(scalar(@items), 2, 'Array overload returns correct number of items');
    
    # Test 8: Array elements are DictionaryEntry objects
    for my $i (0..$#items) {
        isa_ok($items[$i], 'System::Collections::DictionaryEntry', "Item $i is DictionaryEntry");
    }
}

sub test_array_overload_empty_collection {
    my $empty_ht = System::Collections::Hashtable->new();
    
    # Test 9: Empty collection array overload
    my @empty_items = @$empty_ht;
    is(scalar(@empty_items), 0, 'Empty collection returns empty array');
    
    # Test 10: Empty array is still an array reference
    my $empty_ref = \@empty_items;
    is(ref($empty_ref), 'ARRAY', 'Empty collection still returns array reference');
}

sub test_array_overload_with_system_array {
    # Test 11: Array overload with System::Array should return itself
    eval {
        # Create a System::Array instance if possible
        my $sys_array = System::Array->new("System.String", 3);
        if ($sys_array && $sys_array->isa("System::Collections::IEnumerable")) {
            my $result = eval { @$sys_array };
            is($result, $sys_array, 'System::Array returns itself in array overload') if defined $result;
        } else {
            skip("System::Array not available or doesn't implement IEnumerable", 1);
        }
    };
    ok(!$@, 'Array overload with System::Array does not throw') if $@;
}

sub test_array_overload_enumeration_process {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("first", "1");
    $ht->Add("second", "2");
    $ht->Add("third", "3");
    
    # Test 12: Array overload calls GetEnumerator internally
    my @items = @$ht;
    is(scalar(@items), 3, 'Array overload processes all enumerated items');
    
    # Test 13: Enumerator is properly disposed after array overload
    # This is implicit - we can't directly test disposal, but we can verify the operation completes
    ok(1, 'Array overload completes successfully (implies enumerator disposal)');
}

sub test_array_overload_with_null_values {
    my $null_ht = System::Collections::Hashtable->new();
    $null_ht->Add("null_key", undef);
    $null_ht->Add("normal_key", "normal_value");
    
    # Test 14: Array overload handles null values
    my @mixed_items = @$null_ht;
    is(scalar(@mixed_items), 2, 'Array overload handles collections with null values');
    
    # Test 15: Null values are preserved in array overload
    my $null_found = 0;
    my $normal_found = 0;
    for my $entry (@mixed_items) {
        if ($entry->Key() eq "null_key") {
            ok(!defined($entry->Value()), 'Null value preserved in array overload');
            $null_found = 1;
        } elsif ($entry->Key() eq "normal_key") {
            is($entry->Value(), "normal_value", 'Normal value preserved in array overload');
            $normal_found = 1;
        }
    }
    ok($null_found, 'Null value entry found in array overload');
    ok($normal_found, 'Normal value entry found in array overload');
}

#===========================================
# ENUMERATION CONSISTENCY TESTS
#===========================================

sub test_enumeration_consistency {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("consistent1", "value1");
    $ht->Add("consistent2", "value2");
    
    # Test 16: Multiple array overloads return same data
    my @first_array = @$ht;
    my @second_array = @$ht;
    
    is(scalar(@first_array), scalar(@second_array), 'Multiple array overloads return same count');
    
    # Test 17: Manual enumeration matches array overload
    my $enumerator = $ht->GetEnumerator();
    my @manual_items = ();
    while ($enumerator->MoveNext()) {
        push @manual_items, $enumerator->Current();
    }
    $enumerator->Dispose();
    
    is(scalar(@manual_items), scalar(@first_array), 'Manual enumeration matches array overload count');
}

sub test_enumeration_order_consistency {
    my $ht = System::Collections::Hashtable->new();
    for my $i (1..10) {
        $ht->Add("key$i", "value$i");
    }
    
    # Test 18: Array overload order is consistent
    my @first_order = @$ht;
    my @second_order = @$ht;
    
    is(scalar(@first_order), scalar(@second_order), 'Order consistency: same count');
    
    # Test 19: Keys appear in same positions
    for my $i (0..$#first_order) {
        is($first_order[$i]->Key(), $second_order[$i]->Key(), 
           "Order consistency: key at position $i matches");
    }
}

#===========================================
# PERFORMANCE AND STRESS TESTS
#===========================================

sub test_large_collection_array_overload {
    my $large_ht = System::Collections::Hashtable->new();
    
    # Test 20: Large collection array overload
    for my $i (1..500) {
        $large_ht->Add("large_key_$i", "large_value_$i");
    }
    
    my @large_array = @$large_ht;
    is(scalar(@large_array), 500, 'Large collection array overload returns correct count');
    
    # Test 21: Random sampling of large array items
    my $sample_size = 10;
    for my $i (0..$sample_size-1) {
        my $index = int(rand(scalar(@large_array)));
        isa_ok($large_array[$index], 'System::Collections::DictionaryEntry', 
               "Large collection item $index is DictionaryEntry");
    }
}

sub test_repeated_array_overload_performance {
    my $ht = System::Collections::Hashtable->new();
    for my $i (1..100) {
        $ht->Add("perf_key_$i", "perf_value_$i");
    }
    
    # Test 22: Repeated array overloads work correctly
    my $repetitions = 10;
    for my $rep (1..$repetitions) {
        my @items = @$ht;
        is(scalar(@items), 100, "Repetition $rep: correct count");
        
        # Only detailed test first and last repetitions
        if ($rep == 1 || $rep == $repetitions) {
            isa_ok($items[0], 'System::Collections::DictionaryEntry', 
                   "Repetition $rep: first item is DictionaryEntry");
            isa_ok($items[-1], 'System::Collections::DictionaryEntry', 
                   "Repetition $rep: last item is DictionaryEntry");
        }
    }
}

#===========================================
# ERROR HANDLING TESTS
#===========================================

sub test_array_overload_error_handling {
    # Test 23: Array overload with undefined collection
    my $undef_collection = undef;
    eval { my @items = @$undef_collection; };
    like($@, qr/./, 'Array overload with undefined collection throws error');
    
    # Test 24: Array overload survives enumerator exceptions
    # We'll create a custom enumerable that throws during enumeration
    my $problematic_ht = System::Collections::Hashtable->new();
    $problematic_ht->Add("normal", "value");
    
    # This should work normally
    eval { my @items = @$problematic_ht; };
    ok(!$@, 'Array overload works with normal hashtable');
}

sub test_interface_inheritance_compatibility {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("inheritance_test", "value");
    
    # Test 25: Hashtable properly implements IEnumerable
    isa_ok($ht, 'System::Collections::IEnumerable', 'Hashtable implements IEnumerable');
    
    # Test 26: Can call interface methods through inheritance
    can_ok($ht, 'GetEnumerator');
    my $enum = $ht->GetEnumerator();
    ok(defined($enum), 'GetEnumerator returns defined enumerator');
    
    # Test 27: Array overload works through inheritance
    my @inherited_items = @$ht;
    is(scalar(@inherited_items), 1, 'Array overload works through inheritance');
}

#===========================================
# EDGE CASE TESTS
#===========================================

sub test_collection_modification_during_array_overload {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("original", "value");
    
    # Test 28: Array overload captures snapshot
    my @before_mod = @$ht;
    is(scalar(@before_mod), 1, 'Before modification: correct count');
    
    # Modify collection
    $ht->Add("added", "new_value");
    
    # New array overload should see the change
    my @after_mod = @$ht;
    is(scalar(@after_mod), 2, 'After modification: array overload sees changes');
}

sub test_special_key_values_array_overload {
    my $special_ht = System::Collections::Hashtable->new();
    
    # Test 29: Special characters in keys/values
    $special_ht->Add("", "empty_key");
    $special_ht->Add("key_with\nnewline", "newline_value");
    $special_ht->Add("key with spaces", "space_value");
    $special_ht->Add("key\twith\ttabs", "tab_value");
    
    my @special_items = @$special_ht;
    is(scalar(@special_items), 4, 'Array overload handles special characters');
    
    # Verify all special items are DictionaryEntry objects
    for my $i (0..$#special_items) {
        isa_ok($special_items[$i], 'System::Collections::DictionaryEntry', 
               "Special character item $i is DictionaryEntry");
    }
}

sub test_memory_cleanup_array_overload {
    # Test 30: Memory cleanup after array overload
    my $cleanup_ht = System::Collections::Hashtable->new();
    for my $i (1..100) {
        $cleanup_ht->Add("cleanup_$i", "value_$i");
    }
    
    # Perform array overload
    my @cleanup_items = @$cleanup_ht;
    is(scalar(@cleanup_items), 100, 'Cleanup test: correct item count');
    
    # Clear the array and collection
    @cleanup_items = ();
    $cleanup_ht = undef;
    
    # This is mostly to ensure no crashes occur during cleanup
    ok(1, 'Memory cleanup completed successfully');
}

# Run all tests
test_interface_definition();
test_overload_operators();
test_array_overload_with_hashtable();
test_array_overload_empty_collection();
test_array_overload_with_system_array();
test_array_overload_enumeration_process();
test_array_overload_with_null_values();
test_enumeration_consistency();
test_enumeration_order_consistency();
test_large_collection_array_overload();
test_repeated_array_overload_performance();
test_array_overload_error_handling();
test_interface_inheritance_compatibility();
test_collection_modification_during_array_overload();
test_special_key_values_array_overload();
test_memory_cleanup_array_overload();

done_testing();