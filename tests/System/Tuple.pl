#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';
use Test::More;
use System;
use System::Tuple;

BEGIN {
    use_ok('System::Tuple');
}

sub test_tuple_creation {
    # Test basic creation
    my $tuple1 = System::Tuple->new(1);
    isa_ok($tuple1, 'System::Tuple', 'Single item tuple creation');
    is($tuple1->Count(), 1, 'Single item tuple count');
    is($tuple1->Item1(), 1, 'Single item access');
    
    my $tuple2 = System::Tuple->new(1, "hello");
    is($tuple2->Count(), 2, 'Two item tuple count');
    is($tuple2->Item1(), 1, 'First item access');
    is($tuple2->Item2(), "hello", 'Second item access');
    
    my $tuple8 = System::Tuple->new(1, 2, 3, 4, 5, 6, 7, 8);
    is($tuple8->Count(), 8, 'Eight item tuple count');
    is($tuple8->Item8(), 8, 'Eighth item access');
}

sub test_tuple_factory_methods {
    # Test Create method
    my $tuple = Tuple::Create(1, "test", 3.14);
    isa_ok($tuple, 'System::Tuple', 'Create method works');
    is($tuple->Count(), 3, 'Create method count');
    is($tuple->Item1(), 1, 'Create method item1');
    is($tuple->Item2(), "test", 'Create method item2');
    is($tuple->Item3(), 3.14, 'Create method item3');
    
    # Test specific factory methods
    my $tuple1 = Tuple::Create1("single");
    is($tuple1->Count(), 1, 'Create1 count');
    is($tuple1->Item1(), "single", 'Create1 item');
    
    my $tuple2 = Tuple::Create2("first", "second");
    is($tuple2->Count(), 2, 'Create2 count');
    is($tuple2->Item1(), "first", 'Create2 item1');
    is($tuple2->Item2(), "second", 'Create2 item2');
    
    my $tuple3 = Tuple::Create3(1, 2, 3);
    is($tuple3->Count(), 3, 'Create3 count');
    is($tuple3->Item3(), 3, 'Create3 item3');
    
    my $tuple4 = Tuple::Create4("a", "b", "c", "d");
    is($tuple4->Count(), 4, 'Create4 count');
    is($tuple4->Item4(), "d", 'Create4 item4');
    
    my $tuple5 = Tuple::Create5(1, 2, 3, 4, 5);
    is($tuple5->Count(), 5, 'Create5 count');
    is($tuple5->Item5(), 5, 'Create5 item5');
    
    my $tuple6 = Tuple::Create6(1, 2, 3, 4, 5, 6);
    is($tuple6->Count(), 6, 'Create6 count');
    is($tuple6->Item6(), 6, 'Create6 item6');
    
    my $tuple7 = Tuple::Create7(1, 2, 3, 4, 5, 6, 7);
    is($tuple7->Count(), 7, 'Create7 count');
    is($tuple7->Item7(), 7, 'Create7 item7');
    
    my $tuple8 = Tuple::Create8(1, 2, 3, 4, 5, 6, 7, 8);
    is($tuple8->Count(), 8, 'Create8 count');
    is($tuple8->Item8(), 8, 'Create8 item8');
}

sub test_tuple_item_access {
    my $tuple = System::Tuple->new("a", "b", "c", "d", "e", "f", "g", "h");
    
    # Test all item accessors
    is($tuple->Item1(), "a", 'Item1 access');
    is($tuple->Item2(), "b", 'Item2 access');
    is($tuple->Item3(), "c", 'Item3 access');
    is($tuple->Item4(), "d", 'Item4 access');
    is($tuple->Item5(), "e", 'Item5 access');
    is($tuple->Item6(), "f", 'Item6 access');
    is($tuple->Item7(), "g", 'Item7 access');
    is($tuple->Item8(), "h", 'Item8 access');
    
    # Test GetItem method
    is($tuple->GetItem(0), "a", 'GetItem index 0');
    is($tuple->GetItem(1), "b", 'GetItem index 1');
    is($tuple->GetItem(7), "h", 'GetItem index 7');
}

