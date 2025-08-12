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
    require Scalar::Util;
    return(Scalar::Util::refaddr($this)||0);
  }
  
  sub ReferenceEquals {
    my @args = @_;
    # Handle both static call (System::Object->ReferenceEquals) and package call (System::Object::ReferenceEquals)
    shift @args if @args >= 3 && (ref($args[0]) || $args[0] eq __PACKAGE__);
    
    my($value1,$value2) = @args;
    
    # Both null/undef are considered equal
    return(true) if(!defined($value1) && !defined($value2));
    
    # Must have both defined to compare references
    throw(System::ArgumentException->new("value1")) unless(defined($value1));
    throw(System::ArgumentException->new("value2")) unless(defined($value2));
    
    # Both must be references to compare addresses
    throw(System::ArgumentException->new("value1")) unless(ref($value1));
    throw(System::ArgumentException->new("value2")) unless(ref($value2));
    
    require Scalar::Util;
    return(Scalar::Util::refaddr($value1) == Scalar::Util::refaddr($value2));
  }
  
  sub Is($$){
    my($this,$class)=@_;
    return(false) unless(defined($this)&&ref($this));
    return($this->isa("$class"));
  }
  
  sub As($$){
    my($this,$class)=@_;
    return(null) unless defined($this) && ref($this);
    return($this->Is($class)?$this:null);
  }
  
  sub Equals {
    my @args = @_;
    
    # Handle both instance call ($obj->Equals) and static call (System::Object->Equals)
    my $preventEquatable;
    if (@args == 2 && ref($args[0]) && $args[0]->isa(__PACKAGE__) && ref($args[0]) ne __PACKAGE__) {
      # Instance method call: $obj->Equals($other)
      my($this, $other) = @args;
      
      # For instance calls, handle null/undef
      return(false) unless defined($other);
      
      # If both are objects, use reference comparison
      if (ref($other)) {
        eval { return ReferenceEquals($this, $other); };
        return false if $@; # If ReferenceEquals throws, objects are not equal
      } else {
        return(false); # Object can't equal scalar
      }
    } elsif (@args >= 2) {
      # Static method call: System::Object->Equals($val1, $val2) or System::Object::Equals($val1, $val2)
      shift @args if @args >= 3 && (ref($args[0]) || $args[0] eq __PACKAGE__);
      my($value1, $value2) = @args;
      $preventEquatable = $args[2] if @args > 2;
      
      # check for null values - both null are equal
      return(true) if(!defined($value1) && !defined($value2));
      
      # if only one is null, they're not equal
      return(false) if(!defined($value1) || !defined($value2));
      
      my $ref1=ref($value1);
      my $ref2=ref($value2);
      
      # use == overload if possible for scalar values
      unless($ref1||$ref2){
        require Scalar::Util;
        # Handle numeric comparison first
        if (Scalar::Util::looks_like_number($value1) && Scalar::Util::looks_like_number($value2)) {
          return($value1==$value2);
        }
        # Handle special Perl cases: 0 == '' and '' == 0 (numeric conversion)
        return(true) if (($value1 eq '0' && $value2 eq '') || ($value1 eq '' && $value2 eq '0'));
        # String comparison for non-numeric values  
        return($value1 eq $value2);
      }
      
      # use IEquatable.Equals if both types are in the same class chain
      if($ref1&&$ref2){
        return(true) if(ReferenceEquals($value1,$value2));
        
        unless($preventEquatable){
          require Scalar::Util;
          return($value2->Equals($value1,true)) if(Scalar::Util::blessed($value1) && Scalar::Util::blessed($value2) && $value1->isa($ref2) && $value2->isa("System::IEquatable"));
          return($value1->Equals($value2,true)) if(Scalar::Util::blessed($value1) && Scalar::Util::blessed($value2) && $value2->isa($ref1) && $value1->isa("System::IEquatable"));
        }
      }
      
      # try to use overloaded == operator; otherwise return false
      return(eval{return($value1==$value2)}||false);
    }
    
    return(false);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  BEGIN{CSharp::_PackageAlsoKnownAs(__PACKAGE__,"object");}
};

1;