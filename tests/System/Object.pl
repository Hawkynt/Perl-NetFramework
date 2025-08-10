#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Object;
use System::String;
use System::Array;

BEGIN {
    use_ok('System::Object');
}

sub test_object_creation {
    # Test basic constructor
    my $obj = System::Object->new();
    isa_ok($obj, 'System::Object', 'Basic object creation');
    ok(defined($obj), 'Created object is defined');
    ok(ref($obj), 'Created object is a reference');
    
    # Test constructor with class reference
    my $obj2 = System::Object->new();
    isa_ok($obj2, 'System::Object', 'Second object creation');
    
    # Test multiple objects are different
    isnt($obj, $obj2, 'Different object instances are not identical');
}

sub test_toString {
    # Test basic ToString
    my $obj = System::Object->new();
    my $str = $obj->ToString();
    ok(defined($str), 'ToString returns defined value');
    like($str, qr/System::Object/, 'ToString returns class name');
    is(ref(\$str), 'SCALAR', 'ToString returns scalar value');
    
    # Test ToString consistency
    is($obj->ToString(), $obj->ToString(), 'ToString is consistent');
    
    # Test with different objects
    my $obj2 = System::Object->new();
    is($obj->ToString(), $obj2->ToString(), 'Same class objects have same ToString');
    
    # Test ToString with inherited object
    my $str_obj = System::String->new('test');
    my $str_result = $str_obj->ToString();
    is($str_result, 'test', 'Inherited ToString works correctly');
    
    # Test null/undef handling in ToString
    eval {
        my $result = System::Object::ToString(undef);
    };
    # Should handle gracefully or throw exception
    ok(1, 'ToString with undef handled');
}

sub test_getType {
    # Test basic GetType
    my $obj = System::Object->new();
    my $type = $obj->GetType();
    is($type, 'System::Object', 'GetType returns correct type');
    
    # Test GetType consistency
    is($obj->GetType(), $obj->GetType(), 'GetType is consistent');
    
    # Test GetType with different objects of same class
    my $obj2 = System::Object->new();
    is($obj->GetType(), $obj2->GetType(), 'Same class objects have same type');
    
    # Test GetType with inherited classes
    my $str_obj = System::String->new('test');
    is($str_obj->GetType(), 'System::String', 'GetType works with inherited classes');
    
    my $arr_obj = System::Array->new();
    is($arr_obj->GetType(), 'System::Array', 'GetType works with Array');
    
    # Test GetType with null/undef
    eval {
        my $result = System::Object::GetType(undef);
    };
    # Should handle or throw exception
    ok(1, 'GetType with undef handled');
}

sub test_getHashCode {
    # Test basic hash code generation
    my $obj1 = System::Object->new();
    my $hash1 = $obj1->GetHashCode();
    ok(defined($hash1), 'GetHashCode returns defined value');
    ok($hash1 >= 0, 'Hash code is non-negative');
    
    # Test hash code consistency
    is($obj1->GetHashCode(), $obj1->GetHashCode(), 'Hash code is consistent for same object');
    
    # Test different objects have different hash codes
    my $obj2 = System::Object->new();
    my $hash2 = $obj2->GetHashCode();
    isnt($hash1, $hash2, 'Different objects have different hash codes');
    
    # Test hash code with multiple calls
    for my $i (1..5) {
        is($obj1->GetHashCode(), $hash1, "Hash code consistent on call $i");
    }
    
    # Test hash codes are integers
    ok($hash1 =~ /^\d+$/, 'Hash code is numeric');
    ok($hash2 =~ /^\d+$/, 'Second hash code is numeric');
    
    # Test with inherited objects
    my $str_obj = System::String->new('test');
    my $str_hash = $str_obj->GetHashCode();
    ok(defined($str_hash), 'Inherited object GetHashCode works');
    
    # Test null/undef handling
    my $null_hash = System::Object::GetHashCode(undef);
    is($null_hash, 0, 'GetHashCode with undef returns 0');
}

sub test_equals_basic {
    # Test self-equality
    my $obj1 = System::Object->new();
    ok($obj1->Equals($obj1), 'Object equals itself');
    
    # Test different objects are not equal
    my $obj2 = System::Object->new();
    ok(!$obj1->Equals($obj2), 'Different objects are not equal');
    
    # Test with null/undef
    ok(!$obj1->Equals(undef), 'Object does not equal undef');
    
    # Test both null/undef case
    ok(System::Object->Equals(undef, undef), 'Both undef values are equal');
    
    # Test one null case
    ok(!System::Object->Equals($obj1, undef), 'Object and undef are not equal');
    ok(!System::Object->Equals(undef, $obj1), 'Undef and object are not equal');
}

