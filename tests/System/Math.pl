#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';
use Test::More;
use System;
use System::Math;

BEGIN {
    use_ok('System::Math');
}

sub test_math_constants {
    # Test mathematical constants
    ok(abs(System::Math::E - 2.71828182845904523536) < 1e-10, 'E constant is correct');
    ok(abs(System::Math::PI - 3.14159265358979323846) < 1e-10, 'PI constant is correct');
    ok(abs(System::Math::Tau - 6.28318530717958647692) < 1e-10, 'Tau constant is correct');
    is(System::Math::Tau, 2 * System::Math::PI, 'Tau equals 2*PI');
}

sub test_basic_arithmetic {
    # Test Abs
    is(Math::Abs(-5), 5, 'Abs of negative number');
    is(Math::Abs(5), 5, 'Abs of positive number');
    is(Math::Abs(0), 0, 'Abs of zero');
    is(Math::Abs(-3.14), 3.14, 'Abs of negative float');
    
    # Test Sign
    is(Math::Sign(-10), -1, 'Sign of negative number');
    is(Math::Sign(10), 1, 'Sign of positive number');
    is(Math::Sign(0), 0, 'Sign of zero');
    is(Math::Sign(-0.001), -1, 'Sign of small negative');
    
    # Test Min/Max
    is(Math::Min(5, 10), 5, 'Min of two numbers');
    is(Math::Max(5, 10), 10, 'Max of two numbers');
    is(Math::Min(-5, -10), -10, 'Min of negative numbers');
    is(Math::Max(-5, -10), -5, 'Max of negative numbers');
}

sub test_power_and_roots {
    # Test Pow
    is(Math::Pow(2, 3), 8, 'Power function basic');
    is(Math::Pow(5, 0), 1, 'Any number to power 0');
    is(Math::Pow(0, 5), 0, 'Zero to any power');
    ok(abs(Math::Pow(2, 0.5) - sqrt(2)) < 1e-10, 'Power with fractional exponent');
    
    # Test Sqrt
    is(Math::Sqrt(4), 2, 'Square root of 4');
    is(Math::Sqrt(0), 0, 'Square root of 0');
    ok(abs(Math::Sqrt(2) - 1.41421356237) < 1e-10, 'Square root of 2');
    
    # Test Exp and Log
    ok(abs(Math::Exp(1) - Math::E) < 1e-10, 'e^1 equals E');
    is(Math::Log(Math::E), 1, 'Natural log of E');
    ok(abs(Math::Log(10, 10) - 1) < 1e-10, 'Log base 10 of 10');
    ok(abs(Math::Log10(100) - 2) < 1e-10, 'Log10 of 100');
    ok(abs(Math::Log2(8) - 3) < 1e-10, 'Log2 of 8');
}

sub test_trigonometry {
    # Test basic trig functions
    ok(abs(Math::Sin(0)) < 1e-10, 'Sin(0) = 0');
    ok(abs(Math::Cos(0) - 1) < 1e-10, 'Cos(0) = 1');
    ok(abs(Math::Tan(0)) < 1e-10, 'Tan(0) = 0');
    
    # Test with PI
    ok(abs(Math::Sin(Math::PI/2) - 1) < 1e-10, 'Sin(π/2) = 1');
    ok(abs(Math::Cos(Math::PI/2)) < 1e-10, 'Cos(π/2) = 0');
    ok(abs(Math::Sin(Math::PI)) < 1e-10, 'Sin(π) = 0');
    ok(abs(Math::Cos(Math::PI) + 1) < 1e-10, 'Cos(π) = -1');
    
    # Test inverse trig functions
    ok(abs(Math::Asin(1) - Math::PI/2) < 1e-10, 'Arcsin(1) = π/2');
    ok(abs(Math::Acos(0) - Math::PI/2) < 1e-10, 'Arccos(0) = π/2');
    ok(abs(Math::Atan(1) - Math::PI/4) < 1e-10, 'Arctan(1) = π/4');
    
    # Test Atan2
    ok(abs(Math::Atan2(1, 1) - Math::PI/4) < 1e-10, 'Atan2(1,1) = π/4');
    ok(abs(Math::Atan2(1, 0) - Math::PI/2) < 1e-10, 'Atan2(1,0) = π/2');
}

