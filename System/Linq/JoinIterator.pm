package System::Linq::JoinCollection; {
  use base 'System::Collections::IEnumerable';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Linq::JoinEnumerator;
  
  sub new {
    my ($class, $outer, $inner, $outerKeySelector, $innerKeySelector, $resultSelector) = @_;
    
    return bless {
      _outer => $outer,
      _inner => $inner,
      _outerKeySelector => $outerKeySelector,
      _innerKeySelector => $innerKeySelector,
      _resultSelector => $resultSelector,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  sub GetEnumerator {
    my ($this) = @_;
    return System::Linq::JoinEnumerator->new(
      $this->{_outer}, 
      $this->{_inner}, 
      $this->{_outerKeySelector}, 
      $this->{_innerKeySelector}, 
      $this->{_resultSelector}
    );
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

package System::Linq::JoinEnumerator; {
  use base 'System::Collections::IEnumerator';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
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
      _currentOuterItem => undef,
      _currentInnerItems => undef,
      _innerIndex => 0,
      _current => undef,
      _disposed => false,
      _initialized => false,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  sub _Initialize {
    my ($this) = @_;
    return if $this->{_initialized};
    
    # Build hash map of inner items by key
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
    throw(System::ObjectDisposedException->new('JoinEnumerator')) if $this->{_disposed};
    
    $this->_Initialize();
    
    # If we have inner items for current outer item, continue with them
    if (defined($this->{_currentInnerItems}) && $this->{_innerIndex} < @{$this->{_currentInnerItems}}) {
      my $innerItem = $this->{_currentInnerItems}->[$this->{_innerIndex}];
      $this->{_current} = &{$this->{_resultSelector}}($this->{_currentOuterItem}, $innerItem);
      $this->{_innerIndex}++;
      return true;
    }
    
    # Move to next outer item that has matches
    while ($this->{_outerEnumerator}->MoveNext()) {
      my $outerItem = $this->{_outerEnumerator}->Current;
      my $outerKey = &{$this->{_outerKeySelector}}($outerItem);
      my $keyStr = defined($outerKey) ? "$outerKey" : "";
      
      if (exists $this->{_innerLookup}->{$keyStr}) {
        $this->{_currentOuterItem} = $outerItem;
        $this->{_currentInnerItems} = $this->{_innerLookup}->{$keyStr};
        $this->{_innerIndex} = 1; # Start from 1 since we'll return the first item now
        
        my $innerItem = $this->{_currentInnerItems}->[0];
        $this->{_current} = &{$this->{_resultSelector}}($outerItem, $innerItem);
        return true;
      }
    }
    
    return false;
  }
  
  sub Current {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('JoinEnumerator')) if $this->{_disposed};
    return $this->{_current};
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('JoinEnumerator')) if $this->{_disposed};
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