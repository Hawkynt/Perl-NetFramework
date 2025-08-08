package System::Delegate; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Delegate - represents a method pointer/callback system
  sub new {
    my ($class, $target, $method) = @_;
    
    # Special case: if method is a CODE reference and target is undef, allow it
    if (!defined($target) && defined($method) && ref($method) eq 'CODE') {
      # Allow this case for anonymous code references
    }
    # Validate other argument combinations
    elsif ((defined($target) && !defined($method)) || (!defined($target) && defined($method) && ref($method) ne 'CODE')) {
      throw(System::ArgumentException->new("target and method must both be defined or both be undef, or method can be a CODE reference with undef target"));
    }
    
    return bless {
      _invocationList => [],
      _target => $target,
      _method => $method,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Target {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_target};
  }
  
  sub Method {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_method};
  }
  
  # Delegate operations
  sub Invoke {
    my ($this, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # If this delegate has a direct target/method or code reference, invoke it
    if ((defined($this->{_target}) && defined($this->{_method})) || 
        (!defined($this->{_target}) && defined($this->{_method}) && ref($this->{_method}) eq 'CODE')) {
      
      if (defined($this->{_target}) && ref($this->{_target})) {
        # Instance method
        return $this->{_target}->can($this->{_method})->($this->{_target}, @args);
      } elsif (!defined($this->{_target}) && ref($this->{_method}) eq 'CODE') {
        # Code reference with undef target
        return $this->{_method}->(@args);
      } elsif (ref($this->{_method}) eq 'CODE') {
        # Code reference
        return $this->{_method}->(@args);
      } else {
        # Package method call
        my $method = $this->{_target} . "::" . $this->{_method};
        no strict 'refs';
        return &$method(@args);
      }
    }
    
    # Invoke all delegates in invocation list
    my @results = ();
    for my $delegate (@{$this->{_invocationList}}) {
      push @results, $delegate->Invoke(@args);
    }
    
    return wantarray ? @results : $results[-1]; # Return last result in scalar context
  }
  
  sub Combine {
    my ($class_or_this, $a, $b) = @_;
    
    # Static method call
    if (!ref($class_or_this)) {
      return $class_or_this->_CombineImpl($a, $b);
    }
    
    # Instance method call  
    throw(System::ArgumentNullException->new('b')) unless defined($b);
    return $class_or_this->_CombineImpl($class_or_this, $b);
  }
  
  sub Remove {
    my ($class_or_this, $source, $value) = @_;
    
    # Static method call
    if (!ref($class_or_this)) {
      return $class_or_this->_RemoveImpl($source, $value);
    }
    
    # Instance method call
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    return $class_or_this->_RemoveImpl($class_or_this, $value);
  }
  
  # Internal implementation methods
  sub _CombineImpl {
    my ($class, $a, $b) = @_;
    
    return $b unless defined($a);
    return $a unless defined($b);
    
    throw(System::ArgumentException->new('a')) unless $a->isa('System::Delegate');
    throw(System::ArgumentException->new('b')) unless $b->isa('System::Delegate');
    
    # Create new multicast delegate
    my $result = System::Delegate->new();
    
    # Add all delegates from a
    if (@{$a->{_invocationList}}) {
      push @{$result->{_invocationList}}, @{$a->{_invocationList}};
    } else {
      push @{$result->{_invocationList}}, $a;
    }
    
    # Add all delegates from b
    if (@{$b->{_invocationList}}) {
      push @{$result->{_invocationList}}, @{$b->{_invocationList}};
    } else {
      push @{$result->{_invocationList}}, $b;
    }
    
    return $result;
  }
  
  sub _RemoveImpl {
    my ($class, $source, $value) = @_;
    
    return undef unless defined($source);
    return $source unless defined($value);
    
    throw(System::ArgumentException->new('source')) unless $source->isa('System::Delegate');
    throw(System::ArgumentException->new('value')) unless $value->isa('System::Delegate');
    
    # If source has no invocation list, compare directly
    if (!@{$source->{_invocationList}}) {
      return ($source->_Equals($value)) ? undef : $source;
    }
    
    # Remove from invocation list (last occurrence)
    my @newList = @{$source->{_invocationList}};
    for my $i (reverse 0..$#newList) {
      if ($newList[$i]->_Equals($value)) {
        splice @newList, $i, 1;
        last;
      }
    }
    
    # Return appropriate result
    if (@newList == 0) {
      return undef;
    } elsif (@newList == 1) {
      return $newList[0];
    } else {
      my $result = System::Delegate->new();
      @{$result->{_invocationList}} = @newList;
      return $result;
    }
  }
  
  sub _Equals {
    my ($this, $other) = @_;
    
    return false unless defined($other) && $other->isa('System::Delegate');
    
    # Compare target and method
    my $targetEqual = (!defined($this->{_target}) && !defined($other->{_target})) ||
                      (defined($this->{_target}) && defined($other->{_target}) && 
                       $this->{_target} eq $other->{_target});
    
    my $methodEqual = (!defined($this->{_method}) && !defined($other->{_method})) ||
                      (defined($this->{_method}) && defined($other->{_method}) && 
                       $this->{_method} eq $other->{_method});
    
    return $targetEqual && $methodEqual;
  }
  
  # Overloaded operators
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->_Equals($other);
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $targetHash = defined($this->{_target}) ? unpack("%32C*", "$this->{_target}") : 0;
    my $methodHash = defined($this->{_method}) ? unpack("%32C*", "$this->{_method}") : 0;
    
    return $targetHash ^ $methodHash;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;