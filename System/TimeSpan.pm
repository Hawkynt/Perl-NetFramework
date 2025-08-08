package System::TimeSpan; {
  use base "System::Object","System::IEquatable";

  use strict;
  use warnings;
  
  use CSharp;
  use System::Exceptions;
  
  use constant _Long_MaxValue=>9223372036854775807;
  use constant _Long_MinValue=>-9223372036854775808;

  use overload 
    '""'=>\&ToString,
    "=="=>\&Equals,
    "!="=>sub{return(!Equals(@_));},
    "<=>"=>\&CompareTo,
    "<"=>sub{return(CompareTo(@_)==-1);},
    ">"=>sub{return(CompareTo(@_)==1);},
    "<="=>sub{return(CompareTo(@_)!=1);},
    ">="=>sub{return(CompareTo(@_)!=-1);},
    "neg"=>sub{
      throw(ArgumentException->new("this")) unless(ref($_[0])&&$_[0]->isa(__PACKAGE__));
      return(__PACKAGE__->new(-$_[0]->{_value}));
    },
    "-"=>\&Subtract,
    "+"=>\&Add,
    "*"=>sub{
      throw(ArgumentException->new("this")) unless(ref($_[0])&&$_[0]->isa(__PACKAGE__));
      return(__PACKAGE__->new($_[0]->{_value}*(0+$_[1])));
    },
    "/"=>sub{
      throw(ArgumentException->new("this")) unless(ref($_[0])&&$_[0]->isa(__PACKAGE__));
      throw(NotSupportedException->new("unable to divide number by TimeSpan")) if($_[2]);
      return(__PACKAGE__->new($_[0]->{_value}/(0+$_[1])));
    },
  ;
  
  my $zero=__PACKAGE__->new(0);
  my $minValue=__PACKAGE__->new(_Long_MinValue);
  my $maxValue=__PACKAGE__->new(_Long_MaxValue);
  
  sub new($;$$$$$){
    my($class)=shift(@_);
    my $ticks;
    my $count=scalar(@_);
    if($count==0){
      $ticks=0;
    }elsif($count==1){
      $ticks=0+$_[0];
    }elsif($count==3){
      $ticks=(0+$_[0])*TicksPerHour()+(0+$_[1])*TicksPerMinute()+(0+$_[2])*TicksPerSecond();
    }elsif($count==4){
      $ticks=(0+$_[0])*TicksPerDay()+(0+$_[1])*TicksPerHour()+(0+$_[2])*TicksPerMinute()+(0+$_[3])*TicksPerSecond();
    }elsif($count==5){
      $ticks=(0+$_[0])*TicksPerDay()+(0+$_[1])*TicksPerHour()+(0+$_[2])*TicksPerMinute()+(0+$_[3])*TicksPerSecond()+(0+$_[4])*TicksPerMillisecond();
    }else{
      throw(ArgumentException->new());
    }
    bless{
      _value=>$ticks
    },ref($class)||$class||__PACKAGE__;
  }

  #region instance
  sub Ticks($){
    my($this)=@_;
    return($this->{_value});
  }
  
  sub Days($){
    my($this)=@_;
    return(int($this->TotalDays));
  }
  
  sub Hours($){
    my($this)=@_;
    return(int($this->TotalHours)%24);
  }
  
  sub Minutes($){
    my($this)=@_;
    return(int($this->TotalMinutes)%60);
  }
  
  sub Seconds($){
    my($this)=@_;
    return(int($this->TotalSeconds)%60);
  }
  
  sub _10Seconds($){
    my($this)=@_;
    return(int($this->_Total10Seconds)%10);
  }
  
  sub _100Seconds($){
    my($this)=@_;
    return(int($this->_Total100Seconds)%100);
  }
  
  sub Milliseconds($){
    my($this)=@_;
    return(int($this->TotalMilliseconds)%1000);
  }
  
  sub _10Milliseconds($){
    my($this)=@_;
    return(int($this->_Total10Milliseconds)%10000);
  }
  
  sub _100Milliseconds($){
    my($this)=@_;
    return(int($this->_Total100Milliseconds)%100000);
  }
  
  sub _1000Milliseconds($){
    my($this)=@_;
    return(int($this->_Total1000Milliseconds)%1000000);
  }
  
  sub _10000Milliseconds($){
    my($this)=@_;
    return(int($this->_Total10000Milliseconds)%10000000);
  }
  
  sub TotalDays($){
    my($this)=@_;
    return($this->Ticks/TicksPerDay());
  }
  
  sub TotalHours($){
    my($this)=@_;
    return($this->Ticks/TicksPerHour());
  }
  
  sub TotalMinutes($){
    my($this)=@_;
    return($this->Ticks/TicksPerMinute());
  }
  
  sub TotalSeconds($){
    my($this)=@_;
    return($this->Ticks/TicksPerSecond());
  }
  
  sub _Total10Seconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer10Second());
  }
  
  sub _Total100Seconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer100Second());
  }
  
  sub TotalMilliseconds($){
    my($this)=@_;
    return($this->Ticks/TicksPerMillisecond());
  }
  
  sub _Total0Milliseconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer10Millisecond());
  }
  
  sub _Total100Milliseconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer100Millisecond());
  }
  
  sub _Total1000Milliseconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer1000Millisecond());
  }
  
  sub _Total10000Milliseconds($){
    my($this)=@_;
    return($this->Ticks/_TicksPer10000Millisecond());
  }
  
  sub Duration($){
    my($this)=@_;
    return(__PACKAGE__->new(abs($this->{_value})));
  }
  
  sub GetHashCode($){
    my($this)=@_;
    return($this->{_value} ^ ($this->{_value} >> 32));
  }
  
  sub ToString($;$){
    my($this,$format)=@_;
    
    # default format
    $format="c" unless(defined($format));
    
    # convert between standard and user defined
    if($format eq "c"){
      $format="[-][d'.']hh':'mm':'ss['.'fffffff]";
    }elsif($format eq "g"){
      $format="[-][d':']h':'mm':'ss[.FFFFFFF]";
    }elsif($format eq "G"){
      $format="[-]d':'hh':'mm':'ss.fffffff";
    }
    
    my $result=$format;
    $result=~s/([^']+)(?:'(.*?(?:(?:\\\\)+|(?:[^\\])))')?/$this->_HandlePartOfFormat($1,$2)/eg;
    $result=~s/(?:(?:\\\\)+|[^\\]|^)\[\]//g;
    $result=~s/((?:\\\\)+|[^\\]|^)\[(.*?(?:(?:\\\\)+|[^\\]|))\]/$1._HandleFormatBrackets($2)/eg;
    return($result);
  }
  
  sub _HandleFormatBrackets($){
    my($bracketContent)=@_;
    return($bracketContent=~m/[1-9]/?$bracketContent:"");
  }
  
  sub _HandlePartOfFormat($$$){
    my($this,$format,$post)=@_;
    my $result=$format;
    # TODO: escape char handling
    # TODO: formats using big F's
    $result=~s/-/$this->Ticks<0?"-":""/eg;
    $result=~s/dddddddd/Decimal->new($this->Days)->ToString("00000000")/eg;
    $result=~s/ddddddd/Decimal->new($this->Days)->ToString("0000000")/eg;
    $result=~s/fffffff/Decimal->new($this->_10000Milliseconds)->ToString("0000000")/eg;
    $result=~s/dddddd/Decimal->new($this->Days)->ToString("000000")/eg;
    $result=~s/ffffff/Decimal->new($this->_1000Milliseconds)->ToString("000000")/eg;
    $result=~s/ddddd/Decimal->new($this->Days)->ToString("00000")/eg;
    $result=~s/fffff/Decimal->new($this->_100Milliseconds)->ToString("00000")/eg;
    $result=~s/dddd/Decimal->new($this->Days)->ToString("0000")/eg;
    $result=~s/ffff/Decimal->new($this->_10Milliseconds)->ToString("0000")/eg;
    $result=~s/ddd/Decimal->new($this->Days)->ToString("000")/eg;
    $result=~s/fff/Decimal->new($this->Milliseconds)->ToString("000")/eg;
    $result=~s/dd/Decimal->new($this->Days)->ToString("00")/eg;
    $result=~s/hh/Decimal->new($this->Hours)->ToString("00")/eg;
    $result=~s/mm/Decimal->new($this->Minutes)->ToString("00")/eg;
    $result=~s/ss/Decimal->new($this->Seconds)->ToString("00")/eg;
    $result=~s/ff/Decimal->new($this->_100Seconds)->ToString("00")/eg;
    $result=~s/%d/Decimal->new($this->Days)->ToString("0")/eg;
    $result=~s/%h/Decimal->new($this->Hours)->ToString("0")/eg;
    $result=~s/%m/Decimal->new($this->Minutes)->ToString("0")/eg;
    $result=~s/%s/Decimal->new($this->Seconds)->ToString("0")/eg;
    $result=~s/%f/Decimal->new($this->_10Seconds)->ToString("0")/eg;
    $result=~s/d/Decimal->new($this->Days)->ToString("0")/eg;
    $result=~s/h/Decimal->new($this->Hours)->ToString("0")/eg;
    $result=~s/m/Decimal->new($this->Minutes)->ToString("0")/eg;
    $result=~s/s/Decimal->new($this->Seconds)->ToString("0")/eg;
    $result=~s/f/Decimal->new($this->_10Seconds)->ToString("0")/eg;
    $result.=$post if(defined($post));
    return($result);
  }
  
  sub Equals($$;$){
    my($this,$other,$swapped)=@_;
    throw(ArgumentException->new("this")) unless(ref($this)&&$this->isa(__PACKAGE__));
    throw(ArgumentException->new("other")) unless(ref($other)&&$other->isa(__PACKAGE__));
    return($this->{_value}==$other->{_value});
  }
  
  sub CompareTo($$;$){
    my($this,$other,$swapped)=@_;
    throw(ArgumentException->new("this")) unless(ref($this)&&$this->isa(__PACKAGE__));
    throw(ArgumentException->new("other")) unless(ref($other)&&$other->isa(__PACKAGE__));
    return($swapped?-($this->{_value}<=>$other->{_value}):($this->{_value}<=>$other->{_value}));
  }
  
  sub Add($$;$){
    my($this,$other,$swapped)=@_;
    throw(ArgumentException->new("this")) unless(ref($this)&&$this->isa(__PACKAGE__));
    throw(ArgumentException->new("other")) unless(ref($other)&&$other->isa(__PACKAGE__));
    return(__PACKAGE__->new($this->{_value}+$other->{_value}));
  }
  
  sub Subtract($$;$){
    my($this,$other,$swapped)=@_;
    throw(ArgumentException->new("this")) unless(ref($this)&&$this->isa(__PACKAGE__));
    throw(ArgumentException->new("other")) unless(ref($other)&&$other->isa(__PACKAGE__));
    return(__PACKAGE__->new($swapped?$other->{_value}-$this->{_value}:$this->{_value}-$other->{_value}));
  }
  #endregion
  #region static
  sub Zero(){return($zero);}
  sub MinValue(){return($minValue);}
  sub MaxValue(){return($maxValue);}
  sub TicksPerMillisecond(){return(10000);}
  sub _TicksPer10Millisecond(){return(TicksPerMillisecond()*0.1);}
  sub _TicksPer100Millisecond(){return(TicksPerMillisecond()*0.01);}
  sub _TicksPer1000Millisecond(){return(TicksPerMillisecond()*0.001);}
  sub _TicksPer10000Millisecond(){return(TicksPerMillisecond()*0.0001);}
  sub TicksPerSecond(){return(TicksPerMillisecond()*1000);}
  sub _TicksPer10Second(){return(TicksPerSecond()*0.1);}
  sub _TicksPer100Second(){return(TicksPerSecond()*0.01);}
  sub TicksPerMinute(){return(TicksPerSecond()*60);}
  sub TicksPerHour(){return(TicksPerMinute()*60);}
  sub TicksPerDay(){return(TicksPerHour()*24);}
  sub FromDays($){my($class,$days)=@_; return(__PACKAGE__->new($days*TicksPerDay()));}
  sub FromHours($){my($class,$hours)=@_; return(__PACKAGE__->new($hours*TicksPerHour()));}
  sub FromMinutes($){my($class,$minutes)=@_; return(__PACKAGE__->new($minutes*TicksPerMinute()));}
  sub FromSeconds($){my($class,$seconds)=@_; return(__PACKAGE__->new($seconds*TicksPerSecond()));}
  sub FromMilliseconds($){my($class,$milliseconds)=@_; return(__PACKAGE__->new($milliseconds*TicksPerMillisecond()));}
  #endregion
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

1;