sub test_hyperbolic {
    # Test hyperbolic functions
    ok(abs(Math::Sinh(0)) < 1e-10, 'Sinh(0) = 0');
    ok(abs(Math::Cosh(0) - 1) < 1e-10, 'Cosh(0) = 1');
    ok(abs(Math::Tanh(0)) < 1e-10, 'Tanh(0) = 0');
    
    # Test inverse hyperbolic functions
    ok(abs(Math::Asinh(0)) < 1e-10, 'Asinh(0) = 0');
    ok(abs(Math::Acosh(1)) < 1e-10, 'Acosh(1) = 0');
    ok(abs(Math::Atanh(0)) < 1e-10, 'Atanh(0) = 0');
    
    # Test additional hyperbolic functions
    ok(abs(Math::Sech(0) - 1) < 1e-10, 'Sech(0) = 1');
    eval { Math::Csch(0); };
    ok($@, 'Csch(0) throws exception');
    eval { Math::Coth(0); };
    ok($@, 'Coth(0) throws exception');
}

sub test_rounding {
    # Test Floor
    is(Math::Floor(3.7), 3, 'Floor of positive decimal');
    is(Math::Floor(-3.7), -4, 'Floor of negative decimal');
    is(Math::Floor(5), 5, 'Floor of integer');
    
    # Test Ceiling
    is(Math::Ceiling(3.1), 4, 'Ceiling of positive decimal');
    is(Math::Ceiling(-3.1), -3, 'Ceiling of negative decimal');
    is(Math::Ceiling(5), 5, 'Ceiling of integer');
    
    # Test Round
    is(Math::Round(3.5), 4, 'Round 3.5');
    is(Math::Round(3.4), 3, 'Round 3.4');
    is(Math::Round(-3.5), -3, 'Round -3.5');
    is(Math::Round(3.14159, 2), 3.14, 'Round with digits');
    is(Math::Round(3.14159, 4), 3.1416, 'Round to 4 digits');
    
    # Test RoundToEven (banker's rounding)
    is(Math::RoundToEven(2.5, 0), 2, 'RoundToEven 2.5 to even');
    is(Math::RoundToEven(3.5, 0), 4, 'RoundToEven 3.5 to even');
    is(Math::RoundToEven(4.5, 0), 4, 'RoundToEven 4.5 to even');
    
    # Test Truncate
    is(Math::Truncate(3.7), 3, 'Truncate positive decimal');
    is(Math::Truncate(-3.7), -3, 'Truncate negative decimal');
}

sub test_advanced_operations {
    # Test Clamp
    is(Math::Clamp(5, 1, 10), 5, 'Clamp within range');
    is(Math::Clamp(-5, 1, 10), 1, 'Clamp below minimum');
    is(Math::Clamp(15, 1, 10), 10, 'Clamp above maximum');
    
    eval { Math::Clamp(5, 10, 1); };
    ok($@, 'Clamp throws when min > max');
    
    # Test CopySign
    is(Math::CopySign(5, -1), -5, 'CopySign positive to negative');
    is(Math::CopySign(-5, 1), 5, 'CopySign negative to positive');
    is(Math::CopySign(5, 0), 5, 'CopySign with zero sign');
    
    # Test DivRem
    my $remainder;
    my $quotient = Math::DivRem(17, 5, \$remainder);
    is($quotient, 3, 'DivRem quotient');
    is($remainder, 2, 'DivRem remainder');
    
    eval { Math::DivRem(5, 0, \$remainder); };
    ok($@, 'DivRem throws on divide by zero');
    
    # Test MaxMagnitude/MinMagnitude
    is(Math::MaxMagnitude(-5, 3), -5, 'MaxMagnitude with larger negative');
    is(Math::MinMagnitude(-5, 3), 3, 'MinMagnitude with smaller positive');
    
    # Test ScaleB
    is(Math::ScaleB(3, 2), 12, 'ScaleB multiplies by 2^n');
    is(Math::ScaleB(8, -3), 1, 'ScaleB with negative exponent');
}

