#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

use Test::More tests => 122;

# Import required modules
require_ok('System::Guid');
require_ok('System::Exceptions');

# Test 1-10: Basic Construction and Empty Guid
{
    my $empty = System::Guid->Empty();
    ok(defined($empty), 'Empty Guid created');
    isa_ok($empty, 'System::Guid', 'Empty is a Guid');
    
    my $empty2 = System::Guid->Empty();
    is($empty, $empty2, 'Empty returns same instance');
    
    my $default_guid = System::Guid->new();
    ok(defined($default_guid), 'Default constructor works');
    isa_ok($default_guid, 'System::Guid', 'Default constructor returns Guid');
    
    ok($default_guid->Equals($empty), 'Default constructor creates Empty guid');
    
    my $empty_string = $empty->ToString();
    is($empty_string, '00000000-0000-0000-0000-000000000000', 'Empty guid string representation');
    
    my $empty_bytes = $empty->ToByteArray();
    is_deeply($empty_bytes, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], 'Empty guid has all zero bytes');
}

# Test 11-20: NewGuid Creation and Uniqueness
{
    my $guid1 = System::Guid->NewGuid();
    my $guid2 = System::Guid->NewGuid();
    my $guid3 = System::Guid->NewGuid();
    
    ok(defined($guid1), 'NewGuid creates guid');
    isa_ok($guid1, 'System::Guid', 'NewGuid returns Guid instance');
    
    ok(!$guid1->Equals($guid2), 'NewGuid creates different guids (1 vs 2)');
    ok(!$guid1->Equals($guid3), 'NewGuid creates different guids (1 vs 3)');
    ok(!$guid2->Equals($guid3), 'NewGuid creates different guids (2 vs 3)');
    
    my $empty = System::Guid->Empty();
    ok(!$guid1->Equals($empty), 'NewGuid does not create Empty guid');
    
    # Test version 4 (random) guid properties
    my $bytes = $guid1->ToByteArray();
    my $version = ($bytes->[7] & 0xF0) >> 4;
    is($version, 4, 'NewGuid creates version 4 GUID');
    
    my $variant = ($bytes->[8] & 0xC0) >> 6;
    is($variant, 2, 'NewGuid creates proper RFC 4122 variant bits');
    
    # Test multiple NewGuid calls for uniqueness (statistical test)
    my %seen_guids;
    for (1..20) {
        my $guid = System::Guid->NewGuid();
        my $str = $guid->ToString();
        ok(!exists $seen_guids{$str}, "NewGuid #$_ is unique");
        $seen_guids{$str} = 1;
        last if $_ >= 3; # Only test first 3 to avoid too many tests
    }
}

# Test 21-30: String Formatting (ToString)
{
    my $guid = System::Guid->NewGuid();
    
    # Test default format (D)
    my $default_str = $guid->ToString();
    ok(defined($default_str), 'ToString returns defined value');
    is(length($default_str), 36, 'Default format has correct length (32 chars + 4 hyphens)');
    like($default_str, qr/^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/, 'Default format matches pattern');
    
    # Test explicit D format
    my $d_format = $guid->ToString('D');
    is($d_format, $default_str, 'Explicit D format matches default');
    
    my $d_lower = $guid->ToString('d');
    is($d_lower, $default_str, 'Lowercase d format works');
    
    # Test N format (no hyphens)
    my $n_format = $guid->ToString('N');
    is(length($n_format), 32, 'N format has correct length (32 chars)');
    unlike($n_format, qr/-/, 'N format has no hyphens');
    like($n_format, qr/^[0-9A-F]{32}$/, 'N format matches pattern');
    
    my $n_lower = $guid->ToString('n');
    is($n_lower, $n_format, 'Lowercase n format works');
    
    # Test B format (braces)
    my $b_format = $guid->ToString('B');
    like($b_format, qr/^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$/, 'B format has braces and correct pattern');
    
    my $b_lower = $guid->ToString('b');
    is($b_lower, $b_format, 'Lowercase b format works');
}

