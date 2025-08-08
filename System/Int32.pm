package System::Int32; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  
  # Int32: 32-bit signed integer (-2,147,483,648 to 2,147,483,647)
  use constant {
    MinValue => -2147483648,
    MaxValue => 2147483647,
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0;
    
    # Validate range
    if ($value < -2147483648 || $value > 2147483647) {
      throw(System::OverflowException->new("Value was either too large or too small for an Int32"));
    }
    
    # Ensure integer value
    $value = int($value);
    
    return bless {
      _value => $value,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  sub Value {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_value};
  }
  
  # Parsing methods
  sub Parse {
    my ($class, $s, $style, $provider) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    
    # Handle different overloads
    if (!defined($style)) {
      # Parse(string) overload - use basic parsing
      # Remove whitespace
      $s =~ s/^\s+|\s+$//g;
      
      # Check if valid number
      unless ($s =~ /^[+-]?\d+$/) {
        throw(System::FormatException->new('Input string was not in a correct format'));
      }
      
      my $value = int($s);
      
      if ($value < -2147483648 || $value > 2147483647) {
        throw(System::OverflowException->new("Value was either too large or too small for an Int32"));
      }
      
      return $class->new($value);
    } else {
      # Parse(string, NumberStyles, IFormatProvider) overload
      require System::Globalization::NumberParser;
      
      $provider //= System::Globalization::CultureInfo->CurrentCulture();
      
      my $value = System::Globalization::NumberParser::ParseWithStyle(
        $s, $style, $provider, 'System::Int32'
      );
      
      if ($value < -2147483648 || $value > 2147483647) {
        throw(System::OverflowException->new("Value was either too large or too small for an Int32"));
      }
      
      return $class->new($value);
    }
  }
  
  sub TryParse {
    my ($class, $s, $result_ref) = @_;
    throw(System::ArgumentNullException->new('result')) unless defined($result_ref);
    
    eval {
      $$result_ref = $class->Parse($s);
    };
    
    return !$@;
  }
  
  # Formatting methods
  sub ToString {
    my ($this, $format) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!defined($format) || $format eq '' || $format eq 'G') {
      return "$this->{_value}";
    } elsif ($format eq 'X' || $format eq 'x') {
      # For negative numbers, show two's complement representation
      my $val = $this->{_value} < 0 ? $this->{_value} + 4294967296 : $this->{_value};
      return sprintf($format eq 'X' ? '%08X' : '%08x', $val);
    } elsif ($format =~ /^D(\d+)?$/) {
      my $width = $1 // 1;
      return sprintf("%0${width}d", $this->{_value});
    } elsif ($format =~ /^X(\d+)?$/) {
      my $width = $1 // 8;
      my $val = $this->{_value} < 0 ? $this->{_value} + 4294967296 : $this->{_value};
      return sprintf("%0${width}X", $val);
    } elsif ($format =~ /^x(\d+)?$/) {
      my $width = $1 // 8;
      my $val = $this->{_value} < 0 ? $this->{_value} + 4294967296 : $this->{_value};
      return sprintf("%0${width}x", $val);
    } elsif ($format =~ /^N(\d+)?$/) {
      my $decimals = $1 // 2;
      my $formatted = reverse join(',', (reverse split //, sprintf("%.0f", $this->{_value})) =~ /.{1,3}/g);
      return $decimals > 0 ? "$formatted." . ('0' x $decimals) : $formatted;
    } elsif ($format =~ /^C(\d+)?$/) {
      my $decimals = $1 // 2;
      my $formatted = reverse join(',', (reverse split //, sprintf("%.0f", abs($this->{_value}))) =~ /.{1,3}/g);
      my $currency = $decimals > 0 ? "\$${formatted}." . ('0' x $decimals) : "\$${formatted}";
      return $this->{_value} < 0 ? "($currency)" : $currency;
    } else {
      throw(System::FormatException->new("Format string '$format' is not supported"));
    }
  }
  
  # Comparison methods
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    unless ($other->isa('System::Int32')) {
      throw(System::ArgumentException->new('Object must be of type Int32'));
    }
    
    my $thisValue = $this->{_value};
    my $otherValue = $other->{_value};
    
    return $thisValue <=> $otherValue;
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::Int32');
    
    return $this->{_value} == $other->{_value};
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_value};
  }
  
  # Arithmetic operations
  sub Add {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    
    my $result = $aVal + $bVal;
    
    if ($result > 2147483647 || $result < -2147483648) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int32->new($result);
  }
  
  sub Subtract {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    
    my $result = $aVal - $bVal;
    
    if ($result > 2147483647 || $result < -2147483648) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int32->new($result);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    
    my $result = $aVal * $bVal;
    
    if ($result > 2147483647 || $result < -2147483648) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int32->new($result);
  }
  
  sub Divide {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    
    if ($bVal == 0) {
      throw(System::DivideByZeroException->new("Attempted to divide by zero"));
    }
    
    my $result = int($aVal / $bVal);
    return System::Int32->new($result);
  }
  
  sub Modulo {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    
    if ($bVal == 0) {
      throw(System::DivideByZeroException->new("Attempted to divide by zero"));
    }
    
    my $result = $aVal % $bVal;
    return System::Int32->new($result);
  }
  
  # Bitwise operations
  sub BitwiseAnd {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    my $result = $aVal & $bVal;
    return System::Int32->new($result);
  }
  
  sub BitwiseOr {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    my $result = $aVal | $bVal;
    return System::Int32->new($result);
  }
  
  sub BitwiseXor {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int32')) ? $b->{_value} : $b;
    my $result = $aVal ^ $bVal;
    return System::Int32->new($result);
  }
  
  sub BitwiseNot {
    my ($class, $a) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $result = ~$aVal;
    return System::Int32->new($result);
  }
  
  # Shift operations
  sub LeftShift {
    my ($class, $a, $count) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $result = $aVal << ($count & 0x1F); # Mask to 5 bits (0-31)
    return System::Int32->new($result);
  }
  
  sub RightShift {
    my ($class, $a, $count) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    my $result = $aVal >> ($count & 0x1F); # Mask to 5 bits (0-31)
    return System::Int32->new($result);
  }
  
  # Math utility methods
  sub Abs {
    my ($class, $a) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    
    if ($aVal == -2147483648) {
      throw(System::OverflowException->new("Negating the minimum value results in overflow"));
    }
    
    return System::Int32->new(abs($aVal));
  }
  
  sub Sign {
    my ($class, $a) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int32')) ? $a->{_value} : $a;
    return System::Int32->new($aVal <=> 0);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;