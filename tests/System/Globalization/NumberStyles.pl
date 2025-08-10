#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More;

# Import required modules
require System::Globalization::NumberStyles;

# Import NumberStyles constants
use System::Globalization::NumberStyles qw(
    None AllowLeadingWhite AllowTrailingWhite AllowLeadingSign AllowTrailingSign
    AllowParentheses AllowDecimalPoint AllowThousands AllowExponent AllowCurrencySymbol
    AllowHexSpecifier Integer HexNumber Number Float Currency Any
);

# Test plan - comprehensive NumberStyles testing
plan tests => 60;

# Test 1-10: Basic Constants Availability
{
    ok(defined(&None), 'None constant is defined');
    ok(defined(&AllowLeadingWhite), 'AllowLeadingWhite constant is defined');
    ok(defined(&AllowTrailingWhite), 'AllowTrailingWhite constant is defined');
    ok(defined(&AllowLeadingSign), 'AllowLeadingSign constant is defined');
    ok(defined(&AllowTrailingSign), 'AllowTrailingSign constant is defined');
    ok(defined(&AllowParentheses), 'AllowParentheses constant is defined');
    ok(defined(&AllowDecimalPoint), 'AllowDecimalPoint constant is defined');
    ok(defined(&AllowThousands), 'AllowThousands constant is defined');
    ok(defined(&AllowExponent), 'AllowExponent constant is defined');
    ok(defined(&AllowCurrencySymbol), 'AllowCurrencySymbol constant is defined');
}

# Test 11-15: Additional Constants
{
    ok(defined(&AllowHexSpecifier), 'AllowHexSpecifier constant is defined');
    ok(defined(&Integer), 'Integer composite constant is defined');
    ok(defined(&HexNumber), 'HexNumber composite constant is defined');
    ok(defined(&Number), 'Number composite constant is defined');
    ok(defined(&Float), 'Float composite constant is defined');
}

# Test 16-20: Final Constants
{
    ok(defined(&Currency), 'Currency composite constant is defined');
    ok(defined(&Any), 'Any composite constant is defined');
    
    # Test constant values
    is(None, 0x00000000, 'None has correct value');
    is(AllowLeadingWhite, 0x00000001, 'AllowLeadingWhite has correct value');
    is(AllowTrailingWhite, 0x00000002, 'AllowTrailingWhite has correct value');
}

# Test 21-30: Bitwise Flag Operations
{
    # Test basic flag checking
    ok((Integer & AllowLeadingWhite) == AllowLeadingWhite, 'Integer includes AllowLeadingWhite');
    ok((Integer & AllowTrailingWhite) == AllowTrailingWhite, 'Integer includes AllowTrailingWhite');
    ok((Integer & AllowLeadingSign) == AllowLeadingSign, 'Integer includes AllowLeadingSign');
    ok((Integer & AllowDecimalPoint) == 0, 'Integer does not include AllowDecimalPoint');
    
    ok((Float & AllowDecimalPoint) == AllowDecimalPoint, 'Float includes AllowDecimalPoint');
    ok((Float & AllowExponent) == AllowExponent, 'Float includes AllowExponent');
    ok((Float & AllowThousands) == 0, 'Float does not include AllowThousands');
    
    ok((Currency & AllowCurrencySymbol) == AllowCurrencySymbol, 'Currency includes AllowCurrencySymbol');
    ok((Currency & AllowParentheses) == AllowParentheses, 'Currency includes AllowParentheses');
    ok((HexNumber & AllowHexSpecifier) == AllowHexSpecifier, 'HexNumber includes AllowHexSpecifier');
}