sub test_tuple_bounds_checking {
    my $tuple2 = System::Tuple->new("first", "second");
    
    # Test accessing items beyond tuple size
    eval { $tuple2->Item3(); };
    ok($@, 'Item3 throws on 2-tuple');
    
    eval { $tuple2->Item4(); };
    ok($@, 'Item4 throws on 2-tuple');
    
    eval { $tuple2->Item5(); };
    ok($@, 'Item5 throws on 2-tuple');
    
    eval { $tuple2->Item6(); };
    ok($@, 'Item6 throws on 2-tuple');
    
    eval { $tuple2->Item7(); };
    ok($@, 'Item7 throws on 2-tuple');
    
    eval { $tuple2->Item8(); };
    ok($@, 'Item8 throws on 2-tuple');
    
    # Test GetItem bounds checking
    eval { $tuple2->GetItem(-1); };
    ok($@, 'GetItem throws on negative index');
    
    eval { $tuple2->GetItem(2); };
    ok($@, 'GetItem throws on index beyond size');
    
    eval { $tuple2->GetItem(10); };
    ok($@, 'GetItem throws on large index');
}

sub test_tuple_null_reference {
    my $null_tuple;
    
    # Test all methods throw on null reference
    eval { $null_tuple->Count(); };
    ok($@, 'Count throws on null reference');
    
    eval { $null_tuple->Item1(); };
    ok($@, 'Item1 throws on null reference');
    
    eval { $null_tuple->Item2(); };
    ok($@, 'Item2 throws on null reference');
    
    eval { $null_tuple->GetItem(0); };
    ok($@, 'GetItem throws on null reference');
    
    eval { $null_tuple->Equals(System::Tuple->new(1)); };
    ok($@, 'Equals throws on null reference');
    
    eval { $null_tuple->GetHashCode(); };
    ok($@, 'GetHashCode throws on null reference');
    
    eval { $null_tuple->ToString(); };
    ok($@, 'ToString throws on null reference');
}

sub test_tuple_equality {
    my $tuple1 = System::Tuple->new(1, "hello", 3.14);
    my $tuple2 = System::Tuple->new(1, "hello", 3.14);
    my $tuple3 = System::Tuple->new(1, "hello", 2.71);
    my $tuple4 = System::Tuple->new(1, "hello");
    
    # Test equality
    ok($tuple1->Equals($tuple2), 'Equal tuples are equal');
    ok(!$tuple1->Equals($tuple3), 'Tuples with different values are not equal');
    ok(!$tuple1->Equals($tuple4), 'Tuples with different sizes are not equal');
    
    # Test equality with null
    ok(!$tuple1->Equals(undef), 'Tuple not equal to null');
    
    # Test equality with wrong type
    ok(!$tuple1->Equals("not a tuple"), 'Tuple not equal to wrong type');
    
    # Test equality with null values
    my $tuple_null1 = System::Tuple->new(1, undef, 3);
    my $tuple_null2 = System::Tuple->new(1, undef, 3);
    my $tuple_null3 = System::Tuple->new(1, "test", 3);
    
    ok($tuple_null1->Equals($tuple_null2), 'Tuples with same null values are equal');
    ok(!$tuple_null1->Equals($tuple_null3), 'Tuple with null not equal to tuple without null');
}

sub test_tuple_hashing {
    my $tuple1 = System::Tuple->new(1, "hello", 3.14);
    my $tuple2 = System::Tuple->new(1, "hello", 3.14);
    my $tuple3 = System::Tuple->new(1, "hello", 2.71);
    
    # Test that equal tuples have equal hash codes
    is($tuple1->GetHashCode(), $tuple2->GetHashCode(), 'Equal tuples have equal hash codes');
    
    # Test that different tuples likely have different hash codes (not guaranteed but probable)
    isnt($tuple1->GetHashCode(), $tuple3->GetHashCode(), 'Different tuples likely have different hash codes');
    
    # Test hash code consistency
    is($tuple1->GetHashCode(), $tuple1->GetHashCode(), 'Hash code is consistent');
    
    # Test with null values
    my $tuple_null = System::Tuple->new(1, undef, 3);
    my $hash = $tuple_null->GetHashCode();
    ok(defined($hash), 'Hash code works with null values');
}

