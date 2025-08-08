#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import numeric types
use System::Byte;
use System::SByte;
use System::Int16;
use System::Int32;
use System::UInt16;
use System::UInt32;
use System::Single;
use System::Double;

sub test_byte {
    # Test construction and bounds
    my $b1 = System::Byte->new(100);
    is($b1->Value(), 100, 'Byte construction with valid value');
    
    my $b2 = System::Byte->new(0);
    is($b2->Value(), 0, 'Byte minimum value');
    
    my $b3 = System::Byte->new(255);
    is($b3->Value(), 255, 'Byte maximum value');
    
    # Test overflow
    eval { System::Byte->new(256) };
    ok($@, 'Byte throws on overflow');
    
    eval { System::Byte->new(-1) };
    ok($@, 'Byte throws on underflow');
    
    # Test parsing
    my $parsed = System::Byte->Parse("123");
    is($parsed->Value(), 123, 'Byte parsing works');
    
    eval { System::Byte->Parse("256") };
    ok($@, 'Byte parsing throws on overflow');
    
    # Test TryParse
    my $result;
    ok(System::Byte->TryParse("50", \$result), 'Byte TryParse succeeds');
    is($result->Value(), 50, 'Byte TryParse result correct');
    
    ok(!System::Byte->TryParse("300", \$result), 'Byte TryParse fails on overflow');
    
    # Test ToString
    is($b1->ToString(), "100", 'Byte ToString default format');
    is($b1->ToString("X"), "64", 'Byte ToString hex format');
    is($b1->ToString("D3"), "100", 'Byte ToString decimal with width');
    
    # Test arithmetic
    my $b_50 = System::Byte->new(50);
    my $sum = System::Byte->Add($b1, $b_50);
    is($sum->Value(), 150, 'Byte addition works');
    
    my $b_200 = System::Byte->new(200);
    my $b_100 = System::Byte->new(100);
    eval { System::Byte->Add($b_200, $b_100) };
    ok($@, 'Byte addition throws on overflow');
}

sub test_sbyte {
    # Test construction and bounds
    my $sb1 = System::SByte->new(-50);
    is($sb1->Value(), -50, 'SByte construction with negative value');
    
    my $sb2 = System::SByte->new(127);
    is($sb2->Value(), 127, 'SByte maximum value');
    
    my $sb3 = System::SByte->new(-128);
    is($sb3->Value(), -128, 'SByte minimum value');
    
    # Test overflow
    eval { System::SByte->new(128) };
    ok($@, 'SByte throws on positive overflow');
    
    eval { System::SByte->new(-129) };
    ok($@, 'SByte throws on negative overflow');
    
    # Test parsing
    my $parsed = System::SByte->Parse("-75");
    is($parsed->Value(), -75, 'SByte parsing negative number');
    
    # Test ToString with hex (should show two's complement)
    my $negative = System::SByte->new(-1);
    is($negative->ToString("X"), "FF", 'SByte negative hex representation');
}

sub test_int16 {
    # Test construction and bounds
    my $i1 = System::Int16->new(1000);
    is($i1->Value(), 1000, 'Int16 construction');
    
    my $i2 = System::Int16->new(32767);
    is($i2->Value(), 32767, 'Int16 maximum value');
    
    my $i3 = System::Int16->new(-32768);
    is($i3->Value(), -32768, 'Int16 minimum value');
    
    # Test overflow
    eval { System::Int16->new(32768) };
    ok($@, 'Int16 throws on overflow');
    
    # Test arithmetic
    my $product = System::Int16->Multiply(System::Int16->new(100), System::Int16->new(200));
    is($product->Value(), 20000, 'Int16 multiplication');
    
    eval { System::Int16->Multiply(System::Int16->new(300), System::Int16->new(200)) };
    ok($@, 'Int16 multiplication throws on overflow');
    
    # Test bitwise operations
    my $and_result = System::Int16->BitwiseAnd(System::Int16->new(0xFF), System::Int16->new(0x0F));
    is($and_result->Value(), 0x0F, 'Int16 bitwise AND');
    
    # Test shift operations
    my $left_shift = System::Int16->LeftShift(System::Int16->new(5), 2);
    is($left_shift->Value(), 20, 'Int16 left shift');
    
    my $right_shift = System::Int16->RightShift(System::Int16->new(20), 2);
    is($right_shift->Value(), 5, 'Int16 right shift');
}

