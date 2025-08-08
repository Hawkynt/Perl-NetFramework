#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Text::StringBuilder;
require System::String;
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

print "1..80\n"; # Comprehensive StringBuilder tests

# Test 1-10: Construction and basic properties
my $sb1 = System::Text::StringBuilder->new();
test_ok(defined($sb1), 'StringBuilder construction without parameters');
test_ok($sb1->isa('System::Text::StringBuilder'), 'StringBuilder isa StringBuilder');
test_ok($sb1->Length() == 0, 'Empty StringBuilder has length 0');
test_ok($sb1->Capacity() == 16, 'Default capacity is 16');
test_ok($sb1->ToString() eq '', 'Empty StringBuilder toString is empty string');

my $sb2 = System::Text::StringBuilder->new("Hello");
test_ok($sb2->Length() == 5, 'StringBuilder with initial value has correct length');
test_ok($sb2->ToString() eq "Hello", 'StringBuilder with initial value has correct content');
test_ok($sb2->Capacity() >= 5, 'StringBuilder capacity is at least initial string length');

my $sb3 = System::Text::StringBuilder->new("", 50);
test_ok($sb3->Capacity() == 50, 'StringBuilder with specified capacity');
test_ok($sb3->MaxCapacity() == 2147483647, 'MaxCapacity is Int32.MaxValue');

# Test 11-20: Append methods
$sb1->Append("World");
test_ok($sb1->ToString() eq "World", 'Append string works');
test_ok($sb1->Length() == 5, 'Length updated after append');

$sb1->Append(123);
test_ok($sb1->ToString() eq "World123", 'Append number works');

$sb1->AppendChar('!', 3);
test_ok($sb1->ToString() eq "World123!!!", 'AppendChar with repeat count works');

$sb1->AppendLine();
test_ok($sb1->ToString() eq "World123!!!\n", 'AppendLine without value adds newline');

$sb1->Clear();
$sb1->AppendLine("Test");
test_ok($sb1->ToString() eq "Test\n", 'AppendLine with value works');

$sb1->Clear();
$sb1->AppendFormat("Hello {0}, you are {1} years old", "John", 25);
test_ok($sb1->ToString() eq "Hello John, you are 25 years old", 'AppendFormat works');

# Test with System::String objects
my $str = System::String->new("SystemString");
$sb1->Clear();
$sb1->Append($str);
test_ok($sb1->ToString() eq "SystemString", 'Append System::String works');

$sb1->Clear();
$sb1->Append("Repeat", 3);
test_ok($sb1->ToString() eq "RepeatRepeatRepeat", 'Append with count parameter works');

# Test 21-30: Insert methods
$sb1->Clear();
$sb1->Append("Hello World");
$sb1->Insert(6, "Beautiful ");
test_ok($sb1->ToString() eq "Hello Beautiful World", 'Insert string works');

$sb1->Insert(0, ">> ");
test_ok($sb1->ToString() eq ">> Hello Beautiful World", 'Insert at beginning works');

$sb1->Insert($sb1->Length(), " <<");
test_ok($sb1->ToString() eq ">> Hello Beautiful World <<", 'Insert at end works');

$sb1->Clear();
$sb1->Append("ABC");
$sb1->Insert(1, "X", 3);
test_ok($sb1->ToString() eq "AXXXBC", 'Insert with count parameter works');

# Test 31-40: Remove methods
$sb1->Clear();
$sb1->Append("Hello World");
$sb1->Remove(5, 6);
test_ok($sb1->ToString() eq "Hello", 'Remove range works');

$sb1->Remove(0, 2);
test_ok($sb1->ToString() eq "llo", 'Remove from beginning works');

$sb1->Append(" World");
$sb1->Remove($sb1->Length() - 2, 2);
test_ok($sb1->ToString() eq "llo Wor", 'Remove from end works');

$sb1->Clear();
test_ok($sb1->Length() == 0 && $sb1->ToString() eq "", 'Clear method works');

