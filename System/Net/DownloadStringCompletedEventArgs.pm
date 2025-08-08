package System::Net::DownloadStringCompletedEventArgs; {
  use base 'System::ComponentModel::AsyncCompletedEventArgs';
  
  use strict;
  use warnings;
  use CSharp;
  
  # DownloadStringCompletedEventArgs - completion event args for EAP DownloadStringAsync
  
  sub new {
    my ($class, $result, $exception, $cancelled, $userState) = @_;
    my $this = $class->SUPER::new($exception, $cancelled, $userState);
    $this->{_result} = $result;
    return $this;
  }
  
  sub Result {
    my ($this) = @_;
    $this->RaiseExceptionIfNecessary();
    return $this->{_result};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;