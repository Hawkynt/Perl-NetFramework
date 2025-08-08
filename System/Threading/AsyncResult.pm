package System::Threading::AsyncResult; {
  use base 'System::Object', 'System::IAsyncResult';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Threading::ManualResetEvent;
  
  # AsyncResult - concrete implementation of IAsyncResult for APM pattern
  
  sub new {
    my ($class, $asyncCallback, $asyncState) = @_;
    
    return bless {
      _asyncCallback => $asyncCallback,
      _asyncState => $asyncState,
      _isCompleted => 0,
      _completedSynchronously => 1,  # Will be set to 0 if completed asynchronously
      _waitHandle => System::Threading::ManualResetEvent->new(0),
      _result => undef,
      _exception => undef,
      _endCalled => 0,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # IAsyncResult implementation
  sub AsyncState {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_asyncState};
  }
  
  sub AsyncWaitHandle {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_waitHandle};
  }
  
  sub CompletedSynchronously {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_completedSynchronously} ? 1 : 0;
  }
  
  sub IsCompleted {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_isCompleted} ? 1 : 0;
  }
  
  # Internal methods for APM implementation
  sub _SetCompleted {
    my ($this, $result, $exception, $completedSynchronously) = @_;
    
    $this->{_result} = $result;
    $this->{_exception} = $exception;
    $this->{_completedSynchronously} = $completedSynchronously ? 1 : 0;
    $this->{_isCompleted} = 1;
    
    # Signal completion
    $this->{_waitHandle}->Set();
    
    # Invoke callback if provided
    if (defined($this->{_asyncCallback})) {
      eval {
        $this->{_asyncCallback}->($this);
      };
      # Ignore callback exceptions - this matches .NET behavior
    }
  }
  
  sub _GetResult {
    my ($this) = @_;
    
    # Can only call End* method once
    throw(System::InvalidOperationException->new('End method can only be called once'))
      if $this->{_endCalled};
    
    $this->{_endCalled} = 1;
    
    # Wait for completion if not already completed
    unless ($this->IsCompleted()) {
      $this->{_waitHandle}->WaitOne();
    }
    
    # Throw exception if operation failed
    if (defined($this->{_exception})) {
      throw($this->{_exception});
    }
    
    return $this->{_result};
  }
  
  # Cleanup
  sub DESTROY {
    my ($this) = @_;
    if (defined($this->{_waitHandle})) {
      $this->{_waitHandle}->Dispose();
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;