# Test 41-50: Replace methods
$sb1->Clear();
$sb1->Append("Hello World Hello");
$sb1->Replace("Hello", "Hi");
test_ok($sb1->ToString() eq "Hi World Hi", 'Replace string works globally');

$sb1->Replace("Hi", "Hello", 0, 8);
test_ok($sb1->ToString() eq "Hello World Hi", 'Replace with range works');

$sb1->ReplaceChar('l', 'L');
test_ok($sb1->ToString() eq "HeLLo WorLd Hi", 'ReplaceChar works globally');

$sb1->ReplaceChar('L', 'l', 0, 5);
test_ok($sb1->ToString() eq "Hello WorLd Hi", 'ReplaceChar with range works');

$sb1->Replace("Hi", "");
test_ok($sb1->ToString() eq "Hello WorLd ", 'Replace with empty string works');

# Test 51-60: Indexer and character access
$sb1->Clear();
$sb1->Append("Hello");
test_ok($sb1->get_Item(0) eq 'H', 'get_Item at index 0 works');
test_ok($sb1->get_Item(4) eq 'o', 'get_Item at last index works');

$sb1->set_Item(1, 'a');
test_ok($sb1->ToString() eq "Hallo", 'set_Item works');

# Test 61-70: Capacity management
$sb1->Clear();
my $initialCapacity = $sb1->Capacity();
$sb1->EnsureCapacity(100);
test_ok($sb1->Capacity() >= 100, 'EnsureCapacity increases capacity');

$sb1->Capacity(50);
test_ok($sb1->Capacity() == 50, 'Setting capacity works');

# Test large append to trigger capacity growth
$sb1->Clear();
my $longString = "x" x 100;
$sb1->Append($longString);
test_ok($sb1->Length() == 100, 'Large append works');
test_ok($sb1->Capacity() >= 100, 'Capacity auto-grows for large append');

# Test 71-80: ToString overloads and edge cases
$sb1->Clear();
$sb1->Append("Hello World");
test_ok($sb1->ToString(0, 5) eq "Hello", 'ToString with range works');
test_ok($sb1->ToString(6, 5) eq "World", 'ToString with different range works');

# Test Equals and GetHashCode
my $sb4 = System::Text::StringBuilder->new("Test");
my $sb5 = System::Text::StringBuilder->new("Test");
my $sb6 = System::Text::StringBuilder->new("Other");
test_ok($sb4->Equals($sb5), 'Equal StringBuilders are equal');
test_ok(!$sb4->Equals($sb6), 'Different StringBuilders are not equal');
test_ok($sb4->GetHashCode() == $sb5->GetHashCode(), 'Equal StringBuilders have same hash');

# Test exception cases
test_exception(
  sub { System::Text::StringBuilder->new("", -1); },
  'ArgumentOutOfRangeException',
  'Negative capacity throws exception'
);

test_exception(
  sub { $sb1->get_Item(-1); },
  'ArgumentOutOfRangeException',
  'Negative index throws exception'
);

test_exception(
  sub { $sb1->get_Item(1000); },
  'ArgumentOutOfRangeException',
  'Index out of bounds throws exception'
);

test_exception(
  sub { $sb1->Insert(-1, "test"); },
  'ArgumentOutOfRangeException',
  'Insert with negative index throws exception'
);

test_exception(
  sub { $sb1->Remove(-1, 5); },
  'ArgumentOutOfRangeException',
  'Remove with negative startIndex throws exception'
);

test_exception(
  sub { $sb1->Remove(0, -1); },
  'ArgumentOutOfRangeException',
  'Remove with negative length throws exception'
);

test_exception(
  sub { $sb1->Replace("", "test"); },
  'ArgumentException',
  'Replace with empty oldValue throws exception'
);

print "\n# StringBuilder Tests completed: $tests_run\n";
print "# StringBuilder Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);