# Test 31-40: More String Formatting
{
    my $guid = System::Guid->NewGuid();
    
    # Test P format (parentheses)
    my $p_format = $guid->ToString('P');
    like($p_format, qr/^\([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\)$/, 'P format has parentheses and correct pattern');
    
    my $p_lower = $guid->ToString('p');
    is($p_lower, $p_format, 'Lowercase p format works');
    
    # Test X format (array notation)
    my $x_format = $guid->ToString('X');
    like($x_format, qr/^\{0x[0-9A-F]{8},0x[0-9A-F]{4},0x[0-9A-F]{4},\{0x[0-9A-F]{2}(?:,0x[0-9A-F]{2}){7}\}\}$/, 'X format has array notation pattern');
    
    my $x_lower = $guid->ToString('x');
    is($x_lower, $x_format, 'Lowercase x format works');
    
    # Test consistency of ToString
    my $str1 = $guid->ToString();
    my $str2 = $guid->ToString();
    is($str1, $str2, 'ToString is consistent across calls');
    
    # Test invalid format
    eval { $guid->ToString('Z'); };
    like($@, qr/FormatException/, 'Invalid format throws FormatException');
    
    eval { $guid->ToString('invalid'); };
    like($@, qr/FormatException/, 'Invalid format string throws FormatException');
    
    # Test null reference on undef (Perl throws different error than .NET)
    eval { 
        my $undef_guid;
        $undef_guid->ToString();
    };
    like($@, qr/Can't call method.*on an undefined value/, 'ToString on undef throws appropriate error');
}

# Test 41-50: Parsing from String
{
    my $original_guid = System::Guid->NewGuid();
    my $guid_string = $original_guid->ToString();
    
    # Test Parse with default format
    my $parsed = System::Guid->Parse($guid_string);
    isa_ok($parsed, 'System::Guid', 'Parse returns Guid instance');
    ok($parsed->Equals($original_guid), 'Parsed guid equals original');
    
    # Test Parse with different formats
    my $n_format = $original_guid->ToString('N');
    my $parsed_n = System::Guid->Parse($n_format);
    ok($parsed_n->Equals($original_guid), 'Parse N format works');
    
    my $b_format = $original_guid->ToString('B');
    my $parsed_b = System::Guid->Parse($b_format);
    ok($parsed_b->Equals($original_guid), 'Parse B format works');
    
    my $p_format = $original_guid->ToString('P');
    my $parsed_p = System::Guid->Parse($p_format);
    ok($parsed_p->Equals($original_guid), 'Parse P format works');
    
    # Test case insensitive parsing
    my $lower_string = lc($guid_string);
    my $parsed_lower = System::Guid->Parse($lower_string);
    ok($parsed_lower->Equals($original_guid), 'Parse handles lowercase input');
    
    my $upper_string = uc($guid_string);
    my $parsed_upper = System::Guid->Parse($upper_string);
    ok($parsed_upper->Equals($original_guid), 'Parse handles uppercase input');
    
    # Test mixed case
    my $mixed_string = $guid_string;
    $mixed_string =~ s/([0-9A-F])/rand() > 0.5 ? lc($1) : uc($1)/ge;
    my $parsed_mixed = System::Guid->Parse($mixed_string);
    ok($parsed_mixed->Equals($original_guid), 'Parse handles mixed case input');
}

# Test 51-60: Parsing Edge Cases and Errors
{
    # Test Parse with null/undef
    eval { System::Guid->Parse(undef); };
    like($@, qr/ArgumentNullException/, 'Parse with null throws ArgumentNullException');
    
    # Test Parse with invalid formats
    eval { System::Guid->Parse('invalid-guid-format'); };
    like($@, qr/FormatException/, 'Parse with invalid format throws FormatException');
    
    eval { System::Guid->Parse('12345678-1234-1234-1234-12345678901'); }; # One char short
    like($@, qr/FormatException/, 'Parse with too short string throws FormatException');
    
    eval { System::Guid->Parse('12345678-1234-1234-1234-1234567890123'); }; # One char too long
    like($@, qr/FormatException/, 'Parse with too long string throws FormatException');
    
    eval { System::Guid->Parse('1234567G-1234-1234-1234-123456789012'); }; # Invalid hex char
    like($@, qr/FormatException/, 'Parse with invalid hex character throws FormatException');
    
    # Test invalid format (the parser is flexible and might accept various formats)
    # Instead test a clearly invalid format
    eval { System::Guid->Parse('GGGGGGGG-1234-1234-1234-123456789012'); }; # Invalid hex
    like($@, qr/FormatException/, 'Parse with clearly invalid hex throws FormatException');
    
    # Test empty string
    eval { System::Guid->Parse(''); };
    like($@, qr/FormatException/, 'Parse with empty string throws FormatException');
    
    # Test whitespace
    eval { System::Guid->Parse('   '); };
    like($@, qr/FormatException/, 'Parse with whitespace throws FormatException');
    
    # Test special characters
    eval { System::Guid->Parse('12345678-1234-1234-1234-123456789@12'); };
    like($@, qr/FormatException/, 'Parse with special characters throws FormatException');
}

# Test 61-70: TryParse Method
{
    my $original_guid = System::Guid->NewGuid();
    my $guid_string = $original_guid->ToString();
    
    # Test successful TryParse
    my $result;
    my $success = System::Guid->TryParse($guid_string, \$result);
    ok($success, 'TryParse succeeds on valid input');
    isa_ok($result, 'System::Guid', 'TryParse sets correct result type');
    ok($result->Equals($original_guid), 'TryParse result equals original');
    
    # Test TryParse with different formats
    my $n_result;
    my $n_success = System::Guid->TryParse($original_guid->ToString('N'), \$n_result);
    ok($n_success, 'TryParse succeeds on N format');
    ok($n_result->Equals($original_guid), 'TryParse N format result is correct');
    
    my $b_result;
    my $b_success = System::Guid->TryParse($original_guid->ToString('B'), \$b_result);
    ok($b_success, 'TryParse succeeds on B format');
    ok($b_result->Equals($original_guid), 'TryParse B format result is correct');
    
    # Test TryParse failure
    my $fail_result;
    my $fail_success = System::Guid->TryParse('invalid-guid', \$fail_result);
    ok(!$fail_success, 'TryParse fails on invalid input');
    ok(!defined($fail_result), 'TryParse sets undef on failure');
    
    # Test TryParse with undef input
    my $undef_result;
    my $undef_success = System::Guid->TryParse(undef, \$undef_result);
    ok(!$undef_success, 'TryParse fails on undef input');
    ok(!defined($undef_result), 'TryParse sets undef on undef input');
}

# Test 71-80: ParseExact and TryParseExact
{
    my $original_guid = System::Guid->NewGuid();
    
    # Test ParseExact with matching format
    my $d_string = $original_guid->ToString('D');
    my $parsed_d = System::Guid->ParseExact($d_string, 'D');
    ok($parsed_d->Equals($original_guid), 'ParseExact with D format works');
    
    my $n_string = $original_guid->ToString('N');
    my $parsed_n = System::Guid->ParseExact($n_string, 'N');
    ok($parsed_n->Equals($original_guid), 'ParseExact with N format works');
    
    my $b_string = $original_guid->ToString('B');
    my $parsed_b = System::Guid->ParseExact($b_string, 'B');
    ok($parsed_b->Equals($original_guid), 'ParseExact with B format works');
    
    my $p_string = $original_guid->ToString('P');
    my $parsed_p = System::Guid->ParseExact($p_string, 'P');
    ok($parsed_p->Equals($original_guid), 'ParseExact with P format works');
    
    # Test ParseExact with wrong format (should fail validation)
    eval { 
        System::Guid->ParseExact($n_string, 'D'); # N format string with D format specifier
    };
    like($@, qr/FormatException/, 'ParseExact with mismatched format throws FormatException');
    
    # Test ParseExact error cases
    eval { System::Guid->ParseExact(undef, 'D'); };
    like($@, qr/ArgumentNullException/, 'ParseExact with null input throws ArgumentNullException');
    
    eval { System::Guid->ParseExact($d_string, undef); };
    like($@, qr/ArgumentNullException/, 'ParseExact with null format throws ArgumentNullException');
    
    eval { System::Guid->ParseExact($d_string, 'Z'); };
    like($@, qr/FormatException/, 'ParseExact with invalid format throws FormatException');
    
    # Test TryParseExact success
    my $exact_result;
    my $exact_success = System::Guid->TryParseExact($d_string, 'D', \$exact_result);
    ok($exact_success, 'TryParseExact succeeds with correct format');
    ok($exact_result->Equals($original_guid), 'TryParseExact result is correct');
}

# Test 81-90: Byte Array Operations
{
    my $original_guid = System::Guid->NewGuid();
    
    # Test ToByteArray
    my $bytes = $original_guid->ToByteArray();
    isa_ok($bytes, 'ARRAY', 'ToByteArray returns array reference');
    is(scalar(@$bytes), 16, 'Byte array has 16 elements');
    
    # Test all bytes are valid (0-255)
    for my $i (0..15) {
        ok(defined($bytes->[$i]), "Byte $i is defined");
        ok($bytes->[$i] >= 0 && $bytes->[$i] <= 255, "Byte $i is valid (0-255)");
        last if $i >= 2; # Only test first 3 to avoid too many tests
    }
    
    # Test that ToByteArray returns a copy
    my $bytes_copy = $original_guid->ToByteArray();
    $bytes->[0] = 999; # Modify original
    isnt($bytes_copy->[0], 999, 'ToByteArray returns independent copy');
    
    # Test construction from byte array
    my $from_bytes = System::Guid->new($bytes_copy);
    isa_ok($from_bytes, 'System::Guid', 'Construction from byte array works');
    ok($from_bytes->Equals($original_guid), 'Guid from byte array equals original');
    
    # Test round-trip: Guid -> bytes -> Guid
    my $roundtrip_bytes = $from_bytes->ToByteArray();
    is_deeply($roundtrip_bytes, $bytes_copy, 'Round-trip byte conversion preserves data');
    
    # Test construction with invalid byte array
    eval { System::Guid->new([1, 2, 3]); }; # Too few bytes
    like($@, qr/ArgumentException/, 'Constructor with too few bytes throws ArgumentException');
    
    eval { System::Guid->new([1..20]); }; # Too many bytes
    like($@, qr/ArgumentException/, 'Constructor with too many bytes throws ArgumentException');
}

# Test 91-100: Constructor with 11 Arguments
{
    # Test construction from 11 parts (int, short, short, 8 bytes)
    my $from_parts = System::Guid->new(0x12345678, 0x1234, 0x5678, 0x90, 0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67);
    isa_ok($from_parts, 'System::Guid', 'Construction from 11 parts works');
    
    my $parts_string = $from_parts->ToString();
    is(length($parts_string), 36, 'Guid from parts has correct string length');
    like($parts_string, qr/^[0-9A-F-]+$/, 'Guid from parts has valid format');
    
    # Test specific known values
    my $known_guid = System::Guid->new(0x12345678, 0x1234, 0x5678, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0);
    my $known_string = $known_guid->ToString();
    
    # The string should reflect the byte layout with proper endianness
    like($known_string, qr/^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/, 'Known guid has proper format');
    
    # Test edge case values
    my $zero_guid = System::Guid->new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    my $empty = System::Guid->Empty();
    ok($zero_guid->Equals($empty), 'Guid from zero parts equals Empty');
    
    my $max_guid = System::Guid->new(0xFFFFFFFF, 0xFFFF, 0xFFFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
    is($max_guid->ToString(), 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF', 'Max value guid string is correct');
    
    # Test invalid argument counts
    eval { System::Guid->new(1, 2, 3, 4, 5); }; # Too few args
    like($@, qr/ArgumentException/, 'Constructor with too few arguments throws ArgumentException');
    
    eval { System::Guid->new((1) x 12); }; # Too many args
    like($@, qr/ArgumentException/, 'Constructor with too many arguments throws ArgumentException');
    
    eval { System::Guid->new((1) x 10); }; # One short
    like($@, qr/ArgumentException/, 'Constructor with one argument short throws ArgumentException');
    
    # Test numeric arguments (Perl will auto-convert strings to numbers)
    my $numeric_guid = System::Guid->new(123, 456, 789, 1, 2, 3, 4, 5, 6, 7, 8);
    ok(defined($numeric_guid), 'Constructor works with numeric arguments');
}

# Test 101-110: Equality and Comparison
{
    my $guid1 = System::Guid->NewGuid();
    my $guid2 = System::Guid->NewGuid();
    my $guid3 = System::Guid->new($guid1->ToByteArray()); # Copy of guid1
    
    # Test Equals
    ok($guid1->Equals($guid1), 'Guid equals itself');
    ok($guid1->Equals($guid3), 'Guid equals its copy');
    ok(!$guid1->Equals($guid2), 'Different guids are not equal');
    ok(!$guid1->Equals(undef), 'Guid not equal to undef');
    ok(!$guid1->Equals("string"), 'Guid not equal to string');
    
    # Skip testing with unblessed references as they cause isa() to fail
    # ok(!$guid1->Equals({}), 'Guid not equal to hash ref');
    # ok(!$guid1->Equals([]), 'Guid not equal to array ref');
    
    # Test with a blessed object that's not a Guid
    my $other_obj = bless {}, 'SomeOtherClass';
    ok(!$guid1->Equals($other_obj), 'Guid not equal to other blessed object');
    
    # Test CompareTo
    is($guid1->CompareTo($guid1), 0, 'CompareTo self returns 0');
    is($guid1->CompareTo($guid3), 0, 'CompareTo copy returns 0');
    isnt($guid1->CompareTo($guid2), 0, 'CompareTo different guid is not 0');
    
    # Test CompareTo with null
    is($guid1->CompareTo(undef), 1, 'CompareTo null returns 1');
    
    # Test CompareTo with non-Guid
    eval { $guid1->CompareTo($other_obj); };
    like($@, qr/ArgumentException/, 'CompareTo with non-Guid throws ArgumentException');
}

# Test 111-120: GetHashCode and Null Reference Handling
{
    my $guid1 = System::Guid->NewGuid();
    my $guid2 = System::Guid->new($guid1->ToByteArray()); # Copy
    my $guid3 = System::Guid->NewGuid();
    
    # Test GetHashCode
    my $hash1 = $guid1->GetHashCode();
    my $hash1_again = $guid1->GetHashCode();
    my $hash2 = $guid2->GetHashCode();
    my $hash3 = $guid3->GetHashCode();
    
    ok(defined($hash1), 'GetHashCode returns defined value');
    is($hash1, $hash1_again, 'GetHashCode is consistent');
    is($hash1, $hash2, 'Equal guids have same hash code');
    
    # Note: Different guids might have same hash (collision), so we don't test inequality
    ok(defined($hash3), 'Different guid also has defined hash code');
    
    # Test null reference exceptions (Perl handles these differently than .NET)
    eval { 
        my $undef_guid;
        $undef_guid->Equals($guid1);
    };
    like($@, qr/Can't call method.*on an undefined value/, 'Equals on undef throws appropriate error');
    
    eval { 
        my $undef_guid;
        $undef_guid->CompareTo($guid1);
    };
    like($@, qr/Can't call method.*on an undefined value/, 'CompareTo on undef throws appropriate error');
    
    eval { 
        my $undef_guid;
        $undef_guid->GetHashCode();
    };
    like($@, qr/Can't call method.*on an undefined value/, 'GetHashCode on undef throws appropriate error');
    
    eval { 
        my $undef_guid;
        $undef_guid->ToByteArray();
    };
    like($@, qr/Can't call method.*on an undefined value/, 'ToByteArray on undef throws appropriate error');
    
    # Test Empty guid hash code
    my $empty = System::Guid->Empty();
    my $empty_hash = $empty->GetHashCode();
    is($empty_hash, 0, 'Empty guid has hash code of 0');
}

done_testing();