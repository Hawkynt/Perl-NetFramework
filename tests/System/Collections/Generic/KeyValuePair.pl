#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Generic::KeyValuePair');
}

# Test constants
use constant {
    TEST_KEY => "testKey",
    TEST_VALUE => "testValue",
    NULL_KEY => undef,
    NULL_VALUE => undef,
};

#===========================================
# CONSTRUCTION TESTS
#===========================================

sub test_construction_basic {
    # Test 1: Basic construction with string key and value
    my $kvp1 = System::Collections::Generic::KeyValuePair->new(TEST_KEY, TEST_VALUE);
    isa_ok($kvp1, 'System::Collections::Generic::KeyValuePair', 'Constructor creates KeyValuePair');
    is($kvp1->Key(), TEST_KEY, 'Constructor stores key correctly');
    is($kvp1->Value(), TEST_VALUE, 'Constructor stores value correctly');
    
    # Test 2: Construction with null key
    my $kvp2 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, TEST_VALUE);
    isa_ok($kvp2, 'System::Collections::Generic::KeyValuePair', 'Constructor accepts null key');
    ok(!defined($kvp2->Key()), 'Null key stored as undefined');
    is($kvp2->Value(), TEST_VALUE, 'Value stored correctly with null key');
    
    # Test 3: Construction with null value
    my $kvp3 = System::Collections::Generic::KeyValuePair->new(TEST_KEY, NULL_VALUE);
    isa_ok($kvp3, 'System::Collections::Generic::KeyValuePair', 'Constructor accepts null value');
    is($kvp3->Key(), TEST_KEY, 'Key stored correctly with null value');
    ok(!defined($kvp3->Value()), 'Null value stored as undefined');
    
    # Test 4: Construction with both null key and value
    my $kvp4 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, NULL_VALUE);
    isa_ok($kvp4, 'System::Collections::Generic::KeyValuePair', 'Constructor accepts both nulls');
    ok(!defined($kvp4->Key()), 'Null key stored correctly');
    ok(!defined($kvp4->Value()), 'Null value stored correctly');
}

sub test_construction_edge_cases {
    # Test 5: Empty string key and value
    my $kvp1 = System::Collections::Generic::KeyValuePair->new("", "");
    is($kvp1->Key(), "", 'Empty string key stored correctly');
    is($kvp1->Value(), "", 'Empty string value stored correctly');
    
    # Test 6: Whitespace key and value
    my $kvp2 = System::Collections::Generic::KeyValuePair->new("   ", "\t\n");
    is($kvp2->Key(), "   ", 'Whitespace key preserved');
    is($kvp2->Value(), "\t\n", 'Whitespace value preserved');
    
    # Test 7: Special characters
    my $special_key = "key!@#\$%^&*(){}[]|\\:;\"'<>?,.~/`";
    my $special_value = "value!@#\$%^&*(){}[]|\\:;\"'<>?,.~/`";
    my $kvp3 = System::Collections::Generic::KeyValuePair->new($special_key, $special_value);
    is($kvp3->Key(), $special_key, 'Special characters in key preserved');
    is($kvp3->Value(), $special_value, 'Special characters in value preserved');
    
    # Test 8: Numeric values as strings
    my $kvp4 = System::Collections::Generic::KeyValuePair->new("123", "456.78");
    is($kvp4->Key(), "123", 'Numeric string key stored correctly');
    is($kvp4->Value(), "456.78", 'Numeric string value stored correctly');
}

#===========================================
# ACCESSOR METHOD TESTS
#===========================================

sub test_key_accessor {
    my $kvp = System::Collections::Generic::KeyValuePair->new(TEST_KEY, TEST_VALUE);
    
    # Test 9: Key method returns correct value
    is($kvp->Key(), TEST_KEY, 'Key() method returns correct key');
    
    # Test 10: Key method with null key
    my $null_kvp = System::Collections::Generic::KeyValuePair->new(NULL_KEY, TEST_VALUE);
    ok(!defined($null_kvp->Key()), 'Key() method returns undef for null key');
    
    # Test 11: Key method consistency
    my $key1 = $kvp->Key();
    my $key2 = $kvp->Key();
    is($key1, $key2, 'Key() method consistently returns same value');
}

