package System::Byte; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  
  # Byte: 8-bit unsigned integer (0 to 255)
  use constant {
    MinValue => 0,
    MaxValue => 255,
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0;
    
    # Validate range
    if ($value < 0 || $value > 255) {
      throw(System::OverflowException->new("Value was either too large or too small for a Byte"));
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
    
    if ($value < 0 || $value > 255) {
      throw(System::OverflowException->new("Value was either too large or too small for a Byte"));
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
      return sprintf($format eq 'X' ? '%02X' : '%02x', $this->{_value});
    } elsif ($format =~ /^D(\d+)?$/) {
      my $width = $1 // 1;
      return sprintf("%0${width}d", $this->{_value});
    } elsif ($format =~ /^X(\d+)?$/) {
      my $width = $1 // 2;
      return sprintf("%0${width}X", $this->{_value});
    } elsif ($format =~ /^x(\d+)?$/) {
      my $width = $1 // 2;
      return sprintf("%0${width}x", $this->{_value});
    } else {
      throw(System::FormatException->new("Format string '$format' is not supported"));
    }
  }
  
  # Comparison methods
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    unless ($other->isa('System::Byte')) {
      throw(System::ArgumentException->new('Object must be of type Byte'));
    }
    
    my $thisValue = $this->{_value};
    my $otherValue = $other->{_value};
    
    return $thisValue <=> $otherValue;
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::Byte');
    
    return $this->{_value} == $other->{_value};
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_value};
  }
  
  # Arithmetic operations (return new instances)
  sub Add {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    
    my $result = $aVal + $bVal;
    
    if ($result > 255) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Byte->new($result);
  }
  
  sub Subtract {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    
    my $result = $aVal - $bVal;
    
    if ($result < 0) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Byte->new($result);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    
    my $result = $aVal * $bVal;
    
    if ($result > 255) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::Byte->new($result);
  }
  
  sub Divide {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    
    if ($bVal == 0) {
      throw(System::DivideByZeroException->new("Attempted to divide by zero"));
    }
    
    my $result = int($aVal / $bVal);
    return System::Byte->new($result);
  }
  
  # Bitwise operations
  sub BitwiseAnd {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    return System::Byte->new($aVal & $bVal);
  }
  
  sub BitwiseOr {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    return System::Byte->new($aVal | $bVal);
  }
  
  sub BitwiseXor {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Byte')) ? $b->{_value} : $b;
    return System::Byte->new($aVal ^ $bVal);
  }
  
  sub BitwiseNot {
    my ($class, $a) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    my $aVal = (ref($a) && $a->isa('System::Byte')) ? $a->{_value} : $a;
    return System::Byte->new((~$aVal) & 0xFF); # Mask to 8 bits
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;