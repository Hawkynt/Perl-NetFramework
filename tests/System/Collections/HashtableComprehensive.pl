#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Hashtable');
    use_ok('System::Collections::DictionaryEntry');
}

# Test constants
use constant {
    TEST_KEY1 => "testKey1",
    TEST_KEY2 => "testKey2", 
    TEST_VALUE1 => "testValue1",
    TEST_VALUE2 => "testValue2",
    NULL_KEY => undef,
    NULL_VALUE => undef,
};

#===========================================
# CONSTRUCTION AND INITIALIZATION TESTS  
#===========================================

sub test_construction {
    # Test 1: Default constructor
    my $ht1 = System::Collections::Hashtable->new();
    isa_ok($ht1, 'System::Collections::Hashtable', 'Default constructor creates Hashtable');
    is($ht1->Count(), 0, 'Default constructor creates empty hashtable');
    
    # Test 2: Constructor with hash reference
    my $hash_ref = { "key1" => "value1", "key2" => "value2" };
    my $ht2 = System::Collections::Hashtable->new($hash_ref);
    isa_ok($ht2, 'System::Collections::Hashtable', 'Hash reference constructor creates Hashtable');
    is($ht2->Count(), 2, 'Hash reference constructor has correct count');
    is($ht2->Get("key1"), "value1", 'Hash reference constructor preserves values');
    is($ht2->Get("key2"), "value2", 'Hash reference constructor preserves all values');
    
    # Test 3: Constructor with array reference (key-value pairs)
    my $array_ref = ["key1", "value1", "key2", "value2", "key3", "value3"];
    my $ht3 = System::Collections::Hashtable->new($array_ref);
    isa_ok($ht3, 'System::Collections::Hashtable', 'Array reference constructor creates Hashtable');
    is($ht3->Count(), 3, 'Array reference constructor has correct count');
    is($ht3->Get("key1"), "value1", 'Array reference constructor preserves first pair');
    is($ht3->Get("key2"), "value2", 'Array reference constructor preserves middle pair');
    is($ht3->Get("key3"), "value3", 'Array reference constructor preserves last pair');
    
    # Test 4: Constructor with hash (key-value pairs as arguments)
    my $ht4 = System::Collections::Hashtable->new("key1", "value1", "key2", "value2");
    isa_ok($ht4, 'System::Collections::Hashtable', 'Direct key-value constructor creates Hashtable');
    is($ht4->Count(), 2, 'Direct key-value constructor has correct count');
    is($ht4->Get("key1"), "value1", 'Direct key-value constructor preserves first pair');
    is($ht4->Get("key2"), "value2", 'Direct key-value constructor preserves second pair');
    
    # Test 5: Constructor with odd number of array elements
    my $odd_array = ["key1", "value1", "key2"];
    my $ht5 = System::Collections::Hashtable->new($odd_array);
    is($ht5->Count(), 1, 'Odd array elements only creates pairs for complete key-value pairs');
    is($ht5->Get("key1"), "value1", 'Odd array constructor preserves complete pairs');
    ok(!defined($ht5->Get("key2")), 'Odd array constructor ignores incomplete pairs');
}

sub test_construction_edge_cases {
    # Test 6: Empty hash reference
    my $empty_hash = {};
    my $ht6 = System::Collections::Hashtable->new($empty_hash);
    is($ht6->Count(), 0, 'Empty hash reference creates empty hashtable');
    
    # Test 7: Empty array reference
    my $empty_array = [];
    my $ht7 = System::Collections::Hashtable->new($empty_array);
    is($ht7->Count(), 0, 'Empty array reference creates empty hashtable');
    
    # Test 8: Single element array
    my $single_array = ["lonely_key"];
    my $ht8 = System::Collections::Hashtable->new($single_array);
    is($ht8->Count(), 0, 'Single element array creates empty hashtable (no value for key)');
}

#===========================================
# ADD OPERATIONS TESTS
#===========================================