sub test_int32 {
    # Test construction
    my $i1 = System::Int32->new(1000000);
    is($i1->Value(), 1000000, 'Int32 construction');
    
    # Test parsing
    my $parsed = System::Int32->Parse("123456");
    is($parsed->Value(), 123456, 'Int32 parsing');
    
    # Test formatting
    is($i1->ToString("N"), "1,000,000.00", 'Int32 number format');
    is($i1->ToString("C"), "\$1,000,000.00", 'Int32 currency format');
    is($i1->ToString("X"), "000F4240", 'Int32 hex format');
    
    # Test comparison
    my $i2 = System::Int32->new(500000);
    is($i1->CompareTo($i2), 1, 'Int32 comparison greater');
    is($i2->CompareTo($i1), -1, 'Int32 comparison less');
    
    # Test Equals
    my $i3 = System::Int32->new(1000000);
    ok($i1->Equals($i3), 'Int32 equality');
    ok(!$i1->Equals($i2), 'Int32 inequality');
    
    # Test hash code
    is($i1->GetHashCode(), $i3->GetHashCode(), 'Equal Int32s have same hash code');
    
    # Test modulo
    my $mod = System::Int32->Modulo(System::Int32->new(10), System::Int32->new(3));
    is($mod->Value(), 1, 'Int32 modulo operation');
    
    # Test Abs and Sign
    my $negative = System::Int32->new(-500);
    my $abs = System::Int32->Abs($negative);
    is($abs->Value(), 500, 'Int32 absolute value');
    
    my $sign = System::Int32->Sign($negative);
    is($sign->Value(), -1, 'Int32 sign of negative');
    
    $sign = System::Int32->Sign(System::Int32->new(500));
    is($sign->Value(), 1, 'Int32 sign of positive');
    
    $sign = System::Int32->Sign(System::Int32->new(0));
    is($sign->Value(), 0, 'Int32 sign of zero');
}

sub test_uint16_uint32 {
    # Test UInt16
    my $u16 = System::UInt16->new(50000);
    is($u16->Value(), 50000, 'UInt16 construction');
    
    my $u16_max = System::UInt16->new(65535);
    is($u16_max->Value(), 65535, 'UInt16 maximum value');
    
    eval { System::UInt16->new(-1) };
    ok($@, 'UInt16 throws on negative value');
    
    eval { System::UInt16->new(65536) };
    ok($@, 'UInt16 throws on overflow');
    
    # Test UInt32
    my $u32 = System::UInt32->new(3000000000);
    is($u32->Value(), 3000000000, 'UInt32 construction');
    
    my $u32_max = System::UInt32->new(4294967295);
    is($u32_max->Value(), 4294967295, 'UInt32 maximum value');
    
    eval { System::UInt32->new(-1) };
    ok($@, 'UInt32 throws on negative value');
}

sub test_single {
    # Test construction
    my $f1 = System::Single->new(3.14);
    is($f1->Value(), 3.14, 'Single construction');
    
    # Test special values
    my $nan = System::Single->new('nan');
    ok(System::Single->IsNaN($nan), 'Single NaN detection');
    
    my $inf = System::Single->new('inf');
    ok(System::Single->IsPositiveInfinity($inf), 'Single positive infinity detection');
    
    my $neg_inf = System::Single->new('-inf');
    ok(System::Single->IsNegativeInfinity($neg_inf), 'Single negative infinity detection');
    
    # Test parsing
    my $parsed = System::Single->Parse("2.5");
    is($parsed->Value(), 2.5, 'Single parsing');
    
    my $parsed_exp = System::Single->Parse("1.5e2");
    is($parsed_exp->Value(), 150.0, 'Single scientific notation parsing');
    
    my $parsed_nan = System::Single->Parse("NaN");
    ok(System::Single->IsNaN($parsed_nan), 'Single NaN parsing');
    
    # Test ToString
    is($f1->ToString(), "3.14", 'Single ToString default');
    is($f1->ToString("F1"), "3.1", 'Single ToString fixed format');
    is($f1->ToString("E2"), "3.14E+00", 'Single ToString exponential format');
    
    # Test arithmetic
    my $sum = System::Single->Add($f1, System::Single->new(1.86));
    is($sum->Value(), 5.0, 'Single addition');
    
    my $product = System::Single->Multiply(System::Single->new(2.5), System::Single->new(4.0));
    is($product->Value(), 10.0, 'Single multiplication');
    
    # Test comparison (NaN behavior)
    ok(!$nan->Equals($nan), 'Single NaN not equal to itself');
    is($nan->CompareTo(System::Single->new(1.0)), -1, 'Single NaN comparison behavior');
}

