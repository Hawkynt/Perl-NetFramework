package System::Int16; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  
  # Int16: 16-bit signed integer (-32,768 to 32,767)
  use constant {
    MinValue => -32768,
    MaxValue => 32767,
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0;
    
    # Validate range
    if ($value < -32768 || $value > 32767) {
      throw(System::OverflowException->new("Value was either too large or too small for an Int16"));
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
    my ($class, $s) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    
    # Remove whitespace
    $s =~ s/^\s+|\s+$//g;
    
    # Check if valid number
    unless ($s =~ /^[+-]?\d+$/) {
      throw(System::FormatException->new('Input string was not in a correct format'));
    }
    
    my $value = int($s);
    
    if ($value < -32768 || $value > 32767) {
      throw(System::OverflowException->new("Value was either too large or too small for an Int16"));
    }
    
    return $class->new($value);
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
      my $val = $this->{_value} < 0 ? $this->{_value} + 65536 : $this->{_value};
      return sprintf($format eq 'X' ? '%04X' : '%04x', $val);
    } elsif ($format =~ /^D(\d+)?$/) {
      my $width = $1 // 1;
      return sprintf("%0${width}d", $this->{_value});
    } elsif ($format =~ /^X(\d+)?$/) {
      my $width = $1 // 4;
      my $val = $this->{_value} < 0 ? $this->{_value} + 65536 : $this->{_value};
      return sprintf("%0${width}X", $val);
    } elsif ($format =~ /^x(\d+)?$/) {
      my $width = $1 // 4;
      my $val = $this->{_value} < 0 ? $this->{_value} + 65536 : $this->{_value};
      return sprintf("%0${width}x", $val);
    } else {
      throw(System::FormatException->new("Format string '$format' is not supported"));
    }
  }
  
  # Comparison methods
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    unless ($other->isa('System::Int16')) {
      throw(System::ArgumentException->new('Object must be of type Int16'));
    }
    
    my $thisValue = $this->{_value};
    my $otherValue = $other->{_value};
    
    return $thisValue <=> $otherValue;
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::Int16');
    
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
    
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    
    my $result = $aVal + $bVal;
    
    if ($result > 32767 || $result < -32768) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int16->new($result);
  }
  
  sub Subtract {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    
    my $result = $aVal - $bVal;
    
    if ($result > 32767 || $result < -32768) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int16->new($result);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    
    my $result = $aVal * $bVal;
    
    if ($result > 32767 || $result < -32768) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Int16->new($result);
  }
  
  sub Divide {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    
    if ($bVal == 0) {
      throw(System::DivideByZeroException->new("Attempted to divide by zero"));
    }
    
    my $result = int($aVal / $bVal);
    return System::Int16->new($result);
  }
  
  # Bitwise operations
  sub BitwiseAnd {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    my $result = $aVal & $bVal;
    return System::Int16->new($result);
  }
  
  sub BitwiseOr {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    my $result = $aVal | $bVal;
    return System::Int16->new($result);
  }
  
  sub BitwiseXor {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Int16')) ? $b->{_value} : $b;
    my $result = $aVal ^ $bVal;
    return System::Int16->new($result);
  }
  
  sub BitwiseNot {
    my ($class, $a) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $result = (~$aVal) & 0xFFFF;
    # Convert back to signed range
    $result = $result > 32767 ? $result - 65536 : $result;
    return System::Int16->new($result);
  }
  
  # Shift operations
  sub LeftShift {
    my ($class, $a, $count) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $result = ($aVal << $count) & 0xFFFF;
    # Convert back to signed range
    $result = $result > 32767 ? $result - 65536 : $result;
    return System::Int16->new($result);
  }
  
  sub RightShift {
    my ($class, $a, $count) = @_;
    my $aVal = (ref($a) && $a->isa('System::Int16')) ? $a->{_value} : $a;
    my $result = $aVal >> $count;
    return System::Int16->new($result);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;