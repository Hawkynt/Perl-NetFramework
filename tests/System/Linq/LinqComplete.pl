#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use System::Linq;

BEGIN {
    use_ok('System::Linq');
}

sub test_mathematical_operators {
    my $numbers = System::Array->new(1, 2, 3, 4, 5);
    
    # Sum
    is($numbers->Sum(), 15, 'Sum without selector');
    is($numbers->Sum(sub { $_[0] * 2 }), 30, 'Sum with selector');
    
    # Average
    is($numbers->Average(), 3, 'Average without selector');
    is($numbers->Average(sub { $_[0] * 2 }), 6, 'Average with selector');
    
    # Min
    is($numbers->Min(), 1, 'Min without selector');
    is($numbers->Min(sub { $_[0] * -1 }), -5, 'Min with selector');
    
    # Max
    is($numbers->Max(), 5, 'Max without selector');
    is($numbers->Max(sub { $_[0] * 2 }), 10, 'Max with selector');
}

sub test_empty_sequence_exceptions {
    my $empty = System::Array->new();
    
    eval { $empty->Average(); };
    ok($@, 'Average throws on empty sequence');
    
    eval { $empty->Min(); };
    ok($@, 'Min throws on empty sequence');
    
    eval { $empty->Max(); };
    ok($@, 'Max throws on empty sequence');
    
    is($empty->Sum(), 0, 'Sum returns 0 for empty sequence');
}

sub test_set_operations {
    my $arr1 = System::Array->new(1, 2, 3, 4);
    my $arr2 = System::Array->new(3, 4, 5, 6);
    
    # Union
    my $union = $arr1->Union($arr2)->ToArray();
    is($union->Length(), 6, 'Union has correct count');
    ok($union->Contains(1), 'Union contains element from first');
    ok($union->Contains(6), 'Union contains element from second');
    ok($union->Contains(3), 'Union contains common element');
    
    # Intersect
    my $intersect = $arr1->Intersect($arr2)->ToArray();
    is($intersect->Length(), 2, 'Intersect has correct count');
    ok($intersect->Contains(3), 'Intersect contains common element 3');
    ok($intersect->Contains(4), 'Intersect contains common element 4');
    ok(!$intersect->Contains(1), 'Intersect does not contain unique element');
    
    # Except
    my $except = $arr1->Except($arr2)->ToArray();
    is($except->Length(), 2, 'Except has correct count');
    ok($except->Contains(1), 'Except contains unique element 1');
    ok($except->Contains(2), 'Except contains unique element 2');
    ok(!$except->Contains(3), 'Except does not contain common element');
}

sub test_aggregate {
    my $numbers = System::Array->new(1, 2, 3, 4, 5);
    
    # Sum using aggregate
    my $sum = $numbers->Aggregate(0, sub { $_[0] + $_[1] });
    is($sum, 15, 'Aggregate sum');
    
    # Product using aggregate
    my $product = $numbers->Aggregate(1, sub { $_[0] * $_[1] });
    is($product, 120, 'Aggregate product');
    
    # String concatenation
    my $strings = System::Array->new("a", "b", "c");
    my $concat = $strings->Aggregate("", sub { $_[0] . $_[1] });
    is($concat, "abc", 'Aggregate string concatenation');
}

sub test_chaining_with_new_operators {
    my $numbers = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    # Complex chaining
    my $result = $numbers
        ->Where(sub { $_[0] % 2 == 0 })     # Even numbers: [2,4,6,8,10]
        ->Select(sub { $_[0] * $_[0] })      # Squares: [4,16,36,64,100]
        ->Where(sub { $_[0] > 20 })          # > 20: [36,64,100]
        ->ToArray();
    
    is($result->Length(), 3, 'Chained operations count');
    is($result->Sum(), 200, 'Chained operations sum');
    is($result->Min(), 36, 'Chained operations min');
    is($result->Max(), 100, 'Chained operations max');
    is($result->Average(), 200/3, 'Chained operations average');
}

sub test_set_operations_with_duplicates {
    my $arr1 = System::Array->new(1, 1, 2, 2, 3);
    my $arr2 = System::Array->new(2, 2, 3, 3, 4);
    
    # Union should remove duplicates
    my $union = $arr1->Union($arr2)->ToArray();
    is($union->Length(), 4, 'Union removes duplicates');
    is($union->Count(sub { $_[0] == 1 }), 1, 'Union has single 1');
    is($union->Count(sub { $_[0] == 2 }), 1, 'Union has single 2');
    is($union->Count(sub { $_[0] == 3 }), 1, 'Union has single 3');
    is($union->Count(sub { $_[0] == 4 }), 1, 'Union has single 4');
}

sub test_mathematical_with_floating_point {
    my $numbers = System::Array->new(1.5, 2.5, 3.5, 4.5);
    
    is($numbers->Sum(), 12.0, 'Sum with floating point');
    is($numbers->Average(), 3.0, 'Average with floating point');
    is($numbers->Min(), 1.5, 'Min with floating point');
    is($numbers->Max(), 4.5, 'Max with floating point');
}

sub test_mixed_data_types {
    my $mixed = System::Array->new("apple", "banana", "cherry");
    
    # Min/Max should work with strings
    is($mixed->Min(), "apple", 'Min with strings');
    is($mixed->Max(), "cherry", 'Max with strings');
    
    # Aggregate string concatenation
    my $concat = $mixed->Aggregate("", sub { $_[0] . " " . $_[1] });
    like($concat, qr/apple.*banana.*cherry/, 'String aggregate');
}

sub test_linq_performance {
    # Test with larger dataset
    my @large_data = (1..1000);
    my $large_array = System::Array->new(@large_data);
    
    my $sum = $large_array->Sum();
    is($sum, 500500, 'Large dataset sum');
    
    my $evens = $large_array->Where(sub { $_[0] % 2 == 0 })->Count();
    is($evens, 500, 'Large dataset even count');
    
    my $avg = $large_array->Average();
    is($avg, 500.5, 'Large dataset average');
}

# Run all tests
test_mathematical_operators();
test_empty_sequence_exceptions();
test_set_operations();
test_aggregate();
test_chaining_with_new_operators();
test_set_operations_with_duplicates();
test_mathematical_with_floating_point();
test_mixed_data_types();
test_linq_performance();

done_testing();