sub test_value_accessor {
    my $kvp = System::Collections::Generic::KeyValuePair->new(TEST_KEY, TEST_VALUE);
    
    # Test 12: Value method returns correct value
    is($kvp->Value(), TEST_VALUE, 'Value() method returns correct value');
    
    # Test 13: Value method with null value
    my $null_kvp = System::Collections::Generic::KeyValuePair->new(TEST_KEY, NULL_VALUE);
    ok(!defined($null_kvp->Value()), 'Value() method returns undef for null value');
    
    # Test 14: Value method consistency
    my $value1 = $kvp->Value();
    my $value2 = $kvp->Value();
    is($value1, $value2, 'Value() method consistently returns same value');
}

#===========================================
# TOSTRING METHOD TESTS
#===========================================

sub test_toString {
    # Test 15: ToString with both key and value
    my $kvp1 = System::Collections::Generic::KeyValuePair->new("key1", "value1");
    my $str1 = $kvp1->ToString();
    is($str1, "[key1, value1]", 'ToString formats key-value pair correctly');
    
    # Test 16: ToString with null key
    my $kvp2 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, "value2");
    my $str2 = $kvp2->ToString();
    is($str2, "[<null>, value2]", 'ToString handles null key correctly');
    
    # Test 17: ToString with null value
    my $kvp3 = System::Collections::Generic::KeyValuePair->new("key3", NULL_VALUE);
    my $str3 = $kvp3->ToString();
    is($str3, "[key3, <null>]", 'ToString handles null value correctly');
    
    # Test 18: ToString with both nulls
    my $kvp4 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, NULL_VALUE);
    my $str4 = $kvp4->ToString();
    is($str4, "[<null>, <null>]", 'ToString handles both nulls correctly');
    
    # Test 19: ToString with empty strings
    my $kvp5 = System::Collections::Generic::KeyValuePair->new("", "");
    my $str5 = $kvp5->ToString();
    is($str5, "[, ]", 'ToString handles empty strings correctly');
}

#===========================================
# EQUALS METHOD TESTS
#===========================================

sub test_equals {
    my $kvp1 = System::Collections::Generic::KeyValuePair->new("key", "value");
    my $kvp2 = System::Collections::Generic::KeyValuePair->new("key", "value");
    my $kvp3 = System::Collections::Generic::KeyValuePair->new("key", "different");
    my $kvp4 = System::Collections::Generic::KeyValuePair->new("different", "value");
    
    # Test 20: Equal KeyValuePairs
    ok($kvp1->Equals($kvp2), 'Equal KeyValuePairs compare as equal');
    
    # Test 21: Different values
    ok(!$kvp1->Equals($kvp3), 'KeyValuePairs with different values not equal');
    
    # Test 22: Different keys
    ok(!$kvp1->Equals($kvp4), 'KeyValuePairs with different keys not equal');
    
    # Test 23: Null comparison
    ok(!$kvp1->Equals(undef), 'KeyValuePair not equal to null');
    
    # Test 24: Wrong type comparison
    ok(!$kvp1->Equals("string"), 'KeyValuePair not equal to different type');
    
    # Test 25: Self equality
    ok($kvp1->Equals($kvp1), 'KeyValuePair equals itself');
    
    # Test 26: Null keys
    my $kvp_null_key1 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, "value");
    my $kvp_null_key2 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, "value");
    ok($kvp_null_key1->Equals($kvp_null_key2), 'KeyValuePairs with null keys compare correctly');
    
    # Test 27: Null values
    my $kvp_null_val1 = System::Collections::Generic::KeyValuePair->new("key", NULL_VALUE);
    my $kvp_null_val2 = System::Collections::Generic::KeyValuePair->new("key", NULL_VALUE);
    ok($kvp_null_val1->Equals($kvp_null_val2), 'KeyValuePairs with null values compare correctly');
    
    # Test 28: Both nulls
    my $kvp_both_null1 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, NULL_VALUE);
    my $kvp_both_null2 = System::Collections::Generic::KeyValuePair->new(NULL_KEY, NULL_VALUE);
    ok($kvp_both_null1->Equals($kvp_both_null2), 'KeyValuePairs with both nulls compare correctly');
}

#===========================================
# GETHASHCODE METHOD TESTS
#===========================================

