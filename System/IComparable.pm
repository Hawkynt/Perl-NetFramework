package System::IComparable; {
  use strict;
  use warnings;
  
  use CSharp;
  
  sub CompareTo($$){throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;