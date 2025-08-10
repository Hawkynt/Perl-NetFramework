#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';
use POSIX qw(isnan isinf);

# Import required modules
use System::Double;
use System::Exceptions;

# Test constants
sub test_constants {
    ok(System::Double::MinValue < 0, "MinValue is negative");
    ok(System::Double::MaxValue > 0, "MaxValue is positive");
    ok(System::Double::Epsilon > 0, "Epsilon is positive small number");
    ok(defined(System::Double::PositiveInfinity), "PositiveInfinity is defined");
    ok(defined(System::Double::NegativeInfinity), "NegativeInfinity is defined");
    ok(defined(System::Double::NaN), "NaN is defined");
}

# Test new() - Happy path
sub test_new_happy {
    my $double = System::Double->new(123.456);
    isa_ok($double, 'System::Double', "new() creates System::Double object");
    is($double->Value(), 123.456, "new(123.456) stores correct value");
    
    my $double_zero = System::Double->new(0.0);
    is($double_zero->Value(), 0.0, "new(0.0) works correctly");
    
    my $double_negative = System::Double->new(-456.789);
    is($double_negative->Value(), -456.789, "new() handles negative numbers");
    
    my $double_default = System::Double->new();
    is($double_default->Value(), 0.0, "new() with no args defaults to 0.0");
    
    my $double_undef = System::Double->new(undef);
    is($double_undef->Value(), 0.0, "new(undef) defaults to 0.0");
    
    # Test special values
    my $double_inf = System::Double->new('inf');
    ok(isinf($double_inf->Value()), "new('inf') creates infinity");
    
    my $double_ninf = System::Double->new('-inf');
    ok(isinf($double_ninf->Value()) && $double_ninf->Value() < 0, "new('-inf') creates negative infinity");
    
    my $double_nan = System::Double->new('nan');
    ok(isnan($double_nan->Value()), "new('nan') creates NaN");
}

# Test Parse() - Happy path
sub test_parse_happy {
    my $double = System::Double->Parse("123.456");
    isa_ok($double, 'System::Double', "Parse() returns System::Double object");
    is($double->Value(), 123.456, "Parse('123.456') returns correct value");
    
    my $double_int = System::Double->Parse("123");
    is($double_int->Value(), 123.0, "Parse('123') handles integer strings");
    
    my $double_sci = System::Double->Parse("1.23e-4");
    is($double_sci->Value(), 1.23e-4, "Parse() handles scientific notation");
    
    my $double_ws = System::Double->Parse("  3.14  ");
    is($double_ws->Value(), 3.14, "Parse() handles whitespace");
    
    # Test special values
    my $double_inf = System::Double->Parse("Infinity");
    ok(isinf($double_inf->Value()), "Parse('Infinity') creates infinity");
    
    my $double_ninf = System::Double->Parse("-Infinity");
    ok(isinf($double_ninf->Value()) && $double_ninf->Value() < 0, "Parse('-Infinity') creates negative infinity");
    
    my $double_nan = System::Double->Parse("NaN");
    ok(isnan($double_nan->Value()), "Parse('NaN') creates NaN");
}

