use strict;
use warnings;

package System::DirectoryServices::AccountManagement::UserPrincipal; {
  use base 'System::DirectoryServices::AccountManagement::AuthenticablePrincipal'; {

    use CSharp;
    use System::String;
  
    sub new {
      my $class=shift(@_);
      my(%params)=@_;
      my $this=(ref($class)||$class)->SUPER::new(%params);
      return($this);
    }

    ### <summary>
    ### Gets the given name for the user principal.
    ### </summary>
    sub GivenName($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{givenName});
      }
    }

    ### <summary>
    ### Gets the middle name for the user principal.
    ### </summary>
    sub MiddleName($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{middleName});
      }
    }

    ### <summary>
    ### Gets the surname for the user principal.
    ### </summary>
    sub Surname($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{sn});
      }
    }

    ### <summary>
    ### Gets the e-mail address for this account.
    ### </summary>
    sub EmailAddress($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{mail});
      }
    }

    ### <summary>
    ### Gets the home drive for this account.
    ### </summary>
    sub HomeDrive($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{homeDrive});
      }
    }

    ### <summary>
    ### Gets the voice telephone number for the user principal.
    ### </summary>
    sub VoiceTelephoneNumber($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{telephoneNumber});
      }
    }

    ### <summary>
    ### Gets the employee id for the user principal.
    ### </summary>
    sub EmployeeId($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{employeeID});
      }
    }

    ### <summary>
    ### Gets the full name of the user.
    ### </summary>
    sub GetFullName($) {
      my($this)=@_;
      require System::Linq;
      return(System::String::Join(" ",System::Array->new($this->GivenName,$this->MiddleName,$this->Surname)->Where(sub{my$a=$_[0];!System::String::IsNullOrWhitespace($a)})));
    }

    ### <summary>
    ### Gets a user principal object that represents the current user under which the thread is running.
    ### </summary>
    sub Current() {
      my $result=__PACKAGE__->new(_objCurrentPrincipal=>_GetADCurrentUser());
    }

    ### <summary>
    ### Find the user principal by a given identity value.
    ### </summary>
    ### <param name="context">The search context</param>
    ### <param name="identityType">The type of identity to look up</param>
    ### <param name="identityValue">The value of the identity</param>
    ### <returns>The found principal or <c>null</c></returns>
    sub FindByIdentity {
      my($context,$identityType,$identityValue)=@_;
      return(System::DirectoryServices::AccountManagement::Principal::FindByIdentityWithType($context,__PACKAGE__,$identityType,$identityValue));
    }
        
    {
      my $objADCurrentUserCache;
      ### <summary>
      ### Gets the ActiveDirectory user object for the current logged-in user.
      ### </summary>
      ### <returns>The object instance.</returns>
      sub _GetADCurrentUser() {
        return($objADCurrentUserCache) if defined($objADCurrentUserCache);
        require Win32::OLE;
        my $objAdSystemInfo=System::DirectoryServices::AccountManagement::Principal->_ADSystemInfoObject;
        return(undef) unless defined($objAdSystemInfo);
        my $userName=$objAdSystemInfo->{UserName};
        $objADCurrentUserCache=Win32::OLE->GetObject("LDAP://".$userName);
        return($objADCurrentUserCache);
      }
    }

    BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  }
}
1;