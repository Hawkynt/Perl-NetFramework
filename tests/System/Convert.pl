#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Convert;
require System::String;

# Test counters
my $tests_run = 0;
my $tests_passed = 0;

sub test_ok {
  my ($condition, $test_name) = @_;
  $tests_run++;
  if ($condition) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name\n";
  }
}

sub test_exception {
  my ($code, $expected_exception, $test_name) = @_;
  $tests_run++;
  
  my $caught_exception = '';
  eval {
    $code->();
  };
  
  if ($@) {
    $caught_exception = ref($@) ? ref($@) : $@;
  }
  
  if ($caught_exception =~ /$expected_exception/) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name (expected $expected_exception, got $caught_exception)\n";
  }
}

print "1..60\n"; # Comprehensive Convert tests

# Test 1-5: Basic instantiation and boolean conversions
test_exception(
  sub { System::Convert->new(); },
  'InvalidOperationException',
  'Convert cannot be instantiated'
);

# Boolean conversions
test_ok(System::Convert->ToBoolean('true') == 1, 'ToBoolean true string');
test_ok(System::Convert->ToBoolean('false') == 0, 'ToBoolean false string');
test_ok(System::Convert->ToBoolean('TRUE') == 1, 'ToBoolean case insensitive true');
test_ok(System::Convert->ToBoolean('1') == 1, 'ToBoolean numeric 1');
test_ok(System::Convert->ToBoolean('0') == 0, 'ToBoolean numeric 0');

# Test 6-15: Integer conversions
my $byteVal = System::Convert->ToByte('255');
test_ok($byteVal == 255, 'ToByte maximum value');

my $sbyteVal = System::Convert->ToSByte('-128');
test_ok($sbyteVal == -128, 'ToSByte minimum value');

my $int16Val = System::Convert->ToInt16('32767');
test_ok($int16Val == 32767, 'ToInt16 maximum value');

my $uint16Val = System::Convert->ToUInt16('65535');
test_ok($uint16Val == 65535, 'ToUInt16 maximum value');

my $int32Val = System::Convert->ToInt32('2147483647');
test_ok($int32Val == 2147483647, 'ToInt32 maximum value');

my $uint32Val = System::Convert->ToUInt32('4294967295');
test_ok($uint32Val == 4294967295, 'ToUInt32 maximum value');

my $int64Val = System::Convert->ToInt64('-9223372036854775808');
test_ok(defined($int64Val), 'ToInt64 minimum value');

my $uint64Val = System::Convert->ToUInt64('18446744073709551615');
test_ok(defined($uint64Val), 'ToUInt64 maximum value');

# Test decimal conversion from string with decimal point
my $intFromDecimal = System::Convert->ToInt32('42.0');
test_ok($intFromDecimal == 42, 'ToInt32 from decimal string');

# Test 16-25: Floating point conversions
my $singleVal = System::Convert->ToSingle('3.14159');
test_ok(abs($singleVal - 3.14159) < 0.0001, 'ToSingle decimal value');

my $doubleVal = System::Convert->ToDouble('2.718281828');
test_ok(abs($doubleVal - 2.718281828) < 0.000001, 'ToDouble decimal value');

my $decimalVal = System::Convert->ToDecimal('123.456');
test_ok(abs($decimalVal - 123.456) < 0.001, 'ToDecimal decimal value');

# Test scientific notation
my $scientificVal = System::Convert->ToDouble('1.5e2');
test_ok(abs($scientificVal - 150.0) < 0.001, 'ToDouble scientific notation');

# Test negative values
my $negativeInt = System::Convert->ToInt32('-42');
test_ok($negativeInt == -42, 'ToInt32 negative value');

my $negativeDouble = System::Convert->ToDouble('-3.14');
test_ok(abs($negativeDouble + 3.14) < 0.001, 'ToDouble negative value');

# Test zero values
my $zeroInt = System::Convert->ToInt32('0');
test_ok($zeroInt == 0, 'ToInt32 zero');

my $zeroDouble = System::Convert->ToDouble('0.0');
test_ok($zeroDouble == 0.0, 'ToDouble zero');

# Test with System::String objects
my $stringObj = System::String->new('100');
my $fromStringObj = System::Convert->ToInt32($stringObj);
test_ok($fromStringObj == 100, 'ToInt32 from System::String object');

# Test null/undefined handling
my $nullInt = System::Convert->ToInt32(undef);
test_ok($nullInt == 0, 'ToInt32 null returns 0');