sub test_add_basic {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 9: Add single item
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    is($ht->Count(), 1, 'Add increases count');
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'Add stores value correctly');
    
    # Test 10: Add multiple items
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    is($ht->Count(), 2, 'Add second item increases count');
    is($ht->Get(TEST_KEY2), TEST_VALUE2, 'Add second item stores value correctly');
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'Add second item doesn\'t affect first item');
    
    # Test 11: Add with null value
    $ht->Add("null_value_key", NULL_VALUE);
    is($ht->Count(), 3, 'Add with null value increases count');
    ok(!defined($ht->Get("null_value_key")), 'Add with null value stores null correctly');
}

sub test_add_error_handling {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    
    # Test 12: Add duplicate key should throw exception
    eval { $ht->Add(TEST_KEY1, "different_value"); };
    like($@, qr/ArgumentException/, 'Add duplicate key throws ArgumentException');
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'Original value unchanged after failed duplicate add');
    
    # Test 13: Add with null key should throw exception
    eval { $ht->Add(NULL_KEY, TEST_VALUE1); };
    like($@, qr/ArgumentNullException/, 'Add with null key throws ArgumentNullException');
    
    # Test 14: Add on null hashtable should throw exception
    my $null_ht = undef;
    eval { $null_ht->Add(TEST_KEY1, TEST_VALUE1); };
    like($@, qr/NullReferenceException/, 'Add on null hashtable throws NullReferenceException');
}

sub test_addorupdate {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 15: AddOrUpdate new key
    $ht->AddOrUpdate(TEST_KEY1, TEST_VALUE1);
    is($ht->Count(), 1, 'AddOrUpdate new key increases count');
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'AddOrUpdate new key stores value');
    
    # Test 16: AddOrUpdate existing key
    $ht->AddOrUpdate(TEST_KEY1, TEST_VALUE2);
    is($ht->Count(), 1, 'AddOrUpdate existing key maintains count');
    is($ht->Get(TEST_KEY1), TEST_VALUE2, 'AddOrUpdate existing key updates value');
    
    # Test 17: AddOrUpdate with null key should throw exception
    eval { $ht->AddOrUpdate(NULL_KEY, TEST_VALUE1); };
    like($@, qr/ArgumentNullException/, 'AddOrUpdate with null key throws ArgumentNullException');
}

#===========================================
# GET/SET/ITEM OPERATIONS TESTS
#===========================================

sub test_get_operations {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, NULL_VALUE);
    
    # Test 18: Get existing key
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'Get returns correct value for existing key');
    
    # Test 19: Get existing key with null value
    ok(!defined($ht->Get(TEST_KEY2)), 'Get returns null for existing key with null value');
    
    # Test 20: Get non-existing key
    ok(!defined($ht->Get("non_existing")), 'Get returns null for non-existing key');
    
    # Test 21: Get with null key should throw exception
    eval { $ht->Get(NULL_KEY); };
    like($@, qr/ArgumentNullException/, 'Get with null key throws ArgumentNullException');
    
    # Test 22: Get on null hashtable should throw exception
    my $null_ht = undef;
    eval { $null_ht->Get(TEST_KEY1); };
    like($@, qr/NullReferenceException/, 'Get on null hashtable throws NullReferenceException');
}

sub test_set_operations {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 23: Set new key
    $ht->Set(TEST_KEY1, TEST_VALUE1);
    is($ht->Count(), 1, 'Set new key increases count');
    is($ht->Get(TEST_KEY1), TEST_VALUE1, 'Set new key stores value');
    
    # Test 24: Set existing key
    $ht->Set(TEST_KEY1, TEST_VALUE2);
    is($ht->Count(), 1, 'Set existing key maintains count');
    is($ht->Get(TEST_KEY1), TEST_VALUE2, 'Set existing key updates value');
    
    # Test 25: Set with null value
    $ht->Set(TEST_KEY1, NULL_VALUE);
    ok(!defined($ht->Get(TEST_KEY1)), 'Set with null value stores null');
    
    # Test 26: Set with null key should throw exception
    eval { $ht->Set(NULL_KEY, TEST_VALUE1); };
    like($@, qr/ArgumentNullException/, 'Set with null key throws ArgumentNullException');
}

