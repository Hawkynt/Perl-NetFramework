package System::IFormattable; {
  use strict;
  use warnings;
  
  use CSharp;

  sub ToString($$){throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;