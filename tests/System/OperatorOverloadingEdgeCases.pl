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
    use_ok('System::String');
    use_ok('System::Object');  
    use_ok('System::Array');
}

# Test comprehensive operator overloading edge cases
sub test_string_equality_operators_edge_cases {
    # Test == operator with various scenarios
    my $str1 = System::String->new("hello");
    my $str2 = System::String->new("hello");
    my $str3 = System::String->new("Hello");
    my $str4 = System::String->new("");
    my $str5 = System::String->new("");
    
    # Basic equality
    ok($str1 == $str2, 'String == operator with same content');
    ok(!($str1 == $str3), 'String == operator case sensitive');
    ok($str4 == $str5, 'String == operator with empty strings');
    
    # Test != operator  
    ok(!($str1 != $str2), 'String != operator with same content');
    ok($str1 != $str3, 'String != operator case sensitive');
    ok(!($str4 != $str5), 'String != operator with empty strings');
    
    # Test eq operator
    ok($str1 eq $str2, 'String eq operator with same content');
    ok(!($str1 eq $str3), 'String eq operator case sensitive');
    ok($str4 eq $str5, 'String eq operator with empty strings');
    
    # Test ne operator
    ok(!($str1 ne $str2), 'String ne operator with same content');
    ok($str1 ne $str3, 'String ne operator case sensitive');
    ok(!($str4 ne $str5), 'String ne operator with empty strings');
    
    # Test with special characters
    my $special1 = System::String->new("test\x00null");
    my $special2 = System::String->new("test\x00null");
    my $special3 = System::String->new("test\x01null");
    
    ok($special1 == $special2, 'String == with null bytes');
    ok(!($special1 == $special3), 'String == with different control chars');
    ok($special1 eq $special2, 'String eq with null bytes');
    ok($special1 ne $special3, 'String ne with different control chars');
    
    # Test with unicode
    my $unicode1 = System::String->new("café");
    my $unicode2 = System::String->new("café");
    my $unicode3 = System::String->new("cafe");
    
    ok($unicode1 == $unicode2, 'String == with unicode');
    ok(!($unicode1 == $unicode3), 'String == unicode vs ascii');
    ok($unicode1 eq $unicode2, 'String eq with unicode');
    ok($unicode1 ne $unicode3, 'String ne unicode vs ascii');
    
    # Test with very long strings
    my $long1 = System::String->new('x' x 10000);
    my $long2 = System::String->new('x' x 10000);
    my $long3 = System::String->new('y' x 10000);
    
    ok($long1 == $long2, 'String == with very long strings');
    ok(!($long1 == $long3), 'String == with different long strings');
    
    # Test mixed with perl scalars (should use overloaded operators)
    my $perl_str = "hello";
    ok($str1 == $perl_str, 'String == with perl scalar');
    ok($str1 eq $perl_str, 'String eq with perl scalar');
    
    # Test with numbers as strings
    my $num_str1 = System::String->new("42");
    my $num_str2 = System::String->new("42");
    my $num_str3 = System::String->new("042");
    
    ok($num_str1 == $num_str2, 'Numeric string == with same content');
    ok(!($num_str1 == $num_str3), 'Numeric string == with different format');
}

sub test_string_comparison_operators_edge_cases {
    my $str1 = System::String->new("abc");
    my $str2 = System::String->new("def");
    my $str3 = System::String->new("abc");
    my $str4 = System::String->new("ABC");
    
    # Test cmp operator
    ok(($str1 cmp $str2) < 0, 'String cmp less than');
    ok(($str2 cmp $str1) > 0, 'String cmp greater than');
    is($str1 cmp $str3, 0, 'String cmp equal');
    ok(($str4 cmp $str1) < 0, 'String cmp uppercase vs lowercase');
    
    # Test with empty strings
    my $empty = System::String->new("");
    my $non_empty = System::String->new("a");
    
    ok(($empty cmp $non_empty) < 0, 'Empty string cmp less than non-empty');
    ok(($non_empty cmp $empty) > 0, 'Non-empty string cmp greater than empty');
    is($empty cmp System::String->new(""), 0, 'Empty strings cmp equal');
    
    # Test with unicode
    my $unicode1 = System::String->new("café");
    my $unicode2 = System::String->new("cafe");
    my $unicode_cmp = $unicode1 cmp $unicode2;
    ok(defined($unicode_cmp), 'Unicode cmp returns defined value');
    
    # Test with special characters
    my $special1 = System::String->new("test\x00");
    my $special2 = System::String->new("test\x01");
    ok(($special1 cmp $special2) < 0, 'Control character cmp ordering');
    
    # Test comparison consistency (if a cmp b == x, then b cmp a == -x)
    my $test_a = System::String->new("apple");
    my $test_b = System::String->new("banana");
    my $cmp_ab = $test_a cmp $test_b;
    my $cmp_ba = $test_b cmp $test_a;
    is($cmp_ab, -$cmp_ba, 'String cmp antisymmetric property');
    
    # Test transitivity (if a cmp b <= 0 and b cmp c <= 0, then a cmp c <= 0)
    my $trans_a = System::String->new("apple");
    my $trans_b = System::String->new("banana");
    my $trans_c = System::String->new("cherry");
    
    ok(($trans_a cmp $trans_b) <= 0, 'Transitivity test: a <= b');
    ok(($trans_b cmp $trans_c) <= 0, 'Transitivity test: b <= c');
    ok(($trans_a cmp $trans_c) <= 0, 'Transitivity test: a <= c');
    
    # Test with very long strings
    my $long_a = System::String->new('a' x 1000);
    my $long_b = System::String->new('b' x 1000);
    ok(($long_a cmp $long_b) < 0, 'Long string cmp works correctly');
}

