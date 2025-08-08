package System::Collections::Generic::LinkedList; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::IEnumerable;
  require System::Collections::IEnumerator;
  require System::Collections::Generic::LinkedListNode;
  
  # Generic LinkedList<T> implementation (doubly-linked list)
  sub new {
    my ($class) = @_;
    
    return bless {
      _first => undef,
      _last => undef,
      _count => 0,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Count {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_count};
  }
  
  sub First {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_first};
  }
  
  sub Last {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_last};
  }
  
  # Add methods
  sub AddFirst {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $node = System::Collections::Generic::LinkedListNode->new($value);
    $node->_SetList($this);
    
    if ($this->{_first}) {
      $node->_SetNext($this->{_first});
      $this->{_first}->_SetPrevious($node);
    } else {
      # First node in the list
      $this->{_last} = $node;
    }
    
    $this->{_first} = $node;
    $this->{_count}++;
    
    return $node;
  }
  
  sub AddLast {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $node = System::Collections::Generic::LinkedListNode->new($value);
    $node->_SetList($this);
    
    if ($this->{_last}) {
      $node->_SetPrevious($this->{_last});
      $this->{_last}->_SetNext($node);
    } else {
      # First node in the list
      $this->{_first} = $node;
    }
    
    $this->{_last} = $node;
    $this->{_count}++;
    
    return $node;
  }
  
  sub AddAfter {
    my ($this, $node, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('node')) unless defined($node);
    $this->_ValidateNode($node);
    
    my $newNode = System::Collections::Generic::LinkedListNode->new($value);
    $newNode->_SetList($this);
    
    my $next = $node->Next();
    $newNode->_SetNext($next);
    $newNode->_SetPrevious($node);
    $node->_SetNext($newNode);
    
    if ($next) {
      $next->_SetPrevious($newNode);
    } else {
      # We're adding after the last node
      $this->{_last} = $newNode;
    }
    
    $this->{_count}++;
    return $newNode;
  }
  
  sub AddBefore {
    my ($this, $node, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('node')) unless defined($node);
    $this->_ValidateNode($node);
    
    my $newNode = System::Collections::Generic::LinkedListNode->new($value);
    $newNode->_SetList($this);
    
    my $previous = $node->Previous();
    $newNode->_SetPrevious($previous);
    $newNode->_SetNext($node);
    $node->_SetPrevious($newNode);
    
    if ($previous) {
      $previous->_SetNext($newNode);
    } else {
      # We're adding before the first node
      $this->{_first} = $newNode;
    }
    
    $this->{_count}++;
    return $newNode;
  }
  
  # Remove methods
  sub Remove {
    my ($this, $value_or_node) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('value')) unless defined($value_or_node);
    
    if ($value_or_node->isa('System::Collections::Generic::LinkedListNode')) {
      # Remove by node
      $this->_ValidateNode($value_or_node);
      $this->_RemoveNode($value_or_node);
      return true;
    } else {
      # Remove by value - find first node with this value
      my $node = $this->Find($value_or_node);
      if ($node) {
        $this->_RemoveNode($node);
        return true;
      }
      return false;
    }
  }
  
  sub RemoveFirst {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->{_first}) {
      throw(System::InvalidOperationException->new("The LinkedList is empty"));
    }
    
    $this->_RemoveNode($this->{_first});
  }
  
  sub RemoveLast {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->{_last}) {
      throw(System::InvalidOperationException->new("The LinkedList is empty"));
    }
    
    $this->_RemoveNode($this->{_last});
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $current = $this->{_first};
    while ($current) {
      my $next = $current->Next();
      $current->_Invalidate();
      $current = $next;
    }
    
    $this->{_first} = undef;
    $this->{_last} = undef;
    $this->{_count} = 0;
  }
  
  # Search methods
  sub Contains {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return defined($this->Find($value));
  }
  
  sub Find {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $current = $this->{_first};
    while ($current) {
      if (defined($current->Value()) && defined($value)) {
        if ($current->Value() eq $value) {
          return $current;
        }
      } elsif (!defined($current->Value()) && !defined($value)) {
        return $current;
      }
      $current = $current->Next();
    }
    
    return undef;
  }
  
  sub FindLast {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $current = $this->{_last};
    while ($current) {
      if (defined($current->Value()) && defined($value)) {
        if ($current->Value() eq $value) {
          return $current;
        }
      } elsif (!defined($current->Value()) && !defined($value)) {
        return $current;
      }
      $current = $current->Previous();
    }
    
    return undef;
  }
  
  # Conversion methods
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my @array = ();
    my $current = $this->{_first};
    while ($current) {
      push @array, $current->Value();
      $current = $current->Next();
    }
    
    return \@array;
  }
  
  # IEnumerable implementation
  sub GetEnumerator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Collections::Generic::LinkedListEnumerator;
    return System::Collections::Generic::LinkedListEnumerator->new($this);
  }
  
  # Internal helper methods
  sub _ValidateNode {
    my ($this, $node) = @_;
    
    if (!$node->_GetList() || $node->_GetList() != $this) {
      throw(System::InvalidOperationException->new("The node does not belong to this LinkedList"));
    }
  }
  
  sub _RemoveNode {
    my ($this, $node) = @_;
    
    my $previous = $node->Previous();
    my $next = $node->Next();
    
    if ($previous) {
      $previous->_SetNext($next);
    } else {
      $this->{_first} = $next;
    }
    
    if ($next) {
      $next->_SetPrevious($previous);
    } else {
      $this->{_last} = $previous;
    }
    
    $node->_Invalidate();
    $this->{_count}--;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;