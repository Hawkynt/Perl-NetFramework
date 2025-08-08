package System::ComponentModel::PropertyChangedEventArgs; {
  use base 'System::EventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::EventArgs;
  
  # PropertyChangedEventArgs - provides data for PropertyChanged event
  sub new {
    my ($class, $propertyName) = @_;
    
    # PropertyName can be null/undef (indicates all properties changed)
    # but if provided, must be a string
    if (defined($propertyName)) {
      throw(System::ArgumentException->new('propertyName must be a string'))
        if ref($propertyName) && !$propertyName->isa('System::String');
    }
    
    my $this = $class->SUPER::new();
    $this->{_propertyName} = $propertyName;
    
    return $this;
  }
  
  # Properties
  sub PropertyName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_propertyName};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;