#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::DictionaryEntry');
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
    my $entry1 = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    isa_ok($entry1, 'System::Collections::DictionaryEntry', 'Constructor creates DictionaryEntry');
    is($entry1->Key(), TEST_KEY, 'Constructor stores key correctly');
    is($entry1->Value(), TEST_VALUE, 'Constructor stores value correctly');
    
    # Test 2: Construction with null key
    my $entry2 = System::Collections::DictionaryEntry->new(NULL_KEY, TEST_VALUE);
    isa_ok($entry2, 'System::Collections::DictionaryEntry', 'Constructor accepts null key');
    ok(!defined($entry2->Key()), 'Null key stored as undefined');
    is($entry2->Value(), TEST_VALUE, 'Value stored correctly with null key');
    
    # Test 3: Construction with null value
    my $entry3 = System::Collections::DictionaryEntry->new(TEST_KEY, NULL_VALUE);
    isa_ok($entry3, 'System::Collections::DictionaryEntry', 'Constructor accepts null value');
    is($entry3->Key(), TEST_KEY, 'Key stored correctly with null value');
    ok(!defined($entry3->Value()), 'Null value stored as undefined');
    
    # Test 4: Construction with both null key and value
    my $entry4 = System::Collections::DictionaryEntry->new(NULL_KEY, NULL_VALUE);
    isa_ok($entry4, 'System::Collections::DictionaryEntry', 'Constructor accepts both nulls');
    ok(!defined($entry4->Key()), 'Null key stored correctly');
    ok(!defined($entry4->Value()), 'Null value stored correctly');
}

sub test_construction_edge_cases {
    # Test 5: Empty string key
    my $entry5 = System::Collections::DictionaryEntry->new("", TEST_VALUE);
    is($entry5->Key(), "", 'Empty string key stored correctly');
    is($entry5->Value(), TEST_VALUE, 'Value stored correctly with empty string key');
    
    # Test 6: Empty string value
    my $entry6 = System::Collections::DictionaryEntry->new(TEST_KEY, "");
    is($entry6->Key(), TEST_KEY, 'Key stored correctly with empty string value');
    is($entry6->Value(), "", 'Empty string value stored correctly');
    
    # Test 7: Whitespace key and value
    my $entry7 = System::Collections::DictionaryEntry->new("   ", "   ");
    is($entry7->Key(), "   ", 'Whitespace key preserved');
    is($entry7->Value(), "   ", 'Whitespace value preserved');
    
    # Test 8: Special characters in key and value
    my $special_key = "key!@#\$%^&*(){}[]|\\:;\"'<>?,.~/`";
    my $special_value = "value!@#\$%^&*(){}[]|\\:;\"'<>?,.~/`";
    my $entry8 = System::Collections::DictionaryEntry->new($special_key, $special_value);
    is($entry8->Key(), $special_key, 'Special characters in key preserved');
    is($entry8->Value(), $special_value, 'Special characters in value preserved');
    
    # Test 9: Unicode characters
    my $unicode_key = "κλειδί"; # "key" in Greek
    my $unicode_value = "αξία"; # "value" in Greek
    my $entry9 = System::Collections::DictionaryEntry->new($unicode_key, $unicode_value);
    is($entry9->Key(), $unicode_key, 'Unicode key preserved');
    is($entry9->Value(), $unicode_value, 'Unicode value preserved');
    
    # Test 10: Very long key and value
    my $long_key = "k" x 1000;
    my $long_value = "v" x 1000;
    my $entry10 = System::Collections::DictionaryEntry->new($long_key, $long_value);
    is($entry10->Key(), $long_key, 'Very long key stored correctly');
    is($entry10->Value(), $long_value, 'Very long value stored correctly');
}

