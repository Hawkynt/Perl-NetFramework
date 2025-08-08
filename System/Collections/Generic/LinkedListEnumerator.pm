package System::Collections::Generic::LinkedListEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerator;
  
  # Enumerator for Generic LinkedList<T>
  sub new {
    my ($class, $linkedList) = @_;
    throw(System::ArgumentNullException->new('linkedList')) unless defined($linkedList);
    
    return bless {
      _linkedList => $linkedList,
      _current => undef,
      _node => undef,
      _started => false,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IEnumerator implementation
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->{_started} || !$this->{_node}) {
      throw(System::InvalidOperationException->new("Enumeration has not started or has ended"));
    }
    
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->{_started}) {
      $this->{_node} = $this->{_linkedList}->First();
      $this->{_started} = true;
    } else {
      $this->{_node} = $this->{_node} ? $this->{_node}->Next() : undef;
    }
    
    if ($this->{_node}) {
      $this->{_current} = $this->{_node}->Value();
      return true;
    } else {
      $this->{_current} = undef;
      return false;
    }
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_current} = undef;
    $this->{_node} = undef;
    $this->{_started} = false;
  }
  
  # Disposal (no-op in Perl)
  sub Dispose {
    my ($this) = @_;
    # No-op in Perl - garbage collection handles cleanup
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;