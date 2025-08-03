package System::Collections::IEnumerator; {
  use base "System::IDisposable";
  
  use strict;
  use warnings;
  
  use CSharp;

  sub Reset($) {throw NotImplementedException->new()}
  sub MoveNext($) {throw NotImplementedException->new()}
  sub Current($) {throw NotImplementedException->new()}

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;