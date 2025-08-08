package System::Collections::Generic::KeyNotFoundException; {
  use base 'System::Exception';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exception;
  
  # KeyNotFoundException for Dictionary operations
  sub new {
    my ($class, $message, $innerException) = @_;
    $message //= "The given key was not present in the dictionary.";
    
    my $this = $class->SUPER::new($message, $innerException);
    return $this;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;