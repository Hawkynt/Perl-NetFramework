use strict;
use warnings;
use Win32::OLE;

package System::DirectoryServices::AccountManagement::Principal; {
  use base "System::Object";{
    use CSharp;
  
    sub new {
      my $class=shift(@_);
      my(%params)=@_;
      my $this={
        _objCurrentPrincipal=>null
      };
      
      if(%params) {
        foreach my $k(keys(%params)) {
          $this->{$k}=$params{$k};
        }
      }
      
      return(bless $this,ref($class)||$class);
    }

    ### <summary>
    ### Gets the display name for this principal.
    ### </summary>
    sub DisplayName($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{displayName});
      }
    }

    ### <summary>
    ### Gets the description of the principal.
    ### </summary>
    sub Description($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{description});
      }
    }

    ### <summary>
    ### Gets the SAM account name for this principal.
    ### </summary>
    sub SamAccountName($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{samAccountName});
      }
    }

    ### <summary>
    ### Gets the name of this principal.
    ### </summary>
    sub Name($) {
      my($this)=@_; {
        # trim leading CN= from result
        return(substr($this->{_objCurrentPrincipal}->{Name},3));
      }
    }

    ### <summary>
    ### Gets the user principal name (UPN) associated with this principal.
    ### </summary>
    sub UserPrincipalName($) {
      my($this)=@_; {
        return($this->{_objCurrentPrincipal}->{userPrincipalName});
      }
    }
    
    ### <summary>
    ### Gets the groups this principal belongs to.
    ### </summary>
    ### <returns>An array of GroupPrincipals</returns>
    sub GetGroups($) {
      my($this)=@_;
      my @result=();
      foreach my $item (Win32::OLE::in($this->{_objCurrentPrincipal}->{memberOf})) {
        push(@result,new GroupPrincipal(_objCurrentPrincipal=>_GetObject($item)));
      }
      return(new System::Array(@result));
    }
    
    ### <summary>
    ### Find the principal by a given identity value.
    ### </summary>
    ### <param name="context">The search context</param>
    ### <param name="principalType">The type of principal to find</param>
    ### <param name="identityType">The type of identity to look up</param>
    ### <param name="identityValue">The value of the identity</param>
    ### <returns>The found principal or <c>null</c></returns>
    sub FindByIdentityWithType($$$$) {
      my ($context,$principalType,$identityType,$identityValue)=@_;
      
      # first construct the needed ldap filter
      my $filter;
      $filter="(sAMAccountName=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::SamAccountName());
      $filter="(name=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::Name());
      $filter="(userPrincipalName=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName());
      $filter="(distinguishedName=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName());
      $filter="(objectSid=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::Sid());
      $filter="(objectGUID=$identityValue)" if($identityType==System::DirectoryServices::AccountManagement::IdentityType::Guid());
      
      # find ad host and default naming context
      my $adHostName=__PACKAGE__->_FirstDomainController;
      my $namingContext=__PACKAGE__->_DefaultNamingContext;
      
      # construct query
      my $query="<LDAP://$adHostName/$namingContext>;$filter;DistinguishedName;subtree";
      #print "ADSI Query: $query\n";
      
      my $ado=Win32::OLE->CreateObject("ADODB.Connection");
      $ado->{Provider}="ADSDSOObject";
      $ado->Open("ADSearch");
      my $rows=$ado->Execute("$query");
      if(defined($rows) && !($rows->EOF)) {
        my $path=$rows->Fields("DistinguishedName")->{value};
        #print "ADObject Found:$path\n";
        my $result=_GetObject($path);
        return(new($principalType,_objCurrentPrincipal=>$result));
      }
      return(null);
    }
    
    sub _GetObject($) {
      my($ldapPath)=@_;
      return(Win32::OLE->GetObject("LDAP://$ldapPath"));
    }
    
    {
      my $cache;
      
      ### <summary>
      ### Gets the first active and trusted domain controller in the current adsi forest.
      ### </summary>
      ### <returns>The dns host name or <c>null</c>.</returns>
      sub _FirstDomainController() {
        {
          return($cache) if defined($cache);
          my $adsi=__PACKAGE__->_ADSystemInfoObject;
          my $forest=$adsi->{ForestDNSName};
          my $LDAP_MATCHING_RULE_BIT_AND="1.2.840.113556.1.4.803";
          my $SERVER_TRUST_ACCOUNT=8192;
          my $ldapFilter = "(&(objectCategory=computer)(userAccountControl:$LDAP_MATCHING_RULE_BIT_AND:=$SERVER_TRUST_ACCOUNT))";
          
          my $ado=Win32::OLE->CreateObject("ADODB.Connection");
          $ado->{Provider}="ADSDSOObject";
          $ado->Open("ADSearch");
          my $rows=$ado->Execute("<GC://$forest>;$ldapFilter;dnsHostName;subtree");
          if(!($rows->EOF)) {
            $cache=$rows->Fields("dnsHostName")->{value};
            return($cache);
          }
          return(null);
        }
      }
    };
    
    {
      my $cache;
      
      ### <summary>
      ### Gets the default naming context of the current domain
      ### </summary>
      ### <returns>The default naming context eg. DC=JHCN,DC=NET</returns>
      sub _DefaultNamingContext() {
        {
          return($cache) if defined($cache);
          my $adsi=__PACKAGE__->_ADSystemInfoObject;
          my $name=$adsi->{UserName};
          my $index=index(lc($name),",dc=");
          my $result=substr($name,$index+1);
          $cache=$result;
          return($cache);
        }
      }
    };
    
    {
      my $cache;
      ### <summary>
      ### Gets the ActiveDirectory system info object.
      ### </summary>
      ### <returns>The object instance.</returns>
      sub _ADSystemInfoObject($) {
        my($this)=@_; {
          return($cache) if defined($cache);
          $cache=Win32::OLE->new('ADSystemInfo');
          return($cache);
        }
      }
    };
    
    BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  }
}
1;