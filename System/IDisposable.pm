package System::IDisposable; {
  use strict;
  use warnings;
  
  use CSharp;
  
  sub Dispose($){throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;