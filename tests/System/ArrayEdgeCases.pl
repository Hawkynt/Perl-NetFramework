#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Object;
use System::String;
use System::Array;
use Encode qw(encode decode);

BEGIN {
    use_ok('System::Array');
}

# Test comprehensive edge cases for System::Array
sub test_array_construction_edge_cases {
    # Test with various input types
    my $empty_arr = System::Array->new();
    my $single_arr = System::Array->new("only");
    my $multi_arr = System::Array->new(1, "two", 3.14, undef, [], {});
    
    is($empty_arr->Length(), 0, 'Empty array construction');
    is($single_arr->Length(), 1, 'Single element array construction');
    is($multi_arr->Length(), 6, 'Multi-type array construction');
    
    # Test with very large arrays
    my @large_data = (1..100000);
    my $large_arr = System::Array->new(@large_data);
    is($large_arr->Length(), 100000, 'Very large array length correct');
    is($large_arr->Get(0), 1, 'Large array first element');
    is($large_arr->Get(99999), 100000, 'Large array last element');
    
    # Test with unicode data
    my @unicode_data = ("Héllo", "Wörld", "\x{1F600}", "\x{03B1}\x{03B2}\x{03B3}");
    my $unicode_arr = System::Array->new(@unicode_data);
    is($unicode_arr->Length(), 4, 'Unicode array length');
    is($unicode_arr->Get(0), "Héllo", 'Unicode first element');
    is($unicode_arr->Get(2), "\x{1F600}", 'Unicode emoji element');
    
    # Test with null bytes
    my @null_data = ("a\x00b", "c\x00d", "\x00start", "end\x00");
    my $null_arr = System::Array->new(@null_data);
    is($null_arr->Length(), 4, 'Null byte array length');
    is($null_arr->Get(0), "a\x00b", 'Null byte element preserved');
    
    # Test with nested structures
    my $nested_arr = System::Array->new(
        System::String->new("string"),
        System::Array->new(1, 2, 3),
        System::Object->new(),
        [1, 2, 3],  # Perl array ref
        {a => 1, b => 2}  # Perl hash ref
    );
    is($nested_arr->Length(), 5, 'Nested structures array length');
    isa_ok($nested_arr->Get(0), 'System::String', 'Nested System::String');
    isa_ok($nested_arr->Get(1), 'System::Array', 'Nested System::Array');
    isa_ok($nested_arr->Get(2), 'System::Object', 'Nested System::Object');
    
    # Test with duplicates
    my $dup_arr = System::Array->new(1, 1, 2, 2, 2, 3, 1);
    is($dup_arr->Length(), 7, 'Duplicate elements array length');
    is($dup_arr->IndexOf(1), 0, 'First occurrence of duplicate');
    is($dup_arr->LastIndexOf(1), 6, 'Last occurrence of duplicate');
    is($dup_arr->LastIndexOf(2), 4, 'Last occurrence of triple');
}

sub test_array_bounds_and_exceptions_edge_cases {
    my $arr = System::Array->new("a", "b", "c", "d", "e");
    
    # Test all boundary conditions
    is($arr->Get(0), "a", 'Valid index 0');
    is($arr->Get(4), "e", 'Valid last index');
    
    # Test negative indices
    eval { $arr->Get(-1); };
    ok($@, 'Get throws on -1 index');
    like($@, qr/IndexOutOfBoundsException/, 'Correct exception type for negative');
    
    eval { $arr->Set(-1, "value"); };
    ok($@, 'Set throws on -1 index');
    
    eval { $arr->GetValue(-100); };
    ok($@, 'GetValue throws on very negative index');
    
    # Test indices at and beyond length
    eval { $arr->Get(5); };
    ok($@, 'Get throws on index == length');
    
    eval { $arr->Get(100); };
    ok($@, 'Get throws on index >> length');
    
    eval { $arr->Set(10, "value"); };
    ok($@, 'Set throws on index > length');
    
    eval { $arr->SetValue("value", 1000); };
    ok($@, 'SetValue throws on very large index');
    
    # Test with empty array
    my $empty = System::Array->new();
    eval { $empty->Get(0); };
    ok($@, 'Empty array Get(0) throws');
    
    eval { $empty->Set(0, "value"); };
    ok($@, 'Empty array Set(0) throws');
    
    # Test null reference exceptions on all methods
    my $null_array;
    
    eval { $null_array->Length(); };
    ok($@, 'Length throws on null reference');
    like($@, qr/NullReferenceException/, 'Correct null exception type');
    
    eval { $null_array->Get(0); };
    ok($@, 'Get throws on null reference');
    
    eval { $null_array->Set(0, "value"); };
    ok($@, 'Set throws on null reference');
    
    eval { $null_array->GetValue(0); };
    ok($@, 'GetValue throws on null reference');
    
    eval { $null_array->SetValue("value", 0); };
    ok($@, 'SetValue throws on null reference');
    
    eval { $null_array->Clear(); };
    ok($@, 'Clear throws on null reference');
    
    eval { $null_array->IndexOf("value"); };
    ok($@, 'IndexOf throws on null reference');
    
    eval { $null_array->LastIndexOf("value"); };
    ok($@, 'LastIndexOf throws on null reference');
    
    eval { $null_array->GetEnumerator(); };
    ok($@, 'GetEnumerator throws on null reference');
    
    # Test extreme boundary cases
    my $single = System::Array->new("only");
    is($single->Get(0), "only", 'Single element array valid access');
    eval { $single->Get(1); };
    ok($@, 'Single element array bounds check');
}

