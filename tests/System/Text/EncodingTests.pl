#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import encoding classes
use System::Text::Encoding;
use System::Text::ASCIIEncoding;
use System::Text::UTF8Encoding;
use System::Text::UnicodeEncoding;
use System::Text::UTF32Encoding;

sub test_ascii_encoding {
    my $ascii = System::Text::ASCIIEncoding->new();
    isa_ok($ascii, 'System::Text::ASCIIEncoding', 'ASCIIEncoding creation');
    isa_ok($ascii, 'System::Text::Encoding', 'ASCIIEncoding inherits from Encoding');
    
    is($ascii->EncodingName(), "US-ASCII", 'ASCII encoding name');
    is($ascii->WebName(), "us-ascii", 'ASCII web name');
    is($ascii->CodePage(), 20127, 'ASCII code page');
    
    # Test encoding ASCII characters
    my @chars = ('H', 'e', 'l', 'l', 'o');
    my $byteCount = $ascii->GetByteCount(\@chars, 0, 5);
    is($byteCount, 5, 'ASCII byte count correct');
    
    my @bytes = (0) x 10;
    my $bytesEncoded = $ascii->GetBytes(\@chars, 0, 5, \@bytes, 0);
    is($bytesEncoded, 5, 'ASCII bytes encoded');
    is_deeply([@bytes[0..4]], [72, 101, 108, 108, 111], 'ASCII encoding correct');
    
    # Test decoding
    my $charCount = $ascii->GetCharCount(\@bytes, 0, 5);
    is($charCount, 5, 'ASCII char count correct');
    
    my @decodedChars = ('') x 10;
    my $charsDecoded = $ascii->GetChars(\@bytes, 0, 5, \@decodedChars, 0);
    is($charsDecoded, 5, 'ASCII chars decoded');
    is_deeply([@decodedChars[0..4]], \@chars, 'ASCII decoding correct');
    
    # Test non-ASCII character (should be replaced with ?)
    my @nonAsciiChars = (chr(200)); # Extended ASCII
    @bytes = (0) x 5;
    $ascii->GetBytes(\@nonAsciiChars, 0, 1, \@bytes, 0);
    is($bytes[0], ord('?'), 'Non-ASCII character replaced with ?');
}

sub test_utf8_encoding {
    my $utf8 = System::Text::UTF8Encoding->new();
    isa_ok($utf8, 'System::Text::UTF8Encoding', 'UTF8Encoding creation');
    isa_ok($utf8, 'System::Text::Encoding', 'UTF8Encoding inherits from Encoding');
    
    is($utf8->EncodingName(), "UTF-8", 'UTF-8 encoding name');
    is($utf8->WebName(), "utf-8", 'UTF-8 web name');
    is($utf8->CodePage(), 65001, 'UTF-8 code page');
    
    # Test encoding ASCII characters (1 byte each)
    my @asciiChars = ('H', 'e', 'l', 'l', 'o');
    my $byteCount = $utf8->GetByteCount(\@asciiChars, 0, 5);
    is($byteCount, 5, 'UTF-8 ASCII byte count correct');
    
    my @bytes = (0) x 15;
    my $bytesEncoded = $utf8->GetBytes(\@asciiChars, 0, 5, \@bytes, 0);
    is($bytesEncoded, 5, 'UTF-8 ASCII bytes encoded');
    is_deeply([@bytes[0..4]], [72, 101, 108, 108, 111], 'UTF-8 ASCII encoding correct');
    
    # Test encoding 2-byte UTF-8 character (e.g., ñ = U+00F1)
    my @latinChars = (chr(0xF1)); # ñ
    $byteCount = $utf8->GetByteCount(\@latinChars, 0, 1);
    is($byteCount, 2, 'UTF-8 2-byte character byte count');
    
    @bytes = (0) x 5;
    $bytesEncoded = $utf8->GetBytes(\@latinChars, 0, 1, \@bytes, 0);
    is($bytesEncoded, 2, 'UTF-8 2-byte character encoded');
    is($bytes[0], 0xC3, 'UTF-8 2-byte first byte correct');
    is($bytes[1], 0xB1, 'UTF-8 2-byte second byte correct');
    
    # Test decoding
    my $charCount = $utf8->GetCharCount(\@bytes, 0, 2);
    is($charCount, 1, 'UTF-8 2-byte char count correct');
    
    my @decodedChars = ('') x 5;
    my $charsDecoded = $utf8->GetChars(\@bytes, 0, 2, \@decodedChars, 0);
    is($charsDecoded, 1, 'UTF-8 2-byte chars decoded');
    is($decodedChars[0], chr(0xF1), 'UTF-8 2-byte decoding correct');
}

