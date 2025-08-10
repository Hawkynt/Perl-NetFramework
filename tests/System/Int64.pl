#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';

# Import required modules
use System::Int64;
use System::Exceptions;

# Test constants
sub test_constants {
    ok(System::Int64::MinValue < 0, "MinValue is negative");
    ok(System::Int64::MaxValue > 0, "MaxValue is positive");
    ok(abs(System::Int64::MinValue) > abs(System::Int32::MaxValue), "Int64 range larger than Int32");
}

# Test new() - Happy path
sub test_new_happy {
    my $int64 = System::Int64->new(9223372036854775807);
    isa_ok($int64, 'System::Int64', "new() creates System::Int64 object");
    is($int64->Value(), 9223372036854775807, "new() stores large positive value");
    
    my $int64_negative = System::Int64->new(-9223372036854775808);
    is($int64_negative->Value(), -9223372036854775808, "new() handles large negative value");
    
    my $int64_zero = System::Int64->new(0);
    is($int64_zero->Value(), 0, "new(0) works correctly");
    
    my $int64_default = System::Int64->new();
    is($int64_default->Value(), 0, "new() with no args defaults to 0");
}

# Test Parse() - Happy path
sub test_parse_happy {
    my $int64 = System::Int64->Parse("123456789012345");
    isa_ok($int64, 'System::Int64', "Parse() returns System::Int64 object");
    is($int64->Value(), 123456789012345, "Parse() handles large numbers");
    
    my $int64_negative = System::Int64->Parse("-987654321098765");
    is($int64_negative->Value(), -987654321098765, "Parse() handles large negative numbers");
}

# Test Parse() - Exception handling
sub test_parse_exceptions {
    eval {
        System::Int64->Parse(undef);
    };
    ok($@ =~ /ArgumentNullException/, "Parse() throws ArgumentNullException for undef");
    
    eval {
        System::Int64->Parse("abc");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for invalid string");
}

# Test TryParse() - Happy path
sub test_tryparse_happy {
    my $result;
    my $success = System::Int64->TryParse("123456789012345", \$result);
    ok($success, "TryParse() returns true for valid large number");
    is($result->Value(), 123456789012345, "TryParse() sets correct large value");
}

# Test TryParse() - Failure cases
sub test_tryparse_failure {
    my $result;
    my $success = System::Int64->TryParse("invalid", \$result);
    ok(!$success, "TryParse() returns false for invalid string");
}

# Test ToString() - Happy path
sub test_tostring_happy {
    my $int64 = System::Int64->new(123456789012345);
    is($int64->ToString(), "123456789012345", "ToString() returns correct string for large number");
    
    my $int64_negative = System::Int64->new(-987654321098765);
    is($int64_negative->ToString(), "-987654321098765", "ToString() handles negative large numbers");
}

# Test CompareTo() - Happy path
sub test_compareto_happy {
    my $int64_1 = System::Int64->new(1000000000000);
    my $int64_2 = System::Int64->new(2000000000000);
    my $int64_3 = System::Int64->new(1000000000000);
    
    ok($int64_1->CompareTo($int64_2) < 0, "CompareTo() works with large numbers");
    ok($int64_2->CompareTo($int64_1) > 0, "CompareTo() returns positive for larger");
    is($int64_1->CompareTo($int64_3), 0, "CompareTo() returns zero for equal");
}

# Test CompareTo() - Exception handling
sub test_compareto_exceptions {
    my $int64 = System::Int64->new(1000);
    
    eval {
        $int64->CompareTo(undef);
    };
    ok($@ =~ /ArgumentNullException/, "CompareTo() throws ArgumentNullException for undef");
    
    eval {
        $int64->CompareTo("not_an_int64");
    };
    ok($@ =~ /ArgumentException/, "CompareTo() throws ArgumentException for wrong type");
}

# Test Equals() - Happy path
sub test_equals_happy {
    my $int64_1 = System::Int64->new(123456789012345);
    my $int64_2 = System::Int64->new(123456789012345);
    my $int64_3 = System::Int64->new(987654321098765);
    
    ok($int64_1->Equals($int64_2), "Equals() returns true for equal large values");
    ok(!$int64_1->Equals($int64_3), "Equals() returns false for different values");
    ok(!$int64_1->Equals(undef), "Equals() returns false for undef");
}

# Test GetHashCode() - Happy path
sub test_gethashcode_happy {
    my $int64 = System::Int64->new(123456789012345);
    my $hash = $int64->GetHashCode();
    ok(defined($hash), "GetHashCode() returns defined value");
    
    my $int64_zero = System::Int64->new(0);
    is($int64_zero->GetHashCode(), 0, "GetHashCode() returns 0 for zero");
}

# Test arithmetic operations
sub test_arithmetic_operations {
    my $result = System::Int64->Add(1000000000000, 500000000000);
    is($result->Value(), 1500000000000, "Add() works with large numbers");
    
    my $result2 = System::Int64->Subtract(2000000000000, 500000000000);
    is($result2->Value(), 1500000000000, "Subtract() works with large numbers");
    
    my $result3 = System::Int64->Multiply(1000000, 2000000);
    is($result3->Value(), 2000000000000, "Multiply() works correctly");
    
    my $result4 = System::Int64->Divide(1000000000000, 1000);
    is($result4->Value(), 1000000000, "Divide() works correctly");
}

# Test arithmetic exception handling
sub test_arithmetic_exceptions {
    eval {
        System::Int64->Add(undef, 500);
    };
    ok($@ =~ /ArgumentNullException/, "Add() throws ArgumentNullException for undef");
    
    eval {
        System::Int64->Divide(1000, 0);
    };
    ok($@ =~ /DivideByZeroException/, "Divide() throws DivideByZeroException");
}

# Test Value() exception handling
sub test_value_exceptions {
    eval {
        System::Int64::Value(undef);
    };
    ok($@ =~ /NullReferenceException/, "Value() throws NullReferenceException on undef");
}

# Test bitwise operations
sub test_bitwise_operations {
    my $result1 = System::Int64->BitwiseAnd(15, 7);
    is($result1->Value(), 7, "BitwiseAnd works correctly");
    
    my $result2 = System::Int64->BitwiseOr(8, 4);
    is($result2->Value(), 12, "BitwiseOr works correctly");
    
    my $result3 = System::Int64->BitwiseXor(15, 7);
    is($result3->Value(), 8, "BitwiseXor works correctly");
}

# Test edge cases
sub test_edge_cases {
    # Test very large numbers that fit in 64-bit
    my $large_positive = System::Int64->new(9223372036854775000); # Near max but not exactly
    ok(defined($large_positive->Value()), "Can handle very large positive numbers");
    
    my $large_negative = System::Int64->new(-9223372036854775000); # Near min but not exactly
    ok(defined($large_negative->Value()), "Can handle very large negative numbers");
    
    # Test integer division
    my $div_result = System::Int64->Divide(10, 3);
    is($div_result->Value(), 3, "Integer division truncates correctly");
}

# Run all tests
sub run_tests {
    test_constants();
    test_new_happy();
    test_parse_happy();
    test_parse_exceptions();
    test_tryparse_happy();
    test_tryparse_failure();
    test_tostring_happy();
    test_compareto_happy();
    test_compareto_exceptions();
    test_equals_happy();
    test_gethashcode_happy();
    test_arithmetic_operations();
    test_arithmetic_exceptions();
    test_value_exceptions();
    test_bitwise_operations();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();