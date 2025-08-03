package System::Diagnostics::Contracts::Contract; {
  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;

  sub Requires($;$) {
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Require")) unless($require);
  }

  sub Assert($;$) {
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Assert")) unless($require);
  }

  sub Assume($;$) {
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Assume")) unless($require);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;