sub test_item_indexer {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 27: Item getter for non-existing key
    ok(!defined($ht->Item(TEST_KEY1)), 'Item getter returns null for non-existing key');
    
    # Test 28: Item setter for new key
    $ht->Item(TEST_KEY1, TEST_VALUE1);
    is($ht->Count(), 1, 'Item setter for new key increases count');
    is($ht->Item(TEST_KEY1), TEST_VALUE1, 'Item getter returns correct value');
    
    # Test 29: Item setter for existing key
    $ht->Item(TEST_KEY1, TEST_VALUE2);
    is($ht->Count(), 1, 'Item setter for existing key maintains count');
    is($ht->Item(TEST_KEY1), TEST_VALUE2, 'Item setter updates value correctly');
    
    # Test 30: Item with null key should throw exception
    eval { $ht->Item(NULL_KEY); };
    like($@, qr/ArgumentNullException/, 'Item with null key throws ArgumentNullException');
}

#===========================================
# CONTAINS OPERATIONS TESTS
#===========================================

sub test_containskey {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, NULL_VALUE);
    
    # Test 31: ContainsKey for existing key with value
    ok($ht->ContainsKey(TEST_KEY1), 'ContainsKey returns true for existing key with value');
    
    # Test 32: ContainsKey for existing key with null value
    ok($ht->ContainsKey(TEST_KEY2), 'ContainsKey returns true for existing key with null value');
    
    # Test 33: ContainsKey for non-existing key
    ok(!$ht->ContainsKey("non_existing"), 'ContainsKey returns false for non-existing key');
    
    # Test 34: ContainsKey with null key should throw exception
    eval { $ht->ContainsKey(NULL_KEY); };
    like($@, qr/ArgumentNullException/, 'ContainsKey with null key throws ArgumentNullException');
    
    # Test 35: ContainsKey on empty hashtable
    my $empty_ht = System::Collections::Hashtable->new();
    ok(!$empty_ht->ContainsKey(TEST_KEY1), 'ContainsKey returns false on empty hashtable');
}

sub test_containsvalue {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    $ht->Add("null_key", NULL_VALUE);
    
    # Test 36: ContainsValue for existing value
    ok($ht->ContainsValue(TEST_VALUE1), 'ContainsValue returns true for existing value');
    ok($ht->ContainsValue(TEST_VALUE2), 'ContainsValue returns true for second existing value');
    
    # Test 37: ContainsValue for null value
    ok($ht->ContainsValue(NULL_VALUE), 'ContainsValue returns true for existing null value');
    
    # Test 38: ContainsValue for non-existing value
    ok(!$ht->ContainsValue("non_existing_value"), 'ContainsValue returns false for non-existing value');
    
    # Test 39: ContainsValue on empty hashtable
    my $empty_ht = System::Collections::Hashtable->new();
    ok(!$empty_ht->ContainsValue(TEST_VALUE1), 'ContainsValue returns false on empty hashtable');
    ok(!$empty_ht->ContainsValue(NULL_VALUE), 'ContainsValue returns false for null on empty hashtable');
}

#===========================================
# REMOVE OPERATIONS TESTS
#===========================================

sub test_remove {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    
    # Test 40: Remove existing key
    $ht->Remove(TEST_KEY1);
    is($ht->Count(), 1, 'Remove existing key decreases count');
    ok(!$ht->ContainsKey(TEST_KEY1), 'Remove existing key removes key');
    ok($ht->ContainsKey(TEST_KEY2), 'Remove existing key doesn\'t affect other keys');
    
    # Test 41: Remove non-existing key (should not throw)
    $ht->Remove("non_existing");
    is($ht->Count(), 1, 'Remove non-existing key doesn\'t change count');
    
    # Test 42: Remove with null key should throw exception
    eval { $ht->Remove(NULL_KEY); };
    like($@, qr/ArgumentNullException/, 'Remove with null key throws ArgumentNullException');
    
    # Test 43: Remove last item
    $ht->Remove(TEST_KEY2);
    is($ht->Count(), 0, 'Remove last item results in empty hashtable');
    ok(!$ht->ContainsKey(TEST_KEY2), 'Remove last item removes key');
}

