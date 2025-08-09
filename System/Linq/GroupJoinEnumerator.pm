package System::Linq::GroupJoinEnumerator; {
  use base 'System::Collections::IEnumerator';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Array;
  
  sub new {
    my ($class, $outer, $inner, $outerKeySelector, $innerKeySelector, $resultSelector) = @_;
    
    my $this = bless {
      _outer => $outer,
      _inner => $inner,
      _outerKeySelector => $outerKeySelector,
      _innerKeySelector => $innerKeySelector,
      _resultSelector => $resultSelector,
      _outerEnumerator => undef,
      _innerLookup => undef,
      _current => undef,
      _disposed => false,
      _initialized => false,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  sub _Initialize {
    my ($this) = @_;
    return if $this->{_initialized};
    
    # Build hash map of inner items grouped by key
    $this->{_innerLookup} = {};
    my $innerEnumerator = $this->{_inner}->GetEnumerator();
    while ($innerEnumerator->MoveNext()) {
      my $innerItem = $innerEnumerator->Current;
      my $innerKey = &{$this->{_innerKeySelector}}($innerItem);
      my $keyStr = defined($innerKey) ? "$innerKey" : "";
      push @{$this->{_innerLookup}->{$keyStr}}, $innerItem;
    }
    $innerEnumerator->Dispose();
    
    $this->{_outerEnumerator} = $this->{_outer}->GetEnumerator();
    $this->{_initialized} = true;
  }
  
  sub MoveNext {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('GroupJoinEnumerator')) if $this->{_disposed};
    
    $this->_Initialize();
    
    # Move to next outer item
    if ($this->{_outerEnumerator}->MoveNext()) {
      my $outerItem = $this->{_outerEnumerator}->Current;
      my $outerKey = &{$this->{_outerKeySelector}}($outerItem);
      my $keyStr = defined($outerKey) ? "$outerKey" : "";
      
      # Get inner items for this key (or empty array if none)
      my $innerItems = exists $this->{_innerLookup}->{$keyStr} ? 
                       $this->{_innerLookup}->{$keyStr} : [];
      my $innerArray = System::Array->new(@$innerItems);
      
      # Call result selector with outer item and inner group
      $this->{_current} = &{$this->{_resultSelector}}($outerItem, $innerArray);
      return true;
    }
    
    return false;
  }
  
  sub Current {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('GroupJoinEnumerator')) if $this->{_disposed};
    return $this->{_current};
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('GroupJoinEnumerator')) if $this->{_disposed};
    throw(System::NotSupportedException->new('Reset not supported'));
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    
    if (defined($this->{_outerEnumerator})) {
      $this->{_outerEnumerator}->Dispose();
    }
    
    $this->{_disposed} = true;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;