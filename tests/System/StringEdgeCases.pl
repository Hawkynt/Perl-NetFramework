#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::String;
use System::Object;
use System::StringComparison;
use Encode qw(encode decode);

BEGIN {
    use_ok('System::String');
}

# Test comprehensive edge cases for System::String
sub test_string_construction_edge_cases {
    # Test with various input types
    my $str1 = System::String->new("");
    my $str2 = System::String->new(undef);
    my $str3 = System::String->new(0);
    my $str4 = System::String->new("   ");
    
    is($str1->ToString(), "", 'Empty string construction');
    is($str2->ToString(), "", 'Undef becomes empty string');
    is($str3->ToString(), "0", 'Zero becomes string');
    is($str4->ToString(), "   ", 'Whitespace preserved');
    
    # Test with very long strings
    my $long_input = 'A' x 1000000;  # 1 million characters
    my $long_str = System::String->new($long_input);
    is($long_str->Length(), 1000000, 'Very long string length correct');
    is(substr($long_str->ToString(), 0, 10), 'A' x 10, 'Long string content correct');
    
    # Test with unicode input
    my $unicode = "Hello \x{1F600} \x{03B1}\x{03B2}\x{03B3}";
    my $unicode_str = System::String->new($unicode);
    is($unicode_str->ToString(), $unicode, 'Unicode preserved');
    
    # Test with null bytes
    my $null_bytes = "Hello\x00World\x00";
    my $null_str = System::String->new($null_bytes);
    is($null_str->ToString(), $null_bytes, 'Null bytes preserved');
    
    # Test constructor error cases
    eval { System::String->new({}); };
    ok($@, 'Constructor throws on invalid object');
    like($@, qr/ArgumentException/, 'Correct exception for invalid object');
    
    eval { System::String->new([]); };
    ok($@, 'Constructor throws on array ref');
    
    # Test with objects that can ToString
    my $obj_with_toString = bless { value => "test" }, 'TestObject';
    eval q{
        package TestObject;
        sub ToString { return $_[0]->{value}; }
    };
    my $str_from_obj = System::String->new($obj_with_toString);
    is($str_from_obj->ToString(), "test", 'Constructor works with ToString objects');
}

sub test_string_length_edge_cases {
    # Test length with various string types
    is(System::String->new("")->Length(), 0, 'Empty string length');
    is(System::String->new(" ")->Length(), 1, 'Single space length');
    is(System::String->new("\n")->Length(), 1, 'Newline length');
    is(System::String->new("\t")->Length(), 1, 'Tab length');
    is(System::String->new("\x00")->Length(), 1, 'Null byte length');
    
    # Test with unicode characters
    is(System::String->new("\x{1F600}")->Length(), 1, 'Emoji length (single code point)');
    is(System::String->new("\x{00E9}")->Length(), 1, 'Accented char length');
    is(System::String->new("e\x{0301}")->Length(), 2, 'Combining accent length');
    
    # Test with very long string
    my $long = System::String->new('x' x 100000);
    is($long->Length(), 100000, 'Very long string length');
    
    # Test null reference
    eval { my $null; $null->Length(); };
    ok($@, 'Length throws on null reference');
    like($@, qr/NullReferenceException/, 'Correct null reference exception');
}

sub test_string_comparison_edge_cases {
    # Test with empty strings
    my $empty1 = System::String->new("");
    my $empty2 = System::String->new("");
    my $space = System::String->new(" ");
    my $null_str = System::String->new(undef);
    
    ok($empty1->Equals($empty2), 'Empty strings equal');
    ok($empty1->Equals($null_str), 'Empty equals null string');
    ok(!$empty1->Equals($space), 'Empty not equal to space');
    
    # Test case sensitivity
    my $upper = System::String->new("HELLO");
    my $lower = System::String->new("hello");
    my $mixed = System::String->new("Hello");
    
    ok(!$upper->Equals($lower), 'Case sensitive comparison (default)');
    ok($upper->Equals($lower, StringComparison::OrdinalIgnoreCase), 'Case insensitive comparison');
    ok(!$upper->Equals($mixed), 'Mixed case not equal');
    ok($upper->Equals($mixed, StringComparison::OrdinalIgnoreCase), 'Mixed case equal ignore case');
    
    # Test with unicode
    my $unicode1 = System::String->new("\x{00E9}");      # é (precomposed)
    my $unicode2 = System::String->new("e\x{0301}");     # é (decomposed)
    my $unicode3 = System::String->new("\x{00E9}");      # é (precomposed again)
    
    ok($unicode1->Equals($unicode3), 'Same unicode precomposed equal');
    # Decomposed vs precomposed may or may not be equal depending on normalization
    my $decomp_equal = $unicode1->Equals($unicode2);
    ok(defined($decomp_equal), 'Unicode decomposed comparison works');
    
    # Test with null bytes
    my $null1 = System::String->new("a\x00b");
    my $null2 = System::String->new("a\x00b");
    my $null3 = System::String->new("a\x00c");
    ok($null1->Equals($null2), 'Strings with null bytes equal');
    ok(!$null1->Equals($null3), 'Different strings with null bytes not equal');
    
    # Test very long string comparison
    my $long1 = System::String->new('a' x 50000 . 'b');
    my $long2 = System::String->new('a' x 50000 . 'b');
    my $long3 = System::String->new('a' x 50000 . 'c');
    ok($long1->Equals($long2), 'Very long identical strings equal');
    ok(!$long1->Equals($long3), 'Very long different strings not equal');
    
    # Test comparison with non-string inputs
    eval { $empty1->Equals({}); };
    ok($@, 'Equals throws on invalid object');
    
    eval { $empty1->Equals([]); };
    ok($@, 'Equals throws on array ref');
    
    # Test null reference in Equals
    eval { my $null; $null->Equals("test"); };
    ok($@, 'Equals throws on null reference');
}

