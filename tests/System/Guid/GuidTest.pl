#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Guid;

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

print "1..60\n"; # Comprehensive Guid tests

# Test 1-10: Basic Guid functionality
my $empty = System::Guid->Empty();
test_ok(defined($empty), 'Empty Guid created');
test_ok($empty->isa('System::Guid'), 'Empty is a Guid');

my $empty2 = System::Guid->Empty();
test_ok($empty eq $empty2, 'Empty returns same instance');

my $defaultGuid = System::Guid->new();
test_ok(defined($defaultGuid), 'Default constructor works');
test_ok($defaultGuid->isa('System::Guid'), 'Default constructor returns Guid');

# Test that default constructor creates Empty guid
test_ok($defaultGuid->Equals($empty), 'Default constructor creates Empty guid');

# Test NewGuid creates different instances
my $guid1 = System::Guid->NewGuid();
my $guid2 = System::Guid->NewGuid();
test_ok(defined($guid1), 'NewGuid creates guid');
test_ok(!$guid1->Equals($guid2), 'NewGuid creates different guids');
test_ok(!$guid1->Equals($empty), 'NewGuid does not create Empty guid');

# Test 11-20: String representation and parsing
my $guidString = $guid1->ToString();
test_ok(defined($guidString), 'ToString returns string');
test_ok(length($guidString) == 36, 'Default format has correct length'); # 32 chars + 4 hyphens
test_ok($guidString =~ /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/i, 'Default format is correct');

# Test different ToString formats
my $formatN = $guid1->ToString('N');
test_ok(length($formatN) == 32, 'N format has correct length');
test_ok($formatN !~ /-/, 'N format has no hyphens');

my $formatB = $guid1->ToString('B');
test_ok($formatB =~ /^\{.+\}$/, 'B format has braces');

my $formatP = $guid1->ToString('P');
test_ok($formatP =~ /^\(.+\)$/, 'P format has parentheses');

my $formatX = $guid1->ToString('X');
test_ok($formatX =~ /^\{0x.+\}$/, 'X format has array notation');

# Test parsing
my $parsed = System::Guid->Parse($guidString);
test_ok($parsed->isa('System::Guid'), 'Parse returns Guid');
test_ok($parsed->Equals($guid1), 'Parsed guid equals original');

# Test 21-30: Parsing different formats
my $parsedN = System::Guid->Parse($formatN);
test_ok($parsedN->Equals($guid1), 'Parse N format works');

my $parsedB = System::Guid->Parse($formatB);
test_ok($parsedB->Equals($guid1), 'Parse B format works');

my $parsedP = System::Guid->Parse($formatP);
test_ok($parsedP->Equals($guid1), 'Parse P format works');

# Test TryParse
my $tryResult;
my $success = System::Guid->TryParse($guidString, \$tryResult);
test_ok($success, 'TryParse succeeds on valid input');
test_ok($tryResult->Equals($guid1), 'TryParse sets correct result');

my $failResult;
my $failSuccess = System::Guid->TryParse('invalid-guid', \$failResult);
test_ok(!$failSuccess, 'TryParse fails on invalid input');
test_ok(!defined($failResult), 'TryParse sets undef on failure');

# Test ParseExact
my $exactResult = System::Guid->ParseExact($guidString, 'D');
test_ok($exactResult->Equals($guid1), 'ParseExact with D format works');

my $exactResultN = System::Guid->ParseExact($formatN, 'N');
test_ok($exactResultN->Equals($guid1), 'ParseExact with N format works');

# Test 31-40: Byte array operations
my $byteArray = $guid1->ToByteArray();
test_ok(ref($byteArray) eq 'ARRAY', 'ToByteArray returns array ref');
test_ok(@$byteArray == 16, 'Byte array has 16 elements');

# Test all bytes are valid (0-255)
my $validBytes = 1;
for my $byte (@$byteArray) {
  $validBytes = 0 if !defined($byte) || $byte < 0 || $byte > 255;
}
test_ok($validBytes, 'All bytes are valid');

