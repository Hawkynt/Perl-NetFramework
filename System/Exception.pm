#!/usr/bin/perl

# base class for all exceptions
package System::Exception; {
  use base "System::Object";

  use strict;
  use warnings;

  use overload 
    '""'=>\&ToString,
  ;

  use constant {
    TX_TEXT=>"%s: %s\n%s\n",
    StringEmpty=>"",
  };
  
  use CSharp;
  use System::Resources;
  
  sub new($;$$) {
    my $class=shift(@_);
    my($text,$innerException)=@_;
    my $this={
      Message=>$text,
      InnerException=>$innerException,
      StackTrace=>undef,
    };
    bless $this,ref($class)||$class;
  }

  sub Message($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return($this->{Message}?$this->{Message}:sprintf(System::Resources::TX_EXCEPTION, ref($this)));
  }

  sub HasStackTrace($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(defined($this->{StackTrace}));
  }
  
  sub GetStackTrace($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $text=StringEmpty;
    
    my @frames;
    for(my $i=1;;++$i){
      my $frame=_GetCallDump($i);
      push(@frames,$frame);
      last unless(defined($frame->{Package}));
    }
    
    my $caller;
    for(my $i=0;$i<scalar(@frames);++$i) {
      $caller=$frames[$i];
      my $parent=$frames[$i+1];
      my $grandparent=$frames[$i+2];
      my $method=$parent->{Method};
      last unless(defined($caller->{Package}));
      
      # skip the try command
      next if(defined($method) && ($method eq "CSharp::try"));
      
      # skip the try eval block
      next if(defined($method) && ($method eq "(eval)") && defined($grandparent) && defined($grandparent->{Method}) && ($grandparent->{Method}eq"CSharp::try"));
      $text.=sprintf(System::Resources::TX_STACKFRAME,($method?sprintf(System::Resources::TX_METHOD,$method):StringEmpty),$caller->{FileName},$caller->{Line});
    }
    
    $this->{StackTrace}=$text;
  }

  sub ToString($){
    my($this)=@_;
    my $text=ref($this);
    $text=~s/::/./g ;
    $text=sprintf(TX_TEXT,$text,$this->Message(),$this->{StackTrace}||System::Resources::TX_MISSING_STACK);
    return($text);
  }
  
  sub _GetCallDump($) {
    my($stackIndex)=@_;
    my $result={};
    package _throwDB;
    if (my @data=caller($stackIndex+1)) {
      $result->{StackDepth}=$stackIndex;
      $result->{Package}=$data[0];
      $result->{FileName}=$data[1];
      $result->{Line}=$data[2];
      $result->{Method}=$data[3];
      $result->{HasArguments}=$data[4];
      $result->{WantsArray}=$data[5];
      $result->{EvalText}=$data[6];
      $result->{IsRequire}=$data[7];
      $result->{Reserved}=$data[8];
      $result->{Reserved2}=$data[9];
    }
    return($result);
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}    
};
 
1;