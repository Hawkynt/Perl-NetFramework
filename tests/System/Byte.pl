#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';

# Import required modules
use System::Byte;
use System::Exceptions;

# Test constants
sub test_constants {
    is(System::Byte::MinValue, 0, "MinValue constant is 0");
    is(System::Byte::MaxValue, 255, "MaxValue constant is 255");
}

# Test new() - Happy path
sub test_new_happy {
    my $byte = System::Byte->new(123);
    isa_ok($byte, 'System::Byte', "new() creates System::Byte object");
    is($byte->Value(), 123, "new(123) stores correct value");
    
    my $byte_zero = System::Byte->new(0);
    is($byte_zero->Value(), 0, "new(0) works correctly");
    
    my $byte_max = System::Byte->new(255);
    is($byte_max->Value(), 255, "new(255) works correctly");
    
    my $byte_default = System::Byte->new();
    is($byte_default->Value(), 0, "new() with no args defaults to 0");
    
    my $byte_undef = System::Byte->new(undef);
    is($byte_undef->Value(), 0, "new(undef) defaults to 0");
}

# Test new() - Exception handling
sub test_new_exceptions {
    eval {
        System::Byte->new(-1);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for negative value");
    
    eval {
        System::Byte->new(256);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for value > 255");
    
    eval {
        System::Byte->new(1000);
    };
    ok($@ =~ /OverflowException/, "new() throws OverflowException for large value");
}

# Test Value() method - Exception handling
sub test_value_exceptions {
    eval {
        System::Byte::Value(undef);
    };
    ok($@ =~ /NullReferenceException/, "Value() throws NullReferenceException on undef");
}

# Test Parse() - Happy path
sub test_parse_happy {
    my $byte = System::Byte->Parse("123");
    isa_ok($byte, 'System::Byte', "Parse() returns System::Byte object");
    is($byte->Value(), 123, "Parse('123') returns correct value");
    
    my $byte_zero = System::Byte->Parse("0");
    is($byte_zero->Value(), 0, "Parse('0') returns 0");
    
    my $byte_max = System::Byte->Parse("255");
    is($byte_max->Value(), 255, "Parse('255') returns 255");
    
    my $byte_ws = System::Byte->Parse("  42  ");
    is($byte_ws->Value(), 42, "Parse() handles whitespace");
    
    my $byte_pos = System::Byte->Parse("+123");
    is($byte_pos->Value(), 123, "Parse() handles positive sign");
}

# Test Parse() - Exception handling
sub test_parse_exceptions {
    eval {
        System::Byte->Parse(undef);
    };
    ok($@ =~ /ArgumentNullException/, "Parse() throws ArgumentNullException for undef");
    
    eval {
        System::Byte->Parse("256");
    };
    ok($@ =~ /OverflowException/, "Parse() throws OverflowException for value > 255");
    
    eval {
        System::Byte->Parse("-1");
    };
    ok($@ =~ /OverflowException/, "Parse() throws OverflowException for negative value");
    
    eval {
        System::Byte->Parse("abc");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for non-numeric string");
    
    eval {
        System::Byte->Parse("12.5");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for decimal number");
    
    eval {
        System::Byte->Parse("");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for empty string");
}

# Test TryParse() - Happy path
sub test_tryparse_happy {
    my $result;
    my $success = System::Byte->TryParse("123", \$result);
    ok($success, "TryParse() returns true for valid input");
    isa_ok($result, 'System::Byte', "TryParse() sets result to System::Byte object");
    is($result->Value(), 123, "TryParse() sets correct value");
    
    my $result2;
    my $success2 = System::Byte->TryParse("255", \$result2);
    ok($success2, "TryParse() returns true for max value");
    is($result2->Value(), 255, "TryParse() handles max value");
}

# Test TryParse() - Failure cases
sub test_tryparse_failure {
    my $result;
    my $success = System::Byte->TryParse("256", \$result);
    ok(!$success, "TryParse() returns false for overflow value");
    
    my $result2;
    my $success2 = System::Byte->TryParse("abc", \$result2);
    ok(!$success2, "TryParse() returns false for invalid string");
    
    my $result3;
    my $success3 = System::Byte->TryParse("-1", \$result3);
    ok(!$success3, "TryParse() returns false for negative value");
}

# Test TryParse() - Exception handling
sub test_tryparse_exceptions {
    eval {
        System::Byte->TryParse("123", undef);
    };
    ok($@ =~ /ArgumentNullException/, "TryParse() throws ArgumentNullException for undef result reference");
}

# Test ToString() - Happy path
sub test_tostring_happy {
    my $byte = System::Byte->new(123);
    is($byte->ToString(), "123", "ToString() returns string representation");
    
    my $byte_zero = System::Byte->new(0);
    is($byte_zero->ToString(), "0", "ToString() handles zero");
    
    my $byte_max = System::Byte->new(255);
    is($byte_max->ToString(), "255", "ToString() handles max value");
    
    # Test with format specifiers
    is($byte->ToString("G"), "123", "ToString('G') works");
    is($byte->ToString(""), "123", "ToString('') works");
    
    my $byte_hex = System::Byte->new(255);
    is($byte_hex->ToString("X"), "FF", "ToString('X') returns uppercase hex");
    is($byte_hex->ToString("x"), "ff", "ToString('x') returns lowercase hex");
    
    my $byte_dec = System::Byte->new(5);
    is($byte_dec->ToString("D3"), "005", "ToString('D3') pads with zeros");
    
    my $byte_hex2 = System::Byte->new(10);
    is($byte_hex2->ToString("X4"), "000A", "ToString('X4') pads hex with zeros");
    is($byte_hex2->ToString("x2"), "0a", "ToString('x2') works with lowercase");
}

# Test ToString() - Exception handling
sub test_tostring_exceptions {
    eval {
        System::Byte::ToString(undef);
    };
    ok($@ =~ /NullReferenceException/, "ToString() throws NullReferenceException on undef");
    
    my $byte = System::Byte->new(123);
    eval {
        $byte->ToString("Z");
    };
    ok($@ =~ /FormatException/, "ToString() throws FormatException for invalid format");
}

# Test CompareTo() - Happy path
sub test_compareto_happy {
    my $byte1 = System::Byte->new(100);
    my $byte2 = System::Byte->new(200);
    my $byte3 = System::Byte->new(100);
    
    ok($byte1->CompareTo($byte2) < 0, "CompareTo() returns negative for smaller value");
    ok($byte2->CompareTo($byte1) > 0, "CompareTo() returns positive for larger value");
    is($byte1->CompareTo($byte3), 0, "CompareTo() returns zero for equal values");
}

# Test CompareTo() - Exception handling
sub test_compareto_exceptions {
    my $byte = System::Byte->new(100);
    
    eval {
        System::Byte::CompareTo(undef, $byte);
    };
    ok($@ =~ /NullReferenceException/, "CompareTo() throws NullReferenceException on undef this");
    
    eval {
        $byte->CompareTo(undef);
    };
    ok($@ =~ /ArgumentNullException/, "CompareTo() throws ArgumentNullException for undef argument");
    
    eval {
        $byte->CompareTo("not_a_byte");
    };
    ok($@ =~ /ArgumentException/, "CompareTo() throws ArgumentException for wrong type");
}

# Test Equals() - Happy path
sub test_equals_happy {
    my $byte1 = System::Byte->new(123);
    my $byte2 = System::Byte->new(123);
    my $byte3 = System::Byte->new(124);
    
    ok($byte1->Equals($byte2), "Equals() returns true for equal values");
    ok(!$byte1->Equals($byte3), "Equals() returns false for different values");
    ok(!$byte1->Equals(undef), "Equals() returns false for undef");
    ok(!$byte1->Equals("not_a_byte"), "Equals() returns false for wrong type");
}

# Test Equals() - Exception handling
sub test_equals_exceptions {
    eval {
        System::Byte::Equals(undef, System::Byte->new(123));
    };
    ok($@ =~ /NullReferenceException/, "Equals() throws NullReferenceException on undef this");
}

# Test GetHashCode() - Happy path
sub test_gethashcode_happy {
    my $byte = System::Byte->new(123);
    my $hash = $byte->GetHashCode();
    is($hash, 123, "GetHashCode() returns the byte value as hash");
    
    my $byte_zero = System::Byte->new(0);
    is($byte_zero->GetHashCode(), 0, "GetHashCode() returns 0 for zero value");
}

# Test GetHashCode() - Exception handling
sub test_gethashcode_exceptions {
    eval {
        System::Byte::GetHashCode(undef);
    };
    ok($@ =~ /NullReferenceException/, "GetHashCode() throws NullReferenceException on undef");
}

# Test arithmetic operations - Add
sub test_add_operations {
    my $result = System::Byte->Add(100, 50);
    isa_ok($result, 'System::Byte', "Add() returns System::Byte object");
    is($result->Value(), 150, "Add(100, 50) returns 150");
    
    my $byte1 = System::Byte->new(100);
    my $byte2 = System::Byte->new(50);
    my $result2 = System::Byte->Add($byte1, $byte2);
    is($result2->Value(), 150, "Add() works with System::Byte objects");
    
    my $result3 = System::Byte->Add($byte1, 25);
    is($result3->Value(), 125, "Add() works with mixed types");
}

# Test Add() - Exception handling
sub test_add_exceptions {
    eval {
        System::Byte->Add(undef, 50);
    };
    ok($@ =~ /ArgumentNullException/, "Add() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Byte->Add(100, undef);
    };
    ok($@ =~ /ArgumentNullException/, "Add() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Byte->Add(200, 100);
    };
    ok($@ =~ /OverflowException/, "Add() throws OverflowException for result > 255");
}

# Test Subtract operations
sub test_subtract_operations {
    my $result = System::Byte->Subtract(100, 50);
    isa_ok($result, 'System::Byte', "Subtract() returns System::Byte object");
    is($result->Value(), 50, "Subtract(100, 50) returns 50");
    
    my $byte1 = System::Byte->new(100);
    my $byte2 = System::Byte->new(25);
    my $result2 = System::Byte->Subtract($byte1, $byte2);
    is($result2->Value(), 75, "Subtract() works with System::Byte objects");
}

# Test Subtract() - Exception handling
sub test_subtract_exceptions {
    eval {
        System::Byte->Subtract(undef, 50);
    };
    ok($@ =~ /ArgumentNullException/, "Subtract() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Byte->Subtract(100, undef);
    };
    ok($@ =~ /ArgumentNullException/, "Subtract() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Byte->Subtract(50, 100);
    };
    ok($@ =~ /OverflowException/, "Subtract() throws OverflowException for negative result");
}

# Test Multiply operations
sub test_multiply_operations {
    my $result = System::Byte->Multiply(10, 5);
    isa_ok($result, 'System::Byte', "Multiply() returns System::Byte object");
    is($result->Value(), 50, "Multiply(10, 5) returns 50");
    
    my $byte1 = System::Byte->new(12);
    my $byte2 = System::Byte->new(3);
    my $result2 = System::Byte->Multiply($byte1, $byte2);
    is($result2->Value(), 36, "Multiply() works with System::Byte objects");
}

# Test Multiply() - Exception handling
sub test_multiply_exceptions {
    eval {
        System::Byte->Multiply(undef, 5);
    };
    ok($@ =~ /ArgumentNullException/, "Multiply() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Byte->Multiply(10, undef);
    };
    ok($@ =~ /ArgumentNullException/, "Multiply() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Byte->Multiply(200, 5);
    };
    ok($@ =~ /OverflowException/, "Multiply() throws OverflowException for result > 255");
}

# Test Divide operations
sub test_divide_operations {
    my $result = System::Byte->Divide(100, 5);
    isa_ok($result, 'System::Byte', "Divide() returns System::Byte object");
    is($result->Value(), 20, "Divide(100, 5) returns 20");
    
    my $byte1 = System::Byte->new(99);
    my $byte2 = System::Byte->new(3);
    my $result2 = System::Byte->Divide($byte1, $byte2);
    is($result2->Value(), 33, "Divide() works with System::Byte objects");
    
    # Test integer division
    my $result3 = System::Byte->Divide(10, 3);
    is($result3->Value(), 3, "Divide() performs integer division");
}

# Test Divide() - Exception handling
sub test_divide_exceptions {
    eval {
        System::Byte->Divide(undef, 5);
    };
    ok($@ =~ /ArgumentNullException/, "Divide() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Byte->Divide(100, undef);
    };
    ok($@ =~ /ArgumentNullException/, "Divide() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Byte->Divide(100, 0);
    };
    ok($@ =~ /DivideByZeroException/, "Divide() throws DivideByZeroException for division by zero");
}

# Test bitwise operations
sub test_bitwise_operations {
    # Test BitwiseAnd
    my $result1 = System::Byte->BitwiseAnd(15, 7);  # 1111 & 0111 = 0111 = 7
    is($result1->Value(), 7, "BitwiseAnd(15, 7) returns 7");
    
    # Test BitwiseOr
    my $result2 = System::Byte->BitwiseOr(8, 4);   # 1000 | 0100 = 1100 = 12
    is($result2->Value(), 12, "BitwiseOr(8, 4) returns 12");
    
    # Test BitwiseXor
    my $result3 = System::Byte->BitwiseXor(15, 7); # 1111 ^ 0111 = 1000 = 8
    is($result3->Value(), 8, "BitwiseXor(15, 7) returns 8");
    
    # Test BitwiseNot
    my $result4 = System::Byte->BitwiseNot(0);     # ~00000000 = 11111111 = 255
    is($result4->Value(), 255, "BitwiseNot(0) returns 255");
    
    my $result5 = System::Byte->BitwiseNot(255);   # ~11111111 = 00000000 = 0
    is($result5->Value(), 0, "BitwiseNot(255) returns 0");
}

# Test bitwise operations with System::Byte objects
sub test_bitwise_with_objects {
    my $byte1 = System::Byte->new(15);
    my $byte2 = System::Byte->new(7);
    
    my $result = System::Byte->BitwiseAnd($byte1, $byte2);
    is($result->Value(), 7, "BitwiseAnd works with System::Byte objects");
    
    my $result2 = System::Byte->BitwiseOr($byte1, $byte2);
    is($result2->Value(), 15, "BitwiseOr works with System::Byte objects");
}

# Test bitwise operations - Exception handling
sub test_bitwise_exceptions {
    eval {
        System::Byte->BitwiseAnd(undef, 7);
    };
    ok($@ =~ /ArgumentNullException/, "BitwiseAnd() throws ArgumentNullException for undef first argument");
    
    eval {
        System::Byte->BitwiseOr(15, undef);
    };
    ok($@ =~ /ArgumentNullException/, "BitwiseOr() throws ArgumentNullException for undef second argument");
    
    eval {
        System::Byte->BitwiseNot(undef);
    };
    ok($@ =~ /ArgumentNullException/, "BitwiseNot() throws ArgumentNullException for undef argument");
}

# Test edge cases
sub test_edge_cases {
    # Test with floating point input that gets truncated
    my $byte = System::Byte->new(123.7);
    is($byte->Value(), 123, "new() truncates floating point input");
    
    # Test boundary values
    my $min_byte = System::Byte->new(0);
    is($min_byte->Value(), 0, "Minimum value works");
    
    my $max_byte = System::Byte->new(255);
    is($max_byte->Value(), 255, "Maximum value works");
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
    test_subtract_operations();
    test_subtract_exceptions();
    test_multiply_operations();
    test_multiply_exceptions();
    test_divide_operations();
    test_divide_exceptions();
    test_bitwise_operations();
    test_bitwise_with_objects();
    test_bitwise_exceptions();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();