package System::ComponentModel::INotifyPropertyChanging; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # INotifyPropertyChanging - interface for property changing notification (before change)
  # Implementing classes must provide PropertyChanging event
  
  # Interface contract:
  # - PropertyChanging event of type PropertyChangingEventHandler  
  # - Event should be raised before any property value changes
  # - Event is cancelable via CancelEventArgs
  # - PropertyName in EventArgs can be null to indicate all properties changing
  
  sub PropertyChanging {
    throw(System::NotImplementedException->new('PropertyChanging event must be implemented by the derived class'));
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;