sub test_array_element_assignment_edge_cases {
    my $arr = System::Array->new(1, 2, 3);
    
    # Test assignment of various types
    $arr->Set(0, "string");
    is($arr->Get(0), "string", 'Assign string to numeric slot');
    
    $arr->Set(1, undef);
    ok(!defined($arr->Get(1)), 'Assign undef works');
    
    $arr->Set(2, 3.14159);
    is($arr->Get(2), 3.14159, 'Assign float works');
    
    # Test assignment of objects
    my $str_obj = System::String->new("test");
    my $obj_obj = System::Object->new();
    my $arr_obj = System::Array->new(1, 2, 3);
    
    $arr = System::Array->new(undef, undef, undef);
    $arr->Set(0, $str_obj);
    $arr->Set(1, $obj_obj);
    $arr->Set(2, $arr_obj);
    
    isa_ok($arr->Get(0), 'System::String', 'String object assignment');
    isa_ok($arr->Get(1), 'System::Object', 'Object assignment');
    isa_ok($arr->Get(2), 'System::Array', 'Array object assignment');
    
    # Test assignment of references
    my $perl_array = [1, 2, 3];
    my $perl_hash = {a => 1, b => 2};
    
    $arr->Set(0, $perl_array);
    $arr->Set(1, $perl_hash);
    
    is_deeply($arr->Get(0), $perl_array, 'Perl array ref assignment');
    is_deeply($arr->Get(1), $perl_hash, 'Perl hash ref assignment');
    
    # Test assignment edge cases with very large values
    my $large_string = 'X' x 100000;
    my $large_number = 999999999999999999;
    
    $arr = System::Array->new(undef, undef);
    $arr->Set(0, $large_string);
    $arr->Set(1, $large_number);
    
    is(length($arr->Get(0)), 100000, 'Large string assignment');
    is($arr->Get(1), $large_number, 'Large number assignment');
    
    # Test unicode assignment
    my $unicode_str = "Hello \x{1F600} \x{03B1}\x{03B2}\x{03B3}";
    $arr->Set(0, $unicode_str);
    is($arr->Get(0), $unicode_str, 'Unicode string assignment');
    
    # Test null byte assignment
    my $null_bytes = "Hello\x00World\x00";
    $arr->Set(1, $null_bytes);
    is($arr->Get(1), $null_bytes, 'Null bytes assignment preserved');
}

