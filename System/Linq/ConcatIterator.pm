package System::Linq::ConcatIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$enumerator2)=@_;
    bless {
      _enumerator=>$enumerator,
      _enumerator2=>$enumerator2,
      _current=>null,
      _isSecond=>false
    },ref($class)||$class||__PACKAGE__;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator2}->Dispose();
    $this->{_enumerator}=null;
    $this->{_enumerator2}=null;
  }

  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator}->Reset();
    $this->{_enumerator2}->Reset();
    $this->{_current}=null;
    $this->{_isSecond}=false;
  }

  sub MoveNext($) {
    my($this)=@_;
    if($this->{_isSecond}) {
      my $result=$this->{_enumerator2}->MoveNext();
      $this->{_current}=$result?$this->{_enumerator2}->Current:null;
      return($result);
    } else {
      my $result=$this->{_enumerator}->MoveNext();
      if($result) {
        $this->{_current}=$this->{_enumerator}->Current;
        return($result);
      }
      $this->{_isSecond}=true;
      return($this->MoveNext());
    }
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }

};
  
package System::Linq::ConcatCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$collection2)=@_;
    bless {
      _collection=>$collection,
      _collection2=>$collection2,
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::ConcatIterator($this->{_collection}->GetEnumerator(),$this->{_collection2}->GetEnumerator()));
  }
};

1;