package System::Event; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Delegate;
  use Scalar::Util qw(refaddr);
  
  # Event - manages event handlers with add/remove functionality
  sub new {
    my ($class) = @_;
    
    return bless {
      _handlers => {},  # Hash of handler_id => delegate
      _delegate => undef, # Combined multicast delegate
      _nextId => 1,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Event subscription using pointer mechanism
  # Positive pointer = add, negative pointer = remove  
  sub Subscribe {
    my ($this, $handler_ref) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('handler')) unless defined($handler_ref);
    
    # Check if it's a removal (negative reference)
    my $handler_id = $$handler_ref;
    
    if (defined($handler_id) && $handler_id < 0) {
      # Remove handler
      return $this->RemoveHandler(abs($handler_id));
    } else {
      # Add new handler - handler_ref should be a delegate or code reference
      throw(System::ArgumentException->new('handler must be a Delegate or CODE reference'))
        unless (ref($handler_ref) eq 'CODE') || 
               (ref($handler_ref) && $handler_ref->isa('System::Delegate'));
      
      return $this->AddHandler($handler_ref);
    }
  }
  
  # .NET-compatible Add/Remove methods
  sub AddHandler {
    my ($this, $handler) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('handler')) unless defined($handler);
    
    # Convert CODE reference to Delegate
    if (ref($handler) eq 'CODE') {
      $handler = System::Delegate->new(undef, $handler);
    }
    
    throw(System::ArgumentException->new('handler must be a Delegate'))
      unless $handler->isa('System::Delegate');
    
    # Assign unique ID
    my $handler_id = $this->{_nextId}++;
    $this->{_handlers}->{$handler_id} = $handler;
    
    # Rebuild multicast delegate
    $this->_RebuildDelegate();
    
    return $handler_id;
  }
  
  sub RemoveHandler {
    my ($this, $handler_or_id) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('handler_or_id')) unless defined($handler_or_id);
    
    my $removed = false;
    
    if (!ref($handler_or_id) && $handler_or_id =~ /^\d+$/) {
      # Remove by ID
      if (exists($this->{_handlers}->{$handler_or_id})) {
        delete $this->{_handlers}->{$handler_or_id};
        $removed = true;
      }
    } else {
      # Remove by delegate reference
      throw(System::ArgumentException->new('handler must be a Delegate'))
        unless $handler_or_id->isa('System::Delegate');
      
      # Find and remove matching delegate
      for my $id (keys %{$this->{_handlers}}) {
        if ($this->{_handlers}->{$id}->Equals($handler_or_id)) {
          delete $this->{_handlers}->{$id};
          $removed = true;
          last; # Remove only first match
        }
      }
    }
    
    if ($removed) {
      $this->_RebuildDelegate();
    }
    
    return $removed;
  }
  
  # Invoke all event handlers
  sub Invoke {
    my ($this, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return unless defined($this->{_delegate});
    return $this->{_delegate}->Invoke(@args);
  }
  
  # Operator overloading for += and -= syntax
  sub Add {
    my ($this, $handler) = @_;
    return $this->AddHandler($handler);
  }
  
  sub Remove {
    my ($this, $handler) = @_;
    return $this->RemoveHandler($handler);
  }
  
  # Properties
  sub HasHandlers {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return scalar(keys %{$this->{_handlers}}) > 0;
  }
  
  sub HandlerCount {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return scalar(keys %{$this->{_handlers}});
  }
  
  sub GetHandlerIds {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return [sort { $a <=> $b } keys %{$this->{_handlers}}];
  }
  
  # Clear all handlers
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_handlers} = {};
    $this->{_delegate} = undef;
  }
  
  # Internal methods
  sub _RebuildDelegate {
    my ($this) = @_;
    
    my @handlers = values %{$this->{_handlers}};
    
    if (@handlers == 0) {
      $this->{_delegate} = undef;
    } elsif (@handlers == 1) {
      $this->{_delegate} = $handlers[0];
    } else {
      # Combine all delegates
      my $combined = $handlers[0];
      for my $i (1..$#handlers) {
        $combined = System::Delegate->Combine($combined, $handlers[$i]);
      }
      $this->{_delegate} = $combined;
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;