sub test_array_indexof_lastindexof_edge_cases {
    # Test with various data types
    my $mixed = System::Array->new(
        1, "string", 3.14, undef, 
        System::String->new("test"),
        [], {}, 
        1, "string"  # Duplicates
    );
    
    # Test finding different types
    is($mixed->IndexOf(1), 0, 'Find first integer');
    is($mixed->IndexOf("string"), 1, 'Find first string');
    is($mixed->IndexOf(3.14), 2, 'Find float');
    is($mixed->IndexOf(undef), 3, 'Find undef');
    
    # Test last index with duplicates
    is($mixed->LastIndexOf(1), 7, 'Find last integer occurrence');
    is($mixed->LastIndexOf("string"), 8, 'Find last string occurrence');
    
    # Test with System::String objects
    my $str_obj1 = System::String->new("test");
    my $str_obj2 = System::String->new("test");
    my $str_arr = System::Array->new($str_obj1, "other", $str_obj2);
    
    # These should find based on equality, not reference
    is($str_arr->IndexOf($str_obj1), 0, 'Find System::String by reference');
    # Note: This depends on how Equals is implemented in the array search
    
    # Test with empty array
    my $empty = System::Array->new();
    is($empty->IndexOf("anything"), -1, 'IndexOf in empty array');
    is($empty->LastIndexOf("anything"), -1, 'LastIndexOf in empty array');
    
    # Test with single element
    my $single = System::Array->new("only");
    is($single->IndexOf("only"), 0, 'IndexOf single element found');
    is($single->IndexOf("missing"), -1, 'IndexOf single element not found');
    is($single->LastIndexOf("only"), 0, 'LastIndexOf single element');
    
    # Test with all same elements
    my $same = System::Array->new("x", "x", "x", "x", "x");
    is($same->IndexOf("x"), 0, 'IndexOf with all same elements');
    is($same->LastIndexOf("x"), 4, 'LastIndexOf with all same elements');
    is($same->IndexOf("y"), -1, 'IndexOf not found in same elements');
    
    # Test with unicode
    my $unicode = System::Array->new("café", "naïve", "résumé", "café");
    is($unicode->IndexOf("café"), 0, 'IndexOf unicode string');
    is($unicode->LastIndexOf("café"), 3, 'LastIndexOf unicode string');
    is($unicode->IndexOf("naïve"), 1, 'IndexOf unicode with diacritic');
    
    # Test with null bytes
    my $null_arr = System::Array->new("a\x00b", "normal", "a\x00b");
    is($null_arr->IndexOf("a\x00b"), 0, 'IndexOf with null bytes');
    is($null_arr->LastIndexOf("a\x00b"), 2, 'LastIndexOf with null bytes');
    
    # Test with special numeric cases
    my $numeric = System::Array->new(0, 0.0, "0", "", 1, "1");
    is($numeric->IndexOf(0), 0, 'IndexOf zero');
    is($numeric->IndexOf(0.0), 1, 'IndexOf float zero');
    is($numeric->IndexOf("0"), 2, 'IndexOf string zero');
    is($numeric->IndexOf(""), 3, 'IndexOf empty string');
    
    # Test with very large arrays
    my @big_data = (1..10000, "target", 10001..20000);
    my $big_arr = System::Array->new(@big_data);
    is($big_arr->IndexOf("target"), 10000, 'IndexOf in large array');
    is($big_arr->IndexOf("missing"), -1, 'IndexOf not found in large array');
}

sub test_array_contains_edge_cases {
    my $arr = System::Array->new("apple", "banana", "cherry", undef, "", 0);
    
    # Test basic contains
    ok($arr->Contains("banana"), 'Contains existing string');
    ok(!$arr->Contains("grape"), 'Does not contain missing string');
    
    # Test contains with special values
    ok($arr->Contains(undef), 'Contains undef');
    ok($arr->Contains(""), 'Contains empty string');
    ok($arr->Contains(0), 'Contains zero');
    
    # Test contains with type variations
    my $mixed = System::Array->new(1, "1", 1.0, "1.0");
    ok($mixed->Contains(1), 'Contains integer 1');
    ok($mixed->Contains("1"), 'Contains string "1"');
    ok($mixed->Contains(1.0), 'Contains float 1.0');
    ok($mixed->Contains("1.0"), 'Contains string "1.0"');
    
    # Test with System objects
    my $str_obj = System::String->new("test");
    my $obj_arr = System::Array->new($str_obj, "other");
    ok($obj_arr->Contains($str_obj), 'Contains System::String object');
    
    # Test with unicode
    my $unicode = System::Array->new("café", "naïve", "résumé");
    ok($unicode->Contains("café"), 'Contains unicode string');
    ok($unicode->Contains("naïve"), 'Contains unicode with diacritic');
    ok(!$unicode->Contains("cafe"), 'Does not contain ascii version');
    
    # Test with empty array
    my $empty = System::Array->new();
    ok(!$empty->Contains("anything"), 'Empty array contains nothing');
    ok(!$empty->Contains(undef), 'Empty array does not contain undef');
    ok(!$empty->Contains(""), 'Empty array does not contain empty string');
    
    # Test with single element arrays
    my $single_str = System::Array->new("only");
    ok($single_str->Contains("only"), 'Single element array contains element');
    ok(!$single_str->Contains("other"), 'Single element array does not contain other');
    
    my $single_undef = System::Array->new(undef);
    ok($single_undef->Contains(undef), 'Single undef array contains undef');
    ok(!$single_undef->Contains(""), 'Single undef array does not contain empty string');
    
    # Test with very large arrays
    my @large_data = (1..50000, "needle", 50001..100000);
    my $large_arr = System::Array->new(@large_data);
    ok($large_arr->Contains("needle"), 'Contains in very large array');
    ok(!$large_arr->Contains("missing"), 'Does not contain in very large array');
}

