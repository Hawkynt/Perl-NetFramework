package System::StringComparer; {

  use base "System::Object";

  use CSharp;

  use strict;
  use warnings;
  
  sub Ordinal(){
    return(__PACKAGE__->_new(sub{$_[0]cmp$_[1]}));
  }
  
  sub OrdinalIgnoreCase(){
    return(__PACKAGE__->_new(sub{uc($_[0])cmp uc($_[1])}));
  }
  
  sub CurrentCulture(){
    return(Ordinal());
  }
  
  sub CurrentCultureIgnoreCase(){
    return(OrdinalIgnoreCase());
  }
  
  sub InvariantCulture(){
    return(Ordinal());
  }
  
  sub InvariantCultureIgnoreCase(){
    return(OrdinalIgnoreCase());
  }
  
  sub _new($$){
    my($class,$comparer)=@_;
    return(bless({_comparer=>$comparer},ref($class)||$class||__PACKAGE__));
  }
  
  sub Compare($$$){
    my($this,$value1,$value2)=@_;
    return($this->{_comparer}->(CSharp::_ToString($value1),CSharp::_ToString($value2)));
  }
  
  sub Equals($$$){
    my($this,$value1,$value2)=@_;
    return($this->Compare($value1,$value2)==0);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;