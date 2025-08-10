#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';
use Test::More;
use System;

BEGIN {
    use_ok('System::Array');
}

sub test_array_creation {
    my $arr = System::Array->new(1, 2, 3);
    isa_ok($arr, 'System::Array', 'Array creation');
    is($arr->Length(), 3, 'Array length');
}

sub test_array_access {
    my $arr = System::Array->new("a", "b", "c");
    is($arr->Get(0), "a", 'Get first element');
    is($arr->Get(2), "c", 'Get last element');
    
    $arr->Set(1, "modified");
    is($arr->Get(1), "modified", 'Set and get modified element');
}

sub test_array_enumeration {
    my $arr = System::Array->new(1, 2, 3);
    my $enumerator = $arr->GetEnumerator();
    
    my @values;
    while ($enumerator->MoveNext()) {
        push @values, $enumerator->Current();
    }
    
    is_deeply(\@values, [1, 2, 3], 'Array enumeration works');
}

sub test_array_linq {
    my $arr = System::Array->new(1, 2, 3, 4, 5);
    
    my $evens = $arr->Where(sub { $_[0] % 2 == 0 })->ToArray();
    is($evens->Length(), 2, 'Where filter returns correct count');
    is($evens->Get(0), 2, 'First even number');
    is($evens->Get(1), 4, 'Second even number');
    
    my $doubled = $arr->Select(sub { $_[0] * 2 })->ToArray();
    is($doubled->Length(), 5, 'Select returns same count');
    is($doubled->Get(0), 2, 'First doubled value');
    is($doubled->Get(4), 10, 'Last doubled value');
}

sub test_array_contains {
    my $arr = System::Array->new("apple", "banana", "cherry");
    ok($arr->Contains("banana"), 'Array contains existing element');
    ok(!$arr->Contains("grape"), 'Array does not contain non-existing element');
}

sub test_array_indexOf {
    my $arr = System::Array->new("x", "y", "z");
    is($arr->IndexOf("y"), 1, 'IndexOf returns correct position');
    is($arr->IndexOf("missing"), -1, 'IndexOf returns -1 for missing element');
}

sub test_array_lastIndexOf {
    my $arr = System::Array->new("a", "b", "a", "c", "a");
    is($arr->LastIndexOf("a"), 4, 'LastIndexOf returns last occurrence');
    is($arr->LastIndexOf("b"), 1, 'LastIndexOf returns correct position for single occurrence');
    is($arr->LastIndexOf("missing"), -1, 'LastIndexOf returns -1 for missing element');
    
    # Test with duplicate values at end
    my $duplicates = System::Array->new(1, 2, 3, 2, 2);
    is($duplicates->LastIndexOf(2), 4, 'LastIndexOf finds last duplicate');
}

sub test_array_clear {
    my $arr = System::Array->new(1, 2, 3, 4, 5);
    is($arr->Length(), 5, 'Array has initial length');
    
    $arr->Clear();
    is($arr->Length(), 0, 'Array is empty after Clear');
    
    # Test that cleared array behaves correctly
    eval { $arr->Get(0); };
    ok($@, 'Get throws exception on cleared array');
}

sub test_array_bounds_checking {
    my $arr = System::Array->new("a", "b", "c");
    
    # Test negative index
    eval { $arr->Get(-1); };
    ok($@, 'Get throws on negative index');
    
    eval { $arr->Set(-1, "value"); };
    ok($@, 'Set throws on negative index');
    
    eval { $arr->GetValue(-1); };
    ok($@, 'GetValue throws on negative index');
    
    eval { $arr->SetValue("value", -1); };
    ok($@, 'SetValue throws on negative index');
    
    # Test index beyond bounds
    eval { $arr->Get(3); };
    ok($@, 'Get throws on index beyond bounds');
    
    eval { $arr->Set(5, "value"); };
    ok($@, 'Set throws on index beyond bounds');
    
    eval { $arr->GetValue(10); };
    ok($@, 'GetValue throws on index beyond bounds');
    
    eval { $arr->SetValue("value", 10); };
    ok($@, 'SetValue throws on index beyond bounds');
}

sub test_array_null_reference {
    # Test null reference exceptions
    my $null_array;
    
    eval { $null_array->Length(); };
    ok($@, 'Length throws on null reference');
    
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
}

sub test_array_enumerator_detailed {
    my $arr = System::Array->new("x", "y", "z");
    my $enum = $arr->GetEnumerator();
    
    # Test initial state
    eval { $enum->Current(); };
    ok($@, 'Current throws before MoveNext');
    
    # Test enumeration
    ok($enum->MoveNext(), 'First MoveNext returns true');
    is($enum->Current(), "x", 'First Current returns first element');
    
    ok($enum->MoveNext(), 'Second MoveNext returns true');
    is($enum->Current(), "y", 'Second Current returns second element');
    
    ok($enum->MoveNext(), 'Third MoveNext returns true');
    is($enum->Current(), "z", 'Third Current returns third element');
    
    ok(!$enum->MoveNext(), 'Fourth MoveNext returns false');
    eval { $enum->Current(); };
    ok($@, 'Current throws after enumeration ends');
    
    # Test Reset
    $enum->Reset();
    eval { $enum->Current(); };
    ok($@, 'Current throws after Reset before MoveNext');
    
    ok($enum->MoveNext(), 'MoveNext works after Reset');
    is($enum->Current(), "x", 'Current returns first element after Reset');
    
    # Test Dispose
    $enum->Dispose();
    # Note: After dispose, the enumerator should be unusable but we don't test
    # specific dispose behavior as it may vary
}