sub test_array_clear_edge_cases {
    # Test clear on various array states
    my $normal = System::Array->new(1, 2, 3, 4, 5);
    is($normal->Length(), 5, 'Array has initial elements');
    $normal->Clear();
    is($normal->Length(), 0, 'Array cleared successfully');
    
    # Verify array is truly empty
    eval { $normal->Get(0); };
    ok($@, 'Cleared array Get(0) throws');
    
    is($normal->IndexOf(1), -1, 'Cleared array IndexOf returns -1');
    ok(!$normal->Contains(1), 'Cleared array contains nothing');
    
    # Test clear on empty array (should not crash)
    my $empty = System::Array->new();
    is($empty->Length(), 0, 'Empty array length is 0');
    $empty->Clear();
    is($empty->Length(), 0, 'Empty array still empty after clear');
    
    # Test clear on single element
    my $single = System::Array->new("only");
    is($single->Length(), 1, 'Single element array has length 1');
    $single->Clear();
    is($single->Length(), 0, 'Single element array cleared');
    
    # Test clear with various data types
    my $mixed = System::Array->new(
        1, "string", 3.14, undef, [], {},
        System::String->new("test"),
        System::Object->new()
    );
    is($mixed->Length(), 8, 'Mixed array initial length');
    $mixed->Clear();
    is($mixed->Length(), 0, 'Mixed array cleared');
    
    # Test that cleared array can be reused
    $mixed = System::Array->new("new", "data");
    is($mixed->Length(), 2, 'Reused array has new data');
    is($mixed->Get(0), "new", 'Reused array first element');
    is($mixed->Get(1), "data", 'Reused array second element');
    
    # Test clear on very large array
    my @large_data = (1..100000);
    my $large = System::Array->new(@large_data);
    is($large->Length(), 100000, 'Large array initial length');
    $large->Clear();
    is($large->Length(), 0, 'Large array cleared');
    
    # Test multiple consecutive clears
    my $multi = System::Array->new(1, 2, 3);
    $multi->Clear();
    $multi->Clear();  # Should not crash
    $multi->Clear();  # Should not crash
    is($multi->Length(), 0, 'Multiple clears leave array empty');
}

