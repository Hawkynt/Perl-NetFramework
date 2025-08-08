package System::IAsyncResult; {
  use strict;
  use warnings;
  use CSharp;

  # IAsyncResult interface for APM (Asynchronous Programming Model)
  # Represents the status of an asynchronous operation
  
  # Interface methods that must be implemented by derived classes
  sub AsyncState($) { throw System::NotImplementedException->new() }
  sub AsyncWaitHandle($) { throw System::NotImplementedException->new() }
  sub CompletedSynchronously($) { throw System::NotImplementedException->new() }
  sub IsCompleted($) { throw System::NotImplementedException->new() }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;