sub test_unicode_encoding {
    my $unicode = System::Text::UnicodeEncoding->new();
    isa_ok($unicode, 'System::Text::UnicodeEncoding', 'UnicodeEncoding creation');
    isa_ok($unicode, 'System::Text::Encoding', 'UnicodeEncoding inherits from Encoding');
    
    is($unicode->EncodingName(), "UTF-16LE", 'Unicode encoding name (little-endian)');
    is($unicode->WebName(), "utf-16le", 'Unicode web name');
    is($unicode->CodePage(), 1200, 'Unicode code page');
    
    # Test encoding (2 bytes per character)
    my @chars = ('H', 'e', 'l', 'l', 'o');
    my $byteCount = $unicode->GetByteCount(\@chars, 0, 5);
    is($byteCount, 10, 'Unicode byte count correct');
    
    my @bytes = (0) x 15;
    my $bytesEncoded = $unicode->GetBytes(\@chars, 0, 5, \@bytes, 0);
    is($bytesEncoded, 10, 'Unicode bytes encoded');
    
    # Check little-endian encoding of 'H' (0x0048)
    is($bytes[0], 0x48, 'Unicode little-endian low byte');
    is($bytes[1], 0x00, 'Unicode little-endian high byte');
    
    # Test decoding
    my $charCount = $unicode->GetCharCount(\@bytes, 0, 10);
    is($charCount, 5, 'Unicode char count correct');
    
    my @decodedChars = ('') x 10;
    my $charsDecoded = $unicode->GetChars(\@bytes, 0, 10, \@decodedChars, 0);
    is($charsDecoded, 5, 'Unicode chars decoded');
    is_deeply([@decodedChars[0..4]], \@chars, 'Unicode decoding correct');
    
    # Test big-endian
    my $unicodeBE = System::Text::UnicodeEncoding->new(true); # Big-endian
    is($unicodeBE->EncodingName(), "UTF-16BE", 'Unicode big-endian encoding name');
    
    @bytes = (0) x 15;
    $unicodeBE->GetBytes(\@chars, 0, 1, \@bytes, 0); # Just 'H'
    is($bytes[0], 0x00, 'Unicode big-endian high byte first');
    is($bytes[1], 0x48, 'Unicode big-endian low byte second');
}