sub test_getHashCode {
    my $kvp1 = System::Collections::Generic::KeyValuePair->new("key", "value");
    my $kvp2 = System::Collections::Generic::KeyValuePair->new("key", "value");
    my $kvp3 = System::Collections::Generic::KeyValuePair->new("different", "value");
    
    # Test 29: Equal objects have same hash code
    is($kvp1->GetHashCode(), $kvp2->GetHashCode(), 'Equal KeyValuePairs have same hash code');
    
    # Test 30: Hash code consistency
    my $hash1 = $kvp1->GetHashCode();
    my $hash2 = $kvp1->GetHashCode();
    is($hash1, $hash2, 'GetHashCode returns consistent value');
    
    # Test 31: Different objects may have different hash codes
    my $hash3 = $kvp3->GetHashCode();
    # Note: Different objects may have same hash code due to collisions, so we just test it doesn't crash
    ok(defined($hash3), 'Different KeyValuePair produces valid hash code');
    
    # Test 32: Null key hash code
    my $kvp_null_key = System::Collections::Generic::KeyValuePair->new(NULL_KEY, "value");
    my $hash_null_key = $kvp_null_key->GetHashCode();
    ok(defined($hash_null_key), 'KeyValuePair with null key produces valid hash code');
    
    # Test 33: Null value hash code
    my $kvp_null_value = System::Collections::Generic::KeyValuePair->new("key", NULL_VALUE);
    my $hash_null_value = $kvp_null_value->GetHashCode();
    ok(defined($hash_null_value), 'KeyValuePair with null value produces valid hash code');
}

#===========================================
# INHERITANCE TESTS
#===========================================

sub test_inheritance {
    my $kvp = System::Collections::Generic::KeyValuePair->new(TEST_KEY, TEST_VALUE);
    
    # Test 34: KeyValuePair inherits from ValueType
    isa_ok($kvp, 'System::ValueType', 'KeyValuePair inherits from System::ValueType');
    
    # Test 35: Can call ValueType methods
    can_ok($kvp, 'ToString');
    can_ok($kvp, 'Equals');
    can_ok($kvp, 'GetHashCode');
    
    # Test 36: ToString method works (already tested above, but verify inheritance)
    my $string_rep = $kvp->ToString();
    ok(defined($string_rep), 'Inherited ToString returns defined value');
    like($string_rep, qr/\[.*,.*\]/, 'ToString follows expected format');
}

#===========================================
# NULL REFERENCE EXCEPTION TESTS
#===========================================