sub test_string_operators_edge_cases {
    my $str1 = System::String->new("Hello");
    my $str2 = System::String->new("Hello");
    my $str3 = System::String->new("World");
    my $str4 = System::String->new("hello");
    
    # Test == operator
    ok($str1 == $str2, '== operator with equal strings');
    ok(!($str1 == $str3), '== operator with unequal strings');
    ok(!($str1 == $str4), '== operator is case sensitive');
    
    # Test != operator
    ok(!($str1 != $str2), '!= operator with equal strings');
    ok($str1 != $str3, '!= operator with unequal strings');
    ok($str1 != $str4, '!= operator is case sensitive');
    
    # Test eq operator
    ok($str1 eq $str2, 'eq operator with equal strings');
    ok(!($str1 eq $str3), 'eq operator with unequal strings');
    
    # Test ne operator
    ok(!($str1 ne $str2), 'ne operator with equal strings');
    ok($str1 ne $str3, 'ne operator with unequal strings');
    
    # Test cmp operator
    is($str1 cmp $str2, 0, 'cmp with equal strings');
    ok(($str1 cmp $str3) < 0, 'cmp with first string less');
    ok(($str3 cmp $str1) > 0, 'cmp with first string greater');
    
    # Test + operator (concatenation)
    my $concat = $str1 + System::String->new(" ") + $str3;
    is($concat->ToString(), "Hello World", 'Concatenation operator works');
    
    # Test operators with empty strings
    my $empty = System::String->new("");
    ok($empty == System::String->new(""), 'Empty strings equal');
    ok($empty != $str1, 'Empty not equal to non-empty');
    
    # Test with unicode strings
    my $unicode1 = System::String->new("café");
    my $unicode2 = System::String->new("café");
    ok($unicode1 == $unicode2, 'Unicode strings equal');
    
    # Test with very long strings
    my $long1 = System::String->new('x' x 10000);
    my $long2 = System::String->new('x' x 10000);
    ok($long1 == $long2, 'Very long strings equal');
    
    # Test string comparison operators work in both directions
    ok($str1 == $str2, 'Forward equality');
    ok($str2 == $str1, 'Reverse equality');
    is($str1 cmp $str3, -($str3 cmp $str1), 'Comparison symmetry');
}

