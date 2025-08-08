package System::Collections::Generic::ListEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerator;
  
  # Enumerator for Generic List<T>
  sub new {
    my ($class, $list) = @_;
    throw(System::ArgumentNullException->new('list')) unless defined($list);
    
    return bless {
      _list => $list,
      _index => -1,
      _current => undef,
      _version => 0, # For modification detection (simplified)
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IEnumerator implementation
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_index} < 0 || $this->{_index} >= $this->{_list}->Count()) {
      throw(System::InvalidOperationException->new("Enumeration has not started or has ended"));
    }
    
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index}++;
    
    if ($this->{_index} < $this->{_list}->Count()) {
      $this->{_current} = $this->{_list}->Item($this->{_index});
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
  
  # Disposal (no-op in Perl, but part of the interface)
  sub Dispose {
    my ($this) = @_;
    # No-op in Perl - garbage collection handles cleanup
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;