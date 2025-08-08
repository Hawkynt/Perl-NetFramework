package System::ComponentModel::BindingList; {
  use base qw(System::Collections::Generic::List System::ComponentModel::INotifyPropertyChanged System::Collections::Specialized::INotifyCollectionChanged);
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Collections::Generic::List;
  require System::ComponentModel::INotifyPropertyChanged;
  require System::ComponentModel::INotifyPropertyChanging;
  require System::Collections::Specialized::INotifyCollectionChanged;
  require System::Collections::Specialized::NotifyCollectionChangedEventArgs;
  require System::ComponentModel::PropertyChangedEventArgs;
  require System::ComponentModel::PropertyChangingEventArgs;
  require System::Event;
  require System::Delegate;

  # BindingList<T> - A generic list that provides notifications when items are added, removed, or changed
  
  sub new {
    my ($class) = @_;
    
    my $this = $class->SUPER::new();
    
    # Initialize events
    $this->{_propertyChanged} = System::Event->new();
    $this->{_propertyChanging} = System::Event->new();
    $this->{_collectionChanged} = System::Event->new();
    
    # BindingList specific properties
    $this->{_allowEdit} = true;
    $this->{_allowNew} = true;
    $this->{_allowRemove} = true;
    $this->{_raiseListChangedEvents} = true;
    $this->{_supportsChangeNotification} = false;
    $this->{_supportsSearching} = false;
    $this->{_supportsSorting} = false;
    
    return $this;
  }

  # Event properties (implementing INotifyPropertyChanged and INotifyCollectionChanged)
  sub PropertyChanged {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($handler)) {
      # Add handler
      return $this->{_propertyChanged}->AddHandler($handler);
    }
    return $this->{_propertyChanged};
  }
  
  sub PropertyChanging {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($handler)) {
      # Add handler  
      return $this->{_propertyChanging}->AddHandler($handler);
    }
    return $this->{_propertyChanging};
  }
  
  sub CollectionChanged {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($handler)) {
      # Add handler
      return $this->{_collectionChanged}->AddHandler($handler);
    }
    return $this->{_collectionChanged};
  }

  # BindingList specific properties
  sub AllowEdit {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      my $oldValue = $this->{_allowEdit};
      if ($oldValue ne $value) {
        $this->OnPropertyChanging(System::ComponentModel::PropertyChangingEventArgs->new('AllowEdit'));
        $this->{_allowEdit} = $value ? true : false;
        $this->OnPropertyChanged(System::ComponentModel::PropertyChangedEventArgs->new('AllowEdit'));
      }
      return;
    }
    
    # Getter
    return $this->{_allowEdit};
  }
  
  sub AllowNew {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      my $oldValue = $this->{_allowNew};
      if ($oldValue ne $value) {
        $this->OnPropertyChanging(System::ComponentModel::PropertyChangingEventArgs->new('AllowNew'));
        $this->{_allowNew} = $value ? true : false;
        $this->OnPropertyChanged(System::ComponentModel::PropertyChangedEventArgs->new('AllowNew'));
      }
      return;
    }
    
    # Getter
    return $this->{_allowNew};
  }
  
  sub AllowRemove {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      my $oldValue = $this->{_allowRemove};
      if ($oldValue ne $value) {
        $this->OnPropertyChanging(System::ComponentModel::PropertyChangingEventArgs->new('AllowRemove'));
        $this->{_allowRemove} = $value ? true : false;
        $this->OnPropertyChanged(System::ComponentModel::PropertyChangedEventArgs->new('AllowRemove'));
      }
      return;
    }
    
    # Getter
    return $this->{_allowRemove};
  }
  
  sub RaiseListChangedEvents {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      my $oldValue = $this->{_raiseListChangedEvents};
      if ($oldValue ne $value) {
        $this->OnPropertyChanging(System::ComponentModel::PropertyChangingEventArgs->new('RaiseListChangedEvents'));
        $this->{_raiseListChangedEvents} = $value ? true : false;
        $this->OnPropertyChanged(System::ComponentModel::PropertyChangedEventArgs->new('RaiseListChangedEvents'));
      }
      return;
    }
    
    # Getter
    return $this->{_raiseListChangedEvents};
  }

  # Override List<T> methods to provide notifications
  sub Add {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    throw(System::NotSupportedException->new('Collection is read-only'))
      unless $this->{_allowNew};
    
    my $index = $this->Count();
    
    # Call base Add method
    $this->SUPER::Add($item);
    
    # Raise collection changed event
    if ($this->{_raiseListChangedEvents}) {
      my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd([$item], $index);
      $this->OnCollectionChanged($args);
    }
    
    # Hook up change notification if item supports it
    $this->_HookItemChangeNotification($item);
  }
  
  sub Insert {
    my ($this, $index, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('index')) unless defined($index);
    
    throw(System::NotSupportedException->new('Collection is read-only'))
      unless $this->{_allowNew};
    
    # Call base Insert method
    $this->SUPER::Insert($index, $item);
    
    # Raise collection changed event
    if ($this->{_raiseListChangedEvents}) {
      my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd([$item], $index);
      $this->OnCollectionChanged($args);
    }
    
    # Hook up change notification if item supports it
    $this->_HookItemChangeNotification($item);
  }
  
  sub RemoveAt {
    my ($this, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('index')) unless defined($index);
    
    throw(System::NotSupportedException->new('Collection is read-only'))
      unless $this->{_allowRemove};
    
    throw(System::ArgumentOutOfRangeException->new('index', 'Index was out of range'))
      if $index < 0 || $index >= $this->Count();
    
    my $item = $this->Item($index);
    
    # Unhook change notification
    $this->_UnhookItemChangeNotification($item);
    
    # Call base RemoveAt method
    $this->SUPER::RemoveAt($index);
    
    # Raise collection changed event
    if ($this->{_raiseListChangedEvents}) {
      my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove([$item], $index);
      $this->OnCollectionChanged($args);
    }
  }
  
  sub Remove {
    my ($this, $item) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    throw(System::NotSupportedException->new('Collection is read-only'))
      unless $this->{_allowRemove};
    
    my $index = $this->IndexOf($item);
    if ($index >= 0) {
      $this->RemoveAt($index);
      return true;
    }
    return false;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    throw(System::NotSupportedException->new('Collection is read-only'))
      unless $this->{_allowRemove};
    
    # Unhook all item change notifications
    if ($this->{_supportsChangeNotification}) {
      for my $i (0 .. $this->Count() - 1) {
        $this->_UnhookItemChangeNotification($this->Item($i));
      }
    }
    
    # Call base Clear method
    $this->SUPER::Clear();
    
    # Raise collection changed event
    if ($this->{_raiseListChangedEvents}) {
      my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReset();
      $this->OnCollectionChanged($args);
    }
  }
  
  # Override Item for both get and set operations
  sub Item {
    my ($this, $index, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      throw(System::NotSupportedException->new('Collection is read-only'))
        unless $this->{_allowEdit};
      
      throw(System::ArgumentOutOfRangeException->new('index', 'Index was out of range'))
        if $index < 0 || $index >= $this->Count();
      
      my $oldItem = $this->SUPER::Item($index);
      
      # Unhook old item change notification
      $this->_UnhookItemChangeNotification($oldItem);
      
      # Call base Item method (setter)
      $this->SUPER::Item($index, $value);
      
      # Hook up new item change notification
      $this->_HookItemChangeNotification($value);
      
      # Raise collection changed event
      if ($this->{_raiseListChangedEvents}) {
        my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace([$value], [$oldItem], $index);
        $this->OnCollectionChanged($args);
      }
      
      return;
    } else {
      # Getter
      return $this->SUPER::Item($index);
    }
  }

  # Event raising methods
  sub OnPropertyChanged {
    my ($this, $e) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_propertyChanged} && $this->{_propertyChanged}->HasHandlers()) {
      $this->{_propertyChanged}->Invoke($this, $e);
    }
  }
  
  sub OnPropertyChanging {
    my ($this, $e) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_propertyChanging} && $this->{_propertyChanging}->HasHandlers()) {
      $this->{_propertyChanging}->Invoke($this, $e);
    }
  }
  
  sub OnCollectionChanged {
    my ($this, $e) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_collectionChanged} && $this->{_collectionChanged}->HasHandlers()) {
      $this->{_collectionChanged}->Invoke($this, $e);
    }
  }

  # Item change notification support
  sub _HookItemChangeNotification {
    my ($this, $item) = @_;
    
    return unless $this->{_supportsChangeNotification};
    return unless defined($item);
    return unless ref($item);
    
    # Check if item implements INotifyPropertyChanged
    if ($item->can('PropertyChanged')) {
      # Create a delegate that will handle item property changes
      my $handler = sub {
        my ($sender, $e) = @_;
        $this->_OnItemPropertyChanged($sender, $e);
      };
      
      $item->PropertyChanged($handler);
    }
  }
  
  sub _UnhookItemChangeNotification {
    my ($this, $item) = @_;
    
    return unless $this->{_supportsChangeNotification};
    return unless defined($item);
    return unless ref($item);
    
    # In a full implementation, we would need to track and remove specific handlers
    # For now, we'll leave this as a stub
  }
  
  sub _OnItemPropertyChanged {
    my ($this, $item, $e) = @_;
    
    # Find the index of the changed item
    my $index = $this->IndexOf($item);
    if ($index >= 0) {
      # Raise collection changed event for item replacement
      my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace([$item], [$item], $index);
      $this->OnCollectionChanged($args);
    }
  }

  # Enable/disable change notification support
  sub EnableChangeNotification {
    my ($this, $enable) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $enable //= true;
    
    if ($this->{_supportsChangeNotification} ne $enable) {
      $this->{_supportsChangeNotification} = $enable ? true : false;
      
      if ($enable) {
        # Hook up all existing items
        for my $i (0 .. $this->Count() - 1) {
          $this->_HookItemChangeNotification($this->Item($i));
        }
      }
    }
  }

  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;