# Test Parse() - Exception handling
sub test_parse_exceptions {
    eval {
        System::Double->Parse(undef);
    };
    ok($@ =~ /ArgumentNullException/, "Parse() throws ArgumentNullException for undef");
    
    eval {
        System::Double->Parse("abc");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for non-numeric string");
    
    eval {
        System::Double->Parse("");
    };
    ok($@ =~ /FormatException/, "Parse() throws FormatException for empty string");
}

# Test TryParse() - Happy path
sub test_tryparse_happy {
    my $result;
    my $success = System::Double->TryParse("123.456", \$result);
    ok($success, "TryParse() returns true for valid input");
    isa_ok($result, 'System::Double', "TryParse() sets result to System::Double object");
    is($result->Value(), 123.456, "TryParse() sets correct value");
    
    my $result2;
    my $success2 = System::Double->TryParse("1.23e10", \$result2);
    ok($success2, "TryParse() handles scientific notation");
    is($result2->Value(), 1.23e10, "TryParse() scientific notation value is correct");
}

# Test TryParse() - Failure cases
sub test_tryparse_failure {
    my $result;
    my $success = System::Double->TryParse("abc", \$result);
    ok(!$success, "TryParse() returns false for invalid string");
    
    my $result2;
    my $success2 = System::Double->TryParse("", \$result2);
    ok(!$success2, "TryParse() returns false for empty string");
}

# Test ToString() - Happy path
sub test_tostring_happy {
    my $double = System::Double->new(123.456);
    like($double->ToString(), qr/123\.456/, "ToString() returns string representation");
    
    my $double_zero = System::Double->new(0.0);
    is($double_zero->ToString(), "0", "ToString() handles zero");
    
    # Test special values
    my $double_inf = System::Double->new('inf');
    is($double_inf->ToString(), "Infinity", "ToString() handles positive infinity");
    
    my $double_ninf = System::Double->new('-inf');
    is($double_ninf->ToString(), "-Infinity", "ToString() handles negative infinity");
    
    my $double_nan = System::Double->new('nan');
    is($double_nan->ToString(), "NaN", "ToString() handles NaN");
    
    # Test format specifiers
    my $double_format = System::Double->new(3.14159);
    is($double_format->ToString("F2"), "3.14", "ToString('F2') formats to 2 decimal places");
    like($double_format->ToString("E3"), qr/3\.142[eE]/i, "ToString('E3') uses scientific notation");
    like($double_format->ToString("e2"), qr/3\.14[eE]/i, "ToString('e2') uses lowercase scientific notation");
}

# Test ToString() - Exception handling
sub test_tostring_exceptions {
    my $double = System::Double->new(123.456);
    eval {
        $double->ToString("Z");
    };
    ok($@ =~ /FormatException/, "ToString() throws FormatException for invalid format");
}

# Test CompareTo() - Happy path
sub test_compareto_happy {
    my $double1 = System::Double->new(1.5);
    my $double2 = System::Double->new(2.5);
    my $double3 = System::Double->new(1.5);
    
    ok($double1->CompareTo($double2) < 0, "CompareTo() returns negative for smaller value");
    ok($double2->CompareTo($double1) > 0, "CompareTo() returns positive for larger value");
    is($double1->CompareTo($double3), 0, "CompareTo() returns zero for equal values");
    
    # Test NaN comparisons
    my $double_nan1 = System::Double->new('nan');
    my $double_nan2 = System::Double->new('nan');
    is($double_nan1->CompareTo($double_nan2), 0, "CompareTo() returns 0 for NaN vs NaN");
    ok($double1->CompareTo($double_nan1) > 0, "CompareTo() returns positive for non-NaN vs NaN");
    ok($double_nan1->CompareTo($double1) < 0, "CompareTo() returns negative for NaN vs non-NaN");
}

# Test CompareTo() - Exception handling
sub test_compareto_exceptions {
    my $double = System::Double->new(1.5);
    
    eval {
        $double->CompareTo(undef);
    };
    ok($@ =~ /ArgumentNullException/, "CompareTo() throws ArgumentNullException for undef argument");
    
    eval {
        $double->CompareTo("not_a_double");
    };
    ok($@ =~ /ArgumentException/, "CompareTo() throws ArgumentException for wrong type");
}

# Test Equals() - Happy path
sub test_equals_happy {
    my $double1 = System::Double->new(123.456);
    my $double2 = System::Double->new(123.456);
    my $double3 = System::Double->new(123.457);
    
    ok($double1->Equals($double2), "Equals() returns true for equal values");
    ok(!$double1->Equals($double3), "Equals() returns false for different values");
    ok(!$double1->Equals(undef), "Equals() returns false for undef");
    ok(!$double1->Equals("not_a_double"), "Equals() returns false for wrong type");
    
    # Test NaN equals behavior
    my $double_nan1 = System::Double->new('nan');
    my $double_nan2 = System::Double->new('nan');
    ok(!$double_nan1->Equals($double_nan2), "Equals() returns false for NaN vs NaN (NaN != NaN)");
    ok(!$double_nan1->Equals($double1), "Equals() returns false for NaN vs number");
}

# Test GetHashCode() - Happy path
sub test_gethashcode_happy {
    my $double = System::Double->new(123.456);
    my $hash = $double->GetHashCode();
    ok(defined($hash), "GetHashCode() returns defined value");
    
    my $double_zero = System::Double->new(0.0);
    is($double_zero->GetHashCode(), 0, "GetHashCode() returns 0 for zero");
    
    my $double_nan = System::Double->new('nan');
    is($double_nan->GetHashCode(), 0, "GetHashCode() returns 0 for NaN");
}

# Test special value tests - IsNaN
sub test_isnan {
    ok(System::Double->IsNaN('nan'), "IsNaN() returns true for NaN value");
    ok(!System::Double->IsNaN(123.456), "IsNaN() returns false for normal number");
    ok(!System::Double->IsNaN('inf'), "IsNaN() returns false for infinity");
    
    # Test with System::Double objects
    my $double_nan = System::Double->new('nan');
    ok(System::Double->IsNaN($double_nan), "IsNaN() works with System::Double NaN object");
    
    my $double_normal = System::Double->new(123.456);
    ok(!System::Double->IsNaN($double_normal), "IsNaN() works with System::Double normal object");
}

# Test special value tests - IsInfinity
sub test_isinf {
    ok(System::Double->IsInfinity('inf'), "IsInfinity() returns true for positive infinity");
    ok(System::Double->IsInfinity('-inf'), "IsInfinity() returns true for negative infinity");
    ok(!System::Double->IsInfinity(123.456), "IsInfinity() returns false for normal number");
    ok(!System::Double->IsInfinity('nan'), "IsInfinity() returns false for NaN");
    
    # Test with System::Double objects
    my $double_inf = System::Double->new('inf');
    ok(System::Double->IsInfinity($double_inf), "IsInfinity() works with System::Double infinity object");
}

# Test special value tests - IsPositiveInfinity
sub test_isposinf {
    ok(System::Double->IsPositiveInfinity('inf'), "IsPositiveInfinity() returns true for positive infinity");
    ok(!System::Double->IsPositiveInfinity('-inf'), "IsPositiveInfinity() returns false for negative infinity");
    ok(!System::Double->IsPositiveInfinity(123.456), "IsPositiveInfinity() returns false for normal number");
}

# Test special value tests - IsNegativeInfinity
sub test_isneginf {
    ok(!System::Double->IsNegativeInfinity('inf'), "IsNegativeInfinity() returns false for positive infinity");
    ok(System::Double->IsNegativeInfinity('-inf'), "IsNegativeInfinity() returns true for negative infinity");
    ok(!System::Double->IsNegativeInfinity(123.456), "IsNegativeInfinity() returns false for normal number");
}

# Test special value tests - IsFinite
sub test_isfinite {
    ok(System::Double->IsFinite(123.456), "IsFinite() returns true for normal number");
    ok(!System::Double->IsFinite('inf'), "IsFinite() returns false for positive infinity");
    ok(!System::Double->IsFinite('-inf'), "IsFinite() returns false for negative infinity");
    ok(!System::Double->IsFinite('nan'), "IsFinite() returns false for NaN");
}

# Test arithmetic operations - Add
sub test_add_operations {
    my $result = System::Double->Add(1.5, 2.5);
    isa_ok($result, 'System::Double', "Add() returns System::Double object");
    is($result->Value(), 4.0, "Add(1.5, 2.5) returns 4.0");
    
    my $double1 = System::Double->new(3.14);
    my $double2 = System::Double->new(2.86);
    my $result2 = System::Double->Add($double1, $double2);
    is($result2->Value(), 6.0, "Add() works with System::Double objects");
    
    my $result3 = System::Double->Add($double1, 1.86);
    is($result3->Value(), 5.0, "Add() works with mixed types");
}

# Test Subtract operations
sub test_subtract_operations {
    my $result = System::Double->Subtract(5.5, 2.5);
    isa_ok($result, 'System::Double', "Subtract() returns System::Double object");
    is($result->Value(), 3.0, "Subtract(5.5, 2.5) returns 3.0");
    
    my $double1 = System::Double->new(10.0);
    my $double2 = System::Double->new(3.0);
    my $result2 = System::Double->Subtract($double1, $double2);
    is($result2->Value(), 7.0, "Subtract() works with System::Double objects");
}

# Test Multiply operations
sub test_multiply_operations {
    my $result = System::Double->Multiply(2.5, 4.0);
    isa_ok($result, 'System::Double', "Multiply() returns System::Double object");
    is($result->Value(), 10.0, "Multiply(2.5, 4.0) returns 10.0");
    
    my $double1 = System::Double->new(3.0);
    my $double2 = System::Double->new(7.0);
    my $result2 = System::Double->Multiply($double1, $double2);
    is($result2->Value(), 21.0, "Multiply() works with System::Double objects");
}

# Test Divide operations
sub test_divide_operations {
    my $result = System::Double->Divide(10.0, 2.0);
    isa_ok($result, 'System::Double', "Divide() returns System::Double object");
    is($result->Value(), 5.0, "Divide(10.0, 2.0) returns 5.0");
    
    my $double1 = System::Double->new(15.0);
    my $double2 = System::Double->new(3.0);
    my $result2 = System::Double->Divide($double1, $double2);
    is($result2->Value(), 5.0, "Divide() works with System::Double objects");
    
    # Test divide by zero (should produce infinity)
    my $result3 = System::Double->Divide(1.0, 0.0);
    ok(isinf($result3->Value()), "Divide() by zero produces infinity");
}

# Test math functions
sub test_math_functions {
    # Test Sqrt
    my $sqrt_result = System::Double->Sqrt(9.0);
    is($sqrt_result->Value(), 3.0, "Sqrt(9.0) returns 3.0");
    
    # Test Pow
    my $pow_result = System::Double->Pow(2.0, 3.0);
    is($pow_result->Value(), 8.0, "Pow(2.0, 3.0) returns 8.0");
    
    # Test Abs
    my $abs_result = System::Double->Abs(-5.5);
    is($abs_result->Value(), 5.5, "Abs(-5.5) returns 5.5");
    
    my $abs_result2 = System::Double->Abs(5.5);
    is($abs_result2->Value(), 5.5, "Abs(5.5) returns 5.5");
    
    # Test Floor
    my $floor_result = System::Double->Floor(3.7);
    is($floor_result->Value(), 3.0, "Floor(3.7) returns 3.0");
    
    my $floor_result2 = System::Double->Floor(-3.7);
    is($floor_result2->Value(), -4.0, "Floor(-3.7) returns -4.0");
    
    # Test Ceiling
    my $ceil_result = System::Double->Ceiling(3.2);
    is($ceil_result->Value(), 4.0, "Ceiling(3.2) returns 4.0");
    
    my $ceil_result2 = System::Double->Ceiling(-3.7);
    is($ceil_result2->Value(), -3.0, "Ceiling(-3.7) returns -3.0");
    
    # Test Round
    my $round_result = System::Double->Round(3.7);
    is($round_result->Value(), 4.0, "Round(3.7) returns 4.0");
    
    my $round_result2 = System::Double->Round(3.14159, 2);
    is($round_result2->Value(), 3.14, "Round(3.14159, 2) returns 3.14");
}

# Test math functions with System::Double objects
sub test_math_with_objects {
    my $double = System::Double->new(16.0);
    my $sqrt_result = System::Double->Sqrt($double);
    is($sqrt_result->Value(), 4.0, "Math functions work with System::Double objects");
}

# Test edge cases
sub test_edge_cases {
    # Test very large numbers
    my $large = System::Double->new(1.7976931348623157e+308);
    ok(defined($large->Value()), "Can handle very large numbers");
    
    # Test very small numbers
    my $small = System::Double->new(4.9406564584124654e-324);
    ok(defined($small->Value()), "Can handle very small numbers");
    
    # Test operations with special values
    my $inf = System::Double->new('inf');
    my $result = System::Double->Add($inf, 1.0);
    ok(isinf($result->Value()), "Operations with infinity produce infinity");
    
    my $nan = System::Double->new('nan');
    my $result2 = System::Double->Add($nan, 1.0);
    ok(isnan($result2->Value()), "Operations with NaN produce NaN");
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
    test_tostring_exceptions();
    test_compareto_happy();
    test_compareto_exceptions();
    test_equals_happy();
    test_gethashcode_happy();
    test_isnan();
    test_isinf();
    test_isposinf();
    test_isneginf();
    test_isfinite();
    test_add_operations();
    test_subtract_operations();
    test_multiply_operations();
    test_divide_operations();
    test_math_functions();
    test_math_with_objects();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();