#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Object;
use System::String;
use System::Array;
use Config;

BEGIN {
    use_ok('System::Object');
    use_ok('System::String');
    use_ok('System::Array');
}

# Test cross-platform compatibility edge cases
sub test_platform_detection_and_info {
    # Test that we can detect basic platform information
    my $os_name = $^O;
    my $perl_version = $];
    my $arch = $Config{archname};
    
    ok(defined($os_name), 'OS name detected');
    ok(defined($perl_version), 'Perl version detected');
    ok(defined($arch), 'Architecture detected');
    
    # Create a test string with platform info
    my $platform_str = System::String->new("Platform: $os_name, Perl: $perl_version, Arch: $arch");
    ok(defined($platform_str), 'Platform info string created');
    ok($platform_str->Contains($os_name), 'Platform string contains OS name');
    
    # Test that basic operations work regardless of platform
    my $test_obj = System::Object->new();
    ok(defined($test_obj->ToString()), 'Object ToString works on current platform');
    ok($test_obj->GetHashCode() >= 0, 'Object GetHashCode works on current platform');
    
    diag("Running on: $os_name, Perl $perl_version, Architecture: $arch");
}

sub test_line_ending_compatibility {
    # Test various line ending formats
    my @line_endings = (
        "\n",       # Unix LF
        "\r\n",     # Windows CRLF
        "\r",       # Classic Mac CR
        "\n\r",     # Unusual combination
    );
    
    my @ending_names = ('Unix LF', 'Windows CRLF', 'Mac CR', 'Mixed');
    
    for my $i (0..$#line_endings) {
        my $ending = $line_endings[$i];
        my $name = $ending_names[$i];
        
        # Test string creation with line endings
        my $line_str = System::String->new("line1${ending}line2${ending}line3");
        ok(defined($line_str), "String with $name created");
        
        # Test that line endings are preserved
        ok($line_str->Contains($ending), "$name preserved in string");
        
        # Test length includes line ending characters
        my $expected_length = 5 + 5 + 5 + (2 * length($ending));  # line1 + line2 + line3 + 2 endings
        is($line_str->Length(), $expected_length, "$name length calculation correct");
        
        # Test operations with line endings
        ok($line_str->StartsWith("line1"), "$name StartsWith works");
        ok($line_str->EndsWith("line3"), "$name EndsWith works");
        ok($line_str->Contains("line2"), "$name Contains works");
        
        # Test splitting on line endings
        my $parts = $line_str->Split($ending);
        is($parts->Length(), 3, "$name split into correct parts");
        is($parts->Get(0)->ToString(), "line1", "$name first part correct");
        is($parts->Get(1)->ToString(), "line2", "$name second part correct");
        is($parts->Get(2)->ToString(), "line3", "$name third part correct");
        
        # Test array with line ending strings
        my $line_arr = System::Array->new("first$ending", "second$ending", "third");
        is($line_arr->Length(), 3, "$name array length correct");
        ok($line_arr->Contains("first$ending"), "$name array contains line ending element");
        
        # Test joining with line endings
        my $joined = String::Join($ending, System::Array->new("a", "b", "c"));
        is($joined->ToString(), "a${ending}b${ending}c", "$name join works correctly");
    }
}

