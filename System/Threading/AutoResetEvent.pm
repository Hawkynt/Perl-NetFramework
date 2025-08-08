package System::Threading::AutoResetEvent; {
  use base 'System::Threading::EventWaitHandle';
  
  use strict;
  use warnings;
  use threads::shared;
  use CSharp;
  require System::Exceptions;
  require System::Threading::EventWaitHandle;
  
  # AutoResetEvent - automatically resets to non-signaled state after releasing a single waiting thread
  
  sub new {
    my ($class, $initialState) = @_;
    $initialState //= 0;
    
    # Create shared data structures for thread safety
    my $lock : shared;
    my $is_set : shared = $initialState ? 1 : 0;
    
    my $this = bless {
      _lock => \$lock,
      _is_set => \$is_set,
      _disposed => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # WaitHandle overrides
  sub WaitOne {
    my ($this, $millisecondsTimeout, $exitContext) = @_;
    throw(System::ObjectDisposedException->new('AutoResetEvent')) if $this->{_disposed};
    
    $millisecondsTimeout //= -1;  # Infinite timeout by default
    $exitContext //= 0;
    
    my $start_time = time() * 1000;  # Convert to milliseconds
    
    while (1) {
      {
        lock($this->{_lock});
        
        # Check if event is signaled
        if (${$this->{_is_set}}) {
          ${$this->{_is_set}} = 0;  # Auto-reset to non-signaled state
          return 1;  # Successfully waited
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
  
  sub Set {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('AutoResetEvent')) if $this->{_disposed};
    
    lock($this->{_lock});
    ${$this->{_is_set}} = 1;
    
    return 1;
  }
  
  sub Reset {
    my ($this) = @_;
    throw(System::ObjectDisposedException->new('AutoResetEvent')) if $this->{_disposed};
    
    lock($this->{_lock});
    my $was_set = ${$this->{_is_set}};
    ${$this->{_is_set}} = 0;
    
    return $was_set;
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