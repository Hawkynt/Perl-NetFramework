package System::Collections::Generic::KeyValuePair; {
  use base 'System::ValueType';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::ValueType;
  
  # Generic KeyValuePair<TKey, TValue> structure
  sub new {
    my ($class, $key, $value) = @_;
    
    return bless {
      _key => $key,
      _value => $value,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Key {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_key};
  }
  
  sub Value {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_value};
  }
  
  # Overrides from ValueType
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $keyStr = defined($this->{_key}) ? $this->{_key} : '<null>';
    my $valueStr = defined($this->{_value}) ? $this->{_value} : '<null>';
    
    return "[$keyStr, $valueStr]";
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::Collections::Generic::KeyValuePair');
    
    # Compare keys
    my $keysEqual = false;
    if (defined($this->{_key}) && defined($other->{_key})) {
      $keysEqual = ($this->{_key} eq $other->{_key});
    } elsif (!defined($this->{_key}) && !defined($other->{_key})) {
      $keysEqual = true;
    }
    
    # Compare values
    my $valuesEqual = false;
    if (defined($this->{_value}) && defined($other->{_value})) {
      $valuesEqual = ($this->{_value} eq $other->{_value});
    } elsif (!defined($this->{_value}) && !defined($other->{_value})) {
      $valuesEqual = true;
    }
    
    return $keysEqual && $valuesEqual;
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $keyHash = defined($this->{_key}) ? unpack("%32C*", "$this->{_key}") : 0;
    my $valueHash = defined($this->{_value}) ? unpack("%32C*", "$this->{_value}") : 0;
    
    return $keyHash ^ $valueHash;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;