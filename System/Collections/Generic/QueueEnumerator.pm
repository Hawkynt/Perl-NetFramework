package System::Collections::Generic::QueueEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerator;
  
  # Enumerator for Generic Queue<T> (enumerates from front to back)
  sub new {
    my ($class, $queue) = @_;
    throw(System::ArgumentNullException->new('queue')) unless defined($queue);
    
    return bless {
      _queue => $queue,
      _index => -1,
      _current => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IEnumerator implementation
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_index} < 0 || $this->{_index} >= $this->{_queue}->Count()) {
      throw(System::InvalidOperationException->new("Enumeration has not started or has ended"));
    }
    
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index}++;
    
    if ($this->{_index} < $this->{_queue}->Count()) {
      my $items = $this->{_queue}->_GetItems();
      $this->{_current} = $items->[$this->{_index}];
      return true;
    } else {
      $this->{_current} = undef;
      return false;
    }
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index} = -1;
    $this->{_current} = undef;
  }
  
  # Disposal (no-op in Perl)
  sub Dispose {
    my ($this) = @_;
    # No-op in Perl - garbage collection handles cleanup
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;