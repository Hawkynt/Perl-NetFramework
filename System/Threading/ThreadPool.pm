package System::Threading::ThreadPool; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Threading::Thread;
  
  # ThreadPool - provides a pool of threads that can be used to execute tasks
  
  # Static fields
  my $_minWorkerThreads = 1;
  my $_maxWorkerThreads = 10;
  my $_minCompletionPortThreads = 1;
  my $_maxCompletionPortThreads = 10;
  my $_availableWorkerThreads = $_maxWorkerThreads;
  my $_availableCompletionPortThreads = $_maxCompletionPortThreads;
  my @_workerThreads = ();
  my @_workQueue = ();
  my $_initialized = false;
  
  # Static methods
  sub QueueUserWorkItem {
    my ($class, $callback, $state) = @_;
    throw(System::ArgumentNullException->new('callback')) unless defined($callback);
    throw(System::ArgumentException->new('callback must be a CODE reference'))
      unless ref($callback) eq 'CODE';
    
    _InitializeThreadPool() unless $_initialized;
    
    # Check if threads are available
    eval { require threads; };
    if ($@) {
      # Fallback: execute synchronously if threads not available
      eval {
        $callback->($state);
      };
      if ($@) {
        warn "ThreadPool worker error: $@";
      }
      return true;
    }
    
    # Add work item to queue
    push @_workQueue, {
      callback => $callback,
      state => $state,
      queued_time => time(),
    };
    
    # Try to assign to an available worker thread
    _ProcessWorkQueue();
    
    return true;
  }
  
  sub GetAvailableThreads {
    my ($class, $workerThreadsRef, $completionPortThreadsRef) = @_;
    throw(System::ArgumentNullException->new('workerThreads')) unless defined($workerThreadsRef);
    throw(System::ArgumentNullException->new('completionPortThreads')) unless defined($completionPortThreadsRef);
    
    _InitializeThreadPool() unless $_initialized;
    
    $$workerThreadsRef = $_availableWorkerThreads;
    $$completionPortThreadsRef = $_availableCompletionPortThreads;
  }
  
  sub GetMaxThreads {
    my ($class, $workerThreadsRef, $completionPortThreadsRef) = @_;
    throw(System::ArgumentNullException->new('workerThreads')) unless defined($workerThreadsRef);
    throw(System::ArgumentNullException->new('completionPortThreads')) unless defined($completionPortThreadsRef);
    
    $$workerThreadsRef = $_maxWorkerThreads;
    $$completionPortThreadsRef = $_maxCompletionPortThreads;
  }
  
  sub GetMinThreads {
    my ($class, $workerThreadsRef, $completionPortThreadsRef) = @_;
    throw(System::ArgumentNullException->new('workerThreads')) unless defined($workerThreadsRef);
    throw(System::ArgumentNullException->new('completionPortThreads')) unless defined($completionPortThreadsRef);
    
    $$workerThreadsRef = $_minWorkerThreads;
    $$completionPortThreadsRef = $_minCompletionPortThreads;
  }
  
  sub SetMaxThreads {
    my ($class, $workerThreads, $completionPortThreads) = @_;
    throw(System::ArgumentOutOfRangeException->new('workerThreads'))
      if $workerThreads < $_minWorkerThreads;
    throw(System::ArgumentOutOfRangeException->new('completionPortThreads'))
      if $completionPortThreads < $_minCompletionPortThreads;
    
    $_maxWorkerThreads = $workerThreads;
    $_maxCompletionPortThreads = $completionPortThreads;
    
    # Adjust available threads
    $_availableWorkerThreads = $_maxWorkerThreads - scalar(@_workerThreads);
    $_availableCompletionPortThreads = $_maxCompletionPortThreads;
    
    return true;
  }
  
  sub SetMinThreads {
    my ($class, $workerThreads, $completionPortThreads) = @_;
    throw(System::ArgumentOutOfRangeException->new('workerThreads'))
      if $workerThreads > $_maxWorkerThreads || $workerThreads < 1;
    throw(System::ArgumentOutOfRangeException->new('completionPortThreads'))
      if $completionPortThreads > $_maxCompletionPortThreads || $completionPortThreads < 1;
    
    $_minWorkerThreads = $workerThreads;
    $_minCompletionPortThreads = $completionPortThreads;
    
    return true;
  }
  
  # RegisterWaitForSingleObject - simplified version
  sub RegisterWaitForSingleObject {
    my ($class, $waitObject, $callback, $state, $timeout, $executeOnlyOnce) = @_;
    throw(System::ArgumentNullException->new('waitObject')) unless defined($waitObject);
    throw(System::ArgumentNullException->new('callback')) unless defined($callback);
    
    # In a full implementation, this would register a wait handle
    # For now, we'll simulate by queuing the callback
    return QueueUserWorkItem($class, $callback, $state);
  }
  
  # Internal methods
  sub _InitializeThreadPool {
    return if $_initialized;
    
    # Pre-create minimum worker threads
    for my $i (1..$_minWorkerThreads) {
      my $workerThread = _CreateWorkerThread($i);
      push @_workerThreads, $workerThread;
    }
    
    $_availableWorkerThreads = $_maxWorkerThreads - scalar(@_workerThreads);
    $_initialized = true;
  }
  
  sub _CreateWorkerThread {
    my ($threadId) = @_;
    
    # Create a worker thread that processes the work queue
    my $thread = System::Threading::Thread->new(sub {
      my $last_activity = time();
      
      # Worker thread main loop
      while (1) {
        my $workItem = _GetNextWorkItem();
        
        if ($workItem) {
          $last_activity = time();
          
          eval {
            $workItem->{callback}->($workItem->{state});
          };
          
          if ($@) {
            # Log error but continue
            warn "ThreadPool worker error: $@";
          }
        } else {
          # No work available, sleep briefly
          System::Threading::Thread->Sleep(10);
          
          # Check for thread retirement (idle for too long)
          if (time() - $last_activity > 60 && 
              scalar(@_workerThreads) > $_minWorkerThreads) {
            last; # Exit thread
          }
        }
      }
    });
    
    $thread->IsBackground(true);
    $thread->Name("ThreadPool Worker $threadId");
    $thread->Start();
    
    return {
      id => $threadId,
      thread => $thread,
      is_busy => false,
      created_time => time(),
    };
  }
  
  sub _ProcessWorkQueue {
    # If we have queued work and available capacity, create more threads
    if (@_workQueue > 0 && $_availableWorkerThreads > 0 && scalar(@_workerThreads) < $_maxWorkerThreads) {
      my $newThreadId = scalar(@_workerThreads) + 1;
      my $workerThread = _CreateWorkerThread($newThreadId);
      push @_workerThreads, $workerThread;
      $_availableWorkerThreads--;
    }
  }
  
  sub _GetNextWorkItem {
    # Thread-safe work queue access (simplified)
    return shift @_workQueue if @_workQueue > 0;
    return undef;
  }
  
  # Utility methods for monitoring
  sub GetQueuedWorkItemCount {
    my ($class) = @_;
    return scalar(@_workQueue);
  }
  
  sub GetActiveThreadCount {
    my ($class) = @_;
    # Since we simplified the worker thread, count threads that are alive
    my $active = 0;
    for my $worker (@_workerThreads) {
      if (defined($worker->{thread}) && $worker->{thread}->IsAlive()) {
        $active++;
      }
    }
    return $active;
  }
  
  sub GetTotalThreadCount {
    my ($class) = @_;
    return scalar(@_workerThreads);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;