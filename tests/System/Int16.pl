#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';

# Import required modules
use System::Int16;
use System::Exceptions;

# Test constants
sub test_constants {
    is(System::Int16::MinValue, -32768, "MinValue constant is -32768");
    is(System::Int16::MaxValue, 32767, "MaxValue constant is 32767");
}

# Test new() - Happy path
sub test_new_happy {
    my $int16 = System::Int16->new(12345);
    isa_ok($int16, 'System::Int16', "new() creates System::Int16 object");
    is($int16->Value(), 12345, "new(12345) stores correct value");
    
    my $int16_zero = System::Int16->new(0);
    is($int16_zero->Value(), 0, "new(0) works correctly");
    
    my $int16_negative = System::Int16->new(-12345);
    is($int16_negative->Value(), -12345, "new() handles negative numbers");
    
    my $int16_min = System::Int16->new(-32768);
    is($int16_min->Value(), -32768, "new() handles minimum value");
    
    my $int16_max = System::Int16->new(32767);
    is($int16_max->Value(), 32767, "new() handles maximum value");
    
    my $int16_default = System::Int16->new();
    is($int16_default->Value(), 0, "new() with no args defaults to 0");
    
    my $int16_undef = System::Int16->new(undef);
    is($int16_undef->Value(), 0, "new(undef) defaults to 0");
    
    # Test truncation of floating point
    my $int16_float = System::Int16->new(123.7);
    is($int16_float->Value(), 123, "new() truncates floating point input");
}