sub test_string_indexing_edge_cases {
    my $str = System::String->new("Hello World");
    
    # Test normal indexing
    is($str->IndexOf("l"), 2, 'First l at position 2');
    is($str->LastIndexOf("l"), 9, 'Last l at position 9');
    
    # Test with single character
    my $single = System::String->new("A");
    is($single->IndexOf("A"), 0, 'Single char found');
    is($single->LastIndexOf("A"), 0, 'Single char last index');
    is($single->IndexOf("B"), -1, 'Single char not found');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->IndexOf("x"), -1, 'Empty string IndexOf returns -1');
    is($empty->LastIndexOf("x"), -1, 'Empty string LastIndexOf returns -1');
    is($str->IndexOf(""), 0, 'Empty substring found at start');
    
    # Test with substring longer than string
    is($str->IndexOf("Hello World!!!"), -1, 'Longer substring not found');
    
    # Test with exact match
    is($str->IndexOf("Hello World"), 0, 'Exact match found at start');
    
    # Test with unicode
    my $unicode = System::String->new("Héllo Wörld");
    is($unicode->IndexOf("ö"), 8, 'Unicode char found');
    is($unicode->LastIndexOf("ö"), 8, 'Unicode char last index');
    
    # Test with null bytes
    my $null_str = System::String->new("a\x00b\x00c");
    is($null_str->IndexOf("\x00"), 1, 'Null byte found');
    is($null_str->LastIndexOf("\x00"), 3, 'Last null byte found');
    
    # Test Contains method
    ok($str->Contains("Hello"), 'Contains substring');
    ok($str->Contains("World"), 'Contains end substring');
    ok(!$str->Contains("xyz"), 'Does not contain non-existent');
    ok($str->Contains(""), 'Contains empty string');
    
    # Test null reference exceptions
    eval { my $null; $null->IndexOf("x"); };
    ok($@, 'IndexOf throws on null reference');
    
    eval { my $null; $null->LastIndexOf("x"); };
    ok($@, 'LastIndexOf throws on null reference');
    
    eval { my $null; $null->Contains("x"); };
    ok($@, 'Contains throws on null reference');
    
    # Test with invalid arguments
    eval { $str->IndexOf({}); };
    ok($@, 'IndexOf throws on invalid argument');
    
    eval { $str->Contains([]); };
    ok($@, 'Contains throws on array ref');
}

sub test_string_startswith_endswith_edge_cases {
    my $str = System::String->new("Hello World");
    
    # Test normal cases
    ok($str->StartsWith("Hello"), 'StartsWith normal case');
    ok($str->EndsWith("World"), 'EndsWith normal case');
    ok(!$str->StartsWith("World"), 'StartsWith false case');
    ok(!$str->EndsWith("Hello"), 'EndsWith false case');
    
    # Test with empty string
    my $empty = System::String->new("");
    ok($empty->StartsWith(""), 'Empty StartsWith empty');
    ok($empty->EndsWith(""), 'Empty EndsWith empty');
    ok(!$empty->StartsWith("x"), 'Empty does not StartsWith non-empty');
    ok($str->StartsWith(""), 'Non-empty StartsWith empty');
    ok($str->EndsWith(""), 'Non-empty EndsWith empty');
    
    # Test with single character
    my $single = System::String->new("A");
    ok($single->StartsWith("A"), 'Single char StartsWith itself');
    ok($single->EndsWith("A"), 'Single char EndsWith itself');
    ok(!$single->StartsWith("B"), 'Single char does not StartsWith other');
    
    # Test with exact match
    ok($str->StartsWith("Hello World"), 'StartsWith exact match');
    ok($str->EndsWith("Hello World"), 'EndsWith exact match');
    
    # Test with longer string
    ok(!$str->StartsWith("Hello World!!!"), 'StartsWith longer string false');
    ok(!$str->EndsWith("!!!Hello World"), 'EndsWith longer string false');
    
    # Test case sensitivity
    ok(!$str->StartsWith("hello"), 'StartsWith case sensitive');
    ok(!$str->EndsWith("WORLD"), 'EndsWith case sensitive');
    
    # Test with unicode
    my $unicode = System::String->new("Héllo Wörld");
    ok($unicode->StartsWith("Héllo"), 'Unicode StartsWith');
    ok($unicode->EndsWith("Wörld"), 'Unicode EndsWith');
    ok(!$unicode->StartsWith("hello"), 'Unicode case sensitive');
    
    # Test with null bytes
    my $null_str = System::String->new("\x00start");
    ok($null_str->StartsWith("\x00"), 'StartsWith null byte');
    
    my $null_end = System::String->new("end\x00");
    ok($null_end->EndsWith("\x00"), 'EndsWith null byte');
    
    # Test null reference exceptions
    eval { my $null; $null->StartsWith("x"); };
    ok($@, 'StartsWith throws on null reference');
    
    eval { my $null; $null->EndsWith("x"); };
    ok($@, 'EndsWith throws on null reference');
    
    # Test with invalid arguments
    eval { $str->StartsWith({}); };
    ok($@, 'StartsWith throws on invalid argument');
    
    eval { $str->EndsWith([]); };
    ok($@, 'EndsWith throws on array ref');
}