sub test_special_values {
    # Test special value detection
    ok(Math::IsFinite(5.0), 'IsFinite for normal number');
    ok(Math::IsFinite(0), 'IsFinite for zero');
    ok(Math::IsNormal(5.0), 'IsNormal for normal number');
    ok(!Math::IsNormal(0), 'IsNormal false for zero');
    
    # Note: Testing infinity and NaN is tricky in Perl
    # These tests may need adjustment based on Perl version
    my $inf = 9**9**9;
    my $neg_inf = -9**9**9;
    my $nan = 'nan';
    
    ok(Math::IsInfinity($inf), 'IsInfinity detects positive infinity');
    ok(Math::IsPositiveInfinity($inf), 'IsPositiveInfinity works');
    ok(Math::IsNegativeInfinity($neg_inf), 'IsNegativeInfinity works');
}

sub test_utility_functions {
    # Test Factorial
    is(Math::Factorial(0), 1, 'Factorial of 0');
    is(Math::Factorial(1), 1, 'Factorial of 1');
    is(Math::Factorial(5), 120, 'Factorial of 5');
    is(Math::Factorial(6), 720, 'Factorial of 6');
    
    eval { Math::Factorial(-1); };
    ok($@, 'Factorial throws on negative input');
    
    # Test GCD
    is(Math::GCD(12, 8), 4, 'GCD of 12 and 8');
    is(Math::GCD(17, 13), 1, 'GCD of primes');
    is(Math::GCD(0, 5), 5, 'GCD with zero');
    is(Math::GCD(-12, 8), 4, 'GCD with negative number');
    
    # Test LCM
    is(Math::LCM(4, 6), 12, 'LCM of 4 and 6');
    is(Math::LCM(7, 11), 77, 'LCM of primes');
    
    # Test angle conversion
    ok(abs(Math::DegreesToRadians(180) - Math::PI) < 1e-10, 'Degrees to radians');
    ok(abs(Math::RadiansToDegrees(Math::PI) - 180) < 1e-10, 'Radians to degrees');
    is(Math::DegreesToRadians(90), Math::PI/2, '90 degrees to radians');
}

sub test_error_conditions {
    # Test various error conditions
    eval { Math::Log(-1); };
    # Note: Perl's log() may handle this differently than .NET
    
    eval { Math::Sqrt(-1); };
    # Note: Perl may return complex number or NaN
    
    eval { Math::Acosh(0.5); };
    ok($@, 'Acosh throws for value < 1');
    
    eval { Math::Atanh(1); };
    ok($@, 'Atanh throws for |value| >= 1');
    
    eval { Math::Atanh(-1); };
    ok($@, 'Atanh throws for |value| >= 1');
    
    eval { Math::Log2(0); };
    ok($@, 'Log2 throws for value <= 0');
    
    eval { Math::Log2(-1); };
    ok($@, 'Log2 throws for negative value');
}

sub test_edge_cases {
    # Test edge cases and boundary conditions
    is(Math::Pow(0, 0), 1, '0^0 equals 1 by convention');
    ok(Math::IsFinite(Math::Pow(2, 1000)), 'Large powers remain finite in Perl');
    
    # Test very small numbers
    ok(Math::IsFinite(Math::Pow(2, -1000)), 'Very small powers are finite');
    
    # Test with very large numbers
    my $large = 1e100;
    ok(Math::Abs($large) == $large, 'Abs works with large numbers');
    is(Math::Sign($large), 1, 'Sign works with large numbers');
    
    # Test precision limits
    ok(abs(Math::Sin(Math::PI)) < 1e-10, 'Sin(π) is approximately 0');
    ok(abs(Math::Cos(2 * Math::PI) - 1) < 1e-10, 'Cos(2π) is approximately 1');
}

# Run all tests
test_math_constants();
test_basic_arithmetic();
test_power_and_roots();
test_trigonometry();
test_hyperbolic();
test_rounding();
test_advanced_operations();
test_special_values();
test_utility_functions();
test_error_conditions();
test_edge_cases();

done_testing();