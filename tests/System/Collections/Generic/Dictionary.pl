#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Generic::Dictionary');
}

#===========================================
# CONSTRUCTION TESTS
#===========================================

sub test_construction {
    # Test 1: Default constructor
    my $dict1 = System::Collections::Generic::Dictionary->new();
    isa_ok($dict1, 'System::Collections::Generic::Dictionary', 'Default constructor creates Dictionary');
    is($dict1->Count(), 0, 'Default constructor creates empty dictionary');
    
    # Test 2: Constructor with capacity
    my $dict2 = System::Collections::Generic::Dictionary->new(20);
    isa_ok($dict2, 'System::Collections::Generic::Dictionary', 'Constructor with capacity creates Dictionary');
    is($dict2->Count(), 0, 'Constructor with capacity creates empty dictionary');
    
    # Test 3: Constructor with zero capacity
    my $dict3 = System::Collections::Generic::Dictionary->new(0);
    isa_ok($dict3, 'System::Collections::Generic::Dictionary', 'Constructor with zero capacity works');
    is($dict3->Count(), 0, 'Zero capacity dictionary is empty');
}

#===========================================
# ADD AND COUNT TESTS
#===========================================

sub test_add_and_count {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 4: Count on empty dictionary
    is($dict->Count(), 0, 'Empty dictionary has count 0');
    
    # Test 5: Single add
    $dict->Add("key1", "value1");
    is($dict->Count(), 1, 'Count increases after add');
    
    # Test 6: Multiple adds
    $dict->Add("key2", "value2");
    $dict->Add("key3", "value3");
    is($dict->Count(), 3, 'Count correct after multiple adds');
    
    # Test 7: Add null value
    $dict->Add("null_value_key", undef);
    is($dict->Count(), 4, 'Can add null value');
    
    # Test 8: Add with different value types
    $dict->Add("int_key", 42);
    $dict->Add("float_key", 3.14);
    is($dict->Count(), 6, 'Can add different value types');
    
    # Test 9: Add duplicate key throws exception
    eval { $dict->Add("key1", "duplicate_value"); };
    like($@, qr/ArgumentException|same key has already been added/, 'Add duplicate key throws exception');
    is($dict->Count(), 6, 'Count unchanged after failed add');
}

#===========================================
# ITEM INDEXER TESTS
#===========================================

sub test_item_indexer {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 10: Item getter on non-existent key throws exception
    eval { $dict->Item("missing_key"); };
    like($@, qr/KeyNotFoundException|key was not present/, 'Item getter throws on missing key');
    
    # Test 11: Item setter adds new key-value pair
    $dict->Item("new_key", "new_value");
    is($dict->Count(), 1, 'Item setter adds new entry');
    is($dict->Item("new_key"), "new_value", 'Item getter retrieves set value');
    
    # Test 12: Item setter updates existing key
    $dict->Item("new_key", "updated_value");
    is($dict->Count(), 1, 'Item setter does not increase count for existing key');
    is($dict->Item("new_key"), "updated_value", 'Item setter updates existing value');
    
    # Test 13: Item with null key throws exception
    eval { $dict->Item(undef, "value"); };
    like($@, qr/ArgumentNullException|key/, 'Item setter throws on null key');
    
    eval { $dict->Item(undef); };
    like($@, qr/ArgumentNullException|key/, 'Item getter throws on null key');
    
    # Test 14: Item with null value
    $dict->Item("null_val_key", undef);
    ok(!defined($dict->Item("null_val_key")), 'Can set and get null value via Item');
}

#===========================================
# REMOVE TESTS
#===========================================

