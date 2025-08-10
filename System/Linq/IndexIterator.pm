package System::Linq::IndexIterator; {
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
      _index=>-1
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
    $this->{_index}=-1;
  }

  sub MoveNext($) {
    my($this)=@_;
    if($this->{_enumerator}->MoveNext()) {
      $this->{_index}++;
      $this->{_current} = {
        Index => $this->{_index},
        Item => $this->{_enumerator}->Current
      };
      return true;
    }
    $this->{_current}=null;
    return false;
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::IndexCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$) {
    my $class=shift(@_);
    my ($collection)=@_;
    bless {
      _collection=>$collection
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::IndexIterator($this->{_collection}->GetEnumerator()));
  }
};

1;