package System::ComponentModel::AsyncCompletedEventArgs; {
  use base 'System::EventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # AsyncCompletedEventArgs - base class for EAP (Event-based Asynchronous Pattern) completion events
  
  sub new {
    my ($class, $exception, $cancelled, $userState) = @_;
    
    return bless {
      _exception => $exception,
      _cancelled => $cancelled ? 1 : 0,
      _userState => $userState,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Gets the exception that occurred during the asynchronous operation
  sub Error {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_exception};
  }
  
  # Gets whether the asynchronous operation was cancelled
  sub Cancelled {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_cancelled};
  }
  
  # Gets the user state object that was passed to the asynchronous method call
  sub UserState {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_userState};
  }
  
  # Throws an exception if the operation was cancelled or had an error
  sub RaiseExceptionIfNecessary {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_cancelled}) {
      throw(System::OperationCanceledException->new('The operation was cancelled'));
    }
    
    if (defined($this->{_exception})) {
      throw($this->{_exception});
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;