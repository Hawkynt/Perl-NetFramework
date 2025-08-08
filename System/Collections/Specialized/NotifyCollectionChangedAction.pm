package System::Collections::Specialized::NotifyCollectionChangedAction; {
  use strict;
  use warnings;
  use CSharp;
  
  # NotifyCollectionChangedAction - enumeration for collection change types
  
  # Export action constants
  use constant Add => 'Add';
  use constant Remove => 'Remove'; 
  use constant Replace => 'Replace';
  use constant Move => 'Move';
  use constant Reset => 'Reset';
  
  # Export constants to caller's namespace
  sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::Add"} = \&Add;
    *{"${caller}::Remove"} = \&Remove;
    *{"${caller}::Replace"} = \&Replace;
    *{"${caller}::Move"} = \&Move;
    *{"${caller}::Reset"} = \&Reset;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;