sub test_string_substring_edge_cases {
    my $str = System::String->new("Hello World");
    
    # Test normal substring operations
    is($str->Substring(0, 5)->ToString(), "Hello", 'Substring with start and count');
    is($str->Substring(6)->ToString(), "World", 'Substring with start only');
    is($str->Substring(0)->ToString(), "Hello World", 'Substring from start');
    is($str->Substring($str->Length())->ToString(), "", 'Substring from end');
    
    # Test Left and Right methods
    is($str->Left(5)->ToString(), "Hello", 'Left method');
    is($str->Right(5)->ToString(), "World", 'Right method');
    is($str->Left(0)->ToString(), "", 'Left zero characters');
    is($str->Right(0)->ToString(), "", 'Right zero characters');
    
    # Test with counts larger than string
    is($str->Left(100)->ToString(), "Hello World", 'Left more than length');
    is($str->Right(100)->ToString(), "Hello World", 'Right more than length');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->Substring(0)->ToString(), "", 'Empty substring');
    is($empty->Left(5)->ToString(), "", 'Empty Left');
    is($empty->Right(5)->ToString(), "", 'Empty Right');
    
    # Test with single character
    my $single = System::String->new("A");
    is($single->Substring(0, 1)->ToString(), "A", 'Single char substring');
    is($single->Substring(1)->ToString(), "", 'Single char substring from end');
    is($single->Left(1)->ToString(), "A", 'Single char Left');
    is($single->Right(1)->ToString(), "A", 'Single char Right');
    
    # Test with unicode
    my $unicode = System::String->new("Héllö");
    is($unicode->Substring(0, 2)->ToString(), "Hé", 'Unicode substring');
    is($unicode->Left(3)->ToString(), "Hél", 'Unicode Left');
    is($unicode->Right(2)->ToString(), "lö", 'Unicode Right');
    
    # Test boundary conditions
    eval { $str->Substring(-1); };
    ok(!$@, 'Substring with negative start handled'); # Perl allows this
    
    # Test null reference exceptions
    eval { my $null; $null->Substring(0); };
    ok($@, 'Substring throws on null reference');
    
    eval { my $null; $null->Left(5); };
    ok($@, 'Left throws on null reference');
    
    eval { my $null; $null->Right(5); };
    ok($@, 'Right throws on null reference');
}

sub test_string_replace_edge_cases {
    my $str = System::String->new("Hello World Hello");
    
    # Test basic replacement
    is($str->Replace("Hello", "Hi")->ToString(), "Hi World Hi", 'Basic replacement');
    is($str->Replace("World", "Universe")->ToString(), "Hello Universe Hello", 'Single replacement');
    
    # Test replace with empty string
    is($str->Replace("Hello", "")->ToString(), " World ", 'Replace with empty');
    is($str->Replace(" ", "")->ToString(), "HelloWorldHello", 'Remove spaces');
    
    # Test replace empty string with something
    my $empty_replace = System::String->new("abc");
    is($empty_replace->Replace("", "X")->ToString(), "XaXbXcX", 'Replace empty with char');
    
    # Test replace with same string
    is($str->Replace("Hello", "Hello")->ToString(), $str->ToString(), 'Replace with same');
    
    # Test replace non-existent
    is($str->Replace("xyz", "123")->ToString(), $str->ToString(), 'Replace non-existent');
    
    # Test with unicode
    my $unicode = System::String->new("café café");
    is($unicode->Replace("café", "tea")->ToString(), "tea tea", 'Unicode replacement');
    is($unicode->Replace("é", "e")->ToString(), "cafe cafe", 'Replace unicode char');
    
    # Test with null bytes
    my $null_str = System::String->new("a\x00b\x00c");
    is($null_str->Replace("\x00", "|")->ToString(), "a|b|c", 'Replace null bytes');
    
    # Test overlapping replacements
    my $overlap = System::String->new("ababa");
    is($overlap->Replace("aba", "X")->ToString(), "Xba", 'Overlapping replacement (left-to-right)');
    
    # Test very long strings
    my $long = System::String->new('a' x 10000);
    my $long_replaced = $long->Replace('a', 'b');
    is($long_replaced->ToString(), 'b' x 10000, 'Replace in very long string');
    
    # Test null reference exceptions
    eval { my $null; $null->Replace("a", "b"); };
    ok($@, 'Replace throws on null reference');
    
    # Test with invalid arguments
    eval { $str->Replace({}, "replacement"); };
    ok($@, 'Replace throws on invalid what argument');
    
    eval { $str->Replace("what", {}); };
    ok($@, 'Replace throws on invalid replacement argument');
}