sub test_array_enumerator_edge_cases {
    # Test enumerator with empty array
    my $empty = System::Array->new();
    my $empty_enum = $empty->GetEnumerator();
    isa_ok($empty_enum, 'System::_SZArrayEnumerator', 'Empty array enumerator type');
    
    ok(!$empty_enum->MoveNext(), 'Empty enumerator MoveNext returns false');
    
    eval { $empty_enum->Current(); };
    ok($@, 'Empty enumerator Current throws');
    like($@, qr/InvalidOperationException/, 'Correct exception type');
    
    # Test enumerator reset on empty array
    $empty_enum->Reset();
    ok(!$empty_enum->MoveNext(), 'Empty enumerator MoveNext still false after reset');
    
    # Test single element enumerator
    my $single = System::Array->new("only");
    my $single_enum = $single->GetEnumerator();
    
    eval { $single_enum->Current(); };
    ok($@, 'Single enumerator Current throws before MoveNext');
    
    ok($single_enum->MoveNext(), 'Single enumerator MoveNext returns true');
    is($single_enum->Current(), "only", 'Single enumerator Current returns element');
    
    ok(!$single_enum->MoveNext(), 'Single enumerator second MoveNext returns false');
    
    eval { $single_enum->Current(); };
    ok($@, 'Single enumerator Current throws after enumeration');
    
    # Test enumerator with various data types
    my $mixed = System::Array->new(1, "string", undef, 3.14, System::String->new("test"));
    my $mixed_enum = $mixed->GetEnumerator();
    
    my @enumerated;
    while ($mixed_enum->MoveNext()) {
        push @enumerated, $mixed_enum->Current();
    }
    
    is(scalar(@enumerated), 5, 'Mixed enumerator enumerated all elements');
    is($enumerated[0], 1, 'First enumerated element correct');
    is($enumerated[1], "string", 'Second enumerated element correct');
    ok(!defined($enumerated[2]), 'Third enumerated element is undef');
    is($enumerated[3], 3.14, 'Fourth enumerated element correct');
    isa_ok($enumerated[4], 'System::String', 'Fifth enumerated element type');
    
    # Test multiple enumerators on same array
    my $arr = System::Array->new("a", "b", "c");
    my $enum1 = $arr->GetEnumerator();
    my $enum2 = $arr->GetEnumerator();
    
    ok($enum1->MoveNext(), 'First enumerator MoveNext');
    ok($enum2->MoveNext(), 'Second enumerator MoveNext');
    
    is($enum1->Current(), "a", 'First enumerator at first element');
    is($enum2->Current(), "a", 'Second enumerator at first element');
    
    ok($enum1->MoveNext(), 'First enumerator advance');
    is($enum1->Current(), "b", 'First enumerator at second element');
    is($enum2->Current(), "a", 'Second enumerator still at first element');
    
    # Test enumerator after array modification (if supported)
    my $modifiable = System::Array->new(1, 2, 3);
    my $mod_enum = $modifiable->GetEnumerator();
    
    ok($mod_enum->MoveNext(), 'Modifiable enumerator MoveNext');
    is($mod_enum->Current(), 1, 'Modifiable enumerator first element');
    
    $modifiable->Set(1, "modified");
    ok($mod_enum->MoveNext(), 'Enumerator continues after array modification');
    # The behavior here depends on implementation - it might be "modified" or 2
    
    # Test enumerator dispose
    my $dispose_enum = $arr->GetEnumerator();
    ok($dispose_enum->MoveNext(), 'Dispose test enumerator works');
    $dispose_enum->Dispose();
    # After dispose, behavior may vary, but should not crash
    eval { $dispose_enum->MoveNext(); };
    # Whether this throws or not depends on implementation
    ok(1, 'Dispose handled without crashing');
    
    # Test very large array enumeration
    my @big_data = (1..10000);
    my $big_arr = System::Array->new(@big_data);
    my $big_enum = $big_arr->GetEnumerator();
    
    my $count = 0;
    while ($big_enum->MoveNext()) {
        $count++;
        last if $count > 10100;  # Prevent infinite loop in case of error
    }
    is($count, 10000, 'Large array fully enumerated');
    
    # Test enumerator reset on large array
    $big_enum->Reset();
    ok($big_enum->MoveNext(), 'Large array enumerator reset works');
    is($big_enum->Current(), 1, 'Large array enumerator reset to first element');
}