# Test 31-40: HasFlag Helper Method
{
    ok(System::Globalization::NumberStyles::HasFlag(Integer, AllowLeadingWhite), 'HasFlag: Integer has AllowLeadingWhite');
    ok(System::Globalization::NumberStyles::HasFlag(Integer, AllowTrailingWhite), 'HasFlag: Integer has AllowTrailingWhite');
    ok(System::Globalization::NumberStyles::HasFlag(Integer, AllowLeadingSign), 'HasFlag: Integer has AllowLeadingSign');
    ok(!System::Globalization::NumberStyles::HasFlag(Integer, AllowDecimalPoint), 'HasFlag: Integer does not have AllowDecimalPoint');
    
    ok(System::Globalization::NumberStyles::HasFlag(Float, AllowDecimalPoint), 'HasFlag: Float has AllowDecimalPoint');
    ok(System::Globalization::NumberStyles::HasFlag(Float, AllowExponent), 'HasFlag: Float has AllowExponent');
    ok(!System::Globalization::NumberStyles::HasFlag(Float, AllowThousands), 'HasFlag: Float does not have AllowThousands');
    
    ok(System::Globalization::NumberStyles::HasFlag(Currency, AllowCurrencySymbol), 'HasFlag: Currency has AllowCurrencySymbol');
    ok(System::Globalization::NumberStyles::HasFlag(Any, AllowDecimalPoint), 'HasFlag: Any has AllowDecimalPoint');
    ok(!System::Globalization::NumberStyles::HasFlag(None, AllowLeadingWhite), 'HasFlag: None does not have AllowLeadingWhite');
}

# Test 41-50: IsValidStyle Method
{
    ok(System::Globalization::NumberStyles::IsValidStyle(None), 'IsValidStyle: None is valid');
    ok(System::Globalization::NumberStyles::IsValidStyle(Integer), 'IsValidStyle: Integer is valid');
    ok(System::Globalization::NumberStyles::IsValidStyle(Float), 'IsValidStyle: Float is valid');
    ok(System::Globalization::NumberStyles::IsValidStyle(Currency), 'IsValidStyle: Currency is valid');
    ok(System::Globalization::NumberStyles::IsValidStyle(Any), 'IsValidStyle: Any is valid');
    
    ok(!System::Globalization::NumberStyles::IsValidStyle(-1), 'IsValidStyle: -1 is invalid');
    ok(!System::Globalization::NumberStyles::IsValidStyle(Any + 1), 'IsValidStyle: Any+1 is invalid');
    ok(!System::Globalization::NumberStyles::IsValidStyle(undef), 'IsValidStyle: undef is invalid');
    
    # Test custom combinations
    my $custom = AllowLeadingWhite | AllowDecimalPoint;
    ok(System::Globalization::NumberStyles::IsValidStyle($custom), 'IsValidStyle: custom combination is valid');
    ok(System::Globalization::NumberStyles::IsValidStyle(0), 'IsValidStyle: 0 (None) is valid');
}

# Test 51-60: GetStyleName Method
{
    is(System::Globalization::NumberStyles::GetStyleName(None), 'None', 'GetStyleName: None');
    is(System::Globalization::NumberStyles::GetStyleName(Integer), 'Integer', 'GetStyleName: Integer');
    is(System::Globalization::NumberStyles::GetStyleName(Float), 'Float', 'GetStyleName: Float');
    is(System::Globalization::NumberStyles::GetStyleName(Currency), 'Currency', 'GetStyleName: Currency');
    is(System::Globalization::NumberStyles::GetStyleName(Any), 'Any', 'GetStyleName: Any');
    is(System::Globalization::NumberStyles::GetStyleName(HexNumber), 'HexNumber', 'GetStyleName: HexNumber');
    is(System::Globalization::NumberStyles::GetStyleName(Number), 'Number', 'GetStyleName: Number');
    
    # Test composite names
    my $custom1 = AllowLeadingWhite | AllowDecimalPoint;
    my $name1 = System::Globalization::NumberStyles::GetStyleName($custom1);
    like($name1, qr/AllowLeadingWhite/, 'GetStyleName: custom includes AllowLeadingWhite');
    like($name1, qr/AllowDecimalPoint/, 'GetStyleName: custom includes AllowDecimalPoint');
    
    my $custom2 = AllowLeadingSign | AllowTrailingSign | AllowParentheses;
    my $name2 = System::Globalization::NumberStyles::GetStyleName($custom2);
    like($name2, qr/AllowParentheses/, 'GetStyleName: complex custom includes AllowParentheses');
}

done_testing();