package System::Linq::SelectIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use CSharp;

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$selector)=@_;
    bless {
      _enumerator=>$enumerator,
      _selector=>$selector,
      _current=>null,
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
  }

  sub MoveNext($) {
    my($this)=@_;
    my $result=$this->{_enumerator}->MoveNext();
    $this->{_current}=$result?&{$this->{_selector}}($this->{_enumerator}->Current):null;
    return($result);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::SelectCollection; {
  use System::Collections::IEnumerable;
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$selector)=@_;
    bless {
      _collection=>$collection,
      _selector=>$selector
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::SelectIterator($this->{_collection}->GetEnumerator(),$this->{_selector}));
  }
};


1;