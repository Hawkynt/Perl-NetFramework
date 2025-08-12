package System::Diagnostics::Contracts::Contract; {
  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;

  sub Requires {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Contract$/;
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Require")) unless($require);
  }

  sub Assert {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Contract$/;
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Assert")) unless($require);
  }

  sub Assume {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Contract$/;
    my ($require,$message)=@_;
    throw(System::ContractException->new($message||"Assume")) unless($require);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;