sub test_path_separator_compatibility {
    # Test various path separator formats
    my @path_separators = ('/', '\\', ':');
    my @sep_names = ('Unix', 'Windows', 'Classic Mac');
    
    for my $i (0..$#path_separators) {
        my $sep = $path_separators[$i];
        my $name = $sep_names[$i];
        
        # Create path-like strings
        my $path_str = System::String->new("folder${sep}subfolder${sep}file.txt");
        ok(defined($path_str), "$name path string created");
        
        # Test path operations
        ok($path_str->Contains($sep), "$name separator preserved");
        ok($path_str->StartsWith("folder"), "$name path starts correctly");
        ok($path_str->EndsWith("file.txt"), "$name path ends correctly");
        
        # Test path splitting
        my $path_parts = $path_str->Split($sep);
        is($path_parts->Length(), 3, "$name path split correctly");
        is($path_parts->Get(0)->ToString(), "folder", "$name first path component");
        is($path_parts->Get(1)->ToString(), "subfolder", "$name second path component");
        is($path_parts->Get(2)->ToString(), "file.txt", "$name file component");
        
        # Test array of paths
        my $paths_arr = System::Array->new(
            "root${sep}dir1",
            "root${sep}dir2",
            "root${sep}dir3${sep}subdir"
        );
        
        is($paths_arr->Length(), 3, "$name paths array length");
        ok($paths_arr->Contains("root${sep}dir1"), "$name paths array contains element");
        
        # Test that IndexOf works with separators
        is($path_str->IndexOf($sep), 6, "$name first separator position");  # After "folder"
        is($path_str->LastIndexOf($sep), 6 + 1 + 9, "$name last separator position");  # After "subfolder"
    }
    
    # Test mixed separators (realistic cross-platform scenario)
    my $mixed_path = System::String->new("C:\\Windows/System32\\drivers/etc");
    ok($mixed_path->Contains("\\"), 'Mixed path contains backslash');
    ok($mixed_path->Contains("/"), 'Mixed path contains forward slash');
    is($mixed_path->Length(), 32, 'Mixed path length correct');
}

sub test_character_encoding_compatibility {
    # Test various character encodings and ranges
    
    # ASCII range (0-127)
    my $ascii_str = System::String->new("Hello World! 123 @#$%");
    ok(defined($ascii_str), 'ASCII string created');
    is($ascii_str->Length(), 22, 'ASCII string length');
    
    # Extended ASCII range (128-255)
    my $extended_ascii = System::String->new("\xA0\xA1\xA2\xA3\xA4\xA5");  # Non-breaking space and symbols
    ok(defined($extended_ascii), 'Extended ASCII string created');
    is($extended_ascii->Length(), 6, 'Extended ASCII length');
    
    # Latin-1 supplement (Unicode 0080-00FF)
    my $latin1 = System::String->new("\x{00C0}\x{00C1}\x{00C2}\x{00C3}");  # À, Á, Â, Ã
    ok(defined($latin1), 'Latin-1 string created');
    is($latin1->Length(), 4, 'Latin-1 string length');
    
    # Latin Extended-A (Unicode 0100-017F)
    my $latin_ext = System::String->new("\x{0100}\x{0101}\x{0102}\x{0103}");  # Ā, ā, Ă, ă
    ok(defined($latin_ext), 'Latin Extended string created');
    is($latin_ext->Length(), 4, 'Latin Extended length');
    
    # Greek and Coptic (Unicode 0370-03FF)
    my $greek = System::String->new("\x{03B1}\x{03B2}\x{03B3}\x{03B4}");  # α, β, γ, δ
    ok(defined($greek), 'Greek string created');
    is($greek->Length(), 4, 'Greek string length');
    
    # Cyrillic (Unicode 0400-04FF)
    my $cyrillic = System::String->new("\x{0410}\x{0411}\x{0412}\x{0413}");  # А, Б, В, Г
    ok(defined($cyrillic), 'Cyrillic string created');
    is($cyrillic->Length(), 4, 'Cyrillic string length');
    
    # CJK Unified Ideographs (Unicode 4E00-9FFF)
    my $cjk = System::String->new("\x{4E2D}\x{6587}\x{65E5}\x{672C}");  # 中文日本
    ok(defined($cjk), 'CJK string created');
    is($cjk->Length(), 4, 'CJK string length');
    
    # Arabic (Unicode 0600-06FF)
    my $arabic = System::String->new("\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}");  # العربية
    ok(defined($arabic), 'Arabic string created');
    is($arabic->Length(), 7, 'Arabic string length');
    
    # Hebrew (Unicode 0590-05FF)
    my $hebrew = System::String->new("\x{05E2}\x{05D1}\x{05E8}\x{05D9}\x{05EA}");  # עברית
    ok(defined($hebrew), 'Hebrew string created');
    is($hebrew->Length(), 5, 'Hebrew string length');
    
    # Test array with mixed encodings
    my $encoding_arr = System::Array->new(
        $ascii_str, $latin1, $greek, $cyrillic, $cjk, $arabic, $hebrew
    );
    
    is($encoding_arr->Length(), 7, 'Mixed encoding array length');
    ok($encoding_arr->Contains($greek), 'Mixed encoding array contains Greek');
    ok($encoding_arr->Contains($cjk), 'Mixed encoding array contains CJK');
    
    # Test operations across encodings
    my $mixed_concat = $ascii_str + System::String->new(" ") + $greek + System::String->new(" ") + $cjk;
    ok(defined($mixed_concat), 'Mixed encoding concatenation works');
    ok($mixed_concat->Contains("Hello"), 'Mixed string contains ASCII');
    ok($mixed_concat->Contains("\x{03B1}"), 'Mixed string contains Greek');
    ok($mixed_concat->Contains("\x{4E2D}"), 'Mixed string contains CJK');
}

