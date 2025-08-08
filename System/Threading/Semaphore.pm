package System::Threading::Semaphore; {
  use base 'System::Threading::WaitHandle';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Threading::WaitHandle;
  
  # Semaphore - limits the number of threads that can access a resource concurrently
  
  sub new {
    my ($class, $initialCount, $maximumCount, $name) = @_;
    
    throw(System::ArgumentOutOfRangeException->new('initialCount'))
      if !defined($initialCount) || $initialCount < 0;
    throw(System::ArgumentOutOfRangeException->new('maximumCount'))
      if !defined($maximumCount) || $maximumCount < 1;
    throw(System::ArgumentException->new('initialCount cannot exceed maximumCount'))
      if $initialCount > $maximumCount;
    
    # Create shared data structures for thread safety
    my $lock : shared;
    my $current_count : shared = $initialCount;
    
    my $this = bless {
      _lock => \$lock,
      _current_count => \$current_count,
      _maximum_count => $maximumCount,
      _name => $name,
      _disposed => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('Semaphore')) if $this->{_disposed};
    return $this->{_name};
  }
  
  # WaitHandle overrides
  sub WaitOne {
    my ($this, $millisecondsTimeout, $exitContext) = @_;
    throw(System::ObjectDisposedException->new('Semaphore')) if $this->{_disposed};
    
    $millisecondsTimeout //= -1;  # Infinite timeout by default
    $exitContext //= 0;
    
    my $start_time = time() * 1000;  # Convert to milliseconds
    
    while (1) {
      {
        lock($this->{_lock});
        
        # Check if semaphore has available slots
        if (${$this->{_current_count}} > 0) {
          ${$this->{_current_count}}--;
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
  
  sub Release {
    my ($this, $releaseCount) = @_;
    throw(System::ObjectDisposedException->new('Semaphore')) if $this->{_disposed};
    
    $releaseCount //= 1;
    throw(System::ArgumentOutOfRangeException->new('releaseCount'))
      if $releaseCount < 1;
    
    lock($this->{_lock});
    
    # Check if release would exceed maximum count
    my $new_count = ${$this->{_current_count}} + $releaseCount;
    throw(System::SemaphoreFullException->new('Adding releaseCount to the semaphore would cause it to exceed its maximum count'))
      if $new_count > $this->{_maximum_count};
    
    my $previous_count = ${$this->{_current_count}};
    ${$this->{_current_count}} = $new_count;
    
    return $previous_count;
  }
  
  # Static methods
  sub OpenExisting {
    my ($class, $name) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process semaphores
    throw(System::WaitHandleCannotBeOpenedException->new('Semaphore not found'));
  }
  
  sub TryOpenExisting {
    my ($class, $name, $resultRef) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::ArgumentException->new('name cannot be empty')) if $name eq '';
    
    # In this implementation, we don't support cross-process semaphores
    $$resultRef = undef if defined($resultRef);
    return 0;
  }
  
  # IDisposable implementation
  sub Dispose {
    my ($this) = @_;
    $this->{_disposed} = 1 unless $this->{_disposed};
  }
  
  # Destructor
  sub DESTROY {
    my ($this) = @_;
    $this->Dispose() if defined($this) && !$this->{_disposed};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;