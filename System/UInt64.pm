package System::UInt64; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  use Math::BigInt;
  
  # UInt64: 64-bit unsigned integer (0 to 18,446,744,073,709,551,615)
  use constant {
    MinValue => Math::BigInt->new('0'),
    MaxValue => Math::BigInt->new('18446744073709551615'),
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0;
    
    # Convert to BigInt for range checking
    my $bigValue = Math::BigInt->new($value);
    
    # Validate range
    if ($bigValue < MinValue || $bigValue > MaxValue) {
      throw(System::OverflowException->new("Value was either too large or too small for a UInt64"));
    }
    
    return bless {
      _value => $bigValue,
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
    
    # Check if valid number (no negative for unsigned)
    unless ($s =~ /^\+?\d+$/) {
      throw(System::FormatException->new('Input string was not in a correct format'));
    }
    
    my $value = Math::BigInt->new($s);
    
    if ($value < MinValue || $value > MaxValue) {
      throw(System::OverflowException->new("Value was either too large or too small for a UInt64"));
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
    
    my $value = $this->{_value};
    
    if (!defined($format) || $format eq '' || $format eq 'G') {
      return $value->bstr();
    } elsif ($format eq 'X' || $format eq 'x') {
      my $hexStr = $value->as_hex();
      $hexStr =~ s/^0x//;
      return $format eq 'X' ? uc($hexStr) : lc($hexStr);
    } elsif ($format =~ /^D(\d+)?$/) {
      my $width = $1 // 1;
      return sprintf("%0${width}s", $value->bstr());
    } elsif ($format =~ /^X(\d+)?$/) {
      my $width = $1 // 16;
      my $hexStr = $value->as_hex();
      $hexStr =~ s/^0x//;
      return sprintf("%0${width}s", uc($hexStr));
    } elsif ($format =~ /^x(\d+)?$/) {
      my $width = $1 // 16;
      my $hexStr = $value->as_hex();
      $hexStr =~ s/^0x//;
      return sprintf("%0${width}s", lc($hexStr));
    } else {
      throw(System::FormatException->new("Format string '$format' is not supported"));
    }
  }
  
  # Comparison methods
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    unless ($other->isa('System::UInt64')) {
      throw(System::ArgumentException->new('Object must be of type UInt64'));
    }
    
    return $this->{_value}->bcmp($other->{_value});
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::UInt64');
    
    return $this->{_value}->beq($other->{_value});
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    # Use lower 32 bits for hash code
    return int($this->{_value}->bmod(4294967296));
  }
  
  # Arithmetic operations
  sub Add {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = ref($a) && $a->isa('System::UInt64') ? $a->{_value} : Math::BigInt->new($a);
    my $bVal = ref($b) && $b->isa('System::UInt64') ? $b->{_value} : Math::BigInt->new($b);
    
    my $result = $aVal->copy()->badd($bVal);
    
    if ($result > MaxValue) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::UInt64->new($result);
  }
  
  sub Subtract {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = ref($a) && $a->isa('System::UInt64') ? $a->{_value} : Math::BigInt->new($a);
    my $bVal = ref($b) && $b->isa('System::UInt64') ? $b->{_value} : Math::BigInt->new($b);
    
    my $result = $aVal->copy()->bsub($bVal);
    
    if ($result < MinValue) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::UInt64->new($result);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = ref($a) && $a->isa('System::UInt64') ? $a->{_value} : Math::BigInt->new($a);
    my $bVal = ref($b) && $b->isa('System::UInt64') ? $b->{_value} : Math::BigInt->new($b);
    
    my $result = $aVal->copy()->bmul($bVal);
    
    if ($result > MaxValue) {
      throw(System::OverflowException->new("Arithmetic operation resulted in an overflow"));
    }
    
    return System::UInt64->new($result);
  }
  
  sub Divide {
    my ($class, $a, $b) = @_;
    throw(System::ArgumentNullException->new('a')) unless defined($a);
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    
    my $aVal = ref($a) && $a->isa('System::UInt64') ? $a->{_value} : Math::BigInt->new($a);
    my $bVal = ref($b) && $b->isa('System::UInt64') ? $b->{_value} : Math::BigInt->new($b);
    
    if ($bVal->is_zero()) {
      throw(System::DivideByZeroException->new("Attempted to divide by zero"));
    }
    
    my $result = $aVal->copy()->bdiv($bVal);
    return System::UInt64->new($result);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;