sub test_remove {
    my $dict = System::Collections::Generic::Dictionary->new();
    $dict->Add("key1", "value1");
    $dict->Add("key2", "value2");
    $dict->Add("key3", "value3");
    
    # Test 15: Remove existing key
    my $removed = $dict->Remove("key2");
    ok($removed, 'Remove returns true for existing key');
    is($dict->Count(), 2, 'Count decreases after remove');
    
    # Test 16: Remove non-existing key
    my $not_removed = $dict->Remove("missing_key");
    ok(!$not_removed, 'Remove returns false for non-existing key');
    is($dict->Count(), 2, 'Count unchanged when removing non-existing key');
    
    # Test 17: Remove null key throws exception
    eval { $dict->Remove(undef); };
    like($@, qr/ArgumentNullException|key/, 'Remove throws on null key');
    
    # Test 18: Verify removed key no longer accessible
    eval { $dict->Item("key2"); };
    like($@, qr/KeyNotFoundException|key was not present/, 'Removed key not accessible');
    
    # Test 19: Other keys still accessible after remove
    is($dict->Item("key1"), "value1", 'Remaining keys still accessible');
    is($dict->Item("key3"), "value3", 'Remaining keys still accessible');
}

#===========================================
# CLEAR TESTS
#===========================================

sub test_clear {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 20: Clear empty dictionary
    $dict->Clear();
    is($dict->Count(), 0, 'Clear on empty dictionary works');
    
    # Test 21: Clear populated dictionary
    $dict->Add("key1", "value1");
    $dict->Add("key2", "value2");
    $dict->Add("key3", "value3");
    is($dict->Count(), 3, 'Dictionary has items before clear');
    
    $dict->Clear();
    is($dict->Count(), 0, 'Dictionary is empty after clear');
    
    # Test 22: Keys not accessible after clear
    eval { $dict->Item("key1"); };
    like($@, qr/KeyNotFoundException|key was not present/, 'Keys not accessible after clear');
    
    # Test 23: Can add after clear
    $dict->Add("after_clear", "value");
    is($dict->Count(), 1, 'Can add after clear');
    is($dict->Item("after_clear"), "value", 'Item added after clear works correctly');
}

#===========================================
# CONTAINSKEY TESTS
#===========================================

sub test_containsKey {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 24: ContainsKey on empty dictionary
    ok(!$dict->ContainsKey("anything"), 'Empty dictionary does not contain any key');
    
    # Test 25: ContainsKey existing key
    $dict->Add("existing", "value");
    ok($dict->ContainsKey("existing"), 'Dictionary contains existing key');
    
    # Test 26: ContainsKey non-existing key
    ok(!$dict->ContainsKey("missing"), 'Dictionary does not contain non-existing key');
    
    # Test 27: ContainsKey null key throws exception
    eval { $dict->ContainsKey(undef); };
    like($@, qr/ArgumentNullException|key/, 'ContainsKey throws on null key');
    
    # Test 28: ContainsKey after remove
    $dict->Add("to_remove", "value");
    ok($dict->ContainsKey("to_remove"), 'Key exists before remove');
    $dict->Remove("to_remove");
    ok(!$dict->ContainsKey("to_remove"), 'Key does not exist after remove');
}

#===========================================
# CONTAINSVALUE TESTS
#===========================================

sub test_containsValue {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 29: ContainsValue on empty dictionary
    ok(!$dict->ContainsValue("anything"), 'Empty dictionary does not contain any value');
    
    # Test 30: ContainsValue existing value
    $dict->Add("key1", "existing_value");
    ok($dict->ContainsValue("existing_value"), 'Dictionary contains existing value');
    
    # Test 31: ContainsValue non-existing value
    ok(!$dict->ContainsValue("missing_value"), 'Dictionary does not contain non-existing value');
    
    # Test 32: ContainsValue null value
    $dict->Add("null_key", undef);
    ok($dict->ContainsValue(undef), 'Dictionary contains null value');
    
    # Test 33: ContainsValue with duplicate values
    $dict->Add("key2", "existing_value");
    ok($dict->ContainsValue("existing_value"), 'Dictionary contains value present in multiple keys');
    
    # Test 34: ContainsValue after value update
    $dict->Item("key1", "updated_value");
    ok(!$dict->ContainsValue("existing_value"), 'Old value not found after update');
    ok($dict->ContainsValue("updated_value"), 'New value found after update');
}

#===========================================
# TRYGETVALUE TESTS
#===========================================

