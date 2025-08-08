package System::Collections::Concurrent::ConcurrentDictionary; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::Generic::KeyValuePair;
  
  # ConcurrentDictionary - thread-safe dictionary implementation
  
  sub new {
    my ($class) = @_;
    
    # Create shared data structures for thread safety
    my %dict : shared;
    my $lock : shared;
    
    my $this = bless {
      _dict => \%dict,
      _lock => \$lock,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(keys %{$this->{_dict}});
  }
  
  sub IsEmpty {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(keys %{$this->{_dict}}) == 0 ? 1 : 0;
  }
  
  sub Keys {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return [keys %{$this->{_dict}}];
  }
  
  sub Values {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return [values %{$this->{_dict}}];
  }
  
  # Indexer
  sub Item {
    my ($this, $key, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    if (defined($value)) {
      # Setter
      lock($this->{_lock});
      $this->{_dict}->{$key} = $value;
    } else {
      # Getter
      lock($this->{_lock});
      throw(System::Collections::Generic::KeyNotFoundException->new("Key '$key' not found"))
        unless exists($this->{_dict}->{$key});
      return $this->{_dict}->{$key};
    }
  }
  
  # Methods
  sub TryAdd {
    my ($this, $key, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      return 0;  # Key already exists
    }
    
    $this->{_dict}->{$key} = $value;
    return 1;
  }
  
  sub TryGetValue {
    my ($this, $key, $valueRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      $$valueRef = $this->{_dict}->{$key} if defined($valueRef);
      return 1;
    }
    
    $$valueRef = undef if defined($valueRef);
    return 0;
  }
  
  sub TryRemove {
    my ($this, $key, $valueRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      my $value = delete $this->{_dict}->{$key};
      $$valueRef = $value if defined($valueRef);
      return 1;
    }
    
    $$valueRef = undef if defined($valueRef);
    return 0;
  }
  
  sub TryUpdate {
    my ($this, $key, $newValue, $comparisonValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      my $currentValue = $this->{_dict}->{$key};
      
      # Compare values (simple equality check)
      if ((defined($currentValue) && defined($comparisonValue) && $currentValue eq $comparisonValue) ||
          (!defined($currentValue) && !defined($comparisonValue))) {
        $this->{_dict}->{$key} = $newValue;
        return 1;
      }
    }
    
    return 0;
  }
  
  sub GetOrAdd {
    my ($this, $key, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      return $this->{_dict}->{$key};
    }
    
    $this->{_dict}->{$key} = $value;
    return $value;
  }
  
  sub AddOrUpdate {
    my ($this, $key, $addValue, $updateValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    
    if (exists($this->{_dict}->{$key})) {
      $this->{_dict}->{$key} = $updateValue;
      return $updateValue;
    } else {
      $this->{_dict}->{$key} = $addValue;
      return $addValue;
    }
  }
  
  sub ContainsKey {
    my ($this, $key) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('key')) unless defined($key);
    
    lock($this->{_lock});
    return exists($this->{_dict}->{$key}) ? 1 : 0;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    %{$this->{_dict}} = ();
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    my @pairs;
    for my $key (keys %{$this->{_dict}}) {
      push @pairs, System::Collections::Generic::KeyValuePair->new($key, $this->{_dict}->{$key});
    }
    
    return \@pairs;
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return a snapshot enumerator for thread safety
    my $snapshot = $this->ToArray();
    return System::Collections::Concurrent::ConcurrentDictionaryEnumerator->new($snapshot);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Enumerator for ConcurrentDictionary
package System::Collections::Concurrent::ConcurrentDictionaryEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  sub new {
    my ($class, $snapshot) = @_;
    
    my $this = bless {
      _items => $snapshot || [],
      _index => -1,
      _current => undef,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index}++;
    
    if ($this->{_index} < @{$this->{_items}}) {
      $this->{_current} = $this->{_items}->[$this->{_index}];
      return 1;
    }
    
    $this->{_current} = undef;
    return 0;
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index} = -1;
    $this->{_current} = undef;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;