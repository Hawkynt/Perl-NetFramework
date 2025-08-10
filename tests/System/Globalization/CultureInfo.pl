#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Globalization::CultureInfo;
require System::Globalization::NumberStyles;
require System::Globalization::NumberParser;
require System::Int32;

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

print "1..50\n"; # Comprehensive CultureInfo and NumberStyles tests

# Test 1-10: CultureInfo basic functionality
my $invariantCulture = System::Globalization::CultureInfo->InvariantCulture();
test_ok(defined($invariantCulture), 'InvariantCulture returns culture');
test_ok($invariantCulture->isa('System::Globalization::CultureInfo'), 'InvariantCulture isa CultureInfo');
test_ok($invariantCulture->Name() eq '', 'InvariantCulture has empty name');

my $culture1 = System::Globalization::CultureInfo->new('en-US');
test_ok(defined($culture1), 'CultureInfo construction with name');
test_ok($culture1->Name() eq 'en-US', 'CultureInfo has correct name');

my $culture2 = System::Globalization::CultureInfo->new('');
test_ok($culture2->Name() eq '', 'CultureInfo with empty name');

# Test static cultures are singletons
my $invariant2 = System::Globalization::CultureInfo->InvariantCulture();
test_ok($invariantCulture eq $invariant2, 'InvariantCulture returns same instance');

# Test CurrentCulture 
my $currentCulture = System::Globalization::CultureInfo->CurrentCulture();
test_ok(defined($currentCulture), 'CurrentCulture returns culture');
test_ok($currentCulture->isa('System::Globalization::CultureInfo'), 'CurrentCulture isa CultureInfo');

# Test 11-20: NumberStyles constants and operations
# Import NumberStyles constants
use System::Globalization::NumberStyles qw(None Integer Float Currency Any AllowLeadingWhite AllowDecimalPoint AllowThousands);

test_ok(defined(&None), 'NumberStyles::None constant imported');
test_ok(defined(&Integer), 'NumberStyles::Integer constant imported');
test_ok(defined(&Float), 'NumberStyles::Float constant imported');
test_ok(defined(&Currency), 'NumberStyles::Currency constant imported');

# Test bitwise operations
test_ok((Integer & AllowLeadingWhite) == AllowLeadingWhite, 'Integer style includes AllowLeadingWhite');
test_ok((Float & AllowDecimalPoint) == AllowDecimalPoint, 'Float style includes AllowDecimalPoint');
test_ok((Currency & AllowThousands) == AllowThousands, 'Currency style includes AllowThousands');

# Test HasFlag helper method
test_ok(System::Globalization::NumberStyles::HasFlag(Integer, AllowLeadingWhite), 'HasFlag works for Integer');
test_ok(!System::Globalization::NumberStyles::HasFlag(None, AllowDecimalPoint), 'HasFlag returns false for None');

# Test style validation
test_ok(System::Globalization::NumberStyles::IsValidStyle(Integer), 'Integer is valid style');
test_ok(System::Globalization::NumberStyles::IsValidStyle(None), 'None is valid style');
test_ok(!System::Globalization::NumberStyles::IsValidStyle(-1), 'Negative style is invalid');

# Test 21-30: NumberParser basic functionality
my $parsed1 = System::Globalization::NumberParser::ParseWithStyle(
  '42', Integer, $invariantCulture, 'System::Int32'
);
test_ok($parsed1 == 42, 'Parse simple integer works');

my $parsed2 = System::Globalization::NumberParser::ParseWithStyle(
  '  123  ', Integer, $invariantCulture, 'System::Int32'
);
test_ok($parsed2 == 123, 'Parse integer with whitespace works');

my $parsed3 = System::Globalization::NumberParser::ParseWithStyle(
  '-456', Integer, $invariantCulture, 'System::Int32'
);
test_ok($parsed3 == -456, 'Parse negative integer works');

my $parsed4 = System::Globalization::NumberParser::ParseWithStyle(
  '12.34', Float, $invariantCulture, 'System::Double'
);
test_ok(abs($parsed4 - 12.34) < 0.001, 'Parse float works');

# Test TryParse functionality
my $result;
my $success = System::Globalization::NumberParser::TryParseWithStyle(
  '789', Integer, $invariantCulture, 'System::Int32', \$result
);
test_ok($success, 'TryParse successful parse returns true');
test_ok($result == 789, 'TryParse sets correct result');

my $failResult;
my $failSuccess = System::Globalization::NumberParser::TryParseWithStyle(
  'invalid', Integer, $invariantCulture, 'System::Int32', \$failResult
);
test_ok(!$failSuccess, 'TryParse failed parse returns false');
test_ok(!defined($failResult), 'TryParse failed sets undef result');