# Test 26-35: String conversions
my $stringFromInt = System::Convert->ToString(42);
test_ok($stringFromInt->isa('System::String'), 'ToString returns System::String');
test_ok($stringFromInt eq '42', 'ToString integer conversion');

my $stringFromDouble = System::Convert->ToString(3.14);
test_ok($stringFromDouble eq '3.14', 'ToString double conversion');

my $stringFromBool = System::Convert->ToString(1);
test_ok($stringFromBool eq '1', 'ToString boolean conversion');

my $stringFromNull = System::Convert->ToString(undef);
test_ok($stringFromNull eq '', 'ToString null returns empty string');

# Test object with ToString method
my $objectString = System::Convert->ToString($stringObj);
test_ok($objectString eq '100', 'ToString from object with ToString method');

# Test 36-45: Character conversions
my $charFromString = System::Convert->ToChar(System::String->new('A'));
test_ok($charFromString eq 'A', 'ToChar from single character string');

my $charFromNumeric = System::Convert->ToChar(65);  # ASCII 'A'
test_ok($charFromNumeric eq 'A', 'ToChar from ASCII value');

my $charFromChar = System::Convert->ToChar('Z');
test_ok($charFromChar eq 'Z', 'ToChar from character');

test_exception(
  sub { System::Convert->ToChar(System::String->new('ABC')); },
  'FormatException',
  'ToChar multi-character string throws exception'
);

test_exception(
  sub { System::Convert->ToChar(undef); },
  'ArgumentNullException',
  'ToChar null throws exception'
);

# Test 46-55: Base64 conversions
my $testBytes = [72, 101, 108, 108, 111];  # "Hello"
my $base64String = System::Convert->ToBase64String($testBytes);
test_ok($base64String->isa('System::String'), 'ToBase64String returns System::String');
test_ok(length($base64String) > 0, 'ToBase64String produces output');

my $decodedBytes = System::Convert->FromBase64String($base64String);
test_ok(ref($decodedBytes) eq 'ARRAY', 'FromBase64String returns array');
test_ok(@$decodedBytes == @$testBytes, 'FromBase64String correct length');
test_ok($decodedBytes->[0] == $testBytes->[0], 'FromBase64String correct first byte');

# Test hex conversions
my $hexString = System::Convert->ToHexString($testBytes);
test_ok($hexString->isa('System::String'), 'ToHexString returns System::String');
test_ok($hexString =~ /^[0-9A-F]+$/, 'ToHexString produces valid hex');

my $hexFromNumber = System::Convert->ToHexString(255);
test_ok($hexFromNumber eq 'FF', 'ToHexString from number');

my $bytesFromHex = System::Convert->FromHexString('48656C6C6F');  # "Hello"
test_ok(ref($bytesFromHex) eq 'ARRAY', 'FromHexString returns array');
test_ok($bytesFromHex->[0] == 72, 'FromHexString correct first byte');

# Test 56-60: Error handling and edge cases
test_exception(
  sub { System::Convert->ToByte('256'); },
  'OverflowException',
  'ToByte overflow throws exception'
);

test_exception(
  sub { System::Convert->ToByte('-1'); },
  'OverflowException',
  'ToByte underflow throws exception'
);

test_exception(
  sub { System::Convert->ToInt32('abc'); },
  'FormatException',
  'ToInt32 invalid format throws exception'
);

test_exception(
  sub { System::Convert->ToBoolean('maybe'); },
  'FormatException',
  'ToBoolean invalid format throws exception'
);

# Test type code detection
my $typeCode = System::Convert->GetTypeCode(42);
test_ok($typeCode eq 'Int32', 'GetTypeCode integer');

my $stringTypeCode = System::Convert->GetTypeCode('hello');
test_ok($stringTypeCode eq 'String', 'GetTypeCode string');

my $doubleTypeCode = System::Convert->GetTypeCode(3.14);
test_ok($doubleTypeCode eq 'Double', 'GetTypeCode double');

# Test IsDBNull
test_ok(System::Convert->IsDBNull(undef) == 1, 'IsDBNull undef returns true');
test_ok(System::Convert->IsDBNull(42) == 0, 'IsDBNull value returns false');

# Test ChangeType
my $changedType = System::Convert->ChangeType('42', 'Int32');
test_ok($changedType == 42, 'ChangeType string to Int32');

test_exception(
  sub { System::Convert->ChangeType('42', 'InvalidType'); },
  'InvalidCastException',
  'ChangeType invalid type throws exception'
);

print "\n# System::Convert Tests completed: $tests_run\n";
print "# System::Convert Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);