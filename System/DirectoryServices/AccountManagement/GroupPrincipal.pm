use strict;
use warnings;
use Win32::OLE;
package System::DirectoryServices::AccountManagement::GroupPrincipal; {
  use base 'System::DirectoryServices::AccountManagement::AuthenticablePrincipal'; {

    use CSharp;
    use System::Array;
  
    sub new {
      my $class=shift(@_);
      my(%params)=@_;
      my $this=(ref($class)||$class)->SUPER::new(%params);
      return($this);
    }

    ### <summary>
    ### Gets the members of this group.
    ### </summary>
    ### <returns>A list of UserPrincipals.</returns>
    sub Members($) {
      my($this)=@_; {
        my @result=();
        foreach my $item (Win32::OLE::in($this->{_objCurrentPrincipal}->{members})) {
          push(@result,new UserPrincipal(_objCurrentPrincipal=>$item));
        }
        return(new System::Array(@result));
      }
    }
    
    ### <summary>
    ### Find the group principal by a given identity value.
    ### </summary>
    ### <param name="context">The search context</param>
    ### <param name="identityType">The type of identity to look up</param>
    ### <param name="identityValue">The value of the identity</param>
    ### <returns>The found principal or <c>null</c></returns>
    sub FindByIdentity {
      my($context,$identityType,$identityValue)=@_;
      return(System::DirectoryServices::AccountManagement::Principal::FindByIdentityWithType($context,__PACKAGE__,$identityType,$identityValue));
    }
  
    BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
  }
}
1;