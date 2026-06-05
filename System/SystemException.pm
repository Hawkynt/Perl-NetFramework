package System::SystemException; {
  use base 'System::Exception';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exception;
  
  # SystemException - the base class for all system exceptions
  
  sub new {
    my ($class, $message, $innerException) = @_;
    $message = 'System error.' unless defined($message);
    
    return $class->SUPER::new($message, $innerException);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;