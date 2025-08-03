package System::Threading::Thread; {
  use base "System::Object";

  use strict;
  use warnings;
  
  use CSharp;
  use System::Diagnostics::Contracts;

  use constant _STATE_NOT_STARTED=>0;
  use constant _STATE_RUNNING=>1;
  use constant _STATE_TERMINATED=>2;

  # fields
  my $_FIELDS={
    _function=>null,
    _thread=>null,
    _state=>_STATE_NOT_STARTED,
  };

  sub new($$) {
    my $class=shift;
    my $this={};
    bless($this,$class);
    %{$this}=%{$_FIELDS};
    
    my ($function)=@_;
    $this->{_function}=$function;
    
    return($this);
  }

  sub Start($) {
    my $this=shift;
    Contract::Requires($this->{_isRunning}==_STATE_NOT_STARTED,"Thread was already started");
    $this->{_isRunning}=_STATE_RUNNING;
    require threads;
    $this->{_thread}=threads::async {
      $SIG{"TERM"}=sub{threads->exit()};
      &{$this->{_function}}();
    };
  }

  sub Join($) {
    my $this=shift;
    Contract::Requires($this->{_isRunning}==_STATE_RUNNING,"Thread not running");
    $this->{_thread}->join();
    $this->{_isRunning}=_STATE_TERMINATED;
  }

  sub Abort($) {
    my $this=shift;
    Contract::Requires($this->{_isRunning}==_STATE_RUNNING,"Thread not running");
    $this->{_thread}->kill("TERM");
    $this->{_isRunning}=_STATE_TERMINATED;
    $this->{_thread}->join();
  }

  # statics
  sub Sleep($) {
    my($msecs)=@_;
    throw(System::ArgumentException->new()) if(ref($msecs)&&!$msecs->isa("System::TimeSpan"));
    $msecs=$msecs->TotalMilliseconds if(ref($msecs));
    select(null,null,null,$msecs/1000.0);
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};
1;