sub test_string_concatenation_operator_edge_cases {
    # Basic concatenation
    my $str1 = System::String->new("Hello");
    my $str2 = System::String->new(" World");
    my $result = $str1 + $str2;
    
    isa_ok($result, 'System::String', 'Concatenation returns System::String');
    is($result->ToString(), "Hello World", 'Basic concatenation works');
    
    # Test with empty strings
    my $empty = System::String->new("");
    my $non_empty = System::String->new("test");
    
    my $empty_concat1 = $empty + $non_empty;
    my $empty_concat2 = $non_empty + $empty;
    
    is($empty_concat1->ToString(), "test", 'Empty + non-empty concatenation');
    is($empty_concat2->ToString(), "test", 'Non-empty + empty concatenation');
    
    my $both_empty = $empty + System::String->new("");
    is($both_empty->ToString(), "", 'Empty + empty concatenation');
    
    # Test chained concatenation
    my $chain = $str1 + System::String->new(" ") + System::String->new("Beautiful") + System::String->new(" ") + $str2->Trim();
    is($chain->ToString(), "Hello Beautiful World", 'Chained concatenation');
    
    # Test with special characters
    my $special1 = System::String->new("test\n");
    my $special2 = System::String->new("\ttab");
    my $special_result = $special1 + $special2;
    is($special_result->ToString(), "test\n\ttab", 'Concatenation with special chars');
    
    # Test with unicode
    my $unicode1 = System::String->new("Héllo");
    my $unicode2 = System::String->new(" Wörld");
    my $unicode_result = $unicode1 + $unicode2;
    is($unicode_result->ToString(), "Héllo Wörld", 'Unicode concatenation');
    
    # Test with null bytes
    my $null1 = System::String->new("before\x00");
    my $null2 = System::String->new("\x00after");
    my $null_result = $null1 + $null2;
    is($null_result->ToString(), "before\x00\x00after", 'Null byte concatenation');
    
    # Test with very long strings
    my $long1 = System::String->new('A' x 5000);
    my $long2 = System::String->new('B' x 5000);
    my $long_result = $long1 + $long2;
    is($long_result->Length(), 10000, 'Long string concatenation length');
    ok($long_result->StartsWith('A' x 100), 'Long concat starts correctly');
    ok($long_result->EndsWith('B' x 100), 'Long concat ends correctly');
    
    # Test concatenation order preservation
    my $order1 = System::String->new("1");
    my $order2 = System::String->new("2");
    my $order3 = System::String->new("3");
    
    my $left_assoc = ($order1 + $order2) + $order3;
    my $right_assoc = $order1 + ($order2 + $order3);
    
    is($left_assoc->ToString(), "123", 'Left associative concatenation');
    is($right_assoc->ToString(), "123", 'Right associative concatenation');
    is($left_assoc->ToString(), $right_assoc->ToString(), 'Concatenation associativity');
    
    # Test with mixed data types (if supported)
    eval {
        my $mixed = System::String->new("Number: ") + System::String->new("42");
        is($mixed->ToString(), "Number: 42", 'Mixed type concatenation');
    };
    ok(!$@, 'Mixed concatenation does not throw');
}

