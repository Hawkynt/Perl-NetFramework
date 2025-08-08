package System::Threading::Mutex; {
  use base 'System::Threading::WaitHandle';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Threading::WaitHandle;
  require System::Threading::Thread;
  
  # Mutex - provides mutual exclusion functionality
  
  sub new {
    my ($class, $initiallyOwned, $name) = @_;
    $initiallyOwned //= 0;
    
    # Create shared data structures for thread safety
    my $lock : shared;
    my $owner_id : shared;
    my $recursion_count : shared = 0;
    
    $owner_id = undef;
    
    my $this = bless {
      _lock => \$lock,
      _owner_id => \$owner_id,
      _recursion_count => \$recursion_count,
      _name => $name,
      _disposed => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    # If initially owned, acquire the mutex for current thread
    if ($initiallyOwned) {
      $this->WaitOne(0);  # Non-blocking acquire
    }
    
    return $this;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('Mutex')) if $this->{_disposed};
    return $this->{_name};
  }
  
  # WaitHandle overrides
  sub WaitOne {
    my ($this, $millisecondsTimeout, $exitContext) = @_;
    throw(System::ObjectDisposedException->new('Mutex')) if $this->{_disposed};
    
    $millisecondsTimeout //= -1;  # Infinite timeout by default
    $exitContext //= 0;
    
    my $current_thread_id = eval { threads->tid() } || $$;  # Use process ID if not threaded
    my $start_time = time() * 1000;  # Convert to milliseconds
    
    while (1) {
      {
        lock($this->{_lock});
        
        # Check if we already own the mutex (reentrant)
        if (defined(${$this->{_owner_id}}) && ${$this->{_owner_id}} == $current_thread_id) {
          ${$this->{_recursion_count}}++;
          return 1;  # Successfully acquired
        }
        
        # Check if mutex is free
        if (!defined(${$this->{_owner_id}})) {
          ${$this->{_owner_id}} = $current_thread_id;
          ${$this->{_recursion_count}} = 1;
          return 1;  # Successfully acquired
        }
      }
      
      # Check timeout
      if ($millisecondsTimeout >= 0) {
        my $elapsed = (time() * 1000) - $start_time;
        if ($elapsed >= $millisecondsTimeout) {
          return 0;  # Timeout
        }
      }
      
      # Brief sleep to avoid busy waiting
      select(undef, undef, undef, 0.001);  # 1ms sleep
    }
  }
  
  sub ReleaseMutex {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('Mutex')) if $this->{_disposed};
    
    my $current_thread_id = eval { threads->tid() } || $$;  # Use process ID if not threaded
    
    lock($this->{_lock});
    
    # Check if current thread owns the mutex
    if (!defined(${$this->{_owner_id}}) || ${$this->{_owner_id}} != $current_thread_id) {
      throw(System::ApplicationException->new('Calling thread does not own the mutex'));
    }
    
    ${$this->{_recursion_count}}--;
    
    # Only release if recursion count reaches zero
    if (${$this->{_recursion_count}} == 0) {
      ${$this->{_owner_id}} = undef;
    }
    
    return 1;
  }
  
  # Static methods
  sub OpenExisting {
    my ($class, $name) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process mutexes
    throw(System::WaitHandleCannotBeOpenedException->new('Mutex not found'));
  }
  
  sub TryOpenExisting {
    my ($class, $name, $resultRef) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process mutexes
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  # IDisposable implementation
  sub Dispose {
    my ($this) = @_;
    
    if (!$this->{_disposed}) {
      # Release if we own the mutex
      my $current_thread_id = eval { threads->tid() } || $$;  # Use process ID if not threaded
      
      {
        lock($this->{_lock});
        if (defined(${$this->{_owner_id}}) && ${$this->{_owner_id}} == $current_thread_id) {
          ${$this->{_owner_id}} = undef;
          ${$this->{_recursion_count}} = 0;
        }
      }
      
      $this->{_disposed} = 1;
    }
  }
  
  # Destructor
  sub DESTROY {
    my ($this) = @_;
    $this->Dispose() if defined($this) && !$this->{_disposed};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;