package System::OperationCanceledException; {
  use base 'System::SystemException';
  
  use strict;
  use warnings;
  use CSharp;
  require System::SystemException;
  
  # OperationCanceledException - thrown when an operation is canceled
  
  sub new {
    my ($class, $message, $innerException) = @_;
    $message //= 'The operation was canceled.';
    
    return $class->SUPER::new($message, $innerException);
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;