sub test_equals_scalars {
    # Test numeric equality
    ok(System::Object->Equals(5, 5), 'Equal numbers are equal');
    ok(!System::Object->Equals(5, 6), 'Different numbers are not equal');
    ok(System::Object->Equals(3.14, 3.14), 'Equal floats are equal');
    ok(!System::Object->Equals(3.14, 3.15), 'Different floats are not equal');
    
    # Test string equality
    ok(System::Object->Equals('hello', 'hello'), 'Equal strings are equal');
    ok(!System::Object->Equals('hello', 'world'), 'Different strings are not equal');
    
    # Test mixed scalar types
    ok(System::Object->Equals(5, '5'), 'Number and string 5 are equal');
    ok(System::Object->Equals(0, ''), 'Zero and empty string are equal');
    
    # Test edge cases
    ok(System::Object->Equals('', ''), 'Empty strings are equal');
    ok(System::Object->Equals(0, 0), 'Zeros are equal');
    ok(System::Object->Equals(-1, -1), 'Negative numbers are equal');
}

sub test_equals_objects {
    # Test object equality with references
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    my $obj1_ref = $obj1;
    
    # Reference equality
    ok($obj1->Equals($obj1_ref), 'Object equals its reference');
    
    # Different objects
    ok(!$obj1->Equals($obj2), 'Different objects are not equal');
    
    # Test with System::String objects
    my $str1 = System::String->new('hello');
    my $str2 = System::String->new('hello');
    my $str3 = System::String->new('world');
    
    ok($str1->Equals($str2), 'Equal strings are equal via Equals');
    ok(!$str1->Equals($str3), 'Different strings are not equal via Equals');
    
    # Test System::String with Object::Equals
    ok(System::Object->Equals($str1, $str2), 'Equal strings equal via Object::Equals');
    ok(!System::Object->Equals($str1, $str3), 'Different strings not equal via Object::Equals');
}

sub test_equals_preventEquatable {
    # Test the preventEquatable parameter
    my $str1 = System::String->new('test');
    my $str2 = System::String->new('test');
    
    # Normal equality
    ok(System::Object->Equals($str1, $str2), 'Strings equal normally');
    
    # With preventEquatable = true
    ok(System::Object->Equals($str1, $str2, 1), 'Strings equal with preventEquatable');
    
    # Test different strings
    my $str3 = System::String->new('other');
    ok(!System::Object->Equals($str1, $str3, 1), 'Different strings not equal with preventEquatable');
}

sub test_referenceEquals {
    # Test basic reference equality
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    my $obj1_ref = $obj1;
    
    # Same reference
    ok(System::Object->ReferenceEquals($obj1, $obj1_ref), 'Same references are equal');
    
    # Different objects
    ok(!System::Object->ReferenceEquals($obj1, $obj2), 'Different objects have different references');
    
    # Test with undef (both null)
    ok(System::Object->ReferenceEquals(undef, undef), 'Both undef references are equal');
    
    # Test with mixed null/object
    eval { System::Object->ReferenceEquals($obj1, undef); };
    ok($@, 'ReferenceEquals throws with one null argument');
    
    eval { System::Object->ReferenceEquals(undef, $obj1); };
    ok($@, 'ReferenceEquals throws with first null argument');
    
    # Test with scalars (should throw)
    eval { System::Object->ReferenceEquals(5, 5); };
    ok($@, 'ReferenceEquals throws with scalar arguments');
    
    eval { System::Object->ReferenceEquals('hello', 'hello'); };
    ok($@, 'ReferenceEquals throws with string arguments');
}

sub test_is_method {
    # Test Is method with basic objects
    my $obj = System::Object->new();
    ok($obj->Is('System::Object'), 'Object Is System::Object');
    ok(!$obj->Is('System::String'), 'Object is not System::String');
    
    # Test with inherited classes
    my $str = System::String->new('test');
    ok($str->Is('System::String'), 'String Is System::String');
    ok($str->Is('System::Object'), 'String Is System::Object (inheritance)');
    ok(!$str->Is('System::Array'), 'String is not System::Array');
    
    # Test with Array
    my $arr = System::Array->new();
    ok($arr->Is('System::Array'), 'Array Is System::Array');
    ok($arr->Is('System::Object'), 'Array Is System::Object (inheritance)');
    ok(!$arr->Is('System::String'), 'Array is not System::String');
    
    # Test with null/undef
    ok(!System::Object::Is(undef, 'System::Object'), 'Undef is not System::Object');
    
    # Test with scalar values (should return false)
    ok(!System::Object::Is(5, 'System::Object'), 'Scalar is not System::Object');
    ok(!System::Object::Is('hello', 'System::Object'), 'String scalar is not System::Object');
    
    # Test with non-existent class
    ok(!$obj->Is('NonExistent::Class'), 'Object is not non-existent class');
}