sub test_string_stringification_operator_edge_cases {
    # Test "" operator (stringification)
    my $str = System::String->new("test string");
    my $stringified = "$str";
    is($stringified, "test string", 'String stringification works');
    
    # Test with empty string
    my $empty = System::String->new("");
    my $empty_stringified = "$empty";
    is($empty_stringified, "", 'Empty string stringification');
    
    # Test with special characters
    my $special = System::String->new("line1\nline2\tcolumn");
    my $special_stringified = "$special";
    is($special_stringified, "line1\nline2\tcolumn", 'Special char stringification');
    
    # Test with unicode
    my $unicode = System::String->new("Héllo Wörld 🌍");
    my $unicode_stringified = "$unicode";
    is($unicode_stringified, "Héllo Wörld 🌍", 'Unicode stringification');
    
    # Test with null bytes
    my $null_bytes = System::String->new("before\x00after");
    my $null_stringified = "$null_bytes";
    is($null_stringified, "before\x00after", 'Null byte stringification');
    
    # Test in various contexts
    my $context_str = System::String->new("context");
    
    # String interpolation
    my $interpolated = "Prefix $context_str suffix";
    is($interpolated, "Prefix context suffix", 'String interpolation works');
    
    # Array context
    my @array_context = ($context_str, "other");
    is($array_context[0], "context", 'String in array context');
    
    # Hash context
    my %hash_context = ($context_str => "value");
    is($hash_context{"context"}, "value", 'String as hash key');
    
    # Regex context
    my $regex_str = System::String->new("pattern");
    my $test_text = "This contains pattern here";
    ok($test_text =~ /$regex_str/, 'String in regex pattern');
    
    # Print context (test that it doesn't break)
    my $print_str = System::String->new("printable");
    my $print_result = eval { sprintf("Value: %s", $print_str) };
    is($print_result, "Value: printable", 'String in print context');
    ok(!$@, 'String print context does not throw');
    
    # Test with very long strings
    my $long = System::String->new('X' x 1000);
    my $long_stringified = "$long";
    is(length($long_stringified), 1000, 'Long string stringification length');
    is($long_stringified, 'X' x 1000, 'Long string stringification content');
    
    # Test stringification consistency
    my $consistent = System::String->new("consistent");
    is("$consistent", "$consistent", 'Stringification consistency');
    is("$consistent", $consistent->ToString(), 'Stringification equals ToString');
}

sub test_object_equality_edge_cases {
    # Test with System::Object instances
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    my $obj3 = $obj1;  # Reference to same object
    
    # Objects should not be equal unless they're the same reference
    ok(!($obj1 == $obj2), 'Different objects are not equal');
    ok($obj1 == $obj3, 'Same object reference is equal');
    
    # Test with inherited objects
    my $str1 = System::String->new("test");
    my $str2 = System::String->new("test");
    my $str3 = System::String->new("different");
    
    ok($str1 == $str2, 'String objects with same content are equal');
    ok(!($str1 == $str3), 'String objects with different content not equal');
    
    # Test mixed object types
    ok(!($obj1 == $str1), 'Object and String not equal');
    ok(!($str1 == $obj1), 'String and Object not equal');
    
    # Test with Array objects
    my $arr1 = System::Array->new(1, 2, 3);
    my $arr2 = System::Array->new(1, 2, 3);
    my $arr3 = $arr1;  # Reference to same array
    
    # Arrays are compared by reference, not content
    ok(!($arr1 == $arr2), 'Different array objects not equal');
    ok($arr1 == $arr3, 'Same array reference is equal');
    
    # Test with null/undef
    my $null_obj;
    eval { my $result = $null_obj == $obj1; };
    ok($@, 'Comparison with null throws');
    
    eval { my $result = $obj1 == $null_obj; };
    ok($@, 'Comparison with null (reversed) throws');
}

sub test_operator_precedence_and_associativity {
    # Test operator precedence with string concatenation
    my $a = System::String->new("A");
    my $b = System::String->new("B");
    my $c = System::String->new("C");
    
    # Concatenation is left-associative
    my $left_assoc = $a + $b + $c;
    my $explicit_left = ($a + $b) + $c;
    is($left_assoc->ToString(), $explicit_left->ToString(), 'Left associativity');
    
    # Test with comparison and concatenation
    my $str1 = System::String->new("abc");
    my $str2 = System::String->new("def");
    my $concat = $str1 + $str2;
    
    # Comparison should have higher precedence than concatenation in some contexts
    ok($str1 + $str2 == $concat, 'Operator precedence with equality');
    
    # Test chained comparisons
    my $equal1 = System::String->new("test");
    my $equal2 = System::String->new("test");
    my $equal3 = System::String->new("test");
    
    ok($equal1 == $equal2 && $equal2 == $equal3, 'Chained equality comparisons');
    ok($equal1 eq $equal2 && $equal2 eq $equal3, 'Chained string comparisons');
    
    # Test mixed operators
    my $mixed_test = System::String->new("hello");
    my $mixed_space = System::String->new(" ");
    my $mixed_world = System::String->new("world");
    
    my $full_phrase = $mixed_test + $mixed_space + $mixed_world;
    ok($full_phrase == System::String->new("hello world"), 'Mixed concatenation and comparison');
}