sub test_clear {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    $ht->Add("key3", "value3");
    
    # Test 44: Clear non-empty hashtable
    is($ht->Count(), 3, 'Hashtable has items before clear');
    $ht->Clear();
    is($ht->Count(), 0, 'Clear results in zero count');
    ok(!$ht->ContainsKey(TEST_KEY1), 'Clear removes all keys');
    ok(!$ht->ContainsKey(TEST_KEY2), 'Clear removes all keys completely');
    
    # Test 45: Clear empty hashtable
    $ht->Clear();
    is($ht->Count(), 0, 'Clear empty hashtable maintains zero count');
    
    # Test 46: Clear null hashtable should throw exception
    my $null_ht = undef;
    eval { $null_ht->Clear(); };
    like($@, qr/NullReferenceException/, 'Clear on null hashtable throws NullReferenceException');
}

#===========================================
# COUNT OPERATIONS TESTS
#===========================================

sub test_count {
    # Test 47: Count on empty hashtable
    my $ht = System::Collections::Hashtable->new();
    is($ht->Count(), 0, 'Empty hashtable has zero count');
    
    # Test 48: Count after adding items
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    is($ht->Count(), 1, 'Count is 1 after adding one item');
    
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    is($ht->Count(), 2, 'Count is 2 after adding two items');
    
    # Test 49: Count after removing items
    $ht->Remove(TEST_KEY1);
    is($ht->Count(), 1, 'Count decreases after removal');
    
    # Test 50: Count after clear
    $ht->Clear();
    is($ht->Count(), 0, 'Count is 0 after clear');
    
    # Test 51: Count on null hashtable should throw exception
    my $null_ht = undef;
    eval { $null_ht->Count(); };
    like($@, qr/NullReferenceException/, 'Count on null hashtable throws NullReferenceException');
}

#===========================================
# ENUMERATION TESTS
#===========================================

sub test_enumeration_basic {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("key1", "value1");
    $ht->Add("key2", "value2");
    $ht->Add("key3", "value3");
    
    # Test 52: GetEnumerator returns valid enumerator
    my $enumerator = $ht->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::_KVPEnumerator', 'GetEnumerator returns correct type');
    
    # Test 53: Enumerate all items
    my $count = 0;
    my %found_pairs = ();
    while ($enumerator->MoveNext()) {
        my $entry = $enumerator->Current();
        isa_ok($entry, 'System::Collections::DictionaryEntry', 'Current returns DictionaryEntry');
        $found_pairs{$entry->Key} = $entry->Value;
        $count++;
    }
    is($count, 3, 'Enumeration visits all items');
    is($found_pairs{"key1"}, "value1", 'Enumeration finds first key-value pair');
    is($found_pairs{"key2"}, "value2", 'Enumeration finds second key-value pair');
    is($found_pairs{"key3"}, "value3", 'Enumeration finds third key-value pair');
    
    # Test 54: MoveNext returns false after end
    ok(!$enumerator->MoveNext(), 'MoveNext returns false after enumeration ends');
}

sub test_enumeration_edge_cases {
    # Test 55: Enumerate empty hashtable
    my $empty_ht = System::Collections::Hashtable->new();
    my $empty_enum = $empty_ht->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'MoveNext returns false for empty hashtable');
    
    # Test 56: Current before MoveNext should throw exception
    my $ht = System::Collections::Hashtable->new();
    $ht->Add(TEST_KEY1, TEST_VALUE1);
    my $enum = $ht->GetEnumerator();
    eval { $enum->Current(); };
    like($@, qr/InvalidOperationException/, 'Current before MoveNext throws InvalidOperationException');
    
    # Test 57: Current after enumeration ends should throw exception
    $enum->MoveNext();
    $enum->MoveNext(); # This should return false
    eval { $enum->Current(); };
    like($@, qr/InvalidOperationException/, 'Current after enumeration ends throws InvalidOperationException');
    
    # Test 58: Reset enumerator
    $ht->Add(TEST_KEY2, TEST_VALUE2);
    $enum->Reset();
    ok($enum->MoveNext(), 'Reset allows enumeration to start again');
    my $entry = $enum->Current();
    ok(defined($entry->Key), 'Reset enumerator provides valid entries');
}