# Test construction from byte array
my $fromBytes = System::Guid->new($byteArray);
test_ok($fromBytes->isa('System::Guid'), 'Construction from byte array works');
test_ok($fromBytes->Equals($guid1), 'Guid from byte array equals original');

# Test that modifying returned array doesn't affect original
$byteArray->[0] = 999;
my $unmodified = $guid1->ToByteArray();
test_ok($unmodified->[0] != 999, 'ToByteArray returns copy');

# Test construction from 11 arguments (int, short, short, 8 bytes)
my $fromParts = System::Guid->new(0x12345678, 0x1234, 0x5678, 0x90, 0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67);
test_ok($fromParts->isa('System::Guid'), 'Construction from 11 parts works');

my $partsString = $fromParts->ToString();
test_ok(length($partsString) == 36, 'Guid from parts has correct string length');
test_ok($partsString =~ /^[0-9a-fA-F-]+$/, 'Guid from parts has valid format');

# Test 41-50: Comparison and equality
test_ok($guid1->Equals($guid1), 'Guid equals itself');
test_ok(!$guid1->Equals($guid2), 'Different guids are not equal');
test_ok(!$guid1->Equals(undef), 'Guid not equal to undef');
test_ok(!$guid1->Equals("string"), 'Guid not equal to string');

# Test CompareTo
test_ok($guid1->CompareTo($guid1) == 0, 'CompareTo self returns 0');
test_ok($guid1->CompareTo($guid2) != 0, 'CompareTo different guid is not 0');
test_ok($empty->CompareTo($guid1) != 0, 'Empty compared to non-empty is not 0');

# Test GetHashCode
my $hash1 = $guid1->GetHashCode();
my $hash1_again = $guid1->GetHashCode();
test_ok($hash1 == $hash1_again, 'GetHashCode is consistent');

my $hash2 = $guid2->GetHashCode();
# Hash codes might be the same by chance, but different guids should usually have different hashes
test_ok(defined($hash2), 'GetHashCode returns defined value');

# Test 51-60: Error handling and edge cases
test_exception(
  sub { System::Guid->Parse(undef); },
  'ArgumentNullException',
  'Parse with null throws exception'
);

test_exception(
  sub { System::Guid->Parse('invalid-guid-format'); },
  'FormatException',
  'Parse with invalid format throws exception'
);

test_exception(
  sub { System::Guid->new([1, 2, 3]); },  # Too few bytes
  'ArgumentException',
  'Constructor with wrong byte array size throws exception'
);

test_exception(
  sub { System::Guid->new(1, 2, 3, 4, 5); },  # Wrong number of args
  'ArgumentException',
  'Constructor with wrong number of arguments throws exception'
);

test_exception(
  sub { System::Guid->ParseExact($guidString, 'Z'); },
  'FormatException',
  'ParseExact with invalid format throws exception'
);

# Test version 4 (random) guid properties
my $newGuid = System::Guid->NewGuid();
my $bytes = $newGuid->ToByteArray();
my $version = ($bytes->[7] & 0xF0) >> 4;  # Version is in upper 4 bits of byte 7
test_ok($version == 4, 'NewGuid creates version 4 GUID');

my $variant = ($bytes->[8] & 0xC0) >> 6;  # Variant is in upper 2 bits of byte 8
test_ok($variant == 2, 'NewGuid creates proper variant bits');  # RFC 4122 variant

# Test Empty guid string representation
my $emptyString = $empty->ToString();
test_ok($emptyString eq '00000000-0000-0000-0000-000000000000', 'Empty guid string is all zeros');

# Test case insensitive parsing
my $lowerGuidString = lc($guidString);
my $parsedLower = System::Guid->Parse($lowerGuidString);
test_ok($parsedLower->Equals($guid1), 'Parse handles lowercase input');

# Test that toString is cached
my $string1 = $guid1->ToString();
my $string2 = $guid1->ToString();
test_ok($string1 eq $string2, 'ToString result is consistent');

print "\n# System::Guid Tests completed: $tests_run\n";
print "# System::Guid Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);