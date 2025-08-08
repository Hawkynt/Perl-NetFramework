package System::Collections::Generic::DictionaryKeyEnumerator; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerator;
  
  # Key enumerator for Dictionary<TKey, TValue>
  sub new {
    my ($class, $dictionary) = @_;
    throw(System::ArgumentNullException->new('dictionary')) unless defined($dictionary);
    
    my @keys = keys %{$dictionary->_GetBuckets()};
    
    return bless {
      _dictionary => $dictionary,
      _keys => \@keys,
      _index => -1,
      _current => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IEnumerator implementation
  sub Current {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_index} < 0 || $this->{_index} >= scalar(@{$this->{_keys}})) {
      throw(System::InvalidOperationException->new("Enumeration has not started or has ended"));
    }
    
    return $this->{_current};
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_index}++;
    
    if ($this->{_index} < scalar(@{$this->{_keys}})) {
      my $keyStr = $this->{_keys}->[$this->{_index}];
      my $bucket = $this->{_dictionary}->_GetBuckets()->{$keyStr};
      
      $this->{_current} = $bucket->{key};
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