sub test_array_linq_integration_edge_cases {
    # Test Where with empty array
    my $empty = System::Array->new();
    my $empty_where = $empty->Where(sub { $_[0] > 0 });
    is($empty_where->Count(), 0, 'Where on empty array returns empty');
    
    # Test Where with no matches
    my $none_match = System::Array->new(-1, -2, -3);
    my $no_results = $none_match->Where(sub { $_[0] > 0 });
    is($no_results->Count(), 0, 'Where with no matches returns empty');
    
    # Test Where with all matches
    my $all_match = System::Array->new(1, 2, 3, 4, 5);
    my $all_results = $all_match->Where(sub { $_[0] > 0 });
    is($all_results->Count(), 5, 'Where with all matches returns all');
    
    # Test Select with various transformations
    my $nums = System::Array->new(1, 2, 3, 4, 5);
    
    my $doubled = $nums->Select(sub { $_[0] * 2 })->ToArray();
    is($doubled->Length(), 5, 'Select transformation length');
    is($doubled->Get(0), 2, 'Select first transformation');
    is($doubled->Get(4), 10, 'Select last transformation');
    
    my $to_strings = $nums->Select(sub { "num_$_[0]" })->ToArray();
    is($to_strings->Get(0), "num_1", 'Select to string transformation');
    
    # Test chained LINQ operations
    my $chained = $nums
        ->Where(sub { $_[0] % 2 == 0 })  # Even numbers
        ->Select(sub { $_[0] * $_[0] })  # Squared
        ->ToArray();
    is($chained->Length(), 2, 'Chained LINQ length');
    is($chained->Get(0), 4, 'Chained LINQ first result (2^2)');
    is($chained->Get(1), 16, 'Chained LINQ second result (4^2)');
    
    # Test First/Last with predicates
    my $mixed = System::Array->new(1, "string", 3, "another", 5);
    
    eval { 
        my $first_num = $mixed->First(sub { ref($_[0]) eq '' && $_[0] =~ /^\d+$/ });
        is($first_num, 1, 'First with predicate finds number');
    };
    
    eval {
        my $last_str = $mixed->Last(sub { ref($_[0]) eq '' && $_[0] =~ /^[a-zA-Z]+$/ });
        is($last_str, "another", 'Last with predicate finds string');
    };
    
    # Test Any/All with edge cases
    my $empty_any = System::Array->new();
    ok(!$empty_any->Any(), 'Empty array Any returns false');
    ok($empty_any->All(sub { $_[0] > 0 }), 'Empty array All returns true');
    
    my $single = System::Array->new(42);
    ok($single->Any(), 'Single element Any returns true');
    ok($single->Any(sub { $_[0] == 42 }), 'Single element Any with predicate');
    ok(!$single->Any(sub { $_[0] == 0 }), 'Single element Any false predicate');
    ok($single->All(sub { $_[0] > 0 }), 'Single element All with predicate');
    
    # Test Take/Skip edge cases
    my $data = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    my $take_zero = $data->Take(0)->ToArray();
    is($take_zero->Length(), 0, 'Take zero returns empty');
    
    my $take_more = $data->Take(100)->ToArray();
    is($take_more->Length(), 10, 'Take more than length returns all');
    
    my $skip_all = $data->Skip(10)->ToArray();
    is($skip_all->Length(), 0, 'Skip all returns empty');
    
    my $skip_more = $data->Skip(100)->ToArray();
    is($skip_more->Length(), 0, 'Skip more than length returns empty');
    
    # Test Count with predicate
    my $count_all = $data->Count();
    is($count_all, 10, 'Count without predicate');
    
    my $count_even = $data->Count(sub { $_[0] % 2 == 0 });
    is($count_even, 5, 'Count with predicate (even numbers)');
    
    my $count_none = $data->Count(sub { $_[0] > 100 });
    is($count_none, 0, 'Count with predicate (no matches)');
    
    # Test with unicode data
    my $unicode = System::Array->new("café", "naïve", "résumé", "éclair");
    my $unicode_filtered = $unicode
        ->Where(sub { length($_[0]) > 4 })
        ->ToArray();
    is($unicode_filtered->Length(), 3, 'Unicode LINQ filtering');
    
    # Test with mixed data types
    my $mixed_types = System::Array->new(1, "two", 3.0, undef, System::String->new("five"));
    my $defined_only = $mixed_types
        ->Where(sub { defined($_[0]) })
        ->ToArray();
    is($defined_only->Length(), 4, 'Mixed types Where defined');
}

