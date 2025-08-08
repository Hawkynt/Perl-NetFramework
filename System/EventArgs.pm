package System::EventArgs; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # EventArgs - base class for event argument classes
  sub new {
    my ($class) = @_;
    
    return bless {}, ref($class) || $class || __PACKAGE__;
  }
  
  # Static Empty instance for events with no data
  our $Empty;
  
  sub Empty {
    $Empty = System::EventArgs->new() unless defined($Empty);
    return $Empty;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;