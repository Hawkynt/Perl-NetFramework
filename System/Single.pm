package System::Single; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  use POSIX qw(isnan isinf);
  
  # Single: 32-bit floating-point number
  use constant {
    MinValue => -3.4028235e+38,
    MaxValue => 3.4028235e+38,
    Epsilon => 1.175494e-38,
    PositiveInfinity => 'inf',
    NegativeInfinity => '-inf',
    NaN => 'nan',
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0.0;
    
    return bless { _value => $value + 0.0 }, ref($class) || $class || __PACKAGE__;
  }
  
  sub Value { $_[0]->{_value} }
  
  sub Parse {
    my ($class, $s) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    $s =~ s/^\s+|\s+$//g;
    
    # Handle special values
    return $class->new('inf') if lc($s) eq 'infinity' || lc($s) eq 'inf';
    return $class->new('-inf') if lc($s) eq '-infinity' || lc($s) eq '-inf';
    return $class->new('nan') if lc($s) eq 'nan';
    
    unless ($s =~ /^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/) {
      throw(System::FormatException->new('Input string was not in a correct format'));
    }
    
    my $value = $s + 0.0;
    return $class->new($value);
  }
  
  sub TryParse {
    my ($class, $s, $result_ref) = @_;
    eval { $$result_ref = $class->Parse($s); };
    return !$@;
  }
  
  sub ToString {
    my ($this, $format) = @_;
    my $value = $this->{_value};
    
    return 'NaN' if isnan($value);
    return 'Infinity' if isinf($value) && $value > 0;
    return '-Infinity' if isinf($value) && $value < 0;
    
    return "$value" unless defined($format) && $format ne '' && $format ne 'G';
    
    if ($format =~ /^F(\d+)?$/) {
      my $decimals = $1 // 2;
      return sprintf("%.${decimals}f", $value);
    } elsif ($format =~ /^E(\d+)?$/) {
      my $decimals = $1 // 6;
      return sprintf("%.${decimals}E", $value);
    } elsif ($format =~ /^e(\d+)?$/) {
      my $decimals = $1 // 6;
      return sprintf("%.${decimals}e", $value);
    }
    
    throw(System::FormatException->new("Format string '$format' is not supported"));
  }
  
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    throw(System::ArgumentException->new('Object must be of type Single')) unless $other->isa('System::Single');
    
    my $thisVal = $this->{_value};
    my $otherVal = $other->{_value};
    
    # Handle NaN comparisons
    return 0 if isnan($thisVal) && isnan($otherVal);
    return 1 if !isnan($thisVal) && isnan($otherVal);
    return -1 if isnan($thisVal) && !isnan($otherVal);
    
    return $thisVal <=> $otherVal;
  }
  
  sub Equals {
    my ($this, $other) = @_;
    return false unless defined($other) && $other->isa('System::Single');
    
    my $thisVal = $this->{_value};
    my $otherVal = $other->{_value};
    
    # NaN is not equal to anything, including itself
    return false if isnan($thisVal) || isnan($otherVal);
    
    return $thisVal == $otherVal;
  }
  
  sub GetHashCode { 
    my $value = $_[0]->{_value};
    return 0 if isnan($value);
    return int($value);
  }
  
  # Special value tests
  sub IsNaN { 
    my ($class_or_value, $value) = @_;
    # If called as static method, $value is the actual parameter
    my $v = defined($value) ? (ref($value) && $value->isa('System::Single') ? $value->{_value} : $value) 
                            : (ref($class_or_value) && $class_or_value->isa('System::Single') ? $class_or_value->{_value} : $class_or_value);
    return isnan($v);
  }
  sub IsInfinity { 
    my ($class_or_value, $value) = @_;
    my $v = defined($value) ? (ref($value) && $value->isa('System::Single') ? $value->{_value} : $value) 
                            : (ref($class_or_value) && $class_or_value->isa('System::Single') ? $class_or_value->{_value} : $class_or_value);
    return isinf($v);
  }
  sub IsPositiveInfinity { 
    my ($class_or_value, $value) = @_;
    my $v = defined($value) ? (ref($value) && $value->isa('System::Single') ? $value->{_value} : $value) 
                            : (ref($class_or_value) && $class_or_value->isa('System::Single') ? $class_or_value->{_value} : $class_or_value);
    return isinf($v) && $v > 0;
  }
  sub IsNegativeInfinity { 
    my ($class_or_value, $value) = @_;
    my $v = defined($value) ? (ref($value) && $value->isa('System::Single') ? $value->{_value} : $value) 
                            : (ref($class_or_value) && $class_or_value->isa('System::Single') ? $class_or_value->{_value} : $class_or_value);
    return isinf($v) && $v < 0;
  }
  sub IsFinite { 
    my ($class_or_value, $value) = @_;
    my $v = defined($value) ? (ref($value) && $value->isa('System::Single') ? $value->{_value} : $value) 
                            : (ref($class_or_value) && $class_or_value->isa('System::Single') ? $class_or_value->{_value} : $class_or_value);
    return !isnan($v) && !isinf($v);
  }
  
  # Arithmetic operations
  sub Add {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Single')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Single')) ? $b->{_value} : $b;
    return System::Single->new($aVal + $bVal);
  }
  
  sub Subtract {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Single')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Single')) ? $b->{_value} : $b;
    return System::Single->new($aVal - $bVal);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Single')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Single')) ? $b->{_value} : $b;
    return System::Single->new($aVal * $bVal);
  }
  
  sub Divide {
    my ($class, $a, $b) = @_;
    my $aVal = (ref($a) && $a->isa('System::Single')) ? $a->{_value} : $a;
    my $bVal = (ref($b) && $b->isa('System::Single')) ? $b->{_value} : $b;
    return System::Single->new($aVal / $bVal);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;