sub test_tryGetValue {
    my $dict = System::Collections::Generic::Dictionary->new();
    $dict->Add("existing_key", "existing_value");
    $dict->Add("null_value_key", undef);
    
    # Test 35: TryGetValue existing key
    my $value;
    my $found = $dict->TryGetValue("existing_key", \$value);
    ok($found, 'TryGetValue returns true for existing key');
    is($value, "existing_value", 'TryGetValue sets correct value for existing key');
    
    # Test 36: TryGetValue non-existing key
    my $missing_value;
    my $not_found = $dict->TryGetValue("missing_key", \$missing_value);
    ok(!$not_found, 'TryGetValue returns false for non-existing key');
    ok(!defined($missing_value), 'TryGetValue sets undef for non-existing key');
    
    # Test 37: TryGetValue with null value
    my $null_value;
    my $null_found = $dict->TryGetValue("null_value_key", \$null_value);
    ok($null_found, 'TryGetValue returns true for key with null value');
    ok(!defined($null_value), 'TryGetValue correctly retrieves null value');
    
    # Test 38: TryGetValue null key throws exception
    my $dummy_value;
    eval { $dict->TryGetValue(undef, \$dummy_value); };
    like($@, qr/ArgumentNullException|key/, 'TryGetValue throws on null key');
    
    # Test 39: TryGetValue null value reference throws exception
    eval { $dict->TryGetValue("existing_key", undef); };
    like($@, qr/ArgumentNullException|value/, 'TryGetValue throws on null value reference');
}

#===========================================
# KEYS AND VALUES COLLECTIONS TESTS
#===========================================

sub test_keys_and_values {
    my $dict = System::Collections::Generic::Dictionary->new();
    $dict->Add("key1", "value1");
    $dict->Add("key2", "value2");
    $dict->Add("key3", "value3");
    
    # Test 40: Keys collection
    my $keys = $dict->Keys();
    ok(defined($keys), 'Keys returns defined collection');
    isa_ok($keys, 'System::Collections::Generic::DictionaryKeyCollection', 'Keys returns key collection');
    
    # Test 41: Values collection
    my $values = $dict->Values();
    ok(defined($values), 'Values returns defined collection');
    isa_ok($values, 'System::Collections::Generic::DictionaryValueCollection', 'Values returns value collection');
}

#===========================================
# ENUMERATOR TESTS
#===========================================

sub test_enumerator {
    my $dict = System::Collections::Generic::Dictionary->new();
    $dict->Add("key1", "value1");
    $dict->Add("key2", "value2");
    $dict->Add("key3", "value3");
    
    # Test 42: GetEnumerator returns enumerator
    my $enumerator = $dict->GetEnumerator();
    ok(defined($enumerator), 'GetEnumerator returns defined enumerator');
    can_ok($enumerator, 'MoveNext');
    can_ok($enumerator, 'Current');
    
    # Test 43: Enumeration visits all key-value pairs
    my %enumerated;
    my $count = 0;
    while ($enumerator->MoveNext()) {
        $count++;
        my $current = $enumerator->Current();
        ok(defined($current), 'Current returns defined KeyValuePair');
        
        # Current should return a KeyValuePair
        if ($current->can('Key') && $current->can('Value')) {
            $enumerated{$current->Key()} = $current->Value();
        }
    }
    
    is($count, 3, 'Enumerator visits all items');
    
    # Test 44: Enumerator on empty dictionary
    my $empty_dict = System::Collections::Generic::Dictionary->new();
    my $empty_enum = $empty_dict->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'Enumerator on empty dictionary returns false for MoveNext');
}

#===========================================
# NULL REFERENCE EXCEPTION TESTS
#===========================================

