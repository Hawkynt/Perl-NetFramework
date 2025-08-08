package System::Collections::Concurrent::ConcurrentQueue; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  
  # ConcurrentQueue - thread-safe queue implementation
  
  sub new {
    my ($class) = @_;
    
    # Create shared data structures for thread safety
    my @queue : shared;
    my $lock : shared;
    
    my $this = bless {
      _queue => \@queue,
      _lock => \$lock,
      _count => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_queue}});
  }
  
  sub IsEmpty {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return scalar(@{$this->{_queue}}) == 0 ? 1 : 0;
  }
  
  # Methods
  sub Enqueue {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    push @{$this->{_queue}}, $item;
  }
  
  sub TryDequeue {
    my ($this, $resultRef) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    
    if (@{$this->{_queue}} > 0) {
      my $item = shift @{$this->{_queue}};
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
    
    if (@{$this->{_queue}} > 0) {
      my $item = $this->{_queue}->[0];
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
    @{$this->{_queue}} = ();
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    lock($this->{_lock});
    return [@{$this->{_queue}}];  # Return copy
  }
  
  sub CopyTo {
    my ($this, $array, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    throw(System::ArgumentOutOfRangeException->new('index')) if !defined($index) || $index < 0;
    
    lock($this->{_lock});
    
    my $queue = $this->{_queue};
    throw(System::ArgumentException->new('Not enough space in destination array'))
      if $index + @$queue > @$array;
    
    for my $i (0 .. @$queue - 1) {
      $array->[$index + $i] = $queue->[$i];
    }
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return a snapshot enumerator for thread safety
    my $snapshot = $this->ToArray();
    return System::Collections::Concurrent::ConcurrentQueueEnumerator->new($snapshot);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Enumerator for ConcurrentQueue
package System::Collections::Concurrent::ConcurrentQueueEnumerator; {
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