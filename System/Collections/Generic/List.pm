package System::Collections::Generic::List; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::IEnumerator;
  
  # Generic List<T> implementation
  sub new {
    my ($class, @items) = @_;
    
    return bless {
      _items => [@items],
      _capacity => scalar(@items) + 10, # Start with some extra capacity
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return scalar(@{$this->{_items}});
  }
  
  sub Capacity {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      if ($value < $this->Count()) {
        throw(System::ArgumentOutOfRangeException->new("Capacity cannot be less than Count"));
      }
      $this->{_capacity} = $value;
      return;
    }
    
    return $this->{_capacity};
  }
  
  # Indexer
  sub Item {
    my ($this, $index, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($index < 0 || $index >= $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("Index was out of range"));
    }
    
    if (defined($value)) {
      # Setter
      $this->{_items}->[$index] = $value;
      return;
    }
    
    # Getter
    return $this->{_items}->[$index];
  }
  
  # Add/Remove methods
  sub Add {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    push @{$this->{_items}}, $item;
    
    # Expand capacity if needed
    if ($this->Count() > $this->{_capacity}) {
      $this->{_capacity} = $this->Count() * 2;
    }
  }
  
  sub AddRange {
    my ($this, $collection) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('collection')) unless defined($collection);
    
    if (ref($collection) eq 'ARRAY') {
      push @{$this->{_items}}, @$collection;
    } elsif ($collection->isa('System::Collections::Generic::List')) {
      push @{$this->{_items}}, @{$collection->{_items}};
    } elsif ($collection->can('ToArray')) {
      my $array = $collection->ToArray();
      push @{$this->{_items}}, @$array;
    } else {
      throw(System::ArgumentException->new("Collection must be enumerable"));
    }
    
    # Expand capacity if needed
    if ($this->Count() > $this->{_capacity}) {
      $this->{_capacity} = $this->Count() * 2;
    }
  }
  
  sub Insert {
    my ($this, $index, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($index < 0 || $index > $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("Index was out of range"));
    }
    
    splice @{$this->{_items}}, $index, 0, $item;
    
    # Expand capacity if needed
    if ($this->Count() > $this->{_capacity}) {
      $this->{_capacity} = $this->Count() * 2;
    }
  }
  
  sub Remove {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    for my $i (0 .. $#{$this->{_items}}) {
      if (defined($this->{_items}->[$i]) && defined($item)) {
        if ($this->{_items}->[$i] eq $item) {
          splice @{$this->{_items}}, $i, 1;
          return true;
        }
      } elsif (!defined($this->{_items}->[$i]) && !defined($item)) {
        splice @{$this->{_items}}, $i, 1;
        return true;
      }
    }
    
    return false;
  }
  
  sub RemoveAt {
    my ($this, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($index < 0 || $index >= $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("Index was out of range"));
    }
    
    splice @{$this->{_items}}, $index, 1;
  }
  
  sub RemoveRange {
    my ($this, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($index < 0 || $count < 0 || $index + $count > $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("Index and count must be within bounds"));
    }
    
    splice @{$this->{_items}}, $index, $count;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    @{$this->{_items}} = ();
  }
  
  # Search methods
  sub Contains {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return $this->IndexOf($item) >= 0;
  }
  
  sub IndexOf {
    my ($this, $item, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $startIndex //= 0;
    $count //= $this->Count() - $startIndex;
    
    if ($startIndex < 0 || $startIndex >= $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("startIndex was out of range"));
    }
    
    if ($count < 0 || $startIndex + $count > $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("count was out of range"));
    }
    
    for my $i ($startIndex .. $startIndex + $count - 1) {
      if (defined($this->{_items}->[$i]) && defined($item)) {
        if ($this->{_items}->[$i] eq $item) {
          return $i;
        }
      } elsif (!defined($this->{_items}->[$i]) && !defined($item)) {
        return $i;
      }
    }
    
    return -1;
  }
  
  sub LastIndexOf {
    my ($this, $item, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->Count() == 0) {
      return -1;
    }
    
    $startIndex //= $this->Count() - 1;
    $count //= $startIndex + 1;
    
    if ($startIndex < 0 || $startIndex >= $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("startIndex was out of range"));
    }
    
    if ($count < 0 || $startIndex - $count + 1 < 0) {
      throw(System::ArgumentOutOfRangeException->new("count was out of range"));
    }
    
    for my $i (reverse ($startIndex - $count + 1 .. $startIndex)) {
      if (defined($this->{_items}->[$i]) && defined($item)) {
        if ($this->{_items}->[$i] eq $item) {
          return $i;
        }
      } elsif (!defined($this->{_items}->[$i]) && !defined($item)) {
        return $i;
      }
    }
    
    return -1;
  }
  
  # Bulk operations
  sub Reverse {
    my ($this, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($index) && defined($count)) {
      if ($index < 0 || $count < 0 || $index + $count > $this->Count()) {
        throw(System::ArgumentOutOfRangeException->new("Index and count must be within bounds"));
      }
      
      my @slice = splice @{$this->{_items}}, $index, $count;
      splice @{$this->{_items}}, $index, 0, reverse @slice;
    } else {
      @{$this->{_items}} = reverse @{$this->{_items}};
    }
  }
  
  sub Sort {
    my ($this, $comparer) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($comparer)) {
      @{$this->{_items}} = sort { &{$comparer}($a, $b) } @{$this->{_items}};
    } else {
      @{$this->{_items}} = sort @{$this->{_items}};
    }
  }
  
  # Conversion methods
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return [@{$this->{_items}}];
  }
  
  sub TrimExcess {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_capacity} = $this->Count();
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::ListEnumerator;
    return System::Collections::Generic::ListEnumerator->new($this);
  }
  
  # LINQ compatibility - inherit from System::Object which provides LINQ methods
  # The LINQ methods will work with this List via GetEnumerator
  
  # Additional utility methods
  sub Exists {
    my ($this, $predicate) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('predicate')) unless defined($predicate);
    
    for my $item (@{$this->{_items}}) {
      if (&{$predicate}($item)) {
        return true;
      }
    }
    
    return false;
  }
  
  sub Find {
    my ($this, $predicate) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('predicate')) unless defined($predicate);
    
    for my $item (@{$this->{_items}}) {
      if (&{$predicate}($item)) {
        return $item;
      }
    }
    
    return undef;
  }
  
  sub FindAll {
    my ($this, $predicate) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('predicate')) unless defined($predicate);
    
    my $result = System::Collections::Generic::List->new();
    
    for my $item (@{$this->{_items}}) {
      if (&{$predicate}($item)) {
        $result->Add($item);
      }
    }
    
    return $result;
  }
  
  sub FindIndex {
    my ($this, $predicate, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('predicate')) unless defined($predicate);
    
    $startIndex //= 0;
    $count //= $this->Count() - $startIndex;
    
    if ($startIndex < 0 || $startIndex >= $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("startIndex was out of range"));
    }
    
    if ($count < 0 || $startIndex + $count > $this->Count()) {
      throw(System::ArgumentOutOfRangeException->new("count was out of range"));
    }
    
    for my $i ($startIndex .. $startIndex + $count - 1) {
      if (&{$predicate}($this->{_items}->[$i])) {
        return $i;
      }
    }
    
    return -1;
  }
  
  sub ForEach {
    my ($this, $action) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('action')) unless defined($action);
    
    for my $item (@{$this->{_items}}) {
      &{$action}($item);
    }
  }
  
  sub ConvertAll {
    my ($this, $converter) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('converter')) unless defined($converter);
    
    my $result = System::Collections::Generic::List->new();
    
    for my $item (@{$this->{_items}}) {
      $result->Add(&{$converter}($item));
    }
    
    return $result;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;