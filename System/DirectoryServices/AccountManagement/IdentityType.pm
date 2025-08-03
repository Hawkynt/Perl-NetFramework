use strict;
use warnings;

package System::DirectoryServices::AccountManagement::IdentityType; {
  use constant {
    SamAccountName=>0,
    Name=>1,
    UserPrincipalName=>2,
    DistinguishedName=>3,
    Sid=>4,
    Guid=>5
  };
  use CSharp;
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;