sub test_enumeration_with_null_values {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("null_value", NULL_VALUE);
    $ht->Add("normal_key", "normal_value");
    
    # Test 59: Enumerate hashtable with null values
    my $enum = $ht->GetEnumerator();
    my $null_found = 0;
    my $normal_found = 0;
    
    while ($enum->MoveNext()) {
        my $entry = $enum->Current();
        if ($entry->Key eq "null_value") {
            ok(!defined($entry->Value), 'Enumeration correctly handles null values');
            $null_found = 1;
        } elsif ($entry->Key eq "normal_key") {
            is($entry->Value, "normal_value", 'Enumeration correctly handles normal values alongside nulls');
            $normal_found = 1;
        }
    }
    
    ok($null_found, 'Enumeration found null value entry');
    ok($normal_found, 'Enumeration found normal value entry');
}

#===========================================
# KEYS AND VALUES COLLECTION TESTS
#===========================================

sub test_keys_collection {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("key1", "value1");
    $ht->Add("key2", "value2");
    $ht->Add("key3", "value3");
    
    # Test 60: Keys returns valid collection
    my $keys = $ht->Keys();
    isa_ok($keys, 'System::Linq::SelectIterator', 'Keys returns enumerable collection');
    
    # Test 61: Keys collection has correct count
    my $keys_array = $keys->ToArray();
    is(scalar(@$keys_array), 3, 'Keys collection has correct count');
    
    # Test 62: Keys collection contains all keys
    my %key_set = map { $_ => 1 } @$keys_array;
    ok(exists $key_set{"key1"}, 'Keys collection contains first key');
    ok(exists $key_set{"key2"}, 'Keys collection contains second key');
    ok(exists $key_set{"key3"}, 'Keys collection contains third key');
    
    # Test 63: Keys on empty hashtable
    my $empty_ht = System::Collections::Hashtable->new();
    my $empty_keys = $empty_ht->Keys()->ToArray();
    is(scalar(@$empty_keys), 0, 'Keys collection is empty for empty hashtable');
}

sub test_values_collection {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("key1", "value1");
    $ht->Add("key2", "value2");
    $ht->Add("key3", NULL_VALUE);
    
    # Test 64: Values returns valid collection
    my $values = $ht->Values();
    isa_ok($values, 'System::Linq::SelectIterator', 'Values returns enumerable collection');
    
    # Test 65: Values collection has correct count
    my $values_array = $values->ToArray();
    is(scalar(@$values_array), 3, 'Values collection has correct count');
    
    # Test 66: Values collection contains all values
    my %value_set = ();
    foreach my $val (@$values_array) {
        if (defined($val)) {
            $value_set{$val} = 1;
        } else {
            $value_set{"__NULL__"} = 1;
        }
    }
    ok(exists $value_set{"value1"}, 'Values collection contains first value');
    ok(exists $value_set{"value2"}, 'Values collection contains second value');
    ok(exists $value_set{"__NULL__"}, 'Values collection contains null value');
    
    # Test 67: Values on empty hashtable
    my $empty_ht = System::Collections::Hashtable->new();
    my $empty_values = $empty_ht->Values()->ToArray();
    is(scalar(@$empty_values), 0, 'Values collection is empty for empty hashtable');
}

#===========================================
# ERROR HANDLING AND EDGE CASE TESTS
#===========================================

