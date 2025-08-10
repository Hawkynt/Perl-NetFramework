#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';

# Import required modules
use System::Int32;
use System::Exceptions;

# Test constants
sub test_constants {
    is(System::Int32::MinValue, -2147483648, "MinValue constant is correct");
    is(System::Int32::MaxValue, 2147483647, "MaxValue constant is correct");
}

# Test new() - Happy path
sub test_new_happy {
    my $int32 = System::Int32->new(123456789);
    isa_ok($int32, 'System::Int32', "new() creates System::Int32 object");
    is($int32->Value(), 123456789, "new() stores correct value");
    
    my $int32_zero = System::Int32->new(0);
    is($int32_zero->Value(), 0, "new(0) works correctly");
    
    my $int32_negative = System::Int32->new(-123456789);
    is($int32_negative->Value(), -123456789, "new() handles negative numbers");
    
    my $int32_min = System::Int32->new(-2147483648);
    is($int32_min->Value(), -2147483648, "new() handles minimum value");
    
    my $int32_max = System::Int32->new(2147483647);
    is($int32_max->Value(), 2147483647, "new() handles maximum value");
    
    my $int32_default = System::Int32->new();
    is($int32_default->Value(), 0, "new() with no args defaults to 0");
}

# Test new() - Exception handling
sub test_new_exceptions {
    eval {
        System::Int32->new(-2147483649);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for value < MinValue");
    
    eval {
        System::Int32->new(2147483648);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for value > MaxValue");
}

# Test Parse() - Happy path
sub test_parse_happy {
    my $int32 = System::Int32->Parse("123456789");
    isa_ok($int32, 'System::Int32', "Parse() returns System::Int32 object");
    is($int32->Value(), 123456789, "Parse() returns correct value");
    
    my $int32_negative = System::Int32->Parse("-987654321");
    is($int32_negative->Value(), -987654321, "Parse() handles negative numbers");
    
    my $int32_ws = System::Int32->Parse("  12345  ");
    is($int32_ws->Value(), 12345, "Parse() handles whitespace");
}

# Test Parse() - Exception handling
sub test_parse_exceptions {
    eval {
        System::Int32->Parse(undef);
    };
    ok($@ =~ /ArgumentNullException/, "Parse() throws ArgumentNullException for undef");
    
    eval {
        System::Int32->Parse("2147483648");
    };
    ok($@ =~ /OverflowException/, "Parse() throws OverflowException for overflow");
    
    eval {
        System::Int32->Parse("abc");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for invalid string");
}

# Test TryParse() - Happy path
sub test_tryparse_happy {
    my $result;
    my $success = System::Int32->TryParse("123456789", \$result);
    ok($success, "TryParse() returns true for valid input");
    is($result->Value(), 123456789, "TryParse() sets correct value");
}

# Test TryParse() - Failure cases
sub test_tryparse_failure {
    my $result;
    my $success = System::Int32->TryParse("2147483648", \$result);
    ok(!$success, "TryParse() returns false for overflow");
    
    my $result2;
    my $success2 = System::Int32->TryParse("invalid", \$result2);
    ok(!$success2, "TryParse() returns false for invalid string");
}

# Test ToString() - Happy path
sub test_tostring_happy {
    my $int32 = System::Int32->new(123456789);
    is($int32->ToString(), "123456789", "ToString() returns correct string");
    
    my $int32_hex = System::Int32->new(255);
    is($int32_hex->ToString("X"), "000000FF", "ToString('X') returns hex");
}

# Test CompareTo() - Happy path
sub test_compareto_happy {
    my $int32_1 = System::Int32->new(1000);
    my $int32_2 = System::Int32->new(2000);
    my $int32_3 = System::Int32->new(1000);
    
    ok($int32_1->CompareTo($int32_2) < 0, "CompareTo() returns negative for smaller");
    ok($int32_2->CompareTo($int32_1) > 0, "CompareTo() returns positive for larger");
    is($int32_1->CompareTo($int32_3), 0, "CompareTo() returns zero for equal");
}

# Test Equals() - Happy path
sub test_equals_happy {
    my $int32_1 = System::Int32->new(123456789);
    my $int32_2 = System::Int32->new(123456789);
    my $int32_3 = System::Int32->new(987654321);
    
    ok($int32_1->Equals($int32_2), "Equals() returns true for equal values");
    ok(!$int32_1->Equals($int32_3), "Equals() returns false for different values");
}

# Test GetHashCode() - Happy path
sub test_gethashcode_happy {
    my $int32 = System::Int32->new(123456789);
    my $hash = $int32->GetHashCode();
    is($hash, 123456789, "GetHashCode() returns the int32 value");
}

# Test arithmetic operations
sub test_arithmetic_operations {
    my $result = System::Int32->Add(1000000, 500000);
    is($result->Value(), 1500000, "Add() works correctly");
    
    my $result2 = System::Int32->Subtract(2000000, 500000);
    is($result2->Value(), 1500000, "Subtract() works correctly");
    
    my $result3 = System::Int32->Multiply(1000, 2000);
    is($result3->Value(), 2000000, "Multiply() works correctly");
    
    my $result4 = System::Int32->Divide(1000000, 1000);
    is($result4->Value(), 1000, "Divide() works correctly");
}

# Test exception handling for Value()
sub test_value_exceptions {
    eval {
        System::Int32::Value(undef);
    };
    ok($@ =~ /NullReferenceException/, "Value() throws NullReferenceException on undef");
}

# Test bitwise operations
sub test_bitwise_operations {
    my $result1 = System::Int32->BitwiseAnd(15, 7);
    is($result1->Value(), 7, "BitwiseAnd works correctly");
    
    my $result2 = System::Int32->BitwiseOr(8, 4);
    is($result2->Value(), 12, "BitwiseOr works correctly");
    
    my $result3 = System::Int32->BitwiseXor(15, 7);
    is($result3->Value(), 8, "BitwiseXor works correctly");
}

# Test edge cases
sub test_edge_cases {
    # Test boundary values
    my $min_int32 = System::Int32->new(-2147483648);
    is($min_int32->Value(), -2147483648, "Minimum value works");
    
    my $max_int32 = System::Int32->new(2147483647);
    is($max_int32->Value(), 2147483647, "Maximum value works");
}

# Run all tests
sub run_tests {
    test_constants();
    test_new_happy();
    test_new_exceptions();
    test_parse_happy();
    test_parse_exceptions();
    test_tryparse_happy();
    test_tryparse_failure();
    test_tostring_happy();
    test_compareto_happy();
    test_equals_happy();
    test_gethashcode_happy();
    test_arithmetic_operations();
    test_value_exceptions();
    test_bitwise_operations();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();