package System::Threading::Thread; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::TimeSpan;
  require System::String;
  
  # Thread states
  use constant Unstarted => 0;
  use constant Running => 1;
  use constant WaitSleepJoin => 2;
  use constant Stopped => 3;
  use constant StopRequested => 4;
  use constant SuspendRequested => 5;
  use constant Suspended => 6;
  use constant AbortRequested => 7;
  use constant Aborted => 8;
  
  # Thread priority
  use constant Lowest => 0;
  use constant BelowNormal => 1;
  use constant Normal => 2;
  use constant AboveNormal => 3;
  use constant Highest => 4;
  
  sub new {
    my ($class, $start) = @_;
    throw(System::ArgumentNullException->new('start')) unless defined($start);
    throw(System::ArgumentException->new('start must be a CODE reference'))
      unless ref($start) eq 'CODE';
    
    return bless {
      _start => $start,
      _thread => undef,
      _state => Unstarted,
      _name => '',
      _isBackground => false,
      _priority => Normal,
      _result => undef,
      _exception => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub ThreadState {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_state};
  }
  
  sub IsAlive {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_state} == Running || $this->{_state} == WaitSleepJoin;
  }
  
  sub Name {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (@_ > 1) {
      # Setter - value was passed (even if undef)
      $this->{_name} = defined($value) ? $value : '';
      return;
    }
    
    # Getter
    return $this->{_name};
  }
  
  sub IsBackground {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      $this->{_isBackground} = $value ? true : false;
      return;
    }
    
    # Getter
    return $this->{_isBackground};
  }
  
  sub Priority {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      throw(System::ArgumentOutOfRangeException->new('value'))
        if $value < Lowest || $value > Highest;
      $this->{_priority} = $value;
      return;
    }
    
    # Getter
    return $this->{_priority};
  }
  
  # Methods
  sub Start {
    my ($this, $parameter) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::Threading::ThreadStateException->new('Thread was previously started'))
      if $this->{_state} != Unstarted;
    
    $this->{_state} = Running;
    
    # Check if threads are available
    eval { require threads; };
    if ($@) {
      # Fallback to synchronous execution if threads not available
      warn "Threads not available, executing synchronously";
      eval {
        $this->{_result} = $this->{_start}->($parameter);
      };
      if ($@) {
        $this->{_exception} = $@;
        $this->{_state} = Aborted;
      } else {
        $this->{_state} = Stopped;
      }
      return;
    }
    
    # Create thread
    $this->{_thread} = threads->create(sub {
      my $start_func = $this->{_start};
      local $SIG{TERM} = sub { threads->exit(); };
      
      my $result;
      my $exception;
      
      eval {
        $result = $start_func->($parameter);
      };
      
      if ($@) {
        $exception = "$@";  # Stringify the exception
        return { status => 'exception', exception => $exception, result => undef };
      }
      
      return { status => 'completed', exception => undef, result => $result };
    });
    
    # Note: We don't detach background threads automatically
    # because we need to be able to join them for proper cleanup
  }
  
  sub Join {
    my ($this, $millisecondsTimeout) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return true if $this->{_state} == Stopped || $this->{_state} == Aborted;
    
    if (!defined($this->{_thread})) {
      throw(System::Threading::ThreadStateException->new('Thread has not been started'));
    }
    
    $this->{_state} = WaitSleepJoin;
    
    if (defined($millisecondsTimeout)) {
      # Timeout-based join
      my $start_time = time();
      while ($this->{_thread}->is_running()) {
        if ((time() - $start_time) * 1000 >= $millisecondsTimeout) {
          $this->{_state} = Running;
          return false;
        }
        select(undef, undef, undef, 0.01); # Sleep 10ms
      }
    }
    
    # Wait for thread completion
    my $thread_result = $this->{_thread}->join();
    
    if (ref($thread_result) eq 'HASH') {
      $this->{_result} = $thread_result->{result};
      $this->{_exception} = $thread_result->{exception};
      
      if ($thread_result->{status} eq 'exception') {
        $this->{_state} = Aborted;
      } else {
        $this->{_state} = Stopped;
      }
    } else {
      # Fallback for simple return values
      $this->{_state} = Stopped;
    }
    
    return true;
  }
  
  sub Abort {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return if $this->{_state} == Stopped || $this->{_state} == Aborted;
    
    if (defined($this->{_thread})) {
      $this->{_state} = AbortRequested;
      $this->{_thread}->kill('TERM') if $this->{_thread}->is_running();
      $this->{_state} = Aborted;
    }
  }
  
  sub Interrupt {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    # Not implemented in this basic version
    throw(System::NotSupportedException->new('Thread.Interrupt is not supported'));
  }
  
  # Static methods
  sub Sleep {
    my ($class, $timeout_param) = @_;
    
    # Handle the case where Sleep is called as a static method
    if (!defined($timeout_param) && defined($class) && $class ne __PACKAGE__) {
      # $class is actually the timeout parameter
      $timeout_param = $class;
      $class = __PACKAGE__;
    }
    
    throw(System::ArgumentNullException->new('timeout'))
      unless defined($timeout_param);
    
    my $timeout;
    if (ref($timeout_param) && $timeout_param->isa('System::TimeSpan')) {
      $timeout = $timeout_param->TotalMilliseconds() / 1000.0;
    } else {
      # Milliseconds parameter
      $timeout = $timeout_param / 1000.0;
    }
    
    throw(System::ArgumentOutOfRangeException->new('timeout'))
      if $timeout < 0;
    
    select(undef, undef, undef, $timeout);
  }
  
  sub Yield {
    my ($class) = @_;
    # In Perl, we can use threads::yield if available, otherwise brief sleep
    eval { threads->yield(); };
    if ($@) {
      select(undef, undef, undef, 0.001); # 1ms
    }
    return true;
  }
  
  sub CurrentThread {
    my ($class) = @_;
    # Return a thread-like object representing current thread
    my $current = bless {
      _start => undef,
      _thread => undef,
      _state => Running,
      _name => 'Main Thread',
      _isBackground => false,
      _priority => Normal,
      _result => undef,
      _exception => undef,
    }, $class;
    
    return $current;
  }
  
  # Utility methods
  sub GetResult {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_result};
  }
  
  sub GetException {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_exception};
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $name = $this->{_name} || 'Unnamed Thread';
    return "System.Threading.Thread: $name";
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;