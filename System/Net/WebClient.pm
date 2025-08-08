package System::Net::WebClient; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Event;
  require System::ComponentModel::AsyncCompletedEventArgs;
  require System::ComponentModel::ProgressChangedEventArgs;
  require System::Threading::ThreadPool;
  require System::Net::DownloadStringCompletedEventArgs;
  
  # WebClient - demonstrates EAP (Event-based Asynchronous Pattern)
  
  sub new {
    my ($class) = @_;
    
    return bless {
      _isBusy => 0,
      # EAP Events
      _downloadStringCompleted => System::Event->new(),
      _downloadProgressChanged => System::Event->new(),
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # EAP Properties
  sub IsBusy {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_isBusy};
  }
  
  # EAP Events
  sub DownloadStringCompleted {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($handler)) {
      $this->{_downloadStringCompleted}->AddHandler($handler);
    }
    return $this->{_downloadStringCompleted};
  }
  
  sub DownloadProgressChanged {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($handler)) {
      $this->{_downloadProgressChanged}->AddHandler($handler);
    }
    return $this->{_downloadProgressChanged};
  }
  
  # Synchronous method
  sub DownloadString {
    my ($this, $address) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('address')) unless defined($address);
    
    # Simple simulation of downloading a string
    # In real implementation, this would make HTTP request
    return "Downloaded content from: $address";
  }
  
  # EAP Asynchronous method
  sub DownloadStringAsync {
    my ($this, $address, $userToken) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('address')) unless defined($address);
    throw(System::InvalidOperationException->new('Another operation is already in progress')) 
      if $this->{_isBusy};
    
    $this->{_isBusy} = 1;
    
    # Queue the download operation to run asynchronously
    System::Threading::ThreadPool->QueueUserWorkItem(sub {
      my $result = undef;
      my $exception = undef;
      my $cancelled = 0;
      
      eval {
        # Simulate progress reporting
        for my $progress (0, 25, 50, 75, 100) {
          # Report progress
          my $progressArgs = System::ComponentModel::ProgressChangedEventArgs->new($progress, $userToken);
          $this->{_downloadProgressChanged}->Invoke($this, $progressArgs);
          
          # Simulate some work
          System::Threading::Thread->Sleep(100);
        }
        
        # Perform the actual download
        $result = $this->DownloadString($address);
      };
      
      if ($@) {
        $exception = $@;
      }
      
      # Mark operation as no longer busy
      $this->{_isBusy} = 0;
      
      # Raise completion event
      my $completedArgs = System::Net::DownloadStringCompletedEventArgs->new(
        $result, $exception, $cancelled, $userToken
      );
      $this->{_downloadStringCompleted}->Invoke($this, $completedArgs);
    });
  }
  
  # Cancel the asynchronous operation
  sub CancelAsync {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_isBusy}) {
      $this->{_isBusy} = 0;
      
      # In a real implementation, this would signal the worker thread to cancel
      # For simplicity, we'll just mark as no longer busy
      my $completedArgs = System::Net::DownloadStringCompletedEventArgs->new(
        undef, undef, 1, undef  # cancelled = true
      );
      $this->{_downloadStringCompleted}->Invoke($this, $completedArgs);
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;