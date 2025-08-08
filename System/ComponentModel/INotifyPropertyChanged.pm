package System::ComponentModel::INotifyPropertyChanged; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # INotifyPropertyChanged - interface for property change notification
  # Implementing classes must provide PropertyChanged event
  
  # Interface contract:
  # - PropertyChanged event of type PropertyChangedEventHandler
  # - Event should be raised when any property value changes
  # - PropertyName in EventArgs can be null to indicate all properties changed
  
  sub PropertyChanged {
    throw(System::NotImplementedException->new('PropertyChanged event must be implemented by the derived class'));
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;