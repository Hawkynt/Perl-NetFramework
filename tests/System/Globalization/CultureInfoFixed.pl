#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More;

# Import required modules
require System::Globalization::CultureInfo;
require System::Exceptions;

# Test plan - comprehensive CultureInfo testing
plan tests => 77;

# Test 1-10: Basic CultureInfo Creation and Properties
{
    # Test invariant culture
    my $invariant = System::Globalization::CultureInfo->InvariantCulture();
    ok(defined($invariant), 'InvariantCulture returns defined culture');
    isa_ok($invariant, 'System::Globalization::CultureInfo', 'InvariantCulture');
    is($invariant->Name(), '', 'InvariantCulture has empty name');
    is($invariant->DisplayName(), 'Invariant Language (Invariant Country)', 'InvariantCulture display name');
    is($invariant->EnglishName(), 'Invariant Language (Invariant Country)', 'InvariantCulture English name');
    is($invariant->NativeName(), 'Invariant Language (Invariant Country)', 'InvariantCulture native name');
    is($invariant->TwoLetterISOLanguageName(), 'iv', 'InvariantCulture two-letter ISO code');
    is($invariant->ThreeLetterISOLanguageName(), 'ivl', 'InvariantCulture three-letter ISO code');
    ok(!$invariant->IsNeutralCulture(), 'InvariantCulture is not neutral');
    
    # Test singleton behavior
    my $invariant2 = System::Globalization::CultureInfo->InvariantCulture();
    is($invariant, $invariant2, 'InvariantCulture returns same instance');
}

# Test 11-20: English Culture (en-US)
{
    my $culture = System::Globalization::CultureInfo->new('en-US');
    ok(defined($culture), 'en-US culture creation');
    is($culture->Name(), 'en-US', 'en-US culture name');
    is($culture->DisplayName(), 'English (United States)', 'en-US display name');
    is($culture->EnglishName(), 'English (United States)', 'en-US English name');
    is($culture->NativeName(), 'English (United States)', 'en-US native name');
    is($culture->TwoLetterISOLanguageName(), 'en', 'en-US two-letter ISO code');
    is($culture->ThreeLetterISOLanguageName(), 'eng', 'en-US three-letter ISO code');
    ok(!$culture->IsNeutralCulture(), 'en-US is not neutral culture');
    
    # Test formatting methods
    is($culture->GetNumberDecimalSeparator(), '.', 'en-US decimal separator is period');
    is($culture->GetNumberGroupSeparator(), ',', 'en-US group separator is comma');
    is($culture->GetCurrencySymbol(), '$', 'en-US currency symbol is dollar');
}

# Test 21-30: British English Culture (en-GB)
{
    my $culture = System::Globalization::CultureInfo->new('en-GB');
    ok(defined($culture), 'en-GB culture creation');
    is($culture->Name(), 'en-GB', 'en-GB culture name');
    is($culture->DisplayName(), 'English (United Kingdom)', 'en-GB display name');
    is($culture->EnglishName(), 'English (United Kingdom)', 'en-GB English name');
    is($culture->TwoLetterISOLanguageName(), 'en', 'en-GB two-letter ISO code');
    is($culture->ThreeLetterISOLanguageName(), 'eng', 'en-GB three-letter ISO code');
    
    # Test formatting differences from US
    is($culture->GetNumberDecimalSeparator(), '.', 'en-GB decimal separator is period');
    is($culture->GetNumberGroupSeparator(), ',', 'en-GB group separator is comma');
    is($culture->GetCurrencySymbol(), '£', 'en-GB currency symbol is pound');
    ok(!$culture->IsNeutralCulture(), 'en-GB is not neutral culture');
}

# Test 31-40: German Culture (de-DE)
{
    my $culture = System::Globalization::CultureInfo->new('de-DE');
    ok(defined($culture), 'de-DE culture creation');
    is($culture->Name(), 'de-DE', 'de-DE culture name');
    is($culture->DisplayName(), 'German (Germany)', 'de-DE display name');
    is($culture->EnglishName(), 'German (Germany)', 'de-DE English name');
    is($culture->NativeName(), 'Deutsch (Deutschland)', 'de-DE native name');
    is($culture->TwoLetterISOLanguageName(), 'de', 'de-DE two-letter ISO code');
    is($culture->ThreeLetterISOLanguageName(), 'deu', 'de-DE three-letter ISO code');
    
    # Test European formatting (comma decimal separator)
    is($culture->GetNumberDecimalSeparator(), ',', 'de-DE decimal separator is comma');
    is($culture->GetNumberGroupSeparator(), '.', 'de-DE group separator is period');
    is($culture->GetCurrencySymbol(), '€', 'de-DE currency symbol is Euro');
}

