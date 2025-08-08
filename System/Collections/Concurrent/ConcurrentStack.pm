package System::Collections::Concurrent::ConcurrentStack; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  
  # ConcurrentStack - thread-safe stack implementation
  
  sub new {
    my ($class) = @_;
    
    # Create shared data structures for thread safety
    my @stack : shared;
    my $lock : shared;
    
    my $this = bless {
      _stack => \@stack,
      _lock => \$lock,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_stack}});
  }
  
  sub IsEmpty {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_stack}}) == 0 ? 1 : 0;
  }
  
  # Methods
  sub Push {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    push @{$this->{_stack}}, $item;
  }
  
  sub PushRange {
    my ($this, @items) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    push @{$this->{_stack}}, @items;
  }
  
  sub TryPop {
    my ($this, $resultRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    if (@{$this->{_stack}} > 0) {
      my $item = pop @{$this->{_stack}};
      $$resultRef = $item if defined($resultRef);
      return 1;
    }
    
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  sub TryPopRange {
    my ($this, $items, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('items')) unless defined($items);
    throw(System::ArgumentOutOfRangeException->new('count')) if defined($count) && $count < 0;
    
    lock($this->{_lock});
    
    my $availableCount = scalar(@{$this->{_stack}});
    my $popCount = defined($count) ? ($count < $availableCount ? $count : $availableCount) : $availableCount;
    
    @$items = ();
    for (1..$popCount) {
      push @$items, pop @{$this->{_stack}};
    }
    
    return $popCount;
  }
  
  sub TryPeek {
    my ($this, $resultRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    if (@{$this->{_stack}} > 0) {
      my $item = $this->{_stack}->[-1];  # Top of stack
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
    @{$this->{_stack}} = ();
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    # Return copy in stack order (top to bottom)
    return [reverse @{$this->{_stack}}];
  }
  
  sub CopyTo {
    my ($this, $array, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    throw(System::ArgumentOutOfRangeException->new('index')) if !defined($index) || $index < 0;
    
    lock($this->{_lock});
    
    my $stack = $this->{_stack};
    throw(System::ArgumentException->new('Not enough space in destination array'))
      if $index + @$stack > @$array;
    
    # Copy in stack order (top to bottom)
    my @reversed = reverse @$stack;
    for my $i (0 .. @reversed - 1) {
      $array->[$index + $i] = $reversed[$i];
    }
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return a snapshot enumerator for thread safety
    my $snapshot = $this->ToArray();
    return System::Collections::Concurrent::ConcurrentStackEnumerator->new($snapshot);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Enumerator for ConcurrentStack
package System::Collections::Concurrent::ConcurrentStackEnumerator; {
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