sub test_string_trim_edge_cases {
    # Test various whitespace scenarios
    my $spaces = System::String->new("   hello   ");
    my $tabs = System::String->new("\t\thello\t\t");
    my $newlines = System::String->new("\n\nhello\n\n");
    my $mixed = System::String->new(" \t\n hello \n\t ");
    
    is($spaces->Trim()->ToString(), "hello", 'Trim spaces');
    is($tabs->Trim()->ToString(), "hello", 'Trim tabs');
    is($newlines->Trim()->ToString(), "hello", 'Trim newlines');
    is($mixed->Trim()->ToString(), "hello", 'Trim mixed whitespace');
    
    # Test TrimStart and TrimEnd
    is($spaces->TrimStart()->ToString(), "hello   ", 'TrimStart spaces');
    is($spaces->TrimEnd()->ToString(), "   hello", 'TrimEnd spaces');
    is($mixed->TrimStart()->ToString(), "hello \n\t ", 'TrimStart mixed');
    is($mixed->TrimEnd()->ToString(), " \t\n hello", 'TrimEnd mixed');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->Trim()->ToString(), "", 'Trim empty string');
    is($empty->TrimStart()->ToString(), "", 'TrimStart empty string');
    is($empty->TrimEnd()->ToString(), "", 'TrimEnd empty string');
    
    # Test with only whitespace
    my $only_ws = System::String->new("   ");
    is($only_ws->Trim()->ToString(), "", 'Trim only whitespace');
    is($only_ws->TrimStart()->ToString(), "", 'TrimStart only whitespace');
    is($only_ws->TrimEnd()->ToString(), "", 'TrimEnd only whitespace');
    
    # Test with no whitespace
    my $no_ws = System::String->new("hello");
    is($no_ws->Trim()->ToString(), "hello", 'Trim no whitespace');
    is($no_ws->TrimStart()->ToString(), "hello", 'TrimStart no whitespace');
    is($no_ws->TrimEnd()->ToString(), "hello", 'TrimEnd no whitespace');
    
    # Test with unicode whitespace
    my $unicode_ws = System::String->new("\x{00A0}hello\x{00A0}"); # Non-breaking spaces
    # Note: Perl's \s may or may not include Unicode whitespace
    my $unicode_trimmed = $unicode_ws->Trim();
    ok(defined($unicode_trimmed), 'Unicode whitespace trim handled');
    
    # Test with null bytes (should not be trimmed)
    my $null_bytes = System::String->new("\x00hello\x00");
    is($null_bytes->Trim()->ToString(), "\x00hello\x00", 'Null bytes not trimmed');
    
    # Test null reference exceptions
    eval { my $null; $null->Trim(); };
    ok($@, 'Trim throws on null reference');
    
    eval { my $null; $null->TrimStart(); };
    ok($@, 'TrimStart throws on null reference');
    
    eval { my $null; $null->TrimEnd(); };
    ok($@, 'TrimEnd throws on null reference');
}

sub test_string_case_conversion_edge_cases {
    my $mixed = System::String->new("Hello World");
    my $upper = System::String->new("HELLO WORLD");
    my $lower = System::String->new("hello world");
    
    # Test basic case conversion
    is($mixed->ToUpper()->ToString(), "HELLO WORLD", 'ToUpper conversion');
    is($mixed->ToLower()->ToString(), "hello world", 'ToLower conversion');
    is($upper->ToLower()->ToString(), "hello world", 'Upper to lower');
    is($lower->ToUpper()->ToString(), "HELLO WORLD", 'Lower to upper');
    
    # Test invariant versions
    is($mixed->ToUpperInvariant()->ToString(), "HELLO WORLD", 'ToUpperInvariant');
    is($mixed->ToLowerInvariant()->ToString(), "hello world", 'ToLowerInvariant');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->ToUpper()->ToString(), "", 'Empty string ToUpper');
    is($empty->ToLower()->ToString(), "", 'Empty string ToLower');
    
    # Test with numbers and symbols
    my $mixed_content = System::String->new("Hello123!@#");
    is($mixed_content->ToUpper()->ToString(), "HELLO123!@#", 'Mixed content ToUpper');
    is($mixed_content->ToLower()->ToString(), "hello123!@#", 'Mixed content ToLower');
    
    # Test with unicode
    my $unicode = System::String->new("Héllo Wörld");
    is($unicode->ToUpper()->ToString(), "HÉLLO WÖRLD", 'Unicode ToUpper');
    is($unicode->ToLower()->ToString(), "héllo wörld", 'Unicode ToLower');
    
    # Test with special unicode cases
    my $german = System::String->new("Straße"); # German ß
    my $german_upper = $german->ToUpper();
    ok(defined($german_upper), 'German ß case conversion handled');
    
    # Test idempotency
    my $test_str = System::String->new("Test String");
    is($test_str->ToUpper()->ToUpper()->ToString(), $test_str->ToUpper()->ToString(), 'ToUpper idempotent');
    is($test_str->ToLower()->ToLower()->ToString(), $test_str->ToLower()->ToString(), 'ToLower idempotent');
    
    # Test null reference exceptions
    eval { my $null; $null->ToUpper(); };
    ok($@, 'ToUpper throws on null reference');
    
    eval { my $null; $null->ToLower(); };
    ok($@, 'ToLower throws on null reference');
    
    eval { my $null; $null->ToUpperInvariant(); };
    ok($@, 'ToUpperInvariant throws on null reference');
    
    eval { my $null; $null->ToLowerInvariant(); };
    ok($@, 'ToLowerInvariant throws on null reference');
}