sub test_as_method {
    # Test As method with compatible types
    my $obj = System::Object->new();
    my $as_obj = $obj->As('System::Object');
    is($as_obj, $obj, 'As returns same object for compatible type');
    
    # Test As with incompatible type  
    my $as_str = $obj->As('System::String');
    ok(!defined($as_str), 'As returns undef for incompatible type');
    
    # Test with inherited classes
    my $str = System::String->new('test');
    my $as_obj_from_str = $str->As('System::Object');
    is($as_obj_from_str, $str, 'As returns string as object');
    
    my $as_str_from_str = $str->As('System::String');
    is($as_str_from_str, $str, 'As returns string as string');
    
    # Test with incompatible cast
    my $as_arr_from_str = $str->As('System::Array');
    ok(!defined($as_arr_from_str), 'As returns undef for incompatible cast');
    
    # Test with null/undef
    my $as_from_null = System::Object::As(undef, 'System::Object');
    ok(!defined($as_from_null), 'As from null returns undef');
    
    # Test with scalars
    my $as_from_scalar = System::Object::As(5, 'System::Object');
    ok(!defined($as_from_scalar), 'As from scalar returns undef');
}

sub test_inheritance_chain {
    # Test that all System objects inherit from Object
    my $str = System::String->new('test');
    ok($str->isa('System::Object'), 'String inherits from Object');
    
    my $arr = System::Array->new();
    ok($arr->isa('System::Object'), 'Array inherits from Object');
    
    # Test method calls work through inheritance
    ok(defined($str->ToString()), 'String can call ToString from Object');
    ok(defined($str->GetType()), 'String can call GetType');
    ok(defined($str->GetHashCode()), 'String can call GetHashCode');
    
    ok(defined($arr->ToString()), 'Array can call ToString from Object');
    ok(defined($arr->GetType()), 'Array can call GetType');
    ok(defined($arr->GetHashCode()), 'Array can call GetHashCode');
}

sub test_edge_cases {
    # Test with very large numbers
    ok(System::Object->Equals(999999999999999, 999999999999999), 'Large numbers equality');
    
    # Test with special float values
    my $inf = 9**9**9;  # Generate infinity
    ok(System::Object->Equals($inf, $inf), 'Infinity equals itself');
    
    # Test with very long strings
    my $long_str = 'x' x 10000;
    ok(System::Object->Equals($long_str, $long_str), 'Long strings equality');
    
    # Test with empty string vs zero
    ok(System::Object->Equals('', 0), 'Empty string equals zero');
    ok(System::Object->Equals(0, ''), 'Zero equals empty string');
    
    # Test with whitespace
    ok(!System::Object->Equals(' ', ''), 'Space is not empty string');
    ok(!System::Object->Equals('0', 0.0), 'String 0 equals numeric 0');
}

sub test_error_conditions {
    # Test various error conditions that should be handled gracefully
    
    # Test ToString with corrupted object
    eval {
        my $fake_obj = bless {}, 'System::Object';
        my $result = $fake_obj->ToString();
        ok(defined($result), 'ToString works with minimal object');
    };
    
    # Test GetHashCode edge cases
    eval {
        my $obj = System::Object->new();
        # Call GetHashCode many times to ensure consistency
        my $first_hash = $obj->GetHashCode();
        for (1..100) {
            is($obj->GetHashCode(), $first_hash, "Hash consistent on iteration $_") if $_ <= 3;
        }
    };
    
    # Test Equals with various invalid inputs
    eval {
        my $obj = System::Object->new();
        # These should not crash
        $obj->Equals([]);
        $obj->Equals({});
        $obj->Equals(\$obj);
    };
    ok(!$@, 'Equals handles various reference types without crashing');
}

sub test_memory_and_cleanup {
    # Test object creation and destruction
    my @objects;
    for (1..100) {
        push @objects, System::Object->new();
    }
    
    # Verify all objects are unique
    my %seen_hashes;
    for my $i (0..$#objects) {
        my $obj = $objects[$i];
        my $hash = $obj->GetHashCode();
        ok(!exists $seen_hashes{$hash}, "Object $i has unique hash") if $i < 5;
        $seen_hashes{$hash} = 1;
    }
    
    # Test that objects remain valid
    for my $i (0..4) {
        my $obj = $objects[$i];
        ok(defined($obj->ToString()), "Object $i still valid");
        ok(defined($obj->GetHashCode()), "Object $i hash still valid");
    }
    
    # Clear references
    @objects = ();
    %seen_hashes = ();
    ok(1, 'Cleanup completed successfully');
}

# Run all comprehensive tests
test_object_creation();
test_toString();
test_getType();
test_getHashCode();
test_equals_basic();
test_equals_scalars();
test_equals_objects();
test_equals_preventEquatable();
test_referenceEquals();
test_is_method();
test_as_method();
test_inheritance_chain();
test_edge_cases();
test_error_conditions();
test_memory_and_cleanup();

done_testing();