sub test_utf32_encoding {
    my $utf32 = System::Text::UTF32Encoding->new();
    isa_ok($utf32, 'System::Text::UTF32Encoding', 'UTF32Encoding creation');
    isa_ok($utf32, 'System::Text::Encoding', 'UTF32Encoding inherits from Encoding');
    
    is($utf32->EncodingName(), "UTF-32LE", 'UTF-32 encoding name (little-endian)');
    is($utf32->WebName(), "utf-32le", 'UTF-32 web name');
    is($utf32->CodePage(), 12000, 'UTF-32 code page');
    
    # Test encoding (4 bytes per character)
    my @chars = ('H', 'e', 'l', 'l', 'o');
    my $byteCount = $utf32->GetByteCount(\@chars, 0, 5);
    is($byteCount, 20, 'UTF-32 byte count correct');
    
    my @bytes = (0) x 25;
    my $bytesEncoded = $utf32->GetBytes(\@chars, 0, 5, \@bytes, 0);
    is($bytesEncoded, 20, 'UTF-32 bytes encoded');
    
    # Check little-endian encoding of 'H' (0x00000048)
    is($bytes[0], 0x48, 'UTF-32 little-endian byte 0');
    is($bytes[1], 0x00, 'UTF-32 little-endian byte 1');
    is($bytes[2], 0x00, 'UTF-32 little-endian byte 2');
    is($bytes[3], 0x00, 'UTF-32 little-endian byte 3');
    
    # Test decoding
    my $charCount = $utf32->GetCharCount(\@bytes, 0, 20);
    is($charCount, 5, 'UTF-32 char count correct');
    
    my @decodedChars = ('') x 10;
    my $charsDecoded = $utf32->GetChars(\@bytes, 0, 20, \@decodedChars, 0);
    is($charsDecoded, 5, 'UTF-32 chars decoded');
    is_deeply([@decodedChars[0..4]], \@chars, 'UTF-32 decoding correct');
}

sub test_encoding_static_methods {
    # Test static encoding getters
    my $ascii = System::Text::Encoding->ASCII();
    isa_ok($ascii, 'System::Text::ASCIIEncoding', 'Static ASCII method');
    
    my $utf8 = System::Text::Encoding->UTF8();
    isa_ok($utf8, 'System::Text::UTF8Encoding', 'Static UTF8 method');
    
    my $unicode = System::Text::Encoding->Unicode();
    isa_ok($unicode, 'System::Text::UnicodeEncoding', 'Static Unicode method');
    
    my $utf32 = System::Text::Encoding->UTF32();
    isa_ok($utf32, 'System::Text::UTF32Encoding', 'Static UTF32 method');
    
    my $default = System::Text::Encoding->Default();
    isa_ok($default, 'System::Text::UTF8Encoding', 'Static Default method (UTF-8)');
    
    # Test singleton behavior
    my $ascii2 = System::Text::Encoding->ASCII();
    is($ascii, $ascii2, 'ASCII encoding is singleton');
    
    # Test GetEncoding by code page
    my $asciiByCodePage = System::Text::Encoding->GetEncoding(20127);
    isa_ok($asciiByCodePage, 'System::Text::ASCIIEncoding', 'GetEncoding by ASCII code page');
    
    my $utf8ByCodePage = System::Text::Encoding->GetEncoding(65001);
    isa_ok($utf8ByCodePage, 'System::Text::UTF8Encoding', 'GetEncoding by UTF-8 code page');
    
    # Test GetEncoding by name
    my $asciiByName = System::Text::Encoding->GetEncoding('ascii');
    isa_ok($asciiByName, 'System::Text::ASCIIEncoding', 'GetEncoding by ASCII name');
    
    my $utf8ByName = System::Text::Encoding->GetEncoding('utf-8');
    isa_ok($utf8ByName, 'System::Text::UTF8Encoding', 'GetEncoding by UTF-8 name');
}

sub test_encoding_convenience_methods {
    my $utf8 = System::Text::Encoding->UTF8();
    
    # Test GetBytesFromString
    my $string = "Hello";
    my $byteArray = $utf8->GetBytesFromString($string);
    isa_ok($byteArray, 'System::Array', 'GetBytesFromString returns System::Array');
    is($byteArray->Length(), 5, 'Byte array has correct length');
    is($byteArray->GetValue(0), 72, 'First byte correct');
    is($byteArray->GetValue(4), 111, 'Last byte correct');
    
    # Test GetStringFromBytes
    my @bytes = (72, 101, 108, 108, 111); # "Hello"
    my $decodedString = $utf8->GetStringFromBytes(\@bytes, 0, 5);
    isa_ok($decodedString, 'System::String', 'GetStringFromBytes returns System::String');
    is($decodedString->ToString(), "Hello", 'Decoded string correct');
    
    # Test with System::Array input
    require System::Array;
    my $sysArray = System::Array->new(@bytes);
    $decodedString = $utf8->GetStringFromBytes($sysArray, 0, 5);
    is($decodedString->ToString(), "Hello", 'GetStringFromBytes with System::Array correct');
}

