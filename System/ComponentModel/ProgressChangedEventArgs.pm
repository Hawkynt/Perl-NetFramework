package System::ComponentModel::ProgressChangedEventArgs; {
  use base 'System::EventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # ProgressChangedEventArgs - for EAP progress reporting
  
  sub new {
    my ($class, $progressPercentage, $userState) = @_;
    throw(System::ArgumentOutOfRangeException->new('progressPercentage')) 
      if defined($progressPercentage) && ($progressPercentage < 0 || $progressPercentage > 100);
    
    return bless {
      _progressPercentage => $progressPercentage // 0,
      _userState => $userState,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Gets the asynchronous task progress percentage
  sub ProgressPercentage {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_progressPercentage};
  }
  
  # Gets the user state object
  sub UserState {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_userState};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;