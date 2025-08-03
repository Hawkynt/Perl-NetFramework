package System::Collections::IEnumerable; {
  use strict;
  use warnings;

  use CSharp;
  
  use overload fallback => 1;

  # this allows to use enumerations like native perl arrays
  use overload '@{}' => sub {
    my($this)=@_;
    return $this if($this->isa("System::Array"));
    my @result=();
    my $enumerator=$this->GetEnumerator();
    while($enumerator->MoveNext()) {
      push @result,$enumerator->Current();
    }
    $enumerator->Dispose();
    return(\@result);
  };

  sub GetEnumerator($) {throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;