sub test_operator_edge_cases_with_inheritance {
    # Create a custom class that inherits from System::String
    eval q{
        package TestString;
        use base 'System::String';
        
        sub new {
            my $class = shift;
            my $self = $class->SUPER::new(@_);
            return $self;
        }
    };
    
    my $custom_str = TestString->new("custom");
    my $regular_str = System::String->new("custom");
    
    # Test that operators work with inherited classes
    ok($custom_str == $regular_str, 'Inherited class equality works');
    ok($custom_str eq $regular_str, 'Inherited class string comparison works');
    
    my $custom_concat = $custom_str + System::String->new(" test");
    isa_ok($custom_concat, 'System::String', 'Inherited concatenation returns base class');
    
    # Test stringification with inheritance
    my $custom_stringified = "$custom_str";
    is($custom_stringified, "custom", 'Inherited stringification works');
}

sub test_operator_error_conditions {
    # Test operators with invalid arguments
    my $str = System::String->new("test");
    
    # Test concatenation with non-string objects
    eval { my $result = $str + System::Object->new(); };
    ok($@, 'Concatenation with Object throws error');
    
    eval { my $result = $str + [1, 2, 3]; };
    ok($@, 'Concatenation with array ref throws error');
    
    eval { my $result = $str + {key => 'value'}; };
    ok($@, 'Concatenation with hash ref throws error');
    
    # Test comparison with incompatible types
    eval { my $result = $str cmp System::Object->new(); };
    ok($@, 'Comparison with Object throws error');
    
    # Test with null references
    my $null_str;
    eval { my $result = $null_str + $str; };
    ok($@, 'Concatenation with null throws error');
    
    eval { my $result = $str + $null_str; };
    ok($@, 'Concatenation with null (reversed) throws error');
    
    eval { my $result = $null_str == $str; };
    ok($@, 'Equality with null throws error');
    
    eval { my $result = $null_str cmp $str; };
    ok($@, 'Comparison with null throws error');
    
    # Test stringification of null
    eval { my $result = "$null_str"; };
    ok($@, 'Stringification of null throws error');
}

sub test_operator_performance_edge_cases {
    # Test performance with many operations
    my $base = System::String->new("start");
    
    # Many concatenations
    for my $i (1..100) {
        $base = $base + System::String->new("_$i");
        last if $i >= 10;  # Limit for test performance
    }
    
    ok($base->Length() > 5, 'Many concatenations complete successfully');
    ok($base->StartsWith("start"), 'Many concatenations preserve start');
    
    # Many comparisons
    my $test_str = System::String->new("comparison_test");
    my $equal_str = System::String->new("comparison_test");
    my $diff_str = System::String->new("different");
    
    my $equal_count = 0;
    my $diff_count = 0;
    
    for my $i (1..1000) {
        $equal_count++ if $test_str == $equal_str;
        $diff_count++ if $test_str != $diff_str;
        last if $i >= 100;  # Limit for test performance
    }
    
    is($equal_count, 100, 'Repeated equality comparisons work');
    is($diff_count, 100, 'Repeated inequality comparisons work');
    
    # Large string operations
    my $large1 = System::String->new('A' x 10000);
    my $large2 = System::String->new('A' x 10000);
    my $large3 = System::String->new('B' x 10000);
    
    ok($large1 == $large2, 'Large string equality');
    ok($large1 != $large3, 'Large string inequality');
    
    my $large_concat = $large1 + $large3;
    is($large_concat->Length(), 20000, 'Large string concatenation');
}

# Run all comprehensive operator overloading edge case tests
test_string_equality_operators_edge_cases();
test_string_comparison_operators_edge_cases();
test_string_concatenation_operator_edge_cases();
test_string_stringification_operator_edge_cases();
test_object_equality_edge_cases();
test_operator_precedence_and_associativity();
test_operator_edge_cases_with_inheritance();
test_operator_error_conditions();
test_operator_performance_edge_cases();

done_testing();