sub test_null_reference_exceptions {
    my $null_ht = undef;
    
    # Test 68-75: All major methods should throw NullReferenceException on null hashtable
    eval { $null_ht->GetEnumerator(); };
    like($@, qr/NullReferenceException/, 'GetEnumerator on null hashtable throws NullReferenceException');
    
    eval { $null_ht->Keys(); };
    like($@, qr/NullReferenceException/, 'Keys on null hashtable throws NullReferenceException');
    
    eval { $null_ht->Values(); };
    like($@, qr/NullReferenceException/, 'Values on null hashtable throws NullReferenceException');
    
    eval { $null_ht->AddOrUpdate("key", "value"); };
    like($@, qr/NullReferenceException/, 'AddOrUpdate on null hashtable throws NullReferenceException');
    
    eval { $null_ht->ContainsValue("value"); };
    like($@, qr/NullReferenceException/, 'ContainsValue on null hashtable throws NullReferenceException');
    
    eval { $null_ht->Item("key"); };
    like($@, qr/NullReferenceException/, 'Item on null hashtable throws NullReferenceException');
    
    eval { $null_ht->Set("key", "value"); };
    like($@, qr/NullReferenceException/, 'Set on null hashtable throws NullReferenceException');
}

sub test_string_key_edge_cases {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 76: Empty string key
    $ht->Add("", "empty_key_value");
    is($ht->Get(""), "empty_key_value", 'Empty string key works correctly');
    ok($ht->ContainsKey(""), 'ContainsKey works with empty string');
    
    # Test 77: Whitespace key
    $ht->Add("   ", "whitespace_value");
    is($ht->Get("   "), "whitespace_value", 'Whitespace key works correctly');
    
    # Test 78: Special characters in key
    $ht->Add("key!@#\$%^&*()", "special_chars_value");
    is($ht->Get("key!@#\$%^&*()"), "special_chars_value", 'Special characters in key work correctly');
    
    # Test 79: Unicode key
    $ht->Add("κλειδί", "greek_value");  # "key" in Greek
    is($ht->Get("κλειδί"), "greek_value", 'Unicode key works correctly');
    
    # Test 80: Very long key
    my $long_key = "x" x 1000;
    $ht->Add($long_key, "long_key_value");
    is($ht->Get($long_key), "long_key_value", 'Very long key works correctly');
}

sub test_value_edge_cases {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 81: Empty string value
    $ht->Add("empty_value_key", "");
    is($ht->Get("empty_value_key"), "", 'Empty string value works correctly');
    
    # Test 82: Numeric string values
    $ht->Add("numeric_string", "12345");
    is($ht->Get("numeric_string"), "12345", 'Numeric string value works correctly');
    
    # Test 83: Reference values (should work as they're treated as strings)
    my $ref_value = { inner => "value" };
    $ht->Add("reference_key", $ref_value);
    is($ht->Get("reference_key"), $ref_value, 'Reference value works correctly');
    
    # Test 84: Very long value
    my $long_value = "y" x 1000;
    $ht->Add("long_value_key", $long_value);
    is($ht->Get("long_value_key"), $long_value, 'Very long value works correctly');
}

sub test_memory_and_capacity {
    my $ht = System::Collections::Hashtable->new();
    
    # Test 85: Large number of items
    for my $i (1..100) {
        $ht->Add("key_$i", "value_$i");
    }
    is($ht->Count(), 100, 'Large number of items stored correctly');
    
    # Test 86: Random access to large hashtable
    is($ht->Get("key_50"), "value_50", 'Random access works in large hashtable');
    is($ht->Get("key_1"), "value_1", 'First item accessible in large hashtable');
    is($ht->Get("key_100"), "value_100", 'Last item accessible in large hashtable');
    
    # Test 87: Remove from large hashtable
    $ht->Remove("key_50");
    is($ht->Count(), 99, 'Remove from large hashtable works');
    ok(!$ht->ContainsKey("key_50"), 'Removed key not found in large hashtable');
    is($ht->Get("key_51"), "value_51", 'Adjacent keys unaffected by removal');
}

# Run all tests
test_construction();
test_construction_edge_cases();
test_add_basic();
test_add_error_handling();
test_addorupdate();
test_get_operations();
test_set_operations();
test_item_indexer();
test_containskey();
test_containsvalue();
test_remove();
test_clear();
test_count();
test_enumeration_basic();
test_enumeration_edge_cases();
test_enumeration_with_null_values();
test_keys_collection();
test_values_collection();
test_null_reference_exceptions();
test_string_key_edge_cases();
test_value_edge_cases();
test_memory_and_capacity();

done_testing();