sub test_array_edge_cases {
    # Empty array tests
    my $empty = System::Array->new();
    is($empty->Length(), 0, 'Empty array has zero length');
    is($empty->IndexOf("anything"), -1, 'IndexOf on empty array returns -1');
    is($empty->LastIndexOf("anything"), -1, 'LastIndexOf on empty array returns -1');
    
    my $empty_enum = $empty->GetEnumerator();
    ok(!$empty_enum->MoveNext(), 'Empty array enumerator MoveNext returns false');
    
    # Single element array
    my $single = System::Array->new("only");
    is($single->Length(), 1, 'Single element array has length 1');
    is($single->Get(0), "only", 'Single element can be retrieved');
    is($single->IndexOf("only"), 0, 'IndexOf finds single element');
    is($single->LastIndexOf("only"), 0, 'LastIndexOf finds single element');
    
    $single->Clear();
    is($single->Length(), 0, 'Single element array can be cleared');
}

sub test_array_mixed_types {
    # Test array with different data types
    my $mixed = System::Array->new(1, "string", 3.14, undef);
    is($mixed->Length(), 4, 'Mixed type array has correct length');
    
    is($mixed->Get(0), 1, 'Integer element retrieved correctly');
    is($mixed->Get(1), "string", 'String element retrieved correctly');
    is($mixed->Get(2), 3.14, 'Float element retrieved correctly');
    ok(!defined($mixed->Get(3)), 'Undefined element retrieved correctly');
    
    is($mixed->IndexOf("string"), 1, 'IndexOf finds string in mixed array');
    is($mixed->LastIndexOf(undef), 3, 'LastIndexOf finds undefined value');
    
    # Test setting different types
    $mixed->Set(0, "changed");
    is($mixed->Get(0), "changed", 'Type can be changed via Set');
}

sub test_array_large_data {
    # Test with larger dataset
    my @large_data = (1..100);
    my $large_arr = System::Array->new(@large_data);
    
    is($large_arr->Length(), 100, 'Large array has correct length');
    is($large_arr->Get(0), 1, 'First element correct');
    is($large_arr->Get(99), 100, 'Last element correct');
    is($large_arr->Get(49), 50, 'Middle element correct');
    
    is($large_arr->IndexOf(50), 49, 'IndexOf works on large array');
    is($large_arr->LastIndexOf(75), 74, 'LastIndexOf works on large array');
    
    # Test enumeration of large array
    my $count = 0;
    my $enum = $large_arr->GetEnumerator();
    while ($enum->MoveNext()) {
        $count++;
    }
    is($count, 100, 'Large array enumerates all elements');
}

sub test_array_linq_comprehensive {
    my $arr = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    # Test multiple LINQ operations
    my $evens = $arr->Where(sub { $_[0] % 2 == 0 });
    is($evens->Count(), 5, 'Where filter count is correct');
    
    my $doubled = $arr->Select(sub { $_[0] * 2 });
    my $doubled_array = $doubled->ToArray();
    is($doubled_array->Get(0), 2, 'Select transformation correct');
    is($doubled_array->Get(4), 10, 'Select transformation correct for middle element');
    
    # Test First/Last
    is($arr->First(), 1, 'First returns first element');
    is($arr->Last(), 10, 'Last returns last element');
    
    # Test Any/All
    ok($arr->Any(sub { $_[0] > 5 }), 'Any returns true when condition met');
    ok(!$arr->All(sub { $_[0] > 5 }), 'All returns false when not all meet condition');
    ok($arr->All(sub { $_[0] > 0 }), 'All returns true when all meet condition');
    
    # Test Take/Skip
    my $first_three = $arr->Take(3)->ToArray();
    is($first_three->Length(), 3, 'Take returns correct count');
    is($first_three->Get(2), 3, 'Take returns correct elements');
    
    my $skip_five = $arr->Skip(5)->ToArray();
    is($skip_five->Length(), 5, 'Skip returns correct count');
    is($skip_five->Get(0), 6, 'Skip skips correct elements');
}

test_array_creation();
test_array_access();
test_array_enumeration();
test_array_linq();
test_array_contains();
test_array_indexOf();
test_array_lastIndexOf();
test_array_clear();
test_array_bounds_checking();
test_array_null_reference();
test_array_enumerator_detailed();
test_array_edge_cases();
test_array_mixed_types();
test_array_large_data();
test_array_linq_comprehensive();

done_testing();