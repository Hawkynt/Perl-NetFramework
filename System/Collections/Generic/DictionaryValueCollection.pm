package System::Collections::Generic::DictionaryValueCollection; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  
  # Value collection for Dictionary<TKey, TValue>
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
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_dictionary}->ContainsValue($value);
  }
  
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my @values = ();
    my $buckets = $this->{_dictionary}->_GetBuckets();
    
    for my $bucket (values %$buckets) {
      push @values, $bucket->{value};
    }
    
    return \@values;
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::DictionaryValueEnumerator;
    return System::Collections::Generic::DictionaryValueEnumerator->new($this->{_dictionary});
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;