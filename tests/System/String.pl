#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::String');
}

sub test_string_creation {
    my $a = System::String->new("");
    is($a->ToString(), "", "Empty string creation");
    
    $a = System::String->new("abc");
    is($a->ToString(), "abc", "String creation with content");
}

sub test_string_formatting {
    my $a = System::String->new("abc");
    is(String::Format("{0}", $a), "abc", "Basic formatting");
    is(String::Format("{0,-4}", $a), "abc ", "Left-aligned formatting");
    is(String::Format("{0,4}", $a), " abc", "Right-aligned formatting");
}

sub test_string_comparison {
    my $a = System::String->new("abc");
    my $b = System::String->new("abc");
    my $c = System::String->new("def");
    
    ok($a->Equals($b), "String equality");
    ok(!$a->Equals($c), "String inequality");
}

sub test_string_methods {
    my $str = System::String->new("Hello World");
    
    is($str->Length(), 11, "String length");
    ok($str->Contains("World"), "String contains");
    ok(!$str->Contains("xyz"), "String does not contain");
    is($str->IndexOf("World"), 6, "Index of substring");
    is($str->IndexOf("xyz"), -1, "Index of non-existent substring");
    
    ok($str->StartsWith("Hello"), "String starts with");
    ok(!$str->StartsWith("World"), "String does not start with");
    ok($str->EndsWith("World"), "String ends with");
    ok(!$str->EndsWith("Hello"), "String does not end with");
    
    is($str->ToLower()->ToString(), "hello world", "To lower case");
    is($str->ToUpper()->ToString(), "HELLO WORLD", "To upper case");
}

sub test_string_manipulation {
    my $str = System::String->new("Hello World");
    
    is($str->Left(5)->ToString(), "Hello", "Left substring");
    is($str->Right(5)->ToString(), "World", "Right substring");
    is($str->Substring(6)->ToString(), "World", "Substring from position");
    is($str->Substring(0, 5)->ToString(), "Hello", "Substring with length");
    
    is($str->Replace("World", "Universe")->ToString(), "Hello Universe", "String replacement");
    
    my $spaces = System::String->new("  test  ");
    is($spaces->Trim()->ToString(), "test", "Trim whitespace");
    is($spaces->TrimStart()->ToString(), "test  ", "Trim start");
    is($spaces->TrimEnd()->ToString(), "  test", "Trim end");
}

sub test_string_split_join {
    my $str = System::String->new("a,b,c,d");
    my $parts = $str->Split(",");
    is($parts->Length(), 4, "Split into 4 parts");
    is($parts->Get(0)->ToString(), "a", "First part");
    is($parts->Get(3)->ToString(), "d", "Last part");
    
    my $joined = String::Join("-", $parts);
    is($joined->ToString(), "a-b-c-d", "Join with different delimiter");
}

sub test_static_methods {
    ok(String::IsNullOrEmpty(""), "Empty string is null or empty");
    ok(String::IsNullOrEmpty(undef), "Null is null or empty");
    ok(!String::IsNullOrEmpty("test"), "Non-empty string is not null or empty");
    
    ok(String::IsNullOrWhitespace("   "), "Whitespace is null or whitespace");
    ok(!String::IsNullOrWhitespace("test"), "Non-whitespace is not null or whitespace");
}

sub test_string_concatenation {
    my $a = System::String->new("Hello");
    my $b = System::String->new(" World");
    my $result = $a->Concat($b);
    is($result->ToString(), "Hello World", "String concatenation");
    
    my $overloaded = $a + $b;
    is($overloaded->ToString(), "Hello World", "Overloaded + operator");
}

sub test_string_hashing {
    my $a = System::String->new("test");
    my $b = System::String->new("test");
    my $c = System::String->new("different");
    
    is($a->GetHashCode(), $b->GetHashCode(), "Same strings have same hash");
    isnt($a->GetHashCode(), $c->GetHashCode(), "Different strings have different hashes");
}

