package System::AggregateException; {
  use base 'System::Exception';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exception;
  
  # AggregateException - represents one or more errors that occur during application execution
  
  sub new {
    my ($class, $innerExceptions, $message) = @_;
    
    $innerExceptions //= [];
    $message //= 'One or more errors occurred.';
    
    # Ensure innerExceptions is an array reference
    if (ref($innerExceptions) ne 'ARRAY') {
      $innerExceptions = [$innerExceptions];
    }
    
    my $this = $class->SUPER::new($message);
    $this->{_innerExceptions} = $innerExceptions;
    
    return $this;
  }
  
  # Properties
  sub InnerExceptions {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_innerExceptions};
  }
  
  # Methods
  sub GetBaseException {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return the first inner exception, or this exception if no inner exceptions
    my $innerExceptions = $this->{_innerExceptions};
    if (@$innerExceptions > 0) {
      return $innerExceptions->[0];
    }
    
    return $this;
  }
  
  sub Flatten {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my @flattened = ();
    $this->_FlattenHelper(\@flattened);
    
    return System::AggregateException->new(\@flattened, $this->Message());
  }
  
  sub Handle {
    my ($this, $predicate) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('predicate')) unless defined($predicate);
    
    my @unhandled = ();
    
    for my $exception (@{$this->{_innerExceptions}}) {
      if (!$predicate->($exception)) {
        push @unhandled, $exception;
      }
    }
    
    if (@unhandled > 0) {
      throw(System::AggregateException->new(\@unhandled));
    }
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $result = $this->SUPER::ToString();
    
    if (@{$this->{_innerExceptions}} > 0) {
      $result .= "\n---> Inner exceptions:\n";
      
      for my $i (0..$#{$this->{_innerExceptions}}) {
        my $exception = $this->{_innerExceptions}->[$i];
        $result .= sprintf("Exception %d: %s\n", $i + 1, 
                          ref($exception) && $exception->can('ToString') ? 
                          $exception->ToString() : "$exception");
      }
    }
    
    return $result;
  }
  
  # Internal helper methods
  sub _FlattenHelper {
    my ($this, $flattened) = @_;
    
    for my $exception (@{$this->{_innerExceptions}}) {
      if (ref($exception) && $exception->isa('System::AggregateException')) {
        # Recursively flatten nested AggregateExceptions
        $exception->_FlattenHelper($flattened);
      } else {
        push @$flattened, $exception;
      }
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;