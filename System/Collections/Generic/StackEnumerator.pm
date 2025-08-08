package System::Collections::Generic::StackEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerator;
  
  # Enumerator for Generic Stack<T> (enumerates from top to bottom)
  sub new {
    my ($class, $stack) = @_;
    throw(System::ArgumentNullException->new('stack')) unless defined($stack);
    
    return bless {
      _stack => $stack,
      _index => $stack->Count(), # Start from top (Count - 1 index)
      _current => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IEnumerator implementation
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_index} >= $this->{_stack}->Count() || $this->{_index} < 0) {
      throw(System::InvalidOperationException->new("Enumeration has not started or has ended"));
    }
    
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index}--;
    
    if ($this->{_index} >= 0) {
      my $items = $this->{_stack}->_GetItems();
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
    
    $this->{_index} = $this->{_stack}->Count();
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