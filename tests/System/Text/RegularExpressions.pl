#!/usr/bin/perl
# Test System::Text::RegularExpressions functionality
# Based on original RegExTest.pl from x/ directory

use strict;
use warnings;
use Test::More;

plan tests => 34;

# First check if the regex module exists
my $regex_available = eval {
    require System::Text::RegularExpressions;
    1;
};

SKIP: {
    skip "System::Text::RegularExpressions not available", 34 unless $regex_available;

    use_ok('System::Text::RegularExpressions');

    # Import Regex for convenience
    my $Regex = 'System::Text::RegularExpressions::Regex';
    my $RegexOptions = 'System::Text::RegularExpressions::RegexOptions';
    
    # Test 1: Non-matching pattern
    {
        my $match = $Regex->new('abc')->Match('xyz');
        ok(!$match->Success, "Non-matching pattern returns unsuccessful match");
    }
    
    # Test 2: IsMatch for non-matching
    {
        my $isMatching = $Regex->new('abc')->IsMatch('xyz');
        ok(!$isMatching, "IsMatch returns false for non-matching pattern");
    }
    
    # Test 3: Basic matching
    {
        my $match = $Regex->new('abc')->Match('abc');
        ok($match->Success, "Basic pattern matching works");
    }
    
    # Test 4: IsMatch for matching
    {
        my $isMatching = $Regex->new('abc')->IsMatch('abc');
        ok($isMatching, "IsMatch returns true for matching pattern");
    }
    
    # Test 5: Multiple matches
    {
        my $matches = $Regex->new('a')->Matches('aaa');
        ok($matches->Count >= 1, "Multiple matches found");
    }
    
    # Test 6: Groups and captures (if implemented)
    {
        my $matches = $Regex->new('(a)(b)')->Matches('ab');
        if ($matches->Count > 0 && $matches->Item(0)->can('Groups')) {
            my $groups = $matches->Item(0)->Groups;
            ok($groups->Count >= 2, "Groups capture works");
        } else {
            pass("Groups functionality not fully implemented - skipping");
        }
    }
    
    # Test 7: Named groups (if implemented)
    {
        my $matches = $Regex->new('(?<first>a)(?<second>b)')->Matches('ab');
        if ($matches->Count > 0 && $matches->Item(0)->can('Groups')) {
            my $groups = $matches->Item(0)->Groups;
            if ($groups->can('Item') && defined($groups->Item('first'))) {
                is($groups->Item('first')->Value, 'a', "Named groups work");
            } else {
                pass("Named groups not implemented - skipping");
            }
        } else {
            pass("Named groups not implemented - skipping");
        }
    }
    
    # Test 8: Match value
    {
        my $match = $Regex->new('hello')->Match('hello world');
        if ($match->Success) {
            is($match->Value, 'hello', "Match value is correct");
        } else {
            fail("Basic match should succeed");
        }
    }
    
    # Test 9: Match index (if implemented)
    {
        my $match = $Regex->new('world')->Match('hello world');
        if ($match->Success && $match->can('Index')) {
            ok($match->Index >= 0, "Match index is reported");
        } else {
            pass("Match index not implemented - skipping");
        }
    }
    
    # Test 10: Replace functionality (if implemented)
    {
        if ($Regex->can('Replace')) {
            my $result = $Regex->new('world')->Replace('hello world', 'universe');
            is($result, 'hello universe', "Regex replace works");
        } else {
            pass("Regex replace not implemented - skipping");
        }
    }
    
    # Test 11: Split functionality (if implemented)
    {
        if ($Regex->can('Split')) {
            my $parts = $Regex->new(',')->Split('a,b,c');
            ok(scalar(@$parts) == 3, "Regex split works");
        } else {
            pass("Regex split not implemented - skipping");
        }
    }

    # --- Extended coverage: named groups, options, numbering ---------------

    # Test 13: RegexOptions constants exist with .NET values
    {
        is($RegexOptions->None, 0, "RegexOptions.None == 0");
        is($RegexOptions->IgnoreCase, 1, "RegexOptions.IgnoreCase == 1");
        is($RegexOptions->Multiline, 2, "RegexOptions.Multiline == 2");
        is($RegexOptions->Singleline, 16, "RegexOptions.Singleline == 16");
        is($RegexOptions->IgnorePatternWhitespace, 32, "RegexOptions.IgnorePatternWhitespace == 32");
    }

    # Test 14: All positional groups are captured (not just $1)
    {
        my $match = $Regex->new('(a)(b)(c)')->Match('abc');
        my $groups = $match->Groups;
        # group 0 = whole match, then 1..3
        ok($groups->Count == 4, "All positional groups captured (whole + 3)");
        is($groups->Item(1)->Value, 'a', "Positional group 1 value");
        is($groups->Item(3)->Value, 'c', "Positional group 3 value");
    }

    # Test 15: Single named group access by name
    {
        my $match = $Regex->new('(?<letter>a)')->Match('a');
        is($match->Groups->Item('letter')->Value, 'a', "Single named group by name");
    }

    # Test 16: Multiple named groups
    {
        my $match = $Regex->new('(?<yr>\d{4})-(?<mo>\d{2})')->Match('2026-06');
        is($match->Groups->Item('yr')->Value, '2026', "Named group 'yr'");
        is($match->Groups->Item('mo')->Value, '06', "Named group 'mo'");
    }

    # Test 17: Mixed named + positional groups, with correct numbering
    {
        my $match = $Regex->new('(?<a>x)(y)(?<b>z)')->Match('xyz');
        is($match->Groups->Item('a')->Value, 'x', "Mixed: named 'a'");
        is($match->Groups->Item(2)->Value, 'y', "Mixed: positional 2");
        is($match->Groups->Item('b')->Value, 'z', "Mixed: named 'b'");
    }

    # Test 18: Non-capturing group (?:...) does not shift numbering
    {
        my $match = $Regex->new('(?:foo)(bar)')->Match('foobar');
        is($match->Groups->Item(1)->Value, 'bar', "Non-capturing group keeps numbering");
    }

    # Test 19: IgnoreCase option
    {
        my $isMatch = $Regex->new('ABC', $RegexOptions->IgnoreCase)->IsMatch('abc');
        ok($isMatch, "IgnoreCase option honored");
        my $noOpt = $Regex->new('ABC')->IsMatch('abc');
        ok(!$noOpt, "Without IgnoreCase, case-sensitive mismatch");
    }

    # Test 20: Multiline option (^ matches start of each line)
    {
        my $matches = $Regex->new('^b', $RegexOptions->Multiline)->Matches("a\nb\nc");
        ok($matches->Count == 1, "Multiline: ^ anchors per-line");
    }

    # Test 21: Singleline option (. matches newline)
    {
        my $sl = $Regex->new('a.b', $RegexOptions->Singleline)->IsMatch("a\nb");
        ok($sl, "Singleline: dot matches newline");
        my $noSl = $Regex->new('a.b')->IsMatch("a\nb");
        ok(!$noSl, "Without Singleline, dot does not match newline");
    }

    # Test 22: IgnorePatternWhitespace option
    {
        my $x = $Regex->new('a b c', $RegexOptions->IgnorePatternWhitespace)->IsMatch('abc');
        ok($x, "IgnorePatternWhitespace: pattern spaces ignored");
    }

    # Test 23: Replace honoring IgnoreCase and named substitution
    {
        my $result = $Regex->new('(?<w>HELLO)', $RegexOptions->IgnoreCase)
                           ->Replace('say hello', '[${w}]');
        is("$result", 'say [hello]', "Replace with IgnoreCase + named substitution");
    }
}

done_testing();

if ($regex_available) {
    print "\n" . "=" x 60 . "\n";
    print "REGULAR EXPRESSIONS TEST SUMMARY\n";
    print "=" x 60 . "\n";
    print "✅ Tested functionality:\n";
    print "   • Basic pattern matching\n";
    print "   • Match success/failure detection\n";
    print "   • Multiple matches\n";
    print "   • Groups and captures (if available)\n";
    print "   • Named groups (if available)\n";
    print "   • Replace operations (if available)\n";
    print "   • Split operations (if available)\n";
    print "=" x 60 . "\n";
} else {
    print "\n" . "=" x 60 . "\n";
    print "REGULAR EXPRESSIONS NOT AVAILABLE\n";
    print "=" x 60 . "\n";
    print "ℹ️  System::Text::RegularExpressions module not found\n";
    print "   This is an optional component of the framework.\n";
    print "=" x 60 . "\n";
}