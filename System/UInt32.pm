package System::UInt32; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  
  # UInt32: 32-bit unsigned integer (0 to 4,294,967,295)
  use constant {
    MinValue => 0,
    MaxValue => 4294967295,
  };
  
  sub new {
    my ($class, $value) = @_;
    $value //= 0;
    
    if ($value < 0 || $value > 4294967295) {
      throw(System::OverflowException->new("Value was either too large or too small for a UInt32"));
    }
    
    return bless { _value => int($value) }, ref($class) || $class || __PACKAGE__;
  }
  
  sub Value { $_[0]->{_value} }
  
  sub Parse {
    my ($class, $s) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    $s =~ s/^\s+|\s+$//g;
    unless ($s =~ /^[+-]?\d+$/) {
      throw(System::FormatException->new('Input string was not in a correct format'));
    }
    my $value = int($s);
    if ($value < 0 || $value > 4294967295) {
      throw(System::OverflowException->new("Value was either too large or too small for a UInt32"));
    }
    return $class->new($value);
  }
  
  sub TryParse {
    my ($class, $s, $result_ref) = @_;
    eval { $$result_ref = $class->Parse($s); };
    return !$@;
  }
  
  sub ToString {
    my ($this, $format) = @_;
    return "$this->{_value}" unless defined($format) && $format ne '' && $format ne 'G';
    if ($format eq 'X' || $format eq 'x') {
      return sprintf($format eq 'X' ? '%08X' : '%08x', $this->{_value});
    } elsif ($format =~ /^([XxD])(\d+)$/) {
      my ($type, $width) = ($1, $2);
      return sprintf($type eq 'X' ? "%0${width}X" : $type eq 'x' ? "%0${width}x" : "%0${width}d", $this->{_value});
    }
    throw(System::FormatException->new("Format string '$format' is not supported"));
  }
  
  sub CompareTo { $_[0]->{_value} <=> $_[1]->{_value} }
  sub Equals { defined($_[1]) && $_[1]->isa('System::UInt32') && $_[0]->{_value} == $_[1]->{_value} }
  sub GetHashCode { $_[0]->{_value} }
  
  # Arithmetic operations
  sub Add {
    my ($class, $a, $b) = @_;
    my $aVal = $a->isa('System::UInt32') ? $a->{_value} : $a;
    my $bVal = $b->isa('System::UInt32') ? $b->{_value} : $b;
    my $result = $aVal + $bVal;
    throw(System::OverflowException->new("Arithmetic operation resulted in an overflow")) if $result > 4294967295;
    return System::UInt32->new($result);
  }
  
  sub Multiply {
    my ($class, $a, $b) = @_;
    my $aVal = $a->isa('System::UInt32') ? $a->{_value} : $a;
    my $bVal = $b->isa('System::UInt32') ? $b->{_value} : $b;
    my $result = $aVal * $bVal;
    throw(System::OverflowException->new("Arithmetic operation resulted in an overflow")) if $result > 4294967295;
    return System::UInt32->new($result);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;