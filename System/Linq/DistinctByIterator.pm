package System::Linq::DistinctByIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator, $keySelector)=@_;
    bless {
      _enumerator=>$enumerator,
      _keySelector=>$keySelector,
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
      my $key = &{$this->{_keySelector}}($current);
      my $keyStr = defined($key) ? "$key" : "";
      next if($this->{_alreadyVisited}->{$keyStr});
      $this->{_current}=$current;
      $this->{_alreadyVisited}->{$keyStr}=true;
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

package System::Linq::DistinctByCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection, $keySelector)=@_;
    bless {
      _collection=>$collection,
      _keySelector=>$keySelector
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::DistinctByIterator($this->{_collection}->GetEnumerator(), $this->{_keySelector}));
  }
};

1;