# Test 31-40: Advanced NumberStyles parsing
# Test parentheses for negative numbers (requires system to handle this)
eval {
  my $parenResult = System::Globalization::NumberParser::ParseWithStyle(
    '(123)', Currency, $invariantCulture, 'System::Int32'
  );
  test_ok($parenResult == -123, 'Parse parentheses as negative works');
} or test_ok(0, 'Parse parentheses as negative works (implementation pending)');

# Test hexadecimal parsing
eval {
  my $hexResult = System::Globalization::NumberParser::ParseWithStyle(
    'FF', System::Globalization::NumberStyles::HexNumber, $invariantCulture, 'System::Int32'
  );
  test_ok($hexResult == 255, 'Parse hexadecimal FF works');
} or test_ok(0, 'Parse hexadecimal FF works (needs fix)');

eval {
  my $hexResult2 = System::Globalization::NumberParser::ParseWithStyle(
    '0x10', System::Globalization::NumberStyles::HexNumber, $invariantCulture, 'System::Int32'
  );
  test_ok($hexResult2 == 16, 'Parse hexadecimal 0x10 works');
} or test_ok(0, 'Parse hexadecimal 0x10 works (needs fix)');

# Test exponential notation
eval {
  my $expResult = System::Globalization::NumberParser::ParseWithStyle(
    '1.5e2', Float, $invariantCulture, 'System::Double'
  );
  test_ok(abs($expResult - 150) < 0.001, 'Parse exponential notation works');
} or test_ok(0, 'Parse exponential notation works (needs fix)');

# Test thousands separator (once culture methods are implemented)
eval {
  # This test may fail until culture separator methods are implemented
  my $thousandsResult = System::Globalization::NumberParser::ParseWithStyle(
    '1,234', System::Globalization::NumberStyles::Number, $invariantCulture, 'System::Int32'
  );
  test_ok($thousandsResult == 1234, 'Parse with thousands separator works');
} or test_ok(0, 'Parse with thousands separator works (needs culture methods)');

# Test 41-50: Integration with System::Int32::Parse
# Test Int32 Parse with NumberStyles
eval {
  my $int1 = System::Int32->Parse('42', Integer);
  test_ok($int1->Value() == 42, 'Int32::Parse with NumberStyles works');
  
  my $int2 = System::Int32->Parse('  -123  ', Integer);
  test_ok($int2->Value() == -123, 'Int32::Parse with whitespace and sign works');
  
  # Test with culture
  my $int3 = System::Int32->Parse('456', Integer, $invariantCulture);
  test_ok($int3->Value() == 456, 'Int32::Parse with culture works');
} or do {
  test_ok(0, 'Int32::Parse with NumberStyles works (needs fix)');
  test_ok(0, 'Int32::Parse with whitespace and sign works (needs fix)');
  test_ok(0, 'Int32::Parse with culture works (needs fix)');
};

# Test error cases
test_exception(
  sub { System::Globalization::NumberParser::ParseWithStyle(undef, Integer); },
  'ArgumentNullException',
  'Parse with null value throws exception'
);

test_exception(
  sub { System::Globalization::NumberParser::ParseWithStyle('42', undef); },
  'ArgumentNullException',
  'Parse with null style throws exception'
);

eval {
  System::Globalization::NumberParser::ParseWithStyle('abc', Integer, $invariantCulture);
  test_ok(0, 'Parse invalid number throws FormatException');
} or test_ok($@ =~ /FormatException/, 'Parse invalid number throws FormatException');

eval {
  System::Globalization::NumberParser::ParseWithStyle('12.34', Integer, $invariantCulture);
  test_ok(0, 'Parse decimal as integer throws FormatException');
} or test_ok($@ =~ /FormatException/, 'Parse decimal as integer throws FormatException');

# Test GetStyleName utility
my $styleName = System::Globalization::NumberStyles::GetStyleName(Integer);
test_ok($styleName eq 'Integer', 'GetStyleName returns correct name for Integer');

my $customStyleName = System::Globalization::NumberStyles::GetStyleName(AllowLeadingWhite | AllowDecimalPoint);
test_ok($customStyleName =~ /AllowLeadingWhite/, 'GetStyleName includes combined flags');
test_ok($customStyleName =~ /AllowDecimalPoint/, 'GetStyleName includes all combined flags');

print "\n# CultureInfo and NumberStyles Tests completed: $tests_run\n";
print "# CultureInfo and NumberStyles Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);