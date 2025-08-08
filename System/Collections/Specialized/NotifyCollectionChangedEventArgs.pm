package System::Collections::Specialized::NotifyCollectionChangedEventArgs; {
  use base 'System::EventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::EventArgs;
  require System::Collections::Specialized::NotifyCollectionChangedAction;
  
  # NotifyCollectionChangedEventArgs - provides data for CollectionChanged event
  sub new {
    my ($class, $action, $changedItems, $startingIndex, $oldItems, $oldStartingIndex) = @_;
    
    # Validate action
    throw(System::ArgumentNullException->new('action')) unless defined($action);
    throw(System::ArgumentException->new('action must be a valid NotifyCollectionChangedAction'))
      unless $action =~ /^(Add|Remove|Replace|Move|Reset)$/;
    
    my $this = $class->SUPER::new();
    $this->{_action} = $action;
    $this->{_newItems} = $changedItems;
    $this->{_newStartingIndex} = $startingIndex // -1;
    $this->{_oldItems} = $oldItems;
    $this->{_oldStartingIndex} = $oldStartingIndex // -1;
    
    # Validate arguments based on action
    $this->_ValidateArguments();
    
    return $this;
  }
  
  # Convenience constructors for specific actions
  sub NewAdd {
    my ($class, $changedItems, $startingIndex) = @_;
    return $class->new('Add', $changedItems, $startingIndex);
  }
  
  sub NewRemove {
    my ($class, $changedItems, $startingIndex) = @_;
    return $class->new('Remove', undef, -1, $changedItems, $startingIndex);
  }
  
  sub NewReplace {
    my ($class, $newItems, $oldItems, $startingIndex) = @_;
    return $class->new('Replace', $newItems, $startingIndex, $oldItems, $startingIndex);
  }
  
  sub NewMove {
    my ($class, $changedItems, $newIndex, $oldIndex) = @_;
    return $class->new('Move', $changedItems, $newIndex, $changedItems, $oldIndex);
  }
  
  sub NewReset {
    my ($class) = @_;
    return $class->new('Reset');
  }
  
  # Properties
  sub Action {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_action};
  }
  
  sub NewItems {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_newItems};
  }
  
  sub OldItems {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_oldItems};
  }
  
  sub NewStartingIndex {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_newStartingIndex};
  }
  
  sub OldStartingIndex {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_oldStartingIndex};
  }
  
  # Internal validation
  sub _ValidateArguments {
    my ($this) = @_;
    
    my $action = $this->{_action};
    
    if ($action eq 'Add') {
      throw(System::ArgumentException->new('changedItems cannot be null for Add action'))
        unless defined($this->{_newItems});
      throw(System::ArgumentException->new('startingIndex must be >= 0 for Add action'))
        if $this->{_newStartingIndex} < 0;
      throw(System::ArgumentException->new('oldItems must be null for Add action'))
        if defined($this->{_oldItems});
    }
    elsif ($action eq 'Remove') {
      throw(System::ArgumentException->new('oldItems cannot be null for Remove action'))
        unless defined($this->{_oldItems});
      throw(System::ArgumentException->new('oldStartingIndex must be >= 0 for Remove action'))
        if $this->{_oldStartingIndex} < 0;
      throw(System::ArgumentException->new('newItems must be null for Remove action'))
        if defined($this->{_newItems});
    }
    elsif ($action eq 'Replace') {
      throw(System::ArgumentException->new('newItems cannot be null for Replace action'))
        unless defined($this->{_newItems});
      throw(System::ArgumentException->new('oldItems cannot be null for Replace action'))
        unless defined($this->{_oldItems});
      throw(System::ArgumentException->new('startingIndex must be >= 0 for Replace action'))
        if $this->{_newStartingIndex} < 0;
      throw(System::ArgumentException->new('oldStartingIndex must equal newStartingIndex for Replace action'))
        if $this->{_oldStartingIndex} != $this->{_newStartingIndex};
    }
    elsif ($action eq 'Move') {
      throw(System::ArgumentException->new('changedItems cannot be null for Move action'))
        unless defined($this->{_newItems});
      throw(System::ArgumentException->new('newStartingIndex must be >= 0 for Move action'))
        if $this->{_newStartingIndex} < 0;
      throw(System::ArgumentException->new('oldStartingIndex must be >= 0 for Move action'))
        if $this->{_oldStartingIndex} < 0;
      throw(System::ArgumentException->new('newStartingIndex cannot equal oldStartingIndex for Move action'))
        if $this->{_newStartingIndex} == $this->{_oldStartingIndex};
    }
    elsif ($action eq 'Reset') {
      throw(System::ArgumentException->new('newItems must be null for Reset action'))
        if defined($this->{_newItems});
      throw(System::ArgumentException->new('oldItems must be null for Reset action'))
        if defined($this->{_oldItems});
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;