package System::Collections::Generic::Dictionary; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::IEnumerator;
  require System::Collections::Generic::KeyValuePair;
  require System::Collections::Generic::KeyNotFoundException;
  
  # Generic Dictionary<TKey, TValue> implementation
  sub new {
    my ($class, $capacity) = @_;
    $capacity //= 16; # Default capacity
    
    return bless {
      _buckets => {},
      _count => 0,
      _capacity => $capacity,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_count};
  }
  
  sub Keys {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::DictionaryKeyCollection;
    return System::Collections::Generic::DictionaryKeyCollection->new($this);
  }
  
  sub Values {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::DictionaryValueCollection;
    return System::Collections::Generic::DictionaryValueCollection->new($this);
  }
  
  # Indexer
  sub Item {
    my ($this, $key, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    my $keyStr = $this->_GetKeyString($key);
    
    if (@_ > 2) {  # Check argument count instead of value definition
      # Setter - value argument provided (even if undef)
      if (!exists($this->{_buckets}->{$keyStr})) {
        $this->{_count}++;
      }
      $this->{_buckets}->{$keyStr} = { key => $key, value => $value };
      return;
    }
    
    # Getter
    if (!exists($this->{_buckets}->{$keyStr})) {
      throw(System::Collections::Generic::KeyNotFoundException->new("The given key was not present in the dictionary"));
    }
    
    return $this->{_buckets}->{$keyStr}->{value};
  }
  
  # Dictionary methods
  sub Add {
    my ($this, $key, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    my $keyStr = $this->_GetKeyString($key);
    
    if (exists($this->{_buckets}->{$keyStr})) {
      throw(System::ArgumentException->new("An item with the same key has already been added"));
    }
    
    $this->{_buckets}->{$keyStr} = { key => $key, value => $value };
    $this->{_count}++;
  }
  
  sub Remove {
    my ($this, $key) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    my $keyStr = $this->_GetKeyString($key);
    
    if (exists($this->{_buckets}->{$keyStr})) {
      delete $this->{_buckets}->{$keyStr};
      $this->{_count}--;
      return true;
    }
    
    return false;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_buckets} = {};
    $this->{_count} = 0;
  }
  
  sub ContainsKey {
    my ($this, $key) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    my $keyStr = $this->_GetKeyString($key);
    return exists($this->{_buckets}->{$keyStr});
  }
  
  sub ContainsValue {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    for my $bucket (values %{$this->{_buckets}}) {
      if (defined($bucket->{value}) && defined($value)) {
        if ($bucket->{value} eq $value) {
          return true;
        }
      } elsif (!defined($bucket->{value}) && !defined($value)) {
        return true;
      }
    }
    
    return false;
  }
  
  sub TryGetValue {
    my ($this, $key, $value_ref) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    throw(System::ArgumentNullException->new('value')) unless defined($value_ref);
    
    my $keyStr = $this->_GetKeyString($key);
    
    if (exists($this->{_buckets}->{$keyStr})) {
      $$value_ref = $this->{_buckets}->{$keyStr}->{value};
      return true;
    }
    
    $$value_ref = undef;
    return false;
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::DictionaryEnumerator;
    return System::Collections::Generic::DictionaryEnumerator->new($this);
  }
  
  # Internal helper methods
  sub _GetKeyString {
    my ($this, $key) = @_;
    
    # Convert key to string for hashing
    if (!defined($key)) {
      return '__NULL__';
    } elsif (ref($key)) {
      # For objects, use their string representation or memory address
      if ($key->can('ToString')) {
        return $key->ToString();
      } elsif ($key->can('GetHashCode')) {
        return $key->GetHashCode();
      } else {
        return "$key"; # Memory address
      }
    } else {
      return "$key"; # String representation
    }
  }
  
  sub _GetBuckets {
    my ($this) = @_;
    return $this->{_buckets};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;