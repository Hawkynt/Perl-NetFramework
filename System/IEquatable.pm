package System::IEquatable; {
  use strict;
  use warnings;
  
  use CSharp;

  sub Equals($$){throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;