sub test_null_reference_exceptions {
    my $null_dict = undef;
    
    # Test 45: Count on null reference
    eval { $null_dict->Count(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Count throws on null reference');
    
    # Test 46: Add on null reference
    eval { $null_dict->Add("key", "value"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Add throws on null reference');
    
    # Test 47: Item on null reference
    eval { $null_dict->Item("key"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Item getter throws on null reference');
    
    eval { $null_dict->Item("key", "value"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Item setter throws on null reference');
    
    # Test 48: Remove on null reference
    eval { $null_dict->Remove("key"); };
    like($@, qr/NullReferenceException|Can't call method/, 'Remove throws on null reference');
    
    # Test 49: Clear on null reference
    eval { $null_dict->Clear(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Clear throws on null reference');
    
    # Test 50: ContainsKey on null reference
    eval { $null_dict->ContainsKey("key"); };
    like($@, qr/NullReferenceException|Can't call method/, 'ContainsKey throws on null reference');
    
    # Test 51: ContainsValue on null reference
    eval { $null_dict->ContainsValue("value"); };
    like($@, qr/NullReferenceException|Can't call method/, 'ContainsValue throws on null reference');
    
    # Test 52: TryGetValue on null reference
    my $dummy_value;
    eval { $null_dict->TryGetValue("key", \$dummy_value); };
    like($@, qr/NullReferenceException|Can't call method/, 'TryGetValue throws on null reference');
    
    # Test 53: Keys on null reference
    eval { $null_dict->Keys(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Keys throws on null reference');
    
    # Test 54: Values on null reference
    eval { $null_dict->Values(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Values throws on null reference');
    
    # Test 55: GetEnumerator on null reference
    eval { $null_dict->GetEnumerator(); };
    like($@, qr/NullReferenceException|Can't call method/, 'GetEnumerator throws on null reference');
}

#===========================================
# MIXED OPERATIONS TESTS
#===========================================

sub test_mixed_operations {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 56: Mix Add and Item setter
    $dict->Add("add_key", "add_value");
    $dict->Item("item_key", "item_value");
    is($dict->Count(), 2, 'Mix of Add and Item setter works');
    
    # Test 57: Update via Item setter
    $dict->Item("add_key", "updated_via_item");
    is($dict->Count(), 2, 'Item setter update does not increase count');
    is($dict->Item("add_key"), "updated_via_item", 'Item setter update works correctly');
    
    # Test 58: Complex workflow
    $dict->Clear();
    $dict->Add("start", "begin");
    ok($dict->ContainsKey("start"), 'Key exists after add');
    
    $dict->Item("start", "modified");
    is($dict->Item("start"), "modified", 'Value updated correctly');
    
    $dict->Remove("start");
    ok(!$dict->ContainsKey("start"), 'Key removed correctly');
    is($dict->Count(), 0, 'Dictionary empty after remove');
}

#===========================================
# KEY TYPES TESTS
#===========================================

sub test_different_key_types {
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Test 59: String keys
    $dict->Add("string_key", "string_value");
    is($dict->Item("string_key"), "string_value", 'String key works');
    
    # Test 60: Numeric keys (stored as strings in Perl)
    $dict->Add("123", "numeric_value");
    is($dict->Item("123"), "numeric_value", 'Numeric string key works');
    
    # Test 61: Empty string key
    $dict->Add("", "empty_key_value");
    is($dict->Item(""), "empty_key_value", 'Empty string key works');
    
    # Test 62: Whitespace key
    $dict->Add("   ", "space_key_value");
    is($dict->Item("   "), "space_key_value", 'Whitespace key works');
}

#===========================================
# STRESS TESTS
#===========================================

sub test_stress_conditions {
    # Test 63: Large number of entries
    my $dict = System::Collections::Generic::Dictionary->new();
    
    # Add many entries
    for my $i (1..1000) {
        $dict->Add("key_$i", "value_$i");
    }
    is($dict->Count(), 1000, 'Can handle large number of entries');
    
    # Verify random access
    is($dict->Item("key_500"), "value_500", 'Random access works with large dictionary');
    ok($dict->ContainsKey("key_1"), 'First key exists in large dictionary');
    ok($dict->ContainsKey("key_1000"), 'Last key exists in large dictionary');
    
    # Remove some entries
    for my $i (1..100) {
        $dict->Remove("key_$i");
    }
    is($dict->Count(), 900, 'Removal works with large dictionary');
    ok(!$dict->ContainsKey("key_50"), 'Removed key not found');
    ok($dict->ContainsKey("key_500"), 'Non-removed key still found');
    
    # Test 64: Large data values
    my $large_dict = System::Collections::Generic::Dictionary->new();
    my $large_value = "x" x 10000;
    $large_dict->Add("large_key", $large_value);
    my $retrieved = $large_dict->Item("large_key");
    is(length($retrieved), 10000, 'Can handle large data values');
}

#===========================================
# EDGE CASES
#===========================================

sub test_edge_cases {
    # Test 65: Dictionary with only null values
    my $dict = System::Collections::Generic::Dictionary->new();
    $dict->Add("null1", undef);
    $dict->Add("null2", undef);
    $dict->Add("null3", undef);
    
    is($dict->Count(), 3, 'Dictionary can contain multiple null values');
    ok($dict->ContainsValue(undef), 'Dictionary contains null values');
    ok(!defined($dict->Item("null1")), 'Can retrieve null values');
    
    # Test 66: Mixed null and non-null values
    $dict->Add("real", "actual_value");
    ok($dict->ContainsValue("actual_value"), 'Dictionary contains both null and non-null values');
    ok($dict->ContainsValue(undef), 'Dictionary still contains null values after adding non-null');
    
    # Test 67: Case sensitivity
    $dict->Clear();
    $dict->Add("Key", "upper");
    $dict->Add("key", "lower");
    $dict->Add("KEY", "all_upper");
    
    is($dict->Count(), 3, 'Keys are case sensitive');
    is($dict->Item("Key"), "upper", 'Case sensitive key access - mixed case');
    is($dict->Item("key"), "lower", 'Case sensitive key access - lower case');
    is($dict->Item("KEY"), "all_upper", 'Case sensitive key access - upper case');
}

#===========================================
# INTEGRATION TESTS
#===========================================

sub test_integration_scenarios {
    # Test 68: Dictionary as a simple cache
    my $cache = System::Collections::Generic::Dictionary->new();
    
    sub get_cached_value {
        my ($cache, $key, $compute_func) = @_;
        
        if ($cache->ContainsKey($key)) {
            return $cache->Item($key);
        } else {
            my $value = &$compute_func($key);
            $cache->Add($key, $value);
            return $value;
        }
    }
    
    my $compute_count = 0;
    my $compute_func = sub { 
        my ($key) = @_;
        $compute_count++;
        return "computed_$key";
    };
    
    my $value1 = get_cached_value($cache, "test", $compute_func);
    is($value1, "computed_test", 'Cache miss computes value');
    is($compute_count, 1, 'Compute function called once');
    
    my $value2 = get_cached_value($cache, "test", $compute_func);
    is($value2, "computed_test", 'Cache hit returns same value');
    is($compute_count, 1, 'Compute function not called again');
    
    # Test 69: Dictionary for counting occurrences
    my $counter = System::Collections::Generic::Dictionary->new();
    my @words = qw(apple banana apple cherry banana apple);
    
    for my $word (@words) {
        my $current_count;
        if ($counter->TryGetValue($word, \$current_count)) {
            $counter->Item($word, $current_count + 1);
        } else {
            $counter->Add($word, 1);
        }
    }
    
    is($counter->Item("apple"), 3, 'Counter dictionary - apple count');
    is($counter->Item("banana"), 2, 'Counter dictionary - banana count');
    is($counter->Item("cherry"), 1, 'Counter dictionary - cherry count');
    is($counter->Count(), 3, 'Counter dictionary - unique words count');
}

# Run all tests
test_construction();
test_add_and_count();
test_item_indexer();
test_remove();
test_clear();
test_containsKey();
test_containsValue();
test_tryGetValue();
test_keys_and_values();
test_enumerator();
test_null_reference_exceptions();
test_mixed_operations();
test_different_key_types();
test_stress_conditions();
test_edge_cases();
test_integration_scenarios();

done_testing();