sub test_numeric_format_compatibility {
    # Test various numeric formats as strings (locale-independent)
    my @number_formats = (
        "1234.56",          # US/UK format
        "1,234.56",         # US format with thousands separator
        "1.234,56",         # European format
        "1 234,56",         # French format
        "1'234.56",         # Swiss format
        "١٢٣٤.٥٦",          # Arabic-Indic digits
        "一二三四",          # Chinese numbers (as text)
        "1.23E+4",          # Scientific notation
        "-1,234.56",        # Negative number
        "+1,234.56",        # Positive number with sign
    );
    
    my @format_names = (
        'Standard', 'US Thousands', 'European', 'French', 'Swiss', 
        'Arabic-Indic', 'Chinese', 'Scientific', 'Negative', 'Positive'
    );
    
    for my $i (0..$#number_formats) {
        my $num_str = System::String->new($number_formats[$i]);
        my $name = $format_names[$i];
        
        ok(defined($num_str), "$name number format string created");
        is($num_str->ToString(), $number_formats[$i], "$name number format preserved");
        
        # Test that number format strings can be stored in arrays
        my $num_arr = System::Array->new($num_str, System::String->new("other"));
        ok($num_arr->Contains($num_str), "$name number in array");
        
        # Test searching within number strings
        if (length($number_formats[$i]) > 3) {
            my $substr = substr($number_formats[$i], 1, 2);
            ok($num_str->Contains($substr), "$name number substring search");
        }
    }
    
    # Test array of all number formats
    my @all_nums = map { System::String->new($_) } @number_formats;
    my $all_nums_arr = System::Array->new(@all_nums);
    
    is($all_nums_arr->Length(), scalar(@number_formats), 'All number formats in array');
    
    # Test that LINQ works with number format strings
    my $long_formats = $all_nums_arr->Where(sub { $_[0]->Length() > 6 })->ToArray();
    ok($long_formats->Length() > 0, 'LINQ filtering on number format strings');
}

