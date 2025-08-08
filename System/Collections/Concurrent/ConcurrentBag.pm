package System::Collections::Concurrent::ConcurrentBag; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  
  # ConcurrentBag - thread-safe unordered collection
  
  sub new {
    my ($class) = @_;
    
    # Create shared data structures for thread safety
    my @bag : shared;
    my $lock : shared;
    
    my $this = bless {
      _bag => \@bag,
      _lock => \$lock,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_bag}});
  }
  
  sub IsEmpty {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_bag}}) == 0 ? 1 : 0;
  }
  
  # Methods
  sub Add {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    push @{$this->{_bag}}, $item;
  }
  
  sub TryTake {
    my ($this, $resultRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    if (@{$this->{_bag}} > 0) {
      # Take from the end (LIFO-like for efficiency)
      my $item = pop @{$this->{_bag}};
      $$resultRef = $item if defined($resultRef);
      return 1;
    }
    
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  sub TryPeek {
    my ($this, $resultRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    if (@{$this->{_bag}} > 0) {
      # Peek at the last item
      my $item = $this->{_bag}->[-1];
      $$resultRef = $item if defined($resultRef);
      return 1;
    }
    
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    @{$this->{_bag}} = ();
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return [@{$this->{_bag}}];  # Return copy
  }
  
  sub CopyTo {
    my ($this, $array, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    throw(System::ArgumentOutOfRangeException->new('index')) if !defined($index) || $index < 0;
    
    lock($this->{_lock});
    
    my $bag = $this->{_bag};
    throw(System::ArgumentException->new('Not enough space in destination array'))
      if $index + @$bag > @$array;
    
    for my $i (0 .. @$bag - 1) {
      $array->[$index + $i] = $bag->[$i];
    }
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return a snapshot enumerator for thread safety
    my $snapshot = $this->ToArray();
    return System::Collections::Concurrent::ConcurrentBagEnumerator->new($snapshot);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Enumerator for ConcurrentBag
package System::Collections::Concurrent::ConcurrentBagEnumerator; {
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