package System::Decimal; {
  use base 'System::Object','System::IEquatable';

  use strict;
  use warnings;
  
  #region Overloads
  use overload 
    '""'=>\&ToString,
    '+'=>sub{
      my($this,$value,$swapped)=@_;
      return(__PACKAGE__->new(
        _GetNum($this)+_GetNum($value)
      ));
    },
    '-'=>sub{
      my($this,$value,$swapped)=@_;
      
      return(__PACKAGE__->new(
        $swapped?_GetNum($value)-_GetNum($this)
        :_GetNum($this)-_GetNum($value)
      ));
    },
    'neg'=>sub{
      my($this)=@_;
      return(__PACKAGE__->new(-_GetNum($this)));
    },
    '*'=>sub{
      my($this,$value,$swapped)=@_;
      return(__PACKAGE__->new(
        _GetNum($this)*_GetNum($value)
      ));
    },
    '/'=>sub{
      my($this,$value,$swapped)=@_;
      
      return(__PACKAGE__->new(
        $swapped?_GetNum($value)/_GetNum($this)
        :_GetNum($this)/_GetNum($value)
      ));
    },
    '%'=>sub{
      my($this,$value,$swapped)=@_;
      
      return(__PACKAGE__->new(
        $swapped?_GetNum($value)%_GetNum($this)
        :_GetNum($this)%_GetNum($value)
      ));
    },
    '0+'=>sub{
      my($this)=@_;
      return(_GetNum($this));
    },
    '=='=>\&Equals,
    '!='=>sub{
      my($this,$value,$swapped)=@_;
      return(!$this->Equals($value,$swapped));
    },
    '<'=>sub{
       my($this,$value,$swapped)=@_;
       return($swapped?!(_GetNum($this)<_GetNum($value)):_GetNum($this)<_GetNum($value));
    },
    '>'=>sub{
       my($this,$value,$swapped)=@_;
       return($swapped?!(_GetNum($this)>_GetNum($value)):_GetNum($this)>_GetNum($value));
    },
    '<='=>sub{
       my($this,$value,$swapped)=@_;
       return($swapped?!(_GetNum($this)<=_GetNum($value)):_GetNum($this)<=_GetNum($value));
    },
    '>='=>sub{
       my($this,$value,$swapped)=@_;
       return($swapped?!(_GetNum($this)>=_GetNum($value)):_GetNum($this)>=_GetNum($value));
    },
    '<=>'=>sub{
       my($this,$value,$swapped)=@_;
       return($swapped?-(_GetNum($this)<=>_GetNum($value)):_GetNum($this)<=>_GetNum($value));
    },
  ;
  #endregion
  
  use constant Empty=>"";
  
  use CSharp;
  use System::Exceptions;
  
  sub _GetNum($){
    my($value)=@_;
    throw(System::ArgumentException->new("value"))if(ref($value) && !$value->isa("System::Decimal"));
    return(ref($value)?$value->{_value}:$value);
  }
  
  #region instance methods
  sub new($;$) {
    my($class)=shift(@_);
    my($value)=@_;
    bless{
      _value=>_GetNum($value)
    },ref($class)||$class||__PACKAGE__;
  }

  sub ToDecimal($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return($this);
  }

  sub ToString($;$) {
    my($this,$format)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $value=_GetNum($this);
    return($value) unless defined($format);
    my $index=index($format,".");
    my $cformat;
    if($index>=0) {
      $cformat="%0".(length($format)-1).".".(length($format)-$index-1)."f";
      $value=sprintf($cformat,$value);
      $cformat="%s";
      my $index2=index($value.".",".");
      $value="0" x ($index-$index2) . $value if($index2<$index);
    } else {
      $cformat="%0".length($format)."d";
    }
    return(sprintf($cformat,$value));
  }

  sub GetHashCode($){
    my($this)=@_;
    return(int($this->{_value}));
  }
  
  sub Equals($$;$) {
    my($this,$value,$swapped)=@_;
    return($this->{_value}==_GetNum($value));
  }
  #endregion

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
  BEGIN{CSharp::_PackageAlsoKnownAs(__PACKAGE__,"decimal");}
};

1;