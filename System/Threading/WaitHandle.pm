package System::Threading::WaitHandle; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # WaitHandle - base class for synchronization objects
  
  # Constants
  use constant WaitTimeout => 0x102;
  use constant INFINITE => -1;
  
  sub new {
    my ($class) = @_;
    
    my $this = bless {
      _disposed => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    return $this;
  }
  
  # Abstract methods that derived classes must implement
  sub WaitOne {
    my ($this, $millisecondsTimeout, $exitContext) = @_;
    throw(System::NotImplementedException->new('WaitOne must be implemented by derived class'));
  }
  
  # Static methods for waiting on multiple handles
  sub WaitAll {
    my ($class, $waitHandles, $millisecondsTimeout, $exitContext) = @_;
    throw(System::ArgumentNullException->new('waitHandles')) unless defined($waitHandles);
    throw(System::ArgumentException->new('waitHandles cannot be empty')) if @$waitHandles == 0;
    
    $millisecondsTimeout //= -1;
    $exitContext //= 0;
    
    my $start_time = time() * 1000;
    
    # Simple implementation: wait for each handle in sequence
    for my $handle (@$waitHandles) {
      throw(System::ArgumentNullException->new('waitHandles contains null handle')) unless defined($handle);
      
      my $remaining_timeout = $millisecondsTimeout;
      if ($millisecondsTimeout >= 0) {
        my $elapsed = (time() * 1000) - $start_time;
        $remaining_timeout = $millisecondsTimeout - $elapsed;
        return 0 if $remaining_timeout <= 0;
      }
      
      return 0 unless $handle->WaitOne($remaining_timeout, $exitContext);
    }
    
    return 1;  # All handles signaled
  }
  
  sub WaitAny {
    my ($class, $waitHandles, $millisecondsTimeout, $exitContext) = @_;
    throw(System::ArgumentNullException->new('waitHandles')) unless defined($waitHandles);
    throw(System::ArgumentException->new('waitHandles cannot be empty')) if @$waitHandles == 0;
    
    $millisecondsTimeout //= -1;
    $exitContext //= 0;
    
    my $start_time = time() * 1000;
    
    # Simple polling implementation
    while (1) {
      for my $i (0 .. @$waitHandles - 1) {
        my $handle = $waitHandles->[$i];
        throw(System::ArgumentNullException->new('waitHandles contains null handle')) unless defined($handle);
        
        # Try non-blocking wait
        if ($handle->WaitOne(0, $exitContext)) {
          return $i;  # Return index of signaled handle
        }
      }
      
      # Check timeout
      if ($millisecondsTimeout >= 0) {
        my $elapsed = (time() * 1000) - $start_time;
        if ($elapsed >= $millisecondsTimeout) {
          return WaitTimeout;  # Timeout constant
        }
      }
      
      # Brief sleep to avoid busy waiting
      select(undef, undef, undef, 0.001);  # 1ms sleep
    }
  }
  
  # IDisposable implementation
  sub Dispose {
    my ($this) = @_;
    $this->{_disposed} = 1 unless $this->{_disposed};
  }
  
  sub Close {
    my ($this) = @_;
    $this->Dispose();
  }
  
  # Destructor
  sub DESTROY {
    my ($this) = @_;
    $this->Dispose() if defined($this) && !$this->{_disposed};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;