sub test_double {
    # Test construction
    my $d1 = System::Double->new(3.141592653589793);
    is($d1->Value(), 3.141592653589793, 'Double construction with high precision');
    
    # Test special values
    my $nan = System::Double->new('nan');
    ok(System::Double->IsNaN($nan), 'Double NaN detection');
    
    my $inf = System::Double->new('inf');
    ok(System::Double->IsInfinity($inf), 'Double infinity detection');
    ok(System::Double->IsFinite(System::Double->new(1.0)), 'Double finite detection');
    
    # Test parsing
    my $parsed = System::Double->Parse("1.7976931348623157e+308");
    ok(System::Double->IsFinite($parsed), 'Double parsing large number');
    
    # Test formatting
    my $formatted = System::Double->new(123.456);
    is($formatted->ToString("F2"), "123.46", 'Double ToString fixed format');
    is($formatted->ToString("E3"), "1.235E+02", 'Double ToString exponential format');
    is($formatted->ToString("G2"), "1.2e+02", 'Double ToString general format');
    
    # Test math functions
    my $sqrt_result = System::Double->Sqrt(System::Double->new(16.0));
    is($sqrt_result->Value(), 4.0, 'Double square root');
    
    my $pow_result = System::Double->Pow(System::Double->new(2.0), System::Double->new(3.0));
    is($pow_result->Value(), 8.0, 'Double power');
    
    my $abs_result = System::Double->Abs(System::Double->new(-5.5));
    is($abs_result->Value(), 5.5, 'Double absolute value');
    
    my $floor_result = System::Double->Floor(System::Double->new(3.7));
    is($floor_result->Value(), 3.0, 'Double floor');
    
    my $ceil_result = System::Double->Ceiling(System::Double->new(3.2));
    is($ceil_result->Value(), 4.0, 'Double ceiling');
    
    my $round_result = System::Double->Round(System::Double->new(3.14159), 3);
    is($round_result->Value(), 3.142, 'Double rounding');
}

sub test_constants {
    # Test constants are properly defined
    is(System::Byte::MinValue, 0, 'Byte MinValue constant');
    is(System::Byte::MaxValue, 255, 'Byte MaxValue constant');
    
    is(System::SByte::MinValue, -128, 'SByte MinValue constant');
    is(System::SByte::MaxValue, 127, 'SByte MaxValue constant');
    
    is(System::Int16::MinValue, -32768, 'Int16 MinValue constant');
    is(System::Int16::MaxValue, 32767, 'Int16 MaxValue constant');
    
    is(System::Int32::MinValue, -2147483648, 'Int32 MinValue constant');
    is(System::Int32::MaxValue, 2147483647, 'Int32 MaxValue constant');
    
    is(System::UInt16::MinValue, 0, 'UInt16 MinValue constant');
    is(System::UInt16::MaxValue, 65535, 'UInt16 MaxValue constant');
    
    is(System::UInt32::MinValue, 0, 'UInt32 MinValue constant');
    is(System::UInt32::MaxValue, 4294967295, 'UInt32 MaxValue constant');
}

# Run all tests
test_byte();
test_sbyte();
test_int16();
test_int32();
test_uint16_uint32();
test_single();
test_double();
test_constants();

done_testing();