sub test_construction_with_different_types {
    # Test 11: Numeric key and value (as strings in Perl)
    my $entry11 = System::Collections::DictionaryEntry->new("123", "456");
    is($entry11->Key(), "123", 'Numeric string key stored correctly');
    is($entry11->Value(), "456", 'Numeric string value stored correctly');
    
    # Test 12: Reference as key (should work in Perl)
    my $ref_key = { inner => "key" };
    my $entry12 = System::Collections::DictionaryEntry->new($ref_key, TEST_VALUE);
    is($entry12->Key(), $ref_key, 'Reference key stored correctly');
    is($entry12->Value(), TEST_VALUE, 'Value stored correctly with reference key');
    
    # Test 13: Reference as value
    my $ref_value = { inner => "value" };
    my $entry13 = System::Collections::DictionaryEntry->new(TEST_KEY, $ref_value);
    is($entry13->Key(), TEST_KEY, 'Key stored correctly with reference value');
    is($entry13->Value(), $ref_value, 'Reference value stored correctly');
    
    # Test 14: Array reference as key
    my $array_key = ["key", "parts"];
    my $entry14 = System::Collections::DictionaryEntry->new($array_key, TEST_VALUE);
    is($entry14->Key(), $array_key, 'Array reference key stored correctly');
    is($entry14->Value(), TEST_VALUE, 'Value stored correctly with array reference key');
}

#===========================================
# ACCESSOR METHOD TESTS
#===========================================

sub test_key_accessor {
    my $entry = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    
    # Test 15: Key method returns correct value
    is($entry->Key(), TEST_KEY, 'Key() method returns correct key');
    
    # Test 16: Key method with null key
    my $null_entry = System::Collections::DictionaryEntry->new(NULL_KEY, TEST_VALUE);
    ok(!defined($null_entry->Key()), 'Key() method returns undef for null key');
    
    # Test 17: Key method is read-only (cannot modify internal state)
    my $original_key = $entry->Key();
    is($entry->Key(), $original_key, 'Key() method consistently returns same value');
    
    # Test 18: Key method on object with changed internal state
    # This tests that the accessor truly accesses internal state
    $entry->{_key} = "modified_key";
    is($entry->Key(), "modified_key", 'Key() method reflects internal state changes');
}

sub test_value_accessor {
    my $entry = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    
    # Test 19: Value method returns correct value
    is($entry->Value(), TEST_VALUE, 'Value() method returns correct value');
    
    # Test 20: Value method with null value
    my $null_entry = System::Collections::DictionaryEntry->new(TEST_KEY, NULL_VALUE);
    ok(!defined($null_entry->Value()), 'Value() method returns undef for null value');
    
    # Test 21: Value method is read-only (cannot modify internal state)
    my $original_value = $entry->Value();
    is($entry->Value(), $original_value, 'Value() method consistently returns same value');
    
    # Test 22: Value method on object with changed internal state
    $entry->{_value} = "modified_value";
    is($entry->Value(), "modified_value", 'Value() method reflects internal state changes');
}

#===========================================
# IMMUTABILITY TESTS
#===========================================

sub test_immutability_behavior {
    my $entry = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    
    # Test 23: Key and Value should be stable after creation
    my $key1 = $entry->Key();
    my $value1 = $entry->Value();
    my $key2 = $entry->Key();
    my $value2 = $entry->Value();
    
    is($key1, $key2, 'Key() returns consistent value across calls');
    is($value1, $value2, 'Value() returns consistent value across calls');
    
    # Test 24: DictionaryEntry acts as a data container
    # External modifications to key/value shouldn't affect the entry if they're strings
    my $mutable_key = "mutable";
    my $mutable_value = "changeable";
    my $mutable_entry = System::Collections::DictionaryEntry->new($mutable_key, $mutable_value);
    
    $mutable_key = "changed"; # This shouldn't affect the entry since strings are copied
    $mutable_value = "modified";
    
    isnt($mutable_entry->Key(), $mutable_key, 'Entry key unaffected by external variable changes');
    isnt($mutable_entry->Value(), $mutable_value, 'Entry value unaffected by external variable changes');
}

#===========================================
# INHERITANCE AND TYPE TESTS
#===========================================

