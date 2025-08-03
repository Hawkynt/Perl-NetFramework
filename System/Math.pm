package System::Math; {
  use strict;
  use warnings;

  sub Abs($){
    my($value)=@_;
    return(abs($value));
  }
  
  sub Acos($){
    my($value)=@_;
    return(atan2(sqrt(1-$value*$value),$value));
  }
  
  sub Asin($){
    my($value)=@_;
    return(atan2($value, sqrt(1-$value*$value)));
  }
  
  sub Atan($){
    my($value)=@_;
    return(atan2($value,1));
  }
  
  sub Atan2($){
    my($y,$x)=@_;
    return(atan2($y,$x));
  }
  
  sub Ceiling($){
    my($value)=@_;
    require POSIX;
    return(POSIX::ceil($value));
  }
  
  sub Cos($){
    my($value)=@_;
    return(cos($value));
  }
  
  sub Cosh($){
    my($value)=@_;
    return(0.5*(exp($value)+exp(-$value)));
  }
  
  sub Exp($){
    my($value)=@_;
    return(exp($value));
  }
  
  sub Floor($){
    my($value)=@_;
    return(int($value));
  }
  
  sub Log($;$){
    my($value,$base)=@_;
    return(defined($base)?log($value)/log($base):log($value));
  }
  
  sub Log10($){
    my($value)=@_;
    return(log($value)/log(10));
  }
  
  sub Max($$){
    my($a,$b)=@_;
    return($a>$b?$a:$b);
  }
  
  sub Min($$){
    my($a,$b)=@_;
    return($a<$b?$a:$b);
  }
  
  sub Pow($$){
    my($value,$power)=@_;
    return($value**$power);
  }
  
  sub Round($;$){
    my($value,$digits)=@_;
    return(int($value+0.5)) unless defined($digits);
    my $factor=10**$digits;
    return(int($value*$factor+0.5)/$factor);
  }
  
  sub Sign($){
    my($value)=@_;
    return($value<0?-1:$value>0?1:0);
  }
  
  sub Sin($){
    my($value)=@_;
    return(sin($value));
  }
  
  sub Sinh($){
    my($value)=@_;
    return(0.5*(exp($value)-exp(-$value)));
  }
  
  sub Sqrt($){
    my($value)=@_;
    return(sqrt($value));
  }
  
  sub Tan($){
    my($value)=@_;
    return(sin($value)/cos($value));
  }
  
  sub Tanh($){
    my($value)=@_;
    my $a=exp($value);
    my $b=exp(-$value);
    return(($a-$b)/($a+$b));
  }
  
  sub Truncate($){
    my($value)=@_;
    return($value<0?Ceiling($value):Floor($value));
  }
  
  use CSharp;
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
}
1;