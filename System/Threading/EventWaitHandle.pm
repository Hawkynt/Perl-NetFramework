package System::Threading::EventWaitHandle; {
  use base 'System::Threading::WaitHandle';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Threading::WaitHandle;
  
  # EventWaitHandle - base class for event-based synchronization objects
  
  # Event reset mode enumeration
  use constant AutoReset => 0;
  use constant ManualReset => 1;
  
  sub new {
    my ($class, $initialState, $mode, $name) = @_;
    $initialState //= 0;
    $mode //= AutoReset;
    
    my $this = bless {
      _initial_state => $initialState,
      _mode => $mode,
      _name => $name,
      _disposed => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('EventWaitHandle')) if $this->{_disposed};
    return $this->{_name};
  }
  
  # Abstract methods that derived classes should implement
  sub Set {
    my ($this) = @_;
    throw(System::NotImplementedException->new('Set must be implemented by derived class'));
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::NotImplementedException->new('Reset must be implemented by derived class'));
  }
  
  # Static methods
  sub OpenExisting {
    my ($class, $name) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process events
    throw(System::WaitHandleCannotBeOpenedException->new('Event not found'));
  }
  
  sub TryOpenExisting {
    my ($class, $name, $resultRef) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process events
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;