sub test_tuple_string_representation {
    my $tuple1 = System::Tuple->new(1);
    is($tuple1->ToString(), '(1)', 'Single item tuple string representation');
    
    my $tuple2 = System::Tuple->new(1, "hello");
    is($tuple2->ToString(), '(1, hello)', 'Two item tuple string representation');
    
    my $tuple3 = System::Tuple->new(1, "hello", 3.14);
    is($tuple3->ToString(), '(1, hello, 3.14)', 'Three item tuple string representation');
    
    # Test with null values
    my $tuple_null = System::Tuple->new(1, undef, "test");
    is($tuple_null->ToString(), '(1, , test)', 'Tuple with null value string representation');
    
    # Test empty tuple
    my $tuple_empty = System::Tuple->new();
    is($tuple_empty->ToString(), '()', 'Empty tuple string representation');
}

sub test_tuple_mixed_types {
    # Test tuple with various data types
    my $tuple = System::Tuple->new(
        42,                    # integer
        "hello world",         # string
        3.14159,              # float
        undef,                # null
        [1, 2, 3],           # array reference
        { key => "value" },   # hash reference
        \\\"nested ref"       # reference to reference
    );
    
    is($tuple->Count(), 7, 'Mixed type tuple count');
    is($tuple->Item1(), 42, 'Integer item');
    is($tuple->Item2(), "hello world", 'String item');
    is($tuple->Item3(), 3.14159, 'Float item');
    ok(!defined($tuple->Item4()), 'Null item');
    isa_ok($tuple->Item5(), 'ARRAY', 'Array reference item');
    isa_ok($tuple->Item6(), 'HASH', 'Hash reference item');
    is($tuple->Item5()->[1], 2, 'Array reference content');
    is($tuple->Item6()->{key}, "value", 'Hash reference content');
    
    # Test string representation with complex types
    like($tuple->ToString(), qr/42, hello world/, 'Mixed type string starts correctly');
}

sub test_tuple_edge_cases {
    # Test very large tuple
    my @items = (1..8);
    my $large_tuple = System::Tuple->new(@items);
    is($large_tuple->Count(), 8, 'Large tuple count');
    
    # Test tuple with duplicates
    my $dup_tuple = System::Tuple->new("same", "same", "same");
    is($dup_tuple->Count(), 3, 'Duplicate items tuple count');
    is($dup_tuple->Item1(), "same", 'Duplicate item 1');
    is($dup_tuple->Item2(), "same", 'Duplicate item 2');
    is($dup_tuple->Item3(), "same", 'Duplicate item 3');
    
    # Test empty tuple
    my $empty_tuple = System::Tuple->new();
    is($empty_tuple->Count(), 0, 'Empty tuple count');
    
    # Test single item tuple
    my $single_tuple = System::Tuple->new("only");
    is($single_tuple->Count(), 1, 'Single item tuple count');
    is($single_tuple->Item1(), "only", 'Single item value');
    
    # Test equality with empty tuples
    my $empty1 = System::Tuple->new();
    my $empty2 = System::Tuple->new();
    ok($empty1->Equals($empty2), 'Empty tuples are equal');
}

sub test_tuple_immutability {
    # Test that tuple items cannot be modified (they're read-only)
    my $tuple = System::Tuple->new(1, 2, 3);
    
    # Verify we cannot modify items directly
    # In Perl, we don't have read-only enforcement, but we test the concept
    is($tuple->Item1(), 1, 'Original value intact');
    is($tuple->Item2(), 2, 'Original value intact');
    is($tuple->Item3(), 3, 'Original value intact');
    
    # The internal array should not be modifiable through public interface
    # This is enforced by not providing setters
    ok(!$tuple->can('SetItem1'), 'No setter method available');
    ok(!$tuple->can('SetItem'), 'No generic setter available');
}

# Run all tests
test_tuple_creation();
test_tuple_factory_methods();
test_tuple_item_access();
test_tuple_bounds_checking();
test_tuple_null_reference();
test_tuple_equality();
test_tuple_hashing();
test_tuple_string_representation();
test_tuple_mixed_types();
test_tuple_edge_cases();
test_tuple_immutability();

done_testing();