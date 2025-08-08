package System::Threading::Tasks::Task; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Threading::ThreadPool;
  require System::Threading::Thread;
  require System::AggregateException;
  
  # Task status enumeration
  use constant Created => 0;
  use constant WaitingForActivation => 1;
  use constant WaitingToRun => 2;
  use constant Running => 3;
  use constant WaitingForChildrenToComplete => 4;
  use constant RanToCompletion => 5;
  use constant Canceled => 6;
  use constant Faulted => 7;
  
  # Task creation options
  use constant None => 0x0000;
  use constant PreferFairness => 0x0001;
  use constant LongRunning => 0x0002;
  use constant AttachedToParent => 0x0004;
  use constant DenyChildAttach => 0x0008;
  use constant HideScheduler => 0x0010;
  use constant RunContinuationsAsynchronously => 0x0040;
  
  sub new {
    my ($class, $action, $state) = @_;
    throw(System::ArgumentNullException->new('action')) unless defined($action);
    throw(System::ArgumentException->new('action must be a CODE reference'))
      unless ref($action) eq 'CODE';
    
    return bless {
      _action => $action,
      _state => $state,
      _status => Created,
      _result => undef,
      _exception => undef,
      _cancellationToken => undef,
      _continuations => [],
      _startTime => undef,
      _endTime => undef,
      _id => _GenerateTaskId(),
      _parent => undef,
      _children => [],
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Status {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_status};
  }
  
  sub IsCompleted {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_status} >= RanToCompletion;
  }
  
  sub IsCompletedSuccessfully {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_status} == RanToCompletion;
  }
  
  sub IsCanceled {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_status} == Canceled;
  }
  
  sub IsFaulted {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_status} == Faulted;
  }
  
  sub Exception {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_exception};
  }
  
  sub Result {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Wait for completion if not already completed
    $this->Wait() unless $this->IsCompleted();
    
    # Throw exception if faulted
    if ($this->IsFaulted()) {
      throw($this->{_exception});
    }
    
    # Throw if canceled
    if ($this->IsCanceled()) {
      throw(System::OperationCanceledException->new('Task was canceled'));
    }
    
    return $this->{_result};
  }
  
  sub Id {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_id};
  }
  
  # Methods
  sub Start {
    my ($this, $scheduler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::InvalidOperationException->new('Task was already started'))
      if $this->{_status} != Created;
    
    $this->{_status} = WaitingToRun;
    $this->{_startTime} = time();
    
    # For now, execute synchronously to ensure it works
    # TODO: Implement proper async execution later
    $this->_ExecuteTask();
  }
  
  sub Wait {
    my ($this, $timeout) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $start_time = time();
    
    while (!$this->IsCompleted()) {
      if (defined($timeout) && (time() - $start_time) * 1000 >= $timeout) {
        return false;
      }
      
      System::Threading::Thread->Sleep(1);
    }
    
    return true;
  }
  
  sub GetAwaiter {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return a task awaiter (simplified implementation)
    return System::Threading::Tasks::TaskAwaiter->new($this);
  }
  
  sub ContinueWith {
    my ($this, $continuationAction, $continuationOptions) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('continuationAction')) unless defined($continuationAction);
    
    my $continuation = System::Threading::Tasks::Task->new($continuationAction, $this);
    push @{$this->{_continuations}}, $continuation;
    
    # If already completed, start continuation immediately
    if ($this->IsCompleted()) {
      $continuation->Start();
    }
    
    return $continuation;
  }
  
  sub Dispose {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    # Clean up resources
    $this->{_continuations} = [];
  }
  
  # Static factory methods
  sub Run {
    my ($class, $action, $cancellationToken) = @_;
    throw(System::ArgumentNullException->new('action')) unless defined($action);
    
    my $task = $class->new($action);
    $task->{_cancellationToken} = $cancellationToken if defined($cancellationToken);
    $task->Start();
    return $task;
  }
  
  sub FromResult {
    my ($class, $result) = @_;
    my $task = bless {
      _action => sub { return $result; },
      _state => undef,
      _status => RanToCompletion,
      _result => $result,
      _exception => undef,
      _cancellationToken => undef,
      _continuations => [],
      _startTime => time(),
      _endTime => time(),
      _id => _GenerateTaskId(),
      _parent => undef,
      _children => [],
    }, $class;
    
    return $task;
  }
  
  sub Delay {
    my ($class, $millisecondsDelay, $cancellationToken) = @_;
    throw(System::ArgumentOutOfRangeException->new('millisecondsDelay'))
      if $millisecondsDelay < 0;
    
    my $task = $class->new(sub {
      System::Threading::Thread->Sleep($millisecondsDelay);
    });
    
    $task->{_cancellationToken} = $cancellationToken if defined($cancellationToken);
    $task->Start();
    return $task;
  }
  
  sub WhenAll {
    my ($class, @tasks) = @_;
    throw(System::ArgumentNullException->new('tasks')) unless @tasks;
    
    my $whenAllTask = $class->new(sub {
      my @results = ();
      for my $task (@tasks) {
        $task->Wait();
        push @results, $task->Result() if $task->IsCompletedSuccessfully();
      }
      return \@results;
    });
    
    $whenAllTask->Start();
    return $whenAllTask;
  }
  
  sub WhenAny {
    my ($class, @tasks) = @_;
    throw(System::ArgumentNullException->new('tasks')) unless @tasks;
    
    my $whenAnyTask = $class->new(sub {
      while (1) {
        for my $task (@tasks) {
          return $task if $task->IsCompleted();
        }
        System::Threading::Thread->Sleep(1);
      }
    });
    
    $whenAnyTask->Start();
    return $whenAnyTask;
  }
  
  # Async/await simulation
  sub GetResult {
    my ($this) = @_;
    return $this->Result();
  }
  
  sub ConfigureAwait {
    my ($this, $continueOnCapturedContext) = @_;
    # In a full implementation, this would affect the synchronization context
    return $this;  # Simplified
  }
  
  # Internal methods
  sub _ExecuteTask {
    my ($this) = @_;
    
    $this->{_status} = Running;
    
    eval {
      $this->{_result} = $this->{_action}->($this->{_state});
      $this->{_status} = RanToCompletion;
    };
    
    if ($@) {
      $this->{_exception} = System::AggregateException->new([$@]);
      $this->{_status} = Faulted;
    }
    
    $this->{_endTime} = time();
    
    # Execute continuations
    for my $continuation (@{$this->{_continuations}}) {
      $continuation->Start();
    }
  }
  
  # Task ID generation
  my $_nextTaskId = 1;
  sub _GenerateTaskId {
    return $_nextTaskId++;
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $status = $this->Status();
    return "Task $this->{_id}: $status";
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;