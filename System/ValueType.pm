package System::ValueType; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Object;
  
  # ValueType is the base class for all value types in .NET
  # It provides default implementations for Equals and GetHashCode
  # that work based on value equality rather than reference equality
  
  sub new {
    my ($class, @args) = @_;
    
    return bless {}, ref($class) || $class || __PACKAGE__;
  }
  
  # Default Equals implementation for value types
  # This should be overridden by derived classes for proper value comparison
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    
    # Default implementation: check if same type and same internal structure
    return false unless ref($this) eq ref($other);
    
    # For value types, we compare the internal hash structure
    # This is a simplified implementation - real .NET does field-by-field comparison
    return $this->GetHashCode() == $other->GetHashCode();
  }
  
  # Default GetHashCode implementation for value types
  # This should be overridden by derived classes for proper hashing
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Default implementation: hash based on internal structure
    # This is simplified - real .NET does field-by-field hashing
    my $hash = 0;
    
    # Simple hash based on object keys and values
    for my $key (sort keys %$this) {
      my $value = $this->{$key};
      if (defined($value)) {
        if (ref($value)) {
          $hash ^= ref($value) =~ tr/://c; # Count non-colon chars in package name
        } else {
          # Simple hash of the string representation
          $hash ^= length($value);
          for my $char (split //, "$value") {
            $hash = (($hash << 5) + $hash) + ord($char);
            $hash &= 0xFFFFFFFF; # Keep as 32-bit integer
          }
        }
      }
    }
    
    return $hash;
  }
  
  # ToString should be overridden by derived classes
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Default implementation returns the type name
    my $typeName = ref($this) || 'System::ValueType';
    $typeName =~ s/^System:://; # Remove System:: prefix for display
    return $typeName;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;