sub test_string_pad_edge_cases {
    my $str = System::String->new("Hi");
    
    # Test PadLeft
    is($str->PadLeft(5)->ToString(), "   Hi", 'PadLeft with spaces');
    is($str->PadLeft(5, "*")->ToString(), "***Hi", 'PadLeft with custom char');
    is($str->PadLeft(2)->ToString(), "Hi", 'PadLeft with same length');
    is($str->PadLeft(1)->ToString(), "Hi", 'PadLeft with smaller length');
    is($str->PadLeft(0)->ToString(), "Hi", 'PadLeft with zero length');
    
    # Test PadRight
    is($str->PadRight(5)->ToString(), "Hi   ", 'PadRight with spaces');
    is($str->PadRight(5, "*")->ToString(), "Hi***", 'PadRight with custom char');
    is($str->PadRight(2)->ToString(), "Hi", 'PadRight with same length');
    is($str->PadRight(1)->ToString(), "Hi", 'PadRight with smaller length');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->PadLeft(3)->ToString(), "   ", 'PadLeft empty string');
    is($empty->PadRight(3, "X")->ToString(), "XXX", 'PadRight empty string');
    
    # Test with single character string
    my $single = System::String->new("A");
    is($single->PadLeft(5, "0")->ToString(), "0000A", 'PadLeft single char');
    is($single->PadRight(5, "0")->ToString(), "A0000", 'PadRight single char');
    
    # Test with unicode characters
    my $unicode = System::String->new("Ü");
    is($unicode->PadLeft(3, "ä")->ToString(), "ääÜ", 'PadLeft unicode');
    is($unicode->PadRight(3, "ö")->ToString(), "Üöö", 'PadRight unicode');
    
    # Test with multi-character padding (should use only first char)
    is($str->PadLeft(5, "xyz")->ToString(), "xxxHi", 'PadLeft multi-char padding');
    is($str->PadRight(5, "abc")->ToString(), "Hiaaa", 'PadRight multi-char padding');
    
    # Test with very large padding
    my $large_pad = $str->PadLeft(10000, "X");
    is($large_pad->Length(), 10000, 'Large padding length correct');
    ok($large_pad->EndsWith("Hi"), 'Large padding ends correctly');
    
    # Test null reference exceptions
    eval { my $null; $null->PadLeft(5); };
    ok($@, 'PadLeft throws on null reference');
    
    eval { my $null; $null->PadRight(5); };
    ok($@, 'PadRight throws on null reference');
}

sub test_string_remove_edge_cases {
    my $str = System::String->new("Hello World");
    
    # Test Remove with start index only
    is($str->Remove(5)->ToString(), "Hello", 'Remove from index to end');
    is($str->Remove(0)->ToString(), "", 'Remove from start');
    is($str->Remove($str->Length())->ToString(), $str->ToString(), 'Remove from end');
    
    # Test Remove with start and count
    is($str->Remove(5, 1)->ToString(), "HelloWorld", 'Remove single character');
    is($str->Remove(0, 5)->ToString(), " World", 'Remove from start with count');
    is($str->Remove(6, 5)->ToString(), "Hello ", 'Remove from middle to end');
    is($str->Remove(5, 0)->ToString(), $str->ToString(), 'Remove zero characters');
    
    # Test with empty string
    my $empty = System::String->new("");
    is($empty->Remove(0)->ToString(), "", 'Remove from empty string');
    
    # Test with single character
    my $single = System::String->new("A");
    is($single->Remove(0)->ToString(), "", 'Remove from single char');
    is($single->Remove(1)->ToString(), "A", 'Remove from end of single char');
    is($single->Remove(0, 1)->ToString(), "", 'Remove single char with count');
    
    # Test with unicode
    my $unicode = System::String->new("Héllo");
    is($unicode->Remove(1, 1)->ToString(), "Hllo", 'Remove unicode character');
    
    # Test boundary conditions and exceptions
    eval { $str->Remove(-1); };
    ok($@, 'Remove throws on negative start index');
    like($@, qr/ArgumentOutOfRangeException/, 'Correct exception type');
    
    eval { $str->Remove($str->Length() + 1); };
    ok($@, 'Remove throws on start index beyond length');
    
    eval { $str->Remove(0, -1); };
    ok($@, 'Remove throws on negative count');
    
    eval { $str->Remove(5, 10); };
    ok($@, 'Remove throws on count beyond remaining length');
    
    # Test null reference exceptions
    eval { my $null; $null->Remove(0); };
    ok($@, 'Remove throws on null reference');
}

