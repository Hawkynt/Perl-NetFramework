package System::Collections::Generic::Stack; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::IEnumerator;
  
  # Generic Stack<T> implementation (LIFO - Last In, First Out)
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
  
  # Stack operations
  sub Push {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    push @{$this->{_items}}, $item;
    
    # Expand capacity if needed
    if ($this->Count() > $this->{_capacity}) {
      $this->{_capacity} = $this->Count() * 2;
    }
  }
  
  sub Pop {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->Count() == 0) {
      throw(System::InvalidOperationException->new("Stack is empty"));
    }
    
    return pop @{$this->{_items}};
  }
  
  sub Peek {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->Count() == 0) {
      throw(System::InvalidOperationException->new("Stack is empty"));
    }
    
    return $this->{_items}->[-1]; # Last element (top of stack)
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    @{$this->{_items}} = ();
  }
  
  sub Contains {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    for my $stackItem (@{$this->{_items}}) {
      if (defined($stackItem) && defined($item)) {
        if ($stackItem eq $item) {
          return true;
        }
      } elsif (!defined($stackItem) && !defined($item)) {
        return true;
      }
    }
    
    return false;
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return array in stack order (top to bottom)
    return [reverse @{$this->{_items}}];
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
    
    require System::Collections::Generic::StackEnumerator;
    return System::Collections::Generic::StackEnumerator->new($this);
  }
  
  # Internal access for enumerator
  sub _GetItems {
    my ($this) = @_;
    return $this->{_items};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;