sub test_inheritance {
    my $entry = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    
    # Test 25: DictionaryEntry inherits from System::Object
    isa_ok($entry, 'System::Object', 'DictionaryEntry inherits from System::Object');
    
    # Test 26: Can call System::Object methods
    can_ok($entry, 'ToString');
    can_ok($entry, 'GetType');
    can_ok($entry, 'Equals');
    
    # Test 27: ToString method (from System::Object)
    my $string_rep = $entry->ToString();
    ok(defined($string_rep), 'ToString returns defined value');
    like($string_rep, qr/DictionaryEntry/, 'ToString contains class name');
}

#===========================================
# MULTIPLE INSTANCES TESTS
#===========================================

sub test_multiple_instances {
    # Test 28: Multiple instances with same data
    my $entry1 = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    my $entry2 = System::Collections::DictionaryEntry->new(TEST_KEY, TEST_VALUE);
    
    isnt($entry1, $entry2, 'Different instances are different objects');
    is($entry1->Key(), $entry2->Key(), 'Different instances can have same key');
    is($entry1->Value(), $entry2->Value(), 'Different instances can have same value');
    
    # Test 29: Multiple instances with different data
    my $entry3 = System::Collections::DictionaryEntry->new("key1", "value1");
    my $entry4 = System::Collections::DictionaryEntry->new("key2", "value2");
    
    isnt($entry3->Key(), $entry4->Key(), 'Different instances have different keys');
    isnt($entry3->Value(), $entry4->Value(), 'Different instances have different values');
    
    # Test 30: Array of DictionaryEntry objects
    my @entries = (
        System::Collections::DictionaryEntry->new("a", "1"),
        System::Collections::DictionaryEntry->new("b", "2"),
        System::Collections::DictionaryEntry->new("c", "3")
    );
    
    is(scalar(@entries), 3, 'Can create array of DictionaryEntry objects');
    is($entries[0]->Key(), "a", 'Array element 0 key correct');
    is($entries[1]->Value(), "2", 'Array element 1 value correct');
    is($entries[2]->Key(), "c", 'Array element 2 key correct');
}

#===========================================
# MEMORY AND REFERENCE TESTS
#===========================================

sub test_reference_handling {
    # Test 31: Complex reference as key
    my $complex_ref = {
        name => "complex",
        data => [1, 2, 3],
        nested => { inner => "value" }
    };
    
    my $entry = System::Collections::DictionaryEntry->new($complex_ref, "complex_value");
    is($entry->Key(), $complex_ref, 'Complex reference key stored correctly');
    is($entry->Key()->{name}, "complex", 'Complex reference key accessible');
    is($entry->Key()->{data}->[1], 2, 'Nested data in reference key accessible');
    
    # Test 32: Modifying reference after storage
    $complex_ref->{modified} = "after_creation";
    is($entry->Key()->{modified}, "after_creation", 'Reference modifications visible in stored key');
    
    # Test 33: Code reference as value (Perl-specific)
    my $code_ref = sub { return "hello from code"; };
    my $code_entry = System::Collections::DictionaryEntry->new("function", $code_ref);
    is($code_entry->Value(), $code_ref, 'Code reference stored as value');
    is($code_entry->Value()->(), "hello from code", 'Code reference value is executable');
}

#===========================================
# ERROR HANDLING TESTS  
#===========================================

