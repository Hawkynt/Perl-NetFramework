package System::Console; {

  use strict;
  use warnings;

  use CSharp;
  require System::Environment;

  sub Clear() {
    print System::Environment->NewLine() x (100);
  }

  sub Write(@) {
    return if(scalar(@_)<1);
    
    if(scalar(@_)==1) {
      print $_[0];
      return;
    }
    require System::String;
    print System::String::Format(@_);
  }

  sub WriteLine(@) {
    my $flush=$|;
    $|=1;
    Write(@_);
    print System::Environment->NewLine();
    $|=$flush;
  }

  sub ReadLine(){
    my $text=<STDIN>;
    chomp($text) if defined($text);
    return($text);
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;