sub test_encoding_max_counts {
    my $ascii = System::Text::Encoding->ASCII();
    is($ascii->GetMaxByteCount(10), 10, 'ASCII max byte count');
    is($ascii->GetMaxCharCount(10), 10, 'ASCII max char count');
    
    my $utf8 = System::Text::Encoding->UTF8();
    is($utf8->GetMaxByteCount(10), 40, 'UTF-8 max byte count (4 bytes per char)');
    is($utf8->GetMaxCharCount(10), 10, 'UTF-8 max char count');
    
    my $unicode = System::Text::Encoding->Unicode();
    is($unicode->GetMaxByteCount(10), 20, 'Unicode max byte count (2 bytes per char)');
    is($unicode->GetMaxCharCount(10), 5, 'Unicode max char count');
    
    my $utf32 = System::Text::Encoding->UTF32();
    is($utf32->GetMaxByteCount(10), 40, 'UTF-32 max byte count (4 bytes per char)');
    is($utf32->GetMaxCharCount(16), 4, 'UTF-32 max char count');
}

sub test_encoding_equals {
    my $ascii1 = System::Text::Encoding->ASCII();
    my $ascii2 = System::Text::Encoding->ASCII();
    my $utf8 = System::Text::Encoding->UTF8();
    
    ok($ascii1->Equals($ascii2), 'Same encoding types are equal');
    ok(!$ascii1->Equals($utf8), 'Different encoding types are not equal');
    ok(!$ascii1->Equals(undef), 'Encoding not equal to undef');
    
    is($ascii1->GetHashCode(), $ascii2->GetHashCode(), 'Same encodings have same hash code');
    isnt($ascii1->GetHashCode(), $utf8->GetHashCode(), 'Different encodings have different hash codes');
}

sub test_preambles {
    # Test Unicode BOM
    my $unicodeWithBOM = System::Text::UnicodeEncoding->new(false, true); # Little-endian with BOM
    my $preamble = $unicodeWithBOM->GetPreamble();
    isa_ok($preamble, 'System::Array', 'Unicode preamble is System::Array');
    is($preamble->Length(), 2, 'Unicode BOM has 2 bytes');
    is($preamble->GetValue(0), 0xFF, 'Unicode BOM first byte');
    is($preamble->GetValue(1), 0xFE, 'Unicode BOM second byte');
    
    # Test Unicode without BOM
    my $unicodeNoBOM = System::Text::UnicodeEncoding->new(false, false);
    $preamble = $unicodeNoBOM->GetPreamble();
    is($preamble->Length(), 0, 'Unicode without BOM has empty preamble');
    
    # Test UTF-32 BOM
    my $utf32WithBOM = System::Text::UTF32Encoding->new(false, true); # Little-endian with BOM
    $preamble = $utf32WithBOM->GetPreamble();
    is($preamble->Length(), 4, 'UTF-32 BOM has 4 bytes');
    is($preamble->GetValue(0), 0xFF, 'UTF-32 BOM first byte');
    is($preamble->GetValue(1), 0xFE, 'UTF-32 BOM second byte');
    is($preamble->GetValue(2), 0x00, 'UTF-32 BOM third byte');
    is($preamble->GetValue(3), 0x00, 'UTF-32 BOM fourth byte');
}

# Run all tests
test_ascii_encoding();
test_utf8_encoding();
test_unicode_encoding();
test_utf32_encoding();
test_encoding_static_methods();
test_encoding_convenience_methods();
test_encoding_max_counts();
test_encoding_equals();
test_preambles();

done_testing();