package System::Diagnostics::Stopwatch; {
  use base "System::Object";
  
  use CSharp;
  require System::TimeSpan;
  require Time::HiRes;
  
  sub new($;@){
    my($class)=@_;
    return(bless({
      _isRunning=>false,
      _elapsedTicks=>0,
      _lastStartTime=>null,
    },ref($class)||$class||__PACKAGE__));
  }
  
  sub Elapsed($){
    my($this)=@_;
    return(System::TimeSpan->new($this->ElapsedTicks));
  }
  
  sub ElapsedMilliseconds($){
    my($this)=@_;
    return($this->Elapsed->TotalMilliseconds);
  }
  
  sub ElapsedTicks($){
    my($this)=@_;
    return($this->{_elapsedTicks}+$this->_CurrentTicks);
  }
  
  sub _CurrentTicks($){
    my($this)=@_;
    return(0) unless($this->{_isRunning});
    return((Time::HiRes::time()-$this->{_lastStartTime})*System::TimeSpan::TicksPerSecond());
  }
  
  sub IsRunning($){
    my($this)=@_;
    return($this->{_isRunning});
  }
  
  sub Reset($){
    my($this)=@_;
    $this->Stop();
    $this->{_elapsedTicks}=0;
  }
  
  sub Restart($){
    my($this)=@_;
    $this->Reset();
    $this->Start();
  }
  
  sub Start($){
    my($this)=@_;
    $this->{_lastStartTime}=Time::HiRes::time();
    $this->{_isRunning}=true;
  }
  
  sub Stop($){
    my($this)=@_;
    $this->{_elapsedTicks}=$this->ElapsedTicks;
    $this->{_isRunning}=false;
  }
  
  sub StartNew(){
    var $result=__PACKAGE__->new();
    $result->Start();
    return($result);
  }
  
  CSharp::_ShortenPackageName(__PACKAGE__);
};

1;