# Test 41-50: French Culture (fr-FR)
{
    my $culture = System::Globalization::CultureInfo->new('fr-FR');
    ok(defined($culture), 'fr-FR culture creation');
    is($culture->Name(), 'fr-FR', 'fr-FR culture name');
    is($culture->DisplayName(), 'French (France)', 'fr-FR display name');
    is($culture->EnglishName(), 'French (France)', 'fr-FR English name');
    is($culture->NativeName(), 'Français (France)', 'fr-FR native name');
    is($culture->TwoLetterISOLanguageName(), 'fr', 'fr-FR two-letter ISO code');
    is($culture->ThreeLetterISOLanguageName(), 'fra', 'fr-FR three-letter ISO code');
    
    # Test French formatting (comma decimal, space group separator)
    is($culture->GetNumberDecimalSeparator(), ',', 'fr-FR decimal separator is comma');
    is($culture->GetNumberGroupSeparator(), ' ', 'fr-FR group separator is space');
    is($culture->GetCurrencySymbol(), '€', 'fr-FR currency symbol is Euro');
}

# Test 51-60: Additional Currency Symbols
{
    my $japanese = System::Globalization::CultureInfo->new('ja-JP');
    is($japanese->GetCurrencySymbol(), '¥', 'ja-JP currency symbol is Yen');
    
    my $russian = System::Globalization::CultureInfo->new('ru-RU');
    is($russian->GetCurrencySymbol(), '₽', 'ru-RU currency symbol is Ruble');
    
    my $swedish = System::Globalization::CultureInfo->new('sv-SE');
    is($swedish->GetCurrencySymbol(), 'kr', 'sv-SE currency symbol is Krona');
    
    my $polish = System::Globalization::CultureInfo->new('pl-PL');
    is($polish->GetCurrencySymbol(), 'zł', 'pl-PL currency symbol is Zloty');
    
    # Test decimal separator consistency
    is($russian->GetNumberDecimalSeparator(), ',', 'ru-RU uses comma decimal separator');
    is($polish->GetNumberDecimalSeparator(), ',', 'pl-PL uses comma decimal separator');
    is($swedish->GetNumberDecimalSeparator(), ',', 'sv-SE uses comma decimal separator');
    is($japanese->GetNumberDecimalSeparator(), '.', 'ja-JP uses period decimal separator');
    
    # Test group separators
    is($russian->GetNumberGroupSeparator(), ' ', 'ru-RU uses space group separator');
    is($polish->GetNumberGroupSeparator(), '.', 'pl-PL uses period group separator');
}

# Test 61-67: Current Culture Management
{
    # Test default current culture
    my $current = System::Globalization::CultureInfo->CurrentCulture();
    ok(defined($current), 'CurrentCulture returns defined culture');
    isa_ok($current, 'System::Globalization::CultureInfo', 'CurrentCulture');
    
    # Test setting current culture
    my $newCulture = System::Globalization::CultureInfo->new('de-DE');
    System::Globalization::CultureInfo->CurrentCulture($newCulture);
    my $updatedCurrent = System::Globalization::CultureInfo->CurrentCulture();
    is($updatedCurrent->Name(), 'de-DE', 'CurrentCulture can be set');
    
    # Test CurrentUICulture
    my $currentUI = System::Globalization::CultureInfo->CurrentUICulture();
    ok(defined($currentUI), 'CurrentUICulture returns defined culture');
    isa_ok($currentUI, 'System::Globalization::CultureInfo', 'CurrentUICulture');
    
    is($swedish->GetNumberGroupSeparator(), '.', 'sv-SE uses period group separator');
}

# Test 68-72: Culture Comparison and Equality
{
    my $culture1 = System::Globalization::CultureInfo->new('en-US');
    my $culture2 = System::Globalization::CultureInfo->new('en-US');
    my $culture3 = System::Globalization::CultureInfo->new('de-DE');
    
    ok($culture1->Equals($culture2), 'Same culture names are equal');
    ok(!$culture1->Equals($culture3), 'Different culture names are not equal');
    ok(!$culture1->Equals(undef), 'Culture does not equal undef');
    ok(!$culture1->Equals('string'), 'Culture does not equal string');
    
    # Test hash codes
    my $hash1 = $culture1->GetHashCode();
    my $hash2 = $culture2->GetHashCode();
    is($hash1, $hash2, 'Equal cultures have same hash code');
}

# Test 73-77: Exception Handling and Additional Methods
{
    # Test argument exceptions for CurrentCulture setter with invalid objects
    eval { System::Globalization::CultureInfo->CurrentCulture('string') };
    ok($@, 'CurrentCulture setter throws on non-CultureInfo');
    
    eval { System::Globalization::CultureInfo->CurrentUICulture('string') };
    ok($@, 'CurrentUICulture setter throws on non-CultureInfo');
    
    # Test constructor with null - should handle gracefully
    my $null_culture = System::Globalization::CultureInfo->new(undef);
    is($null_culture->Name(), '', 'Constructor with undef defaults to empty name');
    
    # Test ToString method
    my $us_culture = System::Globalization::CultureInfo->new('en-US');
    is($us_culture->ToString(), 'en-US', 'ToString returns culture name');
    is(System::Globalization::CultureInfo->InvariantCulture()->ToString(), 'Invariant Language (Invariant Country)', 'Invariant ToString');
}

done_testing();