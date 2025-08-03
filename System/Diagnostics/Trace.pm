package System::Diagnostics::Trace; {
  use strict;
  use warnings;
  
  use CSharp;
  use System;
  use constant DEBUG=>true;
  
  sub WriteLine($){
    my($text)=@_;
    Console::WriteLine($text) if(DEBUG);
  }
  
  sub Write($){
    my($text)=@_;
    Console::Write($text) if(DEBUG);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;