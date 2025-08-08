package System::Globalization::NumberStyles; {
  use strict;
  use warnings;
  use CSharp;
  
  # NumberStyles - enumeration for number parsing styles
  # These are bitwise flags that can be combined
  
  # Basic styles
  use constant None => 0x00000000;
  use constant AllowLeadingWhite => 0x00000001;
  use constant AllowTrailingWhite => 0x00000002;
  use constant AllowLeadingSign => 0x00000004;
  use constant AllowTrailingSign => 0x00000008;
  use constant AllowParentheses => 0x00000010;
  use constant AllowDecimalPoint => 0x00000020;
  use constant AllowThousands => 0x00000040;
  use constant AllowExponent => 0x00000080;
  use constant AllowCurrencySymbol => 0x00000100;
  use constant AllowHexSpecifier => 0x00000200;
  
  # Composite styles
  use constant Integer => (AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign);
  use constant HexNumber => (AllowLeadingWhite | AllowTrailingWhite | AllowHexSpecifier);
  use constant Number => (AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign | 
                         AllowTrailingSign | AllowDecimalPoint | AllowThousands);
  use constant Float => (AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign | 
                        AllowDecimalPoint | AllowExponent);
  use constant Currency => (AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign | 
                           AllowTrailingSign | AllowParentheses | AllowDecimalPoint | 
                           AllowThousands | AllowCurrencySymbol);
  use constant Any => (AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign | 
                      AllowTrailingSign | AllowParentheses | AllowDecimalPoint | 
                      AllowThousands | AllowExponent | AllowCurrencySymbol);
  
  # Export constants to caller's namespace when imported
  sub import {
    my $caller = caller;
    no strict 'refs';
    
    # Export all constants
    for my $const_name (qw(
      None AllowLeadingWhite AllowTrailingWhite AllowLeadingSign AllowTrailingSign
      AllowParentheses AllowDecimalPoint AllowThousands AllowExponent AllowCurrencySymbol
      AllowHexSpecifier Integer HexNumber Number Float Currency Any
    )) {
      *{"${caller}::$const_name"} = \&{$const_name};
    }
  }
  
  # Helper methods for checking styles
  sub HasFlag {
    my ($style, $flag) = @_;
    return ($style & $flag) == $flag;
  }
  
  sub IsValidStyle {
    my ($style) = @_;
    return defined($style) && $style >= 0 && $style <= Any;
  }
  
  sub GetStyleName {
    my ($style) = @_;
    
    # Return composite style names first
    return 'Any' if $style == Any;
    return 'Currency' if $style == Currency;
    return 'Float' if $style == Float;
    return 'Number' if $style == Number;
    return 'HexNumber' if $style == HexNumber;
    return 'Integer' if $style == Integer;
    return 'None' if $style == None;
    
    # For combined flags, build description
    my @flags = ();
    push @flags, 'AllowLeadingWhite' if HasFlag($style, AllowLeadingWhite);
    push @flags, 'AllowTrailingWhite' if HasFlag($style, AllowTrailingWhite);
    push @flags, 'AllowLeadingSign' if HasFlag($style, AllowLeadingSign);
    push @flags, 'AllowTrailingSign' if HasFlag($style, AllowTrailingSign);
    push @flags, 'AllowParentheses' if HasFlag($style, AllowParentheses);
    push @flags, 'AllowDecimalPoint' if HasFlag($style, AllowDecimalPoint);
    push @flags, 'AllowThousands' if HasFlag($style, AllowThousands);
    push @flags, 'AllowExponent' if HasFlag($style, AllowExponent);
    push @flags, 'AllowCurrencySymbol' if HasFlag($style, AllowCurrencySymbol);
    push @flags, 'AllowHexSpecifier' if HasFlag($style, AllowHexSpecifier);
    
    return join(' | ', @flags);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;