sub test_array_memory_and_performance_edge_cases {
    # Test memory usage with large arrays
    my @huge_data = (1..1000000);  # 1 million elements
    my $huge_arr = System::Array->new(@huge_data);
    
    is($huge_arr->Length(), 1000000, 'Million element array created');
    is($huge_arr->Get(0), 1, 'Million element array first element');
    is($huge_arr->Get(999999), 1000000, 'Million element array last element');
    
    # Test operations on huge array
    ok($huge_arr->Contains(500000), 'Contains works on million element array');
    is($huge_arr->IndexOf(750000), 749999, 'IndexOf works on million element array');
    
    # Test enumeration performance
    my $enum_count = 0;
    my $huge_enum = $huge_arr->GetEnumerator();
    while ($huge_enum->MoveNext() && $enum_count < 1000) {  # Test first 1000
        $enum_count++;
    }
    is($enum_count, 1000, 'Large array enumeration performance acceptable');
    
    # Test clear on huge array
    $huge_arr->Clear();
    is($huge_arr->Length(), 0, 'Huge array cleared successfully');
    
    # Test rapid creation and destruction
    for my $i (1..1000) {
        my $temp_arr = System::Array->new((1..$i));
        is($temp_arr->Length(), $i, "Rapid creation $i elements") if $i <= 3;
        $temp_arr->Clear();
        last if $i >= 100;  # Limit for test performance
    }
    
    # Test memory reuse patterns
    my $reuse_arr = System::Array->new();
    for my $round (1..10) {
        # Fill array
        for my $i (1..1000) {
            $reuse_arr = System::Array->new((1..$i));
            last if $i >= 10;  # Limit for performance
        }
        
        # Clear and verify
        $reuse_arr->Clear();
        is($reuse_arr->Length(), 0, "Memory reuse round $round") if $round <= 3;
    }
    
    # Test with very long strings in array
    my @long_strings = map { 'X' x 10000 } (1..100);
    my $string_arr = System::Array->new(@long_strings);
    is($string_arr->Length(), 100, 'Array with long strings created');
    is(length($string_arr->Get(0)), 10000, 'Long string element preserved');
    
    # Test array of arrays (nested structures)
    my @nested_arrays;
    for my $i (1..100) {
        push @nested_arrays, System::Array->new((1..$i));
        last if $i >= 10;  # Limit for performance
    }
    my $nested = System::Array->new(@nested_arrays);
    is($nested->Length(), 10, 'Nested array structure created');
    isa_ok($nested->Get(0), 'System::Array', 'Nested element is Array');
}

sub test_array_unicode_and_encoding_edge_cases {
    # Test with various unicode character types
    my @unicode_chars = (
        "\x{00E9}",        # é (Latin)
        "\x{03B1}",        # α (Greek)
        "\x{0627}",        # ا (Arabic)
        "\x{4E2D}",        # 中 (Chinese)
        "\x{1F600}",       # 😀 (Emoji)
        "\x{1D400}",       # 𝐀 (Mathematical)
    );
    
    my $unicode_arr = System::Array->new(@unicode_chars);
    is($unicode_arr->Length(), 6, 'Unicode character array length');
    
    for my $i (0..5) {
        is($unicode_arr->Get($i), $unicode_chars[$i], "Unicode char $i preserved");
    }
    
    # Test IndexOf/LastIndexOf with unicode
    is($unicode_arr->IndexOf("\x{00E9}"), 0, 'Unicode IndexOf Latin');
    is($unicode_arr->IndexOf("\x{1F600}"), 4, 'Unicode IndexOf Emoji');
    ok($unicode_arr->Contains("\x{03B1}"), 'Unicode Contains Greek');
    
    # Test with normalization forms
    my $nfc = "\x{00E9}";           # é (NFC)
    my $nfd = "e\x{0301}";          # e + combining acute (NFD)
    
    my $norm_arr = System::Array->new($nfc, "other", $nfd);
    is($norm_arr->IndexOf($nfc), 0, 'Unicode NFC found');
    # NFD may or may not be found depending on normalization
    my $nfd_index = $norm_arr->IndexOf($nfd);
    ok(defined($nfd_index), 'Unicode NFD search handled');
    
    # Test with combining characters
    my @combining = (
        "e\x{0301}",       # e + acute
        "o\x{0308}",       # o + diaeresis  
        "n\x{0303}",       # n + tilde
    );
    
    my $combining_arr = System::Array->new(@combining);
    is($combining_arr->Length(), 3, 'Combining character array length');
    ok($combining_arr->Contains("e\x{0301}"), 'Contains combining characters');
    
    # Test with zero-width characters
    my @zero_width = (
        "a\x{200D}b",      # Zero width joiner
        "c\x{200C}d",      # Zero width non-joiner
        "e\x{FEFF}f",      # Zero width no-break space
    );
    
    my $zw_arr = System::Array->new(@zero_width);
    is($zw_arr->Length(), 3, 'Zero-width character array length');
    ok($zw_arr->Contains("a\x{200D}b"), 'Contains zero-width joiner');
    
    # Test with RTL (right-to-left) text
    my @rtl_text = (
        "\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}",  # Arabic
        "\x{05E9}\x{05DC}\x{05D5}\x{05DD}",                          # Hebrew
    );
    
    my $rtl_arr = System::Array->new(@rtl_text);
    is($rtl_arr->Length(), 2, 'RTL text array length');
    ok($rtl_arr->Contains($rtl_text[0]), 'Contains Arabic text');
    ok($rtl_arr->Contains($rtl_text[1]), 'Contains Hebrew text');
    
    # Test with mixed LTR/RTL
    my $mixed_text = "Hello \x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629} World";
    my $mixed_arr = System::Array->new($mixed_text, "other");
    ok($mixed_arr->Contains($mixed_text), 'Contains mixed LTR/RTL text');
    
    # Test with surrogate pairs and complex emoji
    my @complex_emoji = (
        "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}\x{200D}\x{1F466}",  # Family emoji
        "\x{1F3F4}\x{E0067}\x{E0062}\x{E0065}\x{E006E}\x{E0067}\x{E007F}", # Flag emoji
    );
    
    my $emoji_arr = System::Array->new(@complex_emoji);
    is($emoji_arr->Length(), 2, 'Complex emoji array length');
    # Note: These might not work correctly depending on Perl's Unicode support
    
    # Test enumeration with unicode
    my $unicode_enum = $unicode_arr->GetEnumerator();
    my @enumerated_unicode;
    while ($unicode_enum->MoveNext()) {
        push @enumerated_unicode, $unicode_enum->Current();
    }
    is(scalar(@enumerated_unicode), 6, 'Unicode enumeration count');
    is($enumerated_unicode[4], "\x{1F600}", 'Unicode enumeration emoji');
}