# Test new() - Exception handling
sub test_new_exceptions {
    eval {
        System::Int16->new(-32769);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for value < -32768");
    
    eval {
        System::Int16->new(32768);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for value > 32767");
    
    eval {
        System::Int16->new(100000);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for large positive value");
}

# Test Value() method - Exception handling
sub test_value_exceptions {
    eval {
        System::Int16::Value(undef);
    };
    ok($@ =~ /NullReferenceException/, "Value() throws NullReferenceException on undef");
}

# Test Parse() - Happy path
sub test_parse_happy {
    my $int16 = System::Int16->Parse("12345");
    isa_ok($int16, 'System::Int16', "Parse() returns System::Int16 object");
    is($int16->Value(), 12345, "Parse('12345') returns correct value");
    
    my $int16_zero = System::Int16->Parse("0");
    is($int16_zero->Value(), 0, "Parse('0') returns 0");
    
    my $int16_negative = System::Int16->Parse("-12345");
    is($int16_negative->Value(), -12345, "Parse() handles negative numbers");
    
    my $int16_min = System::Int16->Parse("-32768");
    is($int16_min->Value(), -32768, "Parse() handles minimum value");
    
    my $int16_max = System::Int16->Parse("32767");
    is($int16_max->Value(), 32767, "Parse() handles maximum value");
    
    my $int16_ws = System::Int16->Parse("  123  ");
    is($int16_ws->Value(), 123, "Parse() handles whitespace");
    
    my $int16_pos = System::Int16->Parse("+123");
    is($int16_pos->Value(), 123, "Parse() handles positive sign");
}

# Test Parse() - Exception handling
sub test_parse_exceptions {
    eval {
        System::Int16->Parse(undef);
    };
    ok($@ =~ /ArgumentNullException/, "Parse() throws ArgumentNullException for undef");
    
    eval {
        System::Int16->Parse("32768");
    };
    ok($@ =~ /OverflowException/, "Parse() throws OverflowException for value > 32767");
    
    eval {
        System::Int16->Parse("-32769");
    };
    ok($@ =~ /OverflowException/, "Parse() throws OverflowException for value < -32768");
    
    eval {
        System::Int16->Parse("abc");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for non-numeric string");
    
    eval {
        System::Int16->Parse("12.5");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for decimal number");
    
    eval {
        System::Int16->Parse("");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for empty string");
}

# Test TryParse() - Happy path
sub test_tryparse_happy {
    my $result;
    my $success = System::Int16->TryParse("12345", \$result);
    ok($success, "TryParse() returns true for valid input");
    isa_ok($result, 'System::Int16', "TryParse() sets result to System::Int16 object");
    is($result->Value(), 12345, "TryParse() sets correct value");
    
    my $result2;
    my $success2 = System::Int16->TryParse("-32768", \$result2);
    ok($success2, "TryParse() returns true for minimum value");
    is($result2->Value(), -32768, "TryParse() handles minimum value");
}

# Test TryParse() - Failure cases
sub test_tryparse_failure {
    my $result;
    my $success = System::Int16->TryParse("32768", \$result);
    ok(!$success, "TryParse() returns false for overflow value");
    
    my $result2;
    my $success2 = System::Int16->TryParse("abc", \$result2);
    ok(!$success2, "TryParse() returns false for invalid string");
    
    my $result3;
    my $success3 = System::Int16->TryParse("-32769", \$result3);
    ok(!$success3, "TryParse() returns false for underflow value");
}

# Test TryParse() - Exception handling
sub test_tryparse_exceptions {
    eval {
        System::Int16->TryParse("123", undef);
    };
    ok($@ =~ /ArgumentNullException/, "TryParse() throws ArgumentNullException for undef result reference");
}

# Test ToString() - Happy path
sub test_tostring_happy {
    my $int16 = System::Int16->new(12345);
    is($int16->ToString(), "12345", "ToString() returns string representation");
    
    my $int16_zero = System::Int16->new(0);
    is($int16_zero->ToString(), "0", "ToString() handles zero");
    
    my $int16_negative = System::Int16->new(-12345);
    is($int16_negative->ToString(), "-12345", "ToString() handles negative numbers");
    
    # Test with format specifiers
    is($int16->ToString("G"), "12345", "ToString('G') works");
    is($int16->ToString(""), "12345", "ToString('') works");
    
    my $int16_hex = System::Int16->new(255);
    is($int16_hex->ToString("X"), "00FF", "ToString('X') returns uppercase hex");
    is($int16_hex->ToString("x"), "00ff", "ToString('x') returns lowercase hex");
    
    my $int16_dec = System::Int16->new(5);
    is($int16_dec->ToString("D5"), "00005", "ToString('D5') pads with zeros");
    
    my $int16_hex2 = System::Int16->new(10);
    is($int16_hex2->ToString("X6"), "00000A", "ToString('X6') pads hex with zeros");
    is($int16_hex2->ToString("x2"), "0a", "ToString('x2') works with lowercase");
    
    # Test negative number hex representation (two's complement)
    my $int16_neg = System::Int16->new(-1);
    is($int16_neg->ToString("X"), "FFFF", "ToString('X') shows two's complement for negative numbers");
}

# Test ToString() - Exception handling
sub test_tostring_exceptions {
    eval {
        System::Int16::ToString(undef);
    };
    ok($@ =~ /NullReferenceException/, "ToString() throws NullReferenceException on undef");
    
    my $int16 = System::Int16->new(123);
    eval {
        $int16->ToString("Z");
    };
    ok($@ =~ /FormatException/, "ToString() throws FormatException for invalid format");
}

# Test CompareTo() - Happy path
sub test_compareto_happy {
    my $int16_1 = System::Int16->new(100);
    my $int16_2 = System::Int16->new(200);
    my $int16_3 = System::Int16->new(100);
    
    ok($int16_1->CompareTo($int16_2) < 0, "CompareTo() returns negative for smaller value");
    ok($int16_2->CompareTo($int16_1) > 0, "CompareTo() returns positive for larger value");
    is($int16_1->CompareTo($int16_3), 0, "CompareTo() returns zero for equal values");
    
    # Test with negative numbers
    my $int16_neg1 = System::Int16->new(-100);
    my $int16_neg2 = System::Int16->new(-50);
    ok($int16_neg1->CompareTo($int16_neg2) < 0, "CompareTo() handles negative number ordering");
}

# Test CompareTo() - Exception handling
sub test_compareto_exceptions {
    my $int16 = System::Int16->new(100);
    
    eval {
        System::Int16::CompareTo(undef, $int16);
    };
    ok($@ =~ /NullReferenceException/, "CompareTo() throws NullReferenceException on undef this");
    
    eval {
        $int16->CompareTo(undef);
    };
    ok($@ =~ /ArgumentNullException/, "CompareTo() throws ArgumentNullException for undef argument");
    
    eval {
        $int16->CompareTo("not_an_int16");
    };
    ok($@ =~ /ArgumentException/, "CompareTo() throws ArgumentException for wrong type");
}

# Test Equals() - Happy path
sub test_equals_happy {
    my $int16_1 = System::Int16->new(12345);
    my $int16_2 = System::Int16->new(12345);
    my $int16_3 = System::Int16->new(12346);
    
    ok($int16_1->Equals($int16_2), "Equals() returns true for equal values");
    ok(!$int16_1->Equals($int16_3), "Equals() returns false for different values");
    ok(!$int16_1->Equals(undef), "Equals() returns false for undef");
    ok(!$int16_1->Equals("not_an_int16"), "Equals() returns false for wrong type");
}

# Test Equals() - Exception handling
sub test_equals_exceptions {
    eval {
        System::Int16::Equals(undef, System::Int16->new(123));
    };
    ok($@ =~ /NullReferenceException/, "Equals() throws NullReferenceException on undef this");
}

# Test GetHashCode() - Happy path
sub test_gethashcode_happy {
    my $int16 = System::Int16->new(12345);
    my $hash = $int16->GetHashCode();
    is($hash, 12345, "GetHashCode() returns the int16 value as hash");
    
    my $int16_zero = System::Int16->new(0);
    is($int16_zero->GetHashCode(), 0, "GetHashCode() returns 0 for zero value");
    
    my $int16_negative = System::Int16->new(-12345);
    is($int16_negative->GetHashCode(), -12345, "GetHashCode() handles negative values");
}

# Test GetHashCode() - Exception handling
sub test_gethashcode_exceptions {
    eval {
        System::Int16::GetHashCode(undef);
    };
    ok($@ =~ /NullReferenceException/, "GetHashCode() throws NullReferenceException on undef");
}

# Test arithmetic operations - Add
sub test_add_operations {
    my $result = System::Int16->Add(100, 50);
    isa_ok($result, 'System::Int16', "Add() returns System::Int16 object");
    is($result->Value(), 150, "Add(100, 50) returns 150");
    
    my $int16_1 = System::Int16->new(1000);
    my $int16_2 = System::Int16->new(500);
    my $result2 = System::Int16->Add($int16_1, $int16_2);
    is($result2->Value(), 1500, "Add() works with System::Int16 objects");
    
    # Test with negative numbers
    my $result3 = System::Int16->Add(-100, 50);
    is($result3->Value(), -50, "Add() handles negative numbers");
}

# Test Add() - Exception handling
sub test_add_exceptions {
    eval {
        System::Int16->Add(undef, 50);
    };
    ok($@ =~ /ArgumentNullException/, "Add() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Int16->Add(100, undef);
    };
    ok($@ =~ /ArgumentNullException/, "Add() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Int16->Add(30000, 10000);
    };
    ok($@ =~ /OverflowException/, "Add() throws OverflowException for result > 32767");
    
    eval {
        System::Int16->Add(-30000, -10000);
    };
    ok($@ =~ /OverflowException/, "Add() throws OverflowException for result < -32768");
}

# Test other arithmetic operations
sub test_other_arithmetic {
    # Test Subtract
    my $sub_result = System::Int16->Subtract(1000, 300);
    is($sub_result->Value(), 700, "Subtract() works correctly");
    
    # Test Multiply
    my $mul_result = System::Int16->Multiply(100, 3);
    is($mul_result->Value(), 300, "Multiply() works correctly");
    
    # Test Divide
    my $div_result = System::Int16->Divide(1000, 10);
    is($div_result->Value(), 100, "Divide() works correctly");
    
    # Test integer division
    my $div_result2 = System::Int16->Divide(10, 3);
    is($div_result2->Value(), 3, "Divide() performs integer division");
}

# Test arithmetic exception handling
sub test_arithmetic_exceptions {
    eval {
        System::Int16->Divide(100, 0);
    };
    ok($@ =~ /DivideByZeroException/, "Divide() throws DivideByZeroException for division by zero");
    
    eval {
        System::Int16->Subtract(-30000, 10000);
    };
    ok($@ =~ /OverflowException/, "Subtract() throws OverflowException for underflow");
    
    eval {
        System::Int16->Multiply(1000, 100);
    };
    ok($@ =~ /OverflowException/, "Multiply() throws OverflowException for overflow");
}

# Test bitwise operations
sub test_bitwise_operations {
    # Test BitwiseAnd
    my $result1 = System::Int16->BitwiseAnd(15, 7);  # 1111 & 0111 = 0111 = 7
    is($result1->Value(), 7, "BitwiseAnd(15, 7) returns 7");
    
    # Test BitwiseOr
    my $result2 = System::Int16->BitwiseOr(8, 4);   # 1000 | 0100 = 1100 = 12
    is($result2->Value(), 12, "BitwiseOr(8, 4) returns 12");
    
    # Test BitwiseXor
    my $result3 = System::Int16->BitwiseXor(15, 7); # 1111 ^ 0111 = 1000 = 8
    is($result3->Value(), 8, "BitwiseXor(15, 7) returns 8");
    
    # Test BitwiseNot
    my $result4 = System::Int16->BitwiseNot(0);     # ~0 = -1 (two's complement)
    is($result4->Value(), -1, "BitwiseNot(0) returns -1");
}

# Test shift operations
sub test_shift_operations {
    # Test LeftShift
    my $result1 = System::Int16->LeftShift(5, 2);   # 5 << 2 = 20
    is($result1->Value(), 20, "LeftShift(5, 2) returns 20");
    
    # Test RightShift
    my $result2 = System::Int16->RightShift(20, 2); # 20 >> 2 = 5
    is($result2->Value(), 5, "RightShift(20, 2) returns 5");
    
    # Test shift with negative numbers
    my $result3 = System::Int16->RightShift(-8, 2); # -8 >> 2 = -2 (arithmetic shift)
    is($result3->Value(), -2, "RightShift handles negative numbers with arithmetic shift");
}

# Test edge cases
sub test_edge_cases {
    # Test boundary values
    my $min_int16 = System::Int16->new(-32768);
    is($min_int16->Value(), -32768, "Minimum value works");
    
    my $max_int16 = System::Int16->new(32767);
    is($max_int16->Value(), 32767, "Maximum value works");
    
    # Test operations near boundaries
    my $near_max = System::Int16->new(32766);
    my $result = System::Int16->Add($near_max, 1);
    is($result->Value(), 32767, "Operations near boundary work");
}

# Run all tests
sub run_tests {
    test_constants();
    test_new_happy();
    test_new_exceptions();
    test_value_exceptions();
    test_parse_happy();
    test_parse_exceptions();
    test_tryparse_happy();
    test_tryparse_failure();
    test_tryparse_exceptions();
    test_tostring_happy();
    test_tostring_exceptions();
    test_compareto_happy();
    test_compareto_exceptions();
    test_equals_happy();
    test_equals_exceptions();
    test_gethashcode_happy();
    test_gethashcode_exceptions();
    test_add_operations();
    test_add_exceptions();
    test_other_arithmetic();
    test_arithmetic_exceptions();
    test_bitwise_operations();
    test_shift_operations();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();