sub test_null_reference_exceptions {
    # Test 37: Key method on null object
    my $null_kvp = undef;
    eval { $null_kvp->Key(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Key throws on null reference');
    
    # Test 38: Value method on null object
    eval { $null_kvp->Value(); };
    like($@, qr/NullReferenceException|Can't call method/, 'Value throws on null reference');
    
    # Test 39: ToString method on null object
    eval { $null_kvp->ToString(); };
    like($@, qr/NullReferenceException|Can't call method/, 'ToString throws on null reference');
    
    # Test 40: Equals method on null object
    eval { $null_kvp->Equals($null_kvp); };
    like($@, qr/NullReferenceException|Can't call method/, 'Equals throws on null reference');
    
    # Test 41: GetHashCode method on null object
    eval { $null_kvp->GetHashCode(); };
    like($@, qr/NullReferenceException|Can't call method/, 'GetHashCode throws on null reference');
}

#===========================================
# MULTIPLE INSTANCES TESTS
#===========================================

sub test_multiple_instances {
    # Test 42: Multiple instances with same data
    my $kvp1 = System::Collections::Generic::KeyValuePair->new("same", "data");
    my $kvp2 = System::Collections::Generic::KeyValuePair->new("same", "data");
    
    isnt($kvp1, $kvp2, 'Different instances are different objects');
    ok($kvp1->Equals($kvp2), 'Different instances with same data are equal');
    is($kvp1->GetHashCode(), $kvp2->GetHashCode(), 'Same data produces same hash code');
    
    # Test 43: Array of KeyValuePairs
    my @kvps = (
        System::Collections::Generic::KeyValuePair->new("a", "1"),
        System::Collections::Generic::KeyValuePair->new("b", "2"),
        System::Collections::Generic::KeyValuePair->new("c", "3")
    );
    
    is(scalar(@kvps), 3, 'Can create array of KeyValuePair objects');
    is($kvps[0]->Key(), "a", 'Array element 0 key correct');
    is($kvps[1]->Value(), "2", 'Array element 1 value correct');
    is($kvps[2]->ToString(), "[c, 3]", 'Array element 2 ToString correct');
}

#===========================================
# STRESS AND PERFORMANCE TESTS
#===========================================

sub test_stress_conditions {
    # Test 44: Many KeyValuePair objects
    my @many_kvps;
    for my $i (1..1000) {
        push @many_kvps, System::Collections::Generic::KeyValuePair->new("key_$i", "value_$i");
    }
    
    is(scalar(@many_kvps), 1000, 'Can create many KeyValuePair objects');
    is($many_kvps[0]->Key(), "key_1", 'First KVP in large collection correct');
    is($many_kvps[999]->Value(), "value_1000", 'Last KVP in large collection correct');
    
    # Test 45: Large data in KeyValuePairs
    my $large_key = "k" x 1000;
    my $large_value = "v" x 1000;
    my $large_kvp = System::Collections::Generic::KeyValuePair->new($large_key, $large_value);
    
    is(length($large_kvp->Key()), 1000, 'Large key stored correctly');
    is(length($large_kvp->Value()), 1000, 'Large value stored correctly');
    
    # Test that ToString works with large data
    my $large_str = $large_kvp->ToString();
    ok(length($large_str) > 2000, 'ToString works with large data');
}

#===========================================
# INTEGRATION TESTS
#===========================================

sub test_integration_scenarios {
    # Test 46: Use in dictionary simulation
    my @dict_simulation = (
        System::Collections::Generic::KeyValuePair->new("name", "John"),
        System::Collections::Generic::KeyValuePair->new("age", "30"),
        System::Collections::Generic::KeyValuePair->new("city", "New York")
    );
    
    # Find KVP by key
    my $found_kvp;
    for my $kvp (@dict_simulation) {
        if ($kvp->Key() eq "age") {
            $found_kvp = $kvp;
            last;
        }
    }
    
    ok(defined($found_kvp), 'Can find KVP by key in array');
    is($found_kvp->Value(), "30", 'Found KVP has correct value');
    
    # Test 47: Use in enumeration pattern
    my %key_value_map = ();
    for my $kvp (@dict_simulation) {
        $key_value_map{$kvp->Key()} = $kvp->Value();
    }
    
    is($key_value_map{"name"}, "John", 'Enumeration pattern works - name');
    is($key_value_map{"age"}, "30", 'Enumeration pattern works - age');
    is($key_value_map{"city"}, "New York", 'Enumeration pattern works - city');
    
    # Test 48: KeyValuePair as function parameter and return value
    sub process_kvp {
        my ($kvp) = @_;
        return System::Collections::Generic::KeyValuePair->new(uc($kvp->Key()), uc($kvp->Value()));
    }
    
    my $original_kvp = System::Collections::Generic::KeyValuePair->new("lower", "case");
    my $processed_kvp = process_kvp($original_kvp);
    
    is($processed_kvp->Key(), "LOWER", 'Function can process KeyValuePair key');
    is($processed_kvp->Value(), "CASE", 'Function can process KeyValuePair value');
}

#===========================================
# EDGE CASE TESTS
#===========================================

sub test_edge_cases {
    # Test 49: KeyValuePair with complex reference types
    my $complex_key = { nested => [1, 2, 3] };
    my $complex_value = { data => "complex" };
    my $complex_kvp = System::Collections::Generic::KeyValuePair->new($complex_key, $complex_value);
    
    is($complex_kvp->Key(), $complex_key, 'Complex reference key stored correctly');
    is($complex_kvp->Value(), $complex_value, 'Complex reference value stored correctly');
    
    # Test 50: KeyValuePair equality with complex types (should use eq comparison)
    my $complex_kvp2 = System::Collections::Generic::KeyValuePair->new($complex_key, $complex_value);
    # Note: This will likely fail with references unless they stringify the same way
    # but it tests the behavior
    eval {
        my $are_equal = $complex_kvp->Equals($complex_kvp2);
        ok(defined($are_equal), 'Equals handles complex references without crashing');
    };
    ok(!$@, 'Equals method handles complex references gracefully');
}

# Run all tests
test_construction_basic();
test_construction_edge_cases();
test_key_accessor();
test_value_accessor();
test_toString();
test_equals();
test_getHashCode();
test_inheritance();
test_null_reference_exceptions();
test_multiple_instances();
test_stress_conditions();
test_integration_scenarios();
test_edge_cases();

done_testing();