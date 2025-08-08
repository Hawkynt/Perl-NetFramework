package System::Threading::CallbackPatterns; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Threading::ThreadPool;
  require System::Threading::Thread;
  
  # CallbackPatterns - demonstrates CB (Callback-Based) asynchronous pattern
  # This pattern passes a delegate/callback to be invoked on completion
  
  # Simple callback-based async operation
  sub ExecuteAsync {
    my ($class, $operation, $completionCallback, $state) = @_;
    throw(System::ArgumentNullException->new('operation')) unless defined($operation);
    throw(System::ArgumentException->new('operation must be a CODE reference'))
      unless ref($operation) eq 'CODE';
    
    # Queue the operation to run asynchronously
    System::Threading::ThreadPool->QueueUserWorkItem(sub {
      my $result = undef;
      my $exception = undef;
      
      # Execute the operation
      eval {
        $result = $operation->($state);
      };
      
      if ($@) {
        $exception = $@;
      }
      
      # Invoke the completion callback if provided
      if (defined($completionCallback)) {
        eval {
          $completionCallback->($result, $exception, $state);
        };
        # Ignore callback exceptions
      }
    });
  }
  
  # Callback-based operation with timeout
  sub ExecuteWithTimeoutAsync {
    my ($class, $operation, $timeoutMs, $completionCallback, $state) = @_;
    throw(System::ArgumentNullException->new('operation')) unless defined($operation);
    throw(System::ArgumentException->new('operation must be a CODE reference'))
      unless ref($operation) eq 'CODE';
    throw(System::ArgumentOutOfRangeException->new('timeoutMs')) 
      if defined($timeoutMs) && $timeoutMs < 0;
    
    my $startTime = time();
    my $completed = 0;
    
    # Queue the operation
    System::Threading::ThreadPool->QueueUserWorkItem(sub {
      my $result = undef;
      my $exception = undef;
      my $timedOut = 0;
      
      eval {
        # Check for timeout before starting
        if (defined($timeoutMs)) {
          my $elapsed = (time() - $startTime) * 1000;
          if ($elapsed >= $timeoutMs) {
            $timedOut = 1;
            $exception = System::TimeoutException->new('The operation has timed out');
          }
        }
        
        unless ($timedOut) {
          $result = $operation->($state);
        }
      };
      
      if ($@ && !$timedOut) {
        $exception = $@;
      }
      
      # Only invoke callback once
      unless ($completed) {
        $completed = 1;
        
        if (defined($completionCallback)) {
          eval {
            $completionCallback->($result, $exception, $state, $timedOut);
          };
        }
      }
    });
    
    # Also set up a timeout handler if timeout specified
    if (defined($timeoutMs)) {
      System::Threading::ThreadPool->QueueUserWorkItem(sub {
        System::Threading::Thread->Sleep($timeoutMs);
        
        # Check if operation completed within timeout
        unless ($completed) {
          $completed = 1;
          
          if (defined($completionCallback)) {
            eval {
              my $timeoutException = System::TimeoutException->new('The operation has timed out');
              $completionCallback->(undef, $timeoutException, $state, 1);
            };
          }
        }
      });
    }
  }
  
  # Multiple callback-based operations in parallel
  sub ExecuteAllAsync {
    my ($class, $operations, $completionCallback, $state) = @_;
    throw(System::ArgumentNullException->new('operations')) unless defined($operations);
    throw(System::ArgumentException->new('operations must be an ARRAY reference'))
      unless ref($operations) eq 'ARRAY';
    
    my $totalOperations = scalar(@$operations);
    return if $totalOperations == 0;
    
    my $completedCount = 0;
    my @results = ();
    my @exceptions = ();
    my $lock = {};  # Simple lock for thread safety
    
    for my $i (0 .. $totalOperations - 1) {
      my $operation = $operations->[$i];
      next unless defined($operation) && ref($operation) eq 'CODE';
      
      # Execute each operation asynchronously
      $class->ExecuteAsync($operation, sub {
        my ($result, $exception, $opState) = @_;
        
        # Thread-safe completion tracking
        {
          lock($lock);
          $results[$i] = $result;
          $exceptions[$i] = $exception;
          $completedCount++;
          
          # Check if all operations completed
          if ($completedCount >= $totalOperations) {
            if (defined($completionCallback)) {
              eval {
                $completionCallback->(\@results, \@exceptions, $state);
              };
            }
          }
        }
      }, $i);
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;