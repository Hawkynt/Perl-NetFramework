use strict;
use warnings;

package System::DirectoryServices::AccountManagement::PrincipalContext; {
  use base "System::Object"; {
    use CSharp;
    
    sub new {
      my $class=shift(@_);
      my($contextType,%params)=@_;
      my $this={
        _contextType=>$contextType
      };
      
      if(%params) {
        foreach my $k(keys(%params)) {
          $this->{$k}=$params{$k};
        }
      }
      
      return(bless $this,ref($class)||$class);
    }
    
    sub ContextType($) {
      my($this)=@_; {
        return($this->{_contextType});
      }
    }
    
    BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  }
}
1;