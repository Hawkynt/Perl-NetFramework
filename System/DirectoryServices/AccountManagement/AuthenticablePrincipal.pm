package System::DirectoryServices::AccountManagement::AuthenticablePrincipal; {
  use base 'System::DirectoryServices::AccountManagement::Principal'; {
    use strict;
    use warnings;
    
    sub new {
      my $class=shift(@_);
      my(%params)=@_;
      my $this=(ref($class)||$class)->SUPER::new(%params);
      return($this);      
    }
  }
}
1;
