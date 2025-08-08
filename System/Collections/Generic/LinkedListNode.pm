package System::Collections::Generic::LinkedListNode; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Generic LinkedListNode<T> - represents a node in a LinkedList<T>
  sub new {
    my ($class, $value) = @_;
    
    return bless {
      _value => $value,
      _list => undef,
      _next => undef,
      _previous => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Value {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_value};
  }
  
  sub List {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_list};
  }
  
  sub Next {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_next};
  }
  
  sub Previous {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_previous};
  }
  
  # Internal methods for LinkedList to use
  sub _SetList {
    my ($this, $list) = @_;
    $this->{_list} = $list;
  }
  
  sub _GetList {
    my ($this) = @_;
    return $this->{_list};
  }
  
  sub _SetNext {
    my ($this, $next) = @_;
    $this->{_next} = $next;
  }
  
  sub _SetPrevious {
    my ($this, $previous) = @_;
    $this->{_previous} = $previous;
  }
  
  sub _Invalidate {
    my ($this) = @_;
    $this->{_list} = undef;
    $this->{_next} = undef;
    $this->{_previous} = undef;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;