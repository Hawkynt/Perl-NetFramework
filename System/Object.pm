package System::Object; {
  
  use CSharp;
  require System::Exceptions;
  
  sub new($){
    my($class)=@_;
    return(bless({},ref($class)||$class||__PACKAGE__));
  }
  
  sub ToString($){
    my($this)=@_;
    require Scalar::Util;
    return(sprintf("%s", ref($this) || __PACKAGE__));
  }

  sub GetType($){
    my($this)=@_;
    return(ref($this) || __PACKAGE__);
  }
  
  sub GetHashCode($){
    my($this)=@_;
    return(0)unless(defined($this));
    return($this->GetHashCode())if($this->can("GetHashCode")&&ref($this)ne __PACKAGE__);
    require Scalar::Util;
    return(Scalar::Util::refaddr($this));
  }
  
  sub ReferenceEquals($$){
    my($value1,$value2)=@_;
    return(true) unless(defined($value1)||defined($value2));
    throw(System::ArgumentException->new("value1")) unless(ref($value1));
    throw(System::ArgumentException->new("value2")) unless(ref($value2));
    require Scalar::Util;
    return(Scalar::Util::refaddr($value1) eq Scalar::Util::refaddr($value2));
  }
  
  sub Is($$){
    my($this,$class)=@_;
    return(false) unless(defined($this)&&ref($this));
    return($this->isa("$class"));
  }
  
  sub As($$){
    my($this,$class)=@_;
    return($this->Is($class)?$this:null);
  }
  
  sub Equals($$;$){
    my($value1,$value2,$preventEquatable)=@_;
    
    # check for null values
    return(true) unless(defined($value1)||defined($value2));
    
    my $ref1=ref($value1);
    my $ref2=ref($value2);
    
    # use == overload if possible for scalar values
    unless($ref1||$ref2){
      require Scalar::Util;
      return($value1==$value2)if(Scalar::Util::looks_like_number($value1) && Scalar::Util::looks_like_number($value2));
      return($value1 eq $value2);
    }
    
    # use IEquatable.Equals if both types are in the same class chain
    if($ref1&&$ref2){
      return(true) if(ReferenceEquals($value1,$value2));
      
      unless($preventEquatable){
        return($value2->Equals($value1,true)) if($value1->isa($ref2) && $value2->isa("System::IEquatable"));
        return($value1->Equals($value2,true)) if($value2->isa($ref1) && $value1->isa("System::IEquatable"));
      }
    }
    
    # try to use overloaded == operator; otherwise return false
    return(eval{return($value1==$value2)}||false);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  BEGIN{CSharp::_PackageAlsoKnownAs(__PACKAGE__,"object");}
};

1;