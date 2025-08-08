package System::Collections::Specialized::INotifyCollectionChanged; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # INotifyCollectionChanged - interface for collection change notification
  # Implementing classes must provide CollectionChanged event
  
  # Interface contract:
  # - CollectionChanged event of type NotifyCollectionChangedEventHandler
  # - Event should be raised when collection items are added, removed, replaced, or moved
  # - Event provides detailed information about the change via NotifyCollectionChangedEventArgs
  
  sub CollectionChanged {
    throw(System::NotImplementedException->new('CollectionChanged event must be implemented by the derived class'));
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;