sub test_error_conditions {
    # Test 34: Constructor with no arguments (should work, both will be undef)
    my $no_args_entry = System::Collections::DictionaryEntry->new();
    isa_ok($no_args_entry, 'System::Collections::DictionaryEntry', 'Constructor works with no arguments');
    ok(!defined($no_args_entry->Key()), 'No-args constructor has undefined key');
    ok(!defined($no_args_entry->Value()), 'No-args constructor has undefined value');
    
    # Test 35: Constructor with one argument (value will be undef)
    my $one_arg_entry = System::Collections::DictionaryEntry->new("single");
    isa_ok($one_arg_entry, 'System::Collections::DictionaryEntry', 'Constructor works with one argument');
    is($one_arg_entry->Key(), "single", 'One-arg constructor stores key correctly');
    ok(!defined($one_arg_entry->Value()), 'One-arg constructor has undefined value');
    
    # Test 36: Method calls on undefined entry object
    my $undef_entry = undef;
    eval { $undef_entry->Key(); };
    like($@, qr/Can't call method/, 'Calling Key on undefined object throws error');
    
    eval { $undef_entry->Value(); };
    like($@, qr/Can't call method/, 'Calling Value on undefined object throws error');
}

#===========================================
# STRESS AND PERFORMANCE TESTS
#===========================================

sub test_stress_conditions {
    # Test 37: Many DictionaryEntry objects
    my @many_entries;
    for my $i (1..1000) {
        push @many_entries, System::Collections::DictionaryEntry->new("key_$i", "value_$i");
    }
    
    is(scalar(@many_entries), 1000, 'Can create many DictionaryEntry objects');
    is($many_entries[0]->Key(), "key_1", 'First entry in large collection correct');
    is($many_entries[999]->Key(), "key_1000", 'Last entry in large collection correct');
    is($many_entries[499]->Value(), "value_500", 'Middle entry in large collection correct');
    
    # Test 38: Large data in entries
    my $large_key = "x" x 10000;
    my $large_value = "y" x 10000;
    my $large_entry = System::Collections::DictionaryEntry->new($large_key, $large_value);
    
    is(length($large_entry->Key()), 10000, 'Large key stored correctly');
    is(length($large_entry->Value()), 10000, 'Large value stored correctly');
    
    # Test 39: Entry with deeply nested structure
    my $deep_structure = {
        level1 => {
            level2 => {
                level3 => {
                    level4 => {
                        level5 => "deep_value"
                    }
                }
            }
        }
    };
    
    my $deep_entry = System::Collections::DictionaryEntry->new("deep", $deep_structure);
    is($deep_entry->Value()->{level1}->{level2}->{level3}->{level4}->{level5}, 
       "deep_value", 'Deeply nested structure accessible');
}

#===========================================
# INTEGRATION TESTS
#===========================================

sub test_integration_scenarios {
    # Test 40: Use in hash table simulation
    my @hash_simulation = (
        System::Collections::DictionaryEntry->new("name", "John"),
        System::Collections::DictionaryEntry->new("age", "30"),
        System::Collections::DictionaryEntry->new("city", "New York")
    );
    
    # Find entry by key
    my $found_entry;
    for my $entry (@hash_simulation) {
        if ($entry->Key() eq "age") {
            $found_entry = $entry;
            last;
        }
    }
    
    ok(defined($found_entry), 'Can find entry by key in array');
    is($found_entry->Value(), "30", 'Found entry has correct value');
    
    # Test 41: Use in enumeration pattern
    my %key_value_map = ();
    for my $entry (@hash_simulation) {
        $key_value_map{$entry->Key()} = $entry->Value();
    }
    
    is($key_value_map{"name"}, "John", 'Enumeration pattern works - name');
    is($key_value_map{"age"}, "30", 'Enumeration pattern works - age');
    is($key_value_map{"city"}, "New York", 'Enumeration pattern works - city');
    
    # Test 42: DictionaryEntry as return value from function
    sub create_entry {
        my ($k, $v) = @_;
        return System::Collections::DictionaryEntry->new($k, $v);
    }
    
    my $function_entry = create_entry("function_key", "function_value");
    isa_ok($function_entry, 'System::Collections::DictionaryEntry', 'Function can return DictionaryEntry');
    is($function_entry->Key(), "function_key", 'Function-created entry has correct key');
    is($function_entry->Value(), "function_value", 'Function-created entry has correct value');
}

# Run all tests
test_construction_basic();
test_construction_edge_cases();
test_construction_with_different_types();
test_key_accessor();
test_value_accessor();
test_immutability_behavior();
test_inheritance();
test_multiple_instances();
test_reference_handling();
test_error_conditions();
test_stress_conditions();
test_integration_scenarios();

done_testing();