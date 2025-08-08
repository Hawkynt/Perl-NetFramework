package System::Threading::Tasks::TaskAwaiter; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # TaskAwaiter - provides an awaiter for Task objects
  
  sub new {
    my ($class, $task) = @_;
    throw(System::ArgumentNullException->new('task')) unless defined($task);
    
    return bless {
      _task => $task,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub IsCompleted {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_task}->IsCompleted();
  }
  
  # Methods
  sub GetResult {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Wait for task completion
    $this->{_task}->Wait();
    
    # Return result or throw exception
    return $this->{_task}->Result();
  }
  
  sub OnCompleted {
    my ($this, $continuation) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('continuation')) unless defined($continuation);
    
    if ($this->IsCompleted()) {
      # Already completed, run continuation immediately
      $continuation->();
    } else {
      # Register continuation to run when task completes
      $this->{_task}->ContinueWith(sub { $continuation->(); });
    }
  }
  
  sub UnsafeOnCompleted {
    my ($this, $continuation) = @_;
    # For now, same as OnCompleted
    return $this->OnCompleted($continuation);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;