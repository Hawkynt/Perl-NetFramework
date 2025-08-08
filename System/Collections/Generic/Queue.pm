package System::Collections::Generic::Queue; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::IEnumerator;
  
  # Generic Queue<T> implementation (FIFO - First In, First Out)
  sub new {
    my ($class, $capacity) = @_;
    $capacity //= 10; # Default capacity
    
    return bless {
      _items => [],
      _capacity => $capacity,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties  
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return scalar(@{$this->{_items}});
  }
  
  # Queue operations
  sub Enqueue {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    push @{$this->{_items}}, $item;
    
    # Expand capacity if needed
    if ($this->Count() > $this->{_capacity}) {
      $this->{_capacity} = $this->Count() * 2;
    }
  }
  
  sub Dequeue {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->Count() == 0) {
      throw(System::InvalidOperationException->new("Queue is empty"));
    }
    
    return shift @{$this->{_items}};
  }
  
  sub Peek {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->Count() == 0) {
      throw(System::InvalidOperationException->new("Queue is empty"));
    }
    
    return $this->{_items}->[0]; # First element (front of queue)
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    @{$this->{_items}} = ();
  }
  
  sub Contains {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    for my $queueItem (@{$this->{_items}}) {
      if (defined($queueItem) && defined($item)) {
        if ($queueItem eq $item) {
          return true;
        }
      } elsif (!defined($queueItem) && !defined($item)) {
        return true;
      }
    }
    
    return false;
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return array in queue order (front to back)
    return [@{$this->{_items}}];
  }
  
  sub TrimExcess {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_capacity} = $this->Count();
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::QueueEnumerator;
    return System::Collections::Generic::QueueEnumerator->new($this);
  }
  
  # Internal access for enumerator
  sub _GetItems {
    my ($this) = @_;
    return $this->{_items};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;