sub test_date_time_format_compatibility {
    # Test various date/time formats as strings
    my @date_formats = (
        "2023-12-31",           # ISO 8601
        "12/31/2023",           # US format
        "31/12/2023",           # UK/European format
        "31.12.2023",           # German format
        "2023年12月31日",        # Japanese format
        "31 décembre 2023",     # French format
        "Dec 31, 2023",         # US long format
        "Sunday, December 31, 2023",  # Full format
        "2023-12-31T23:59:59Z", # ISO 8601 with time
        "23:59:59",             # Time only
        "11:59:59 PM",          # 12-hour format
    );
    
    my @format_names = (
        'ISO 8601', 'US Short', 'UK Short', 'German', 'Japanese', 
        'French', 'US Long', 'Full', 'ISO DateTime', 'Time 24h', 'Time 12h'
    );
    
    for my $i (0..$#date_formats) {
        my $date_str = System::String->new($date_formats[$i]);
        my $name = $format_names[$i];
        
        ok(defined($date_str), "$name date format string created");
        is($date_str->ToString(), $date_formats[$i], "$name date format preserved");
        
        # Test common date operations
        if ($date_formats[$i] =~ /2023/) {
            ok($date_str->Contains("2023"), "$name contains year");
        }
        
        if ($date_formats[$i] =~ /12|Dec|décembre/) {
            ok($date_str->Contains("12") || $date_str->Contains("Dec") || $date_str->Contains("décembre"), 
               "$name contains month indicator");
        }
        
        if ($date_formats[$i] =~ /31/) {
            ok($date_str->Contains("31"), "$name contains day");
        }
    }
    
    # Test array of date formats
    my @all_dates = map { System::String->new($_) } @date_formats;
    my $all_dates_arr = System::Array->new(@all_dates);
    
    is($all_dates_arr->Length(), scalar(@date_formats), 'All date formats in array');
    
    # Test filtering date formats
    my $formats_with_2023 = $all_dates_arr->Where(sub { $_[0]->Contains("2023") })->ToArray();
    ok($formats_with_2023->Length() > 0, 'Date format filtering works');
}

sub test_currency_format_compatibility {
    # Test various currency formats as strings
    my @currency_formats = (
        "$1,234.56",        # US Dollar
        "€1.234,56",        # Euro (European format)
        "£1,234.56",        # British Pound
        "¥1234",            # Japanese Yen (no decimals)
        "₹1,23,456.78",     # Indian Rupee (Indian number format)
        "R$1.234,56",       # Brazilian Real
        "₽1 234,56",        # Russian Ruble
        "₩1,234",           # Korean Won
        "CHF 1'234.56",     # Swiss Franc
        "CAD $1,234.56",    # Canadian Dollar
        "1.234,56 €",       # Euro (amount first)
        "USD 1,234.56",     # US Dollar with code
    );
    
    my @currency_names = (
        'US Dollar', 'Euro EU', 'British Pound', 'Japanese Yen', 'Indian Rupee',
        'Brazilian Real', 'Russian Ruble', 'Korean Won', 'Swiss Franc',
        'Canadian Dollar', 'Euro Suffix', 'US Dollar Code'
    );
    
    for my $i (0..$#currency_formats) {
        my $curr_str = System::String->new($currency_formats[$i]);
        my $name = $currency_names[$i];
        
        ok(defined($curr_str), "$name currency string created");
        is($curr_str->ToString(), $currency_formats[$i], "$name currency format preserved");
        
        # Test that currency symbols are preserved
        my $format = $currency_formats[$i];
        if ($format =~ /[\$€£¥₹₽₩]/) {
            # Extract the currency symbol
            my ($symbol) = $format =~ /([\$€£¥₹₽₩])/;
            ok($curr_str->Contains($symbol), "$name currency symbol preserved");
        }
        
        # Test numeric part detection
        if ($format =~ /(\d+)/) {
            ok($curr_str->Contains($1), "$name numeric part preserved");
        }
    }
    
    # Test array operations with currency formats
    my @all_currencies = map { System::String->new($_) } @currency_formats;
    my $curr_arr = System::Array->new(@all_currencies);
    
    is($curr_arr->Length(), scalar(@currency_formats), 'All currency formats in array');
    
    # Test searching for specific currencies
    my $dollar_currencies = $curr_arr->Where(sub { $_[0]->Contains('$') || $_[0]->Contains('USD') || $_[0]->Contains('CAD') })->ToArray();
    ok($dollar_currencies->Length() > 0, 'Dollar currency filtering');
    
    my $euro_currencies = $curr_arr->Where(sub { $_[0]->Contains('€') })->ToArray();
    ok($euro_currencies->Length() > 0, 'Euro currency filtering');
}

