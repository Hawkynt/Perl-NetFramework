package System::NotImplementedException; {
  use base 'System::SystemException';
  
  use strict;
  use warnings;
  use CSharp;
  require System::SystemException;
  
  # NotImplementedException - thrown when a method is not implemented
  
  sub new {
    my ($class, $message, $innerException) = @_;
    $message //= 'The method or operation is not implemented.';
    
    return $class->SUPER::new($message, $innerException);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;