sub test_missing_methods {
    my $str = System::String->new("Hello World");
    
    # Test LastIndexOf
    is($str->LastIndexOf("l"), 9, "LastIndexOf finds last occurrence");
    is($str->LastIndexOf("xyz"), -1, "LastIndexOf returns -1 for not found");
    
    # Test ToLowerInvariant/ToUpperInvariant
    is($str->ToLowerInvariant()->ToString(), "hello world", "ToLowerInvariant works");
    is($str->ToUpperInvariant()->ToString(), "HELLO WORLD", "ToUpperInvariant works");
    
    # Test PadLeft/PadRight (if not in StringMethodsTest.pl)
    my $short = System::String->new("Hi");
    is($short->PadLeft(5)->ToString(), "   Hi", "PadLeft with spaces");
    is($short->PadLeft(5, "*")->ToString(), "***Hi", "PadLeft with custom char");
    is($short->PadRight(5)->ToString(), "Hi   ", "PadRight with spaces");
    is($short->PadRight(5, "*")->ToString(), "Hi***", "PadRight with custom char");
    
    # Test Remove (if not in StringMethodsTest.pl) 
    is($str->Remove(5)->ToString(), "Hello", "Remove from index");
    is($str->Remove(5, 1)->ToString(), "HelloWorld", "Remove with length");
}

sub test_operator_overloads {
    my $a = System::String->new("Hello");
    my $b = System::String->new("Hello");
    my $c = System::String->new("World");
    
    # Test == and != operators
    ok($a == $b, "== operator works for equal strings");
    ok(!($a == $c), "== operator works for unequal strings");
    ok(!($a != $b), "!= operator works for equal strings");  
    ok($a != $c, "!= operator works for unequal strings");
    
    # Test eq and ne operators
    ok($a eq $b, "eq operator works for equal strings");
    ok(!($a eq $c), "eq operator works for unequal strings");
    ok(!($a ne $b), "ne operator works for equal strings");
    ok($a ne $c, "ne operator works for unequal strings");
    
    # Test cmp operator
    is($a cmp $b, 0, "cmp operator returns 0 for equal strings");
    is($a cmp $c, -1, "cmp operator returns -1 for less than");
    is($c cmp $a, 1, "cmp operator returns 1 for greater than");
}

sub test_error_conditions {
    # Test null reference exceptions
    eval { my $null; $null->ToString(); };
    ok($@, "ToString throws on null reference");
    
    eval { my $null; $null->Length(); };
    ok($@, "Length throws on null reference");
    
    eval { my $null; $null->Contains("test"); };
    ok($@, "Contains throws on null reference");
    
    # Test argument exceptions
    my $str = System::String->new("test");
    eval { $str->Contains({}); }; # Invalid object that can't ToString
    ok($@, "Contains throws on invalid argument");
}

sub test_edge_cases {
    # Empty string tests
    my $empty = System::String->new("");
    is($empty->Length(), 0, "Empty string has zero length");
    ok($empty->StartsWith(""), "Empty string starts with empty");
    ok($empty->EndsWith(""), "Empty string ends with empty");
    is($empty->IndexOf("x"), -1, "IndexOf on empty string returns -1");
    
    # Single character tests
    my $single = System::String->new("A");
    is($single->Length(), 1, "Single char string length");
    ok($single->StartsWith("A"), "Single char starts with itself");
    ok($single->EndsWith("A"), "Single char ends with itself");
    
    # Unicode/special character handling
    my $unicode = System::String->new("Hello\x{00A0}World"); # Non-breaking space
    ok($unicode->Contains("\x{00A0}"), "Contains works with unicode");
}

test_string_creation();
test_string_formatting();
test_string_comparison();
test_string_methods();
test_string_manipulation();
test_string_split_join();
test_static_methods();
test_string_concatenation();
test_string_hashing();
test_missing_methods();
test_operator_overloads();
test_error_conditions();
test_edge_cases();

done_testing();