package System::Collections::Generic::DictionaryKeyCollection; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  
  # Key collection for Dictionary<TKey, TValue>
  sub new {
    my ($class, $dictionary) = @_;
    throw(System::ArgumentNullException->new('dictionary')) unless defined($dictionary);
    
    return bless {
      _dictionary => $dictionary,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_dictionary}->Count();
  }
  
  # Methods
  sub Contains {
    my ($this, $key) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_dictionary}->ContainsKey($key);
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my @keys = ();
    my $buckets = $this->{_dictionary}->_GetBuckets();
    
    for my $bucket (values %$buckets) {
      push @keys, $bucket->{key};
    }
    
    return \@keys;
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::DictionaryKeyEnumerator;
    return System::Collections::Generic::DictionaryKeyEnumerator->new($this->{_dictionary});
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;