package System::Globalization::NumberParser; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Globalization::NumberStyles;
  require System::Globalization::CultureInfo;
  
  # NumberParser - utility for parsing numbers with culture and style support
  
  sub ParseWithStyle {
    my ($value, $style, $culture, $targetType) = @_;
    
    # Validate arguments
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    throw(System::ArgumentNullException->new('style')) unless defined($style);
    $culture //= System::Globalization::CultureInfo->InvariantCulture();
    $targetType //= 'System::Int32';
    
    # Convert value to string if it's an object
    if (ref($value) && $value->can('ToString')) {
      $value = $value->ToString();
    }
    
    # Return result and cleaned string
    my $cleanValue = _CleanNumberString($value, $style, $culture);
    my $numericValue = _ConvertToNumber($cleanValue, $style, $targetType);
    
    return $numericValue;
  }
  
  sub TryParseWithStyle {
    my ($value, $style, $culture, $targetType, $resultRef) = @_;
    
    eval {
      my $result = ParseWithStyle($value, $style, $culture, $targetType);
      $$resultRef = $result if defined($resultRef);
      return true;
    };
    
    if ($@) {
      $$resultRef = undef if defined($resultRef);
      return false;
    }
    
    return true;
  }
  
  # Internal helper methods
  sub _CleanNumberString {
    my ($value, $style, $culture) = @_;
    
    my $cleaned = $value;
    my $isNegative = false;
    my $hasDecimal = false;
    
    # Handle whitespace
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowLeadingWhite)) {
      $cleaned =~ s/^\s+//;
    }
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowTrailingWhite)) {
      $cleaned =~ s/\s+$//;
    }
    
    # Handle currency symbol
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowCurrencySymbol)) {
      my $currencySymbol = $culture->GetCurrencySymbol();
      $cleaned =~ s/\Q$currencySymbol\E//g;
    }
    
    # Handle parentheses for negative numbers
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowParentheses)) {
      if ($cleaned =~ /^\s*\((.+)\)\s*$/) {
        $cleaned = $1;
        $isNegative = true;
      }
    }
    
    # Handle leading sign
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowLeadingSign)) {
      if ($cleaned =~ s/^([+-])//) {
        $isNegative = ($1 eq '-');
      }
    }
    
    # Handle trailing sign
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowTrailingSign)) {
      if ($cleaned =~ s/([+-])$//) {
        $isNegative = ($1 eq '-');
      }
    }
    
    # Handle thousands separator
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowThousands)) {
      my $groupSep = $culture->GetNumberGroupSeparator();
      $cleaned =~ s/\Q$groupSep\E//g;
    }
    
    # Handle decimal point
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowDecimalPoint)) {
      my $decimalSep = $culture->GetNumberDecimalSeparator();
      if ($cleaned =~ /\Q$decimalSep\E/) {
        $hasDecimal = true;
        $cleaned =~ s/\Q$decimalSep\E/./;  # Convert to standard dot
      }
    }
    
    # Handle hexadecimal
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowHexSpecifier)) {
      # Remove 0x prefix if present
      $cleaned =~ s/^0x//i;
      
      # Validate hex characters
      if ($cleaned !~ /^[0-9a-fA-F]+$/) {
        throw(System::FormatException->new("Input string was not in a correct format"));
      }
      
      # Convert hex to decimal
      $cleaned = hex($cleaned);
    }
    
    # Handle exponential notation
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowExponent)) {
      # This is complex - for now, let Perl handle it
      if ($cleaned =~ /[eE]/) {
        eval {
          $cleaned = 0 + $cleaned;  # Let Perl convert
        };
        if ($@) {
          throw(System::FormatException->new("Input string was not in a correct format"));
        }
      }
    }
    
    # Apply negative sign
    if ($isNegative) {
      if ($cleaned =~ /^-/) {
        # Already negative, make positive
        $cleaned =~ s/^-//;
      } else {
        # Make negative
        $cleaned = "-$cleaned";
      }
    }
    
    return $cleaned;
  }
  
  sub _ConvertToNumber {
    my ($value, $style, $targetType) = @_;
    
    # Handle hexadecimal - already converted in _CleanNumberString
    if (System::Globalization::NumberStyles::HasFlag($style, 
        System::Globalization::NumberStyles::AllowHexSpecifier)) {
      return $value;  # Already converted
    }
    
    # Validate basic number format
    if ($value !~ /^[+-]?\d*\.?\d*([eE][+-]?\d+)?$/) {
      throw(System::FormatException->new("Input string was not in a correct format"));
    }
    
    # Convert to appropriate numeric type
    if ($targetType =~ /Int|UInt|Byte|SByte/) {
      # Integer types
      if ($value =~ /\./) {
        # Has decimal part - check if it's just .0
        my ($whole, $frac) = split /\./, $value;
        if ($frac !~ /^0*$/) {
          throw(System::FormatException->new("Input string was not in a correct format"));
        }
        $value = $whole;
      }
      return int($value);
    } elsif ($targetType =~ /Single|Double|Decimal/) {
      # Floating point types
      return 0 + $value;  # Numeric conversion
    }
    
    return 0 + $value;  # Default numeric conversion
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;