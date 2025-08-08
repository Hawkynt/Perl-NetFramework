package System::Threading::ThreadStateException; {
  use base 'System::SystemException';
  
  use strict;
  use warnings;
  use CSharp;
  require System::SystemException;
  
  # ThreadStateException - thrown when a Thread is in an invalid ThreadState for the method call
  
  sub new {
    my ($class, $message, $innerException) = @_;
    $message //= 'Thread was in an invalid state for the operation being executed.';
    
    return $class->SUPER::new($message, $innerException);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;