sub test_platform_specific_characters {
    # Test characters that might behave differently on different platforms
    
    # Test control characters
    my @control_chars = (
        "\x00",     # NULL
        "\x01",     # Start of Heading
        "\x07",     # Bell
        "\x08",     # Backspace
        "\x09",     # Tab
        "\x0A",     # Line Feed
        "\x0D",     # Carriage Return
        "\x1B",     # Escape
        "\x7F",     # Delete
    );
    
    for my $i (0..$#control_chars) {
        my $ctrl_char = $control_chars[$i];
        my $ctrl_str = System::String->new("before${ctrl_char}after");
        
        ok(defined($ctrl_str), "Control character $i string created");
        is($ctrl_str->Length(), 6 + length($ctrl_char), "Control character $i length correct");
        ok($ctrl_str->Contains($ctrl_char), "Control character $i preserved");
        ok($ctrl_str->StartsWith("before"), "Control character $i starts correctly");
        ok($ctrl_str->EndsWith("after"), "Control character $i ends correctly");
    }
    
    # Test whitespace characters
    my @whitespace_chars = (
        " ",            # Space
        "\t",           # Tab
        "\n",           # Newline
        "\r",           # Carriage return
        "\f",           # Form feed
        "\v",           # Vertical tab
        "\x{00A0}",     # Non-breaking space
        "\x{2000}",     # En quad
        "\x{2001}",     # Em quad
        "\x{2028}",     # Line separator
        "\x{2029}",     # Paragraph separator
    );
    
    for my $i (0..$#whitespace_chars) {
        my $ws_char = $whitespace_chars[$i];
        my $ws_str = System::String->new("word${ws_char}word");
        
        ok(defined($ws_str), "Whitespace character $i string created");
        ok($ws_str->Contains($ws_char), "Whitespace character $i preserved");
        
        # Test trimming behavior (may vary by platform/Perl version)
        my $padded = System::String->new("${ws_char}content${ws_char}");
        my $trimmed = $padded->Trim();
        ok(defined($trimmed), "Whitespace character $i trim operation works");
        
        last if $i >= 5;  # Limit for performance
    }
}

sub test_cross_platform_hash_consistency {
    # Test that hash codes are consistent across different data
    my @test_strings = (
        "",
        "a",
        "hello",
        "Hello World!",
        "The quick brown fox jumps over the lazy dog",
        "1234567890",
        "!@#\$%^&*()_+-=[]{}|;':\",./<>?",
        "café naïve résumé",
        "\x{4E2D}\x{6587}",  # Chinese characters
        "\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}",  # Arabic
    );
    
    my %hash_consistency;
    
    for my $i (0..$#test_strings) {
        my $test_str = $test_strings[$i];
        my $str_obj = System::String->new($test_str);
        
        # Get hash multiple times to ensure consistency
        my $hash1 = $str_obj->GetHashCode();
        my $hash2 = $str_obj->GetHashCode();
        my $hash3 = $str_obj->GetHashCode();
        
        is($hash1, $hash2, "Hash consistency test $i - first comparison");
        is($hash2, $hash3, "Hash consistency test $i - second comparison");
        is($hash1, $hash3, "Hash consistency test $i - third comparison");
        
        # Store hash for duplicate testing
        $hash_consistency{$test_str} = $hash1;
        
        # Test that hash is within reasonable bounds
        ok($hash1 >= 0, "Hash test $i is non-negative");
        ok($hash1 =~ /^\d+$/, "Hash test $i is numeric");
    }
    
    # Test that identical strings have identical hashes
    for my $test_str (@test_strings[0..4]) {  # Test subset for performance
        my $str_obj1 = System::String->new($test_str);
        my $str_obj2 = System::String->new($test_str);
        
        is($str_obj1->GetHashCode(), $str_obj2->GetHashCode(), 
           "Identical strings have same hash: '$test_str'");
        is($str_obj1->GetHashCode(), $hash_consistency{$test_str},
           "Hash matches stored value: '$test_str'");
    }
}

# Run all cross-platform compatibility edge case tests
test_platform_detection_and_info();
test_line_ending_compatibility();
test_path_separator_compatibility();
test_character_encoding_compatibility();
test_numeric_format_compatibility();
test_date_time_format_compatibility();
test_currency_format_compatibility();
test_platform_specific_characters();
test_cross_platform_hash_consistency();

done_testing();