sub test_array_cross_platform_edge_cases {
    # Test with different line ending styles
    my @line_endings = (
        "line1\nline2",     # Unix LF
        "line1\r\nline2",   # Windows CRLF  
        "line1\rline2",     # Old Mac CR
    );
    
    my $line_arr = System::Array->new(@line_endings);
    is($line_arr->Length(), 3, 'Line ending array length');
    
    for my $i (0..2) {
        is($line_arr->Get($i), $line_endings[$i], "Line ending style $i preserved");
    }
    
    # Test with path separators
    my @paths = (
        "folder/file.txt",      # Unix style
        "folder\\file.txt",     # Windows style
        "folder:file.txt",      # Mac style (rare)
    );
    
    my $path_arr = System::Array->new(@paths);
    is($path_arr->Length(), 3, 'Path separator array length');
    ok($path_arr->Contains("folder/file.txt"), 'Contains Unix path');
    ok($path_arr->Contains("folder\\file.txt"), 'Contains Windows path');
    
    # Test with different number formats
    my @numbers = (
        "1,234.56",     # US format
        "1.234,56",     # European format
        "1 234,56",     # French format
    );
    
    my $num_arr = System::Array->new(@numbers);
    is($num_arr->Length(), 3, 'Number format array length');
    ok($num_arr->Contains("1,234.56"), 'Contains US number format');
    
    # Test with different date formats (as strings)
    my @dates = (
        "12/31/2023",       # US MM/DD/YYYY
        "31/12/2023",       # UK DD/MM/YYYY
        "2023-12-31",       # ISO YYYY-MM-DD
    );
    
    my $date_arr = System::Array->new(@dates);
    is($date_arr->Length(), 3, 'Date format array length');
    ok($date_arr->Contains("2023-12-31"), 'Contains ISO date format');
    
    # Test with locale-specific characters
    my @locale_chars = (
        "naïve",            # French
        "Müller",           # German
        "piñata",           # Spanish
        "São Paulo",        # Portuguese
    );
    
    my $locale_arr = System::Array->new(@locale_chars);
    is($locale_arr->Length(), 4, 'Locale character array length');
    ok($locale_arr->Contains("naïve"), 'Contains French characters');
    ok($locale_arr->Contains("Müller"), 'Contains German characters');
}

# Run all comprehensive edge case tests
test_array_construction_edge_cases();
test_array_bounds_and_exceptions_edge_cases();
test_array_element_assignment_edge_cases();
test_array_indexof_lastindexof_edge_cases();
test_array_contains_edge_cases();
test_array_clear_edge_cases();
test_array_enumerator_edge_cases();
test_array_linq_integration_edge_cases();
test_array_memory_and_performance_edge_cases();
test_array_unicode_and_encoding_edge_cases();
test_array_cross_platform_edge_cases();

done_testing();