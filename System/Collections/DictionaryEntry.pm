package System::Collections::DictionaryEntry; {
  use base "System::Object";
  
  use strict;
  use warnings;

  use CSharp;
  
  sub new($$$) {
    my($class)=shift;
    my($key,$value)=@_;
    bless {
      _key=>$key,
      _value=>$value
    },ref($class)||$class||__PACKAGE__;
  }

  sub Key() {
    my($this)=@_;
    return($this->{_key});
  }

  sub Value(){
    my($this)=@_;
    return($this->{_value});
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}
1;