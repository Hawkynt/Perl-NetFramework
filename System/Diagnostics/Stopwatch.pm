package System::Diagnostics::Stopwatch; {
  use base "System::Object";
  
  use strict;
  use warnings;
  use CSharp;
  require System::TimeSpan;
  require System::Exceptions;
  require Time::HiRes;
  
  sub new($;@){
    my($class)=@_;
    return(bless({
      _isRunning=>false,
      _elapsedTicks=>0,
      _lastStartTime=>undef,
    },ref($class)||$class||__PACKAGE__));
  }
  
  sub Elapsed($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return(System::TimeSpan->new($this->ElapsedTicks()));
  }
  
  sub ElapsedMilliseconds($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return($this->ElapsedTicks() / System::TimeSpan::TicksPerMillisecond());
  }
  
  sub ElapsedMicroseconds($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return($this->ElapsedTicks() / (System::TimeSpan::TicksPerMillisecond() / 1000));
  }
  
  sub ElapsedTicks($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return($this->{_elapsedTicks}+$this->_CurrentTicks());
  }
  
  sub _CurrentTicks($){
    my($this)=@_;
    return(0) unless($this->{_isRunning});
    return(0) unless(defined($this->{_lastStartTime}));
    return((Time::HiRes::time()-$this->{_lastStartTime})*System::TimeSpan::TicksPerSecond());
  }
  
  sub IsRunning($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return($this->{_isRunning});
  }
  
  sub Reset($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    $this->Stop();
    $this->{_elapsedTicks}=0;
  }
  
  sub Restart($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    $this->Reset();
    $this->Start();
  }
  
  sub Start($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return if($this->{_isRunning}); # Already running, do nothing like .NET
    $this->{_lastStartTime}=Time::HiRes::time();
    $this->{_isRunning}=true;
  }
  
  sub Stop($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return unless($this->{_isRunning}); # Not running, do nothing like .NET
    $this->{_elapsedTicks}=$this->ElapsedTicks();
    $this->{_isRunning}=false;
    $this->{_lastStartTime}=undef;
  }
  
  sub StartNew(){
    my($class) = @_;
    $class = __PACKAGE__ unless defined($class);
    my $result=$class->new();
    $result->Start();
    return($result);
  }
  
  sub Frequency(){
    # .NET Stopwatch.Frequency returns ticks per second
    return(System::TimeSpan::TicksPerSecond());
  }
  
  sub IsHighResolution(){
    # Time::HiRes provides high resolution timing in Perl
    return(true);
  }
  
  # Additional utility methods for better .NET compatibility
  sub GetTimestamp(){
    # Returns current timestamp in ticks
    return(Time::HiRes::time() * System::TimeSpan::TicksPerSecond());
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;