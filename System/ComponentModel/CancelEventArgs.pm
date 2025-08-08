package System::ComponentModel::CancelEventArgs; {
  use base 'System::EventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::EventArgs;
  
  # CancelEventArgs - provides data for cancelable events
  sub new {
    my ($class, $cancel) = @_;
    $cancel //= false;
    
    # Validate cancel parameter
    throw(System::ArgumentException->new('cancel must be a boolean value'))
      if defined($cancel) && $cancel ne '0' && $cancel ne '1' && $cancel ne 'true' && $cancel ne 'false';
    
    my $this = $class->SUPER::new();
    $this->{_cancel} = $cancel ? true : false;
    
    return $this;
  }
  
  # Properties
  sub Cancel {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      throw(System::ArgumentException->new('value must be a boolean'))
        if $value ne '0' && $value ne '1' && $value ne 'true' && $value ne 'false';
      
      $this->{_cancel} = $value ? true : false;
      return;
    }
    
    # Getter
    return $this->{_cancel};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;