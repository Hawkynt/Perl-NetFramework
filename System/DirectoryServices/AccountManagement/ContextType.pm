package System::DirectoryServices::AccountManagement::ContextType; {
  use constant {
    Machine=>0,
    Domain=>1,
    ApplicationDirectory=>2
  };
  
  use strict;
  use warnings;

  use CSharp;
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;