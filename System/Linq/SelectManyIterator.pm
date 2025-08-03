package System::Linq::SelectManyIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$selector)=@_;
    bless {
      _enumerator=>$enumerator,
      _subenumerator=>null,
      _selector=>$selector,
      _current=>null,
    },ref($class)||$class||__PACKAGE__;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
    return unless(defined($this->{_subenumerator}));
    $this->{_subenumerator}->Dispose();
    $this->{_subenumerator}=null;
  }

  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
    $this->{_subenumerator}=null;
  }

  sub MoveNext($) {
    my($this)=@_;
    my $result;
    if(defined($this->{_subenumerator})) {
      $result=$this->{_subenumerator}->MoveNext();
      if($result){
        $this->{_current}=$this->{_subenumerator}->Current;
        return(true);
      }
      $this->{_subenumerator}=null;
    }
    
    $result=$this->{_enumerator}->MoveNext();
    unless($result){
      $this->{_current}=null;
      return(false());
    }
    
    my $nextCollection=defined($this->{_selector})?&{$this->{_selector}}($this->{_enumerator}->Current):$this->{_enumerator}->Current;
    $this->{_subenumerator}=$nextCollection->GetEnumerator();
    return($this->MoveNext());
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::SelectManyCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$selector)=@_;
    bless {
      _collection=>$collection,
      _selector=>$selector
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::SelectManyIterator($this->{_collection}->GetEnumerator(),$this->{_selector}));
  }
};


1;