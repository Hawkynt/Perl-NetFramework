package System::Linq::DistinctIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$) {
    my $class=shift(@_);
    my ($enumerator)=@_;
    bless {
      _enumerator=>$enumerator,
      _current=>null,
      _alreadyVisited=>{}
    },ref($class)||$class||__PACKAGE__;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
    $this->{_alreadyVisited}={};
  }

  sub MoveNext($) {
    my($this)=@_;
    while(my $result=$this->{_enumerator}->MoveNext()) {
      my $current=$this->{_enumerator}->Current;
      next if($this->{_alreadyVisited}->{$current});
      $this->{_current}=$current;
      $this->{_alreadyVisited}->{$current}=true;
      return(true);
    }
    $this->{_current}=null;
    return(false);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::DistinctCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$) {
    my $class=shift(@_);
    my ($collection)=@_;
    bless {
      _collection=>$collection,
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::DistinctIterator($this->{_collection}->GetEnumerator()));
  }
};

1;