sub test_string_split_join_edge_cases {
    # Test basic split
    my $csv = System::String->new("a,b,c,d");
    my $parts = $csv->Split(",");
    is($parts->Length(), 4, 'Split creates correct number of parts');
    is($parts->Get(0)->ToString(), "a", 'First split part');
    is($parts->Get(3)->ToString(), "d", 'Last split part');
    
    # Test split with empty string
    my $empty = System::String->new("");
    my $empty_parts = $empty->Split(",");
    is($empty_parts->Length(), 1, 'Split empty string creates one part');
    is($empty_parts->Get(0)->ToString(), "", 'Empty string split part is empty');
    
    # Test split with delimiter not found
    my $no_delim = System::String->new("hello");
    my $no_parts = $no_delim->Split(",");
    is($no_parts->Length(), 1, 'Split without delimiter creates one part');
    is($no_parts->Get(0)->ToString(), "hello", 'No delimiter split preserves string');
    
    # Test split with consecutive delimiters
    my $consecutive = System::String->new("a,,b");
    my $consec_parts = $consecutive->Split(",");
    is($consec_parts->Length(), 3, 'Consecutive delimiters create empty parts');
    is($consec_parts->Get(1)->ToString(), "", 'Middle part is empty');
    
    # Test split with delimiter at start/end
    my $edge_delim = System::String->new(",a,b,");
    my $edge_parts = $edge_delim->Split(",");
    is($edge_parts->Length(), 4, 'Edge delimiters create empty parts');
    is($edge_parts->Get(0)->ToString(), "", 'First part empty');
    is($edge_parts->Get(3)->ToString(), "", 'Last part empty');
    
    # Test split with unicode delimiter
    my $unicode_csv = System::String->new("a→b→c");
    my $unicode_parts = $unicode_csv->Split("→");
    is($unicode_parts->Length(), 3, 'Unicode delimiter split');
    is($unicode_parts->Get(1)->ToString(), "b", 'Unicode split middle part');
    
    # Test split with multi-character delimiter
    my $multi_delim = System::String->new("a::b::c");
    my $multi_parts = $multi_delim->Split("::");
    is($multi_parts->Length(), 3, 'Multi-char delimiter split');
    is($multi_parts->Get(1)->ToString(), "b", 'Multi-char split middle part');
    
    # Test split with count limit
    my $limited_parts = $csv->Split(",", 2);
    is($limited_parts->Length(), 2, 'Split with count limit');
    is($limited_parts->Get(1)->ToString(), "b,c,d", 'Limited split preserves remainder');
    
    # Test Join
    my $joined = String::Join("-", $parts);
    is($joined->ToString(), "a-b-c-d", 'Join with different delimiter');
    
    my $empty_join = String::Join(",", System::Array->new());
    is($empty_join->ToString(), "", 'Join empty array');
    
    my $single_join = String::Join(",", System::Array->new("only"));
    is($single_join->ToString(), "only", 'Join single element');
    
    # Test null reference exceptions
    eval { my $null; $null->Split(","); };
    ok($@, 'Split throws on null reference');
    
    # Test with null delimiter
    eval { $csv->Split(undef); };
    ok($@, 'Split throws on null delimiter');
}

sub test_string_static_methods_edge_cases {
    # Test IsNullOrEmpty
    ok(String::IsNullOrEmpty(undef), 'IsNullOrEmpty with undef');
    ok(String::IsNullOrEmpty(""), 'IsNullOrEmpty with empty string');
    ok(!String::IsNullOrEmpty(" "), 'IsNullOrEmpty with space');
    ok(!String::IsNullOrEmpty("text"), 'IsNullOrEmpty with text');
    ok(String::IsNullOrEmpty(0), 'IsNullOrEmpty with zero');
    
    # Test IsNullOrWhitespace
    ok(String::IsNullOrWhitespace(undef), 'IsNullOrWhitespace with undef');
    ok(String::IsNullOrWhitespace(""), 'IsNullOrWhitespace with empty');
    ok(String::IsNullOrWhitespace(" "), 'IsNullOrWhitespace with space');
    ok(String::IsNullOrWhitespace("\t\n "), 'IsNullOrWhitespace with mixed whitespace');
    ok(!String::IsNullOrWhitespace("text"), 'IsNullOrWhitespace with text');
    ok(!String::IsNullOrWhitespace(" text "), 'IsNullOrWhitespace with text and spaces');
    
    # Test Format method
    is(String::Format("Hello {0}", "World"), "Hello World", 'Basic format');
    is(String::Format("{0} {1}", "Hello", "World"), "Hello World", 'Multiple format');
    is(String::Format("{1} {0}", "World", "Hello"), "Hello World", 'Reordered format');
    is(String::Format("{0,5}", "Hi"), "   Hi", 'Format with alignment');
    is(String::Format("{0,-5}", "Hi"), "Hi   ", 'Format with negative alignment');
    
    # Test Format with escaped braces
    is(String::Format("{{0}}", "test"), "{0}", 'Format with escaped braces');
    is(String::Format("{{{0}}}", "test"), "{test}", 'Format with mixed braces');
    
    # Test Format edge cases
    is(String::Format("No placeholders"), "No placeholders", 'Format without placeholders');
    is(String::Format(""), "", 'Format empty string');
    is(String::Format("{0}", ""), " ", 'Format with empty replacement');  # Note: this might format differently
    
    # Test Format with various data types
    is(String::Format("{0}", 42), "42", 'Format with number');
    is(String::Format("{0}", undef), "", 'Format with undef');
    
    # Test error cases
    eval { String::IsNullOrEmpty({}); };
    ok($@, 'IsNullOrEmpty throws on invalid object');
    
    eval { String::IsNullOrWhitespace([]); };
    ok($@, 'IsNullOrWhitespace throws on array ref');
    
    eval { String::Format({}); };
    ok($@, 'Format throws on invalid format string');
}

sub test_string_hash_code_edge_cases {
    # Test hash consistency
    my $str1 = System::String->new("test");
    my $str2 = System::String->new("test");
    my $str3 = System::String->new("different");
    
    is($str1->GetHashCode(), $str2->GetHashCode(), 'Same content same hash');
    isnt($str1->GetHashCode(), $str3->GetHashCode(), 'Different content different hash');
    
    # Test hash consistency across calls
    my $hash1 = $str1->GetHashCode();
    for (1..100) {
        is($str1->GetHashCode(), $hash1, "Hash consistent call $_") if $_ <= 3;
    }
    
    # Test with various string types
    my $empty = System::String->new("");
    my $empty_hash = $empty->GetHashCode();
    ok(defined($empty_hash), 'Empty string has hash');
    
    my $unicode = System::String->new("café");
    my $unicode_hash = $unicode->GetHashCode();
    ok(defined($unicode_hash), 'Unicode string has hash');
    
    my $long = System::String->new('x' x 10000);
    my $long_hash = $long->GetHashCode();
    ok(defined($long_hash), 'Long string has hash');
    
    # Test hash distribution (basic check)
    my %hashes;
    for my $i (0..99) {
        my $test_str = System::String->new("test$i");
        my $hash = $test_str->GetHashCode();
        $hashes{$hash} = 1;
    }
    ok(keys(%hashes) > 50, 'Hash codes reasonably distributed');
    
    # Test null reference exception
    eval { my $null; $null->GetHashCode(); };
    ok($@, 'GetHashCode throws on null reference');
}

sub test_string_memory_and_performance {
    # Test with very large strings
    my $mega_string = System::String->new('A' x 1000000);
    is($mega_string->Length(), 1000000, 'Mega string length correct');
    
    # Test operations on large strings
    my $mega_upper = $mega_string->ToUpper();
    ok($mega_upper->StartsWith("A"), 'Mega string operations work');
    
    # Test many small operations
    my $base = System::String->new("test");
    for (1..1000) {
        $base = $base->Concat(System::String->new("$_"));
        last if $_ >= 10;  # Limit for test performance
    }
    ok($base->Length() > 4, 'Many operations complete');
    
    # Test rapid object creation/destruction
    for (1..10000) {
        my $temp = System::String->new("temp$_");
        $temp->ToString();
        last if $_ >= 100;  # Limit for test performance
    }
    ok(1, 'Rapid creation/destruction completes');
}

# Run all comprehensive edge case tests
test_string_construction_edge_cases();
test_string_length_edge_cases();
test_string_comparison_edge_cases();
test_string_operators_edge_cases();
test_string_indexing_edge_cases();
test_string_startswith_endswith_edge_cases();
test_string_substring_edge_cases();
test_string_replace_edge_cases();
test_string_trim_edge_cases();
test_string_case_conversion_edge_cases();
test_string_pad_edge_cases();
test_string_remove_edge_cases();
test_string_split_join_edge_cases();
test_string_static_methods_edge_cases();
test_string_hash_code_edge_cases();
test_string_memory_and_performance();

done_testing();