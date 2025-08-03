package System::Linq::SkipWhileIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new {
    my $class=shift(@_);
    my ($enumerator,$predicate)=@_;
    bless {
      _enumerator=>$enumerator,
      _predicate=>$predicate,
      _current=>null,
      _alreadySkipped=>false,
    },ref($class)||$class;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
  }

  sub Reset($) {
    my($this)=@_;
    $this->{_alreadySkipped}=false();
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
  }

  sub MoveNext($) {
    my($this)=@_;
    my $result;
    unless($this->{_alreadySkipped}){
      $this->{_alreadySkipped}=true;
      do{
        return(false) unless($this->{_enumerator}->MoveNext());
      }while(&{$this->{_predicate}}($this->{_enumerator}->Current));
      $result=true;
    }else{
      $result=$this->{_enumerator}->MoveNext()
    }
    
    $this->{_current}=$result?$this->{_enumerator}->Current:null;
    return($result);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::SkipWhileCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$predicate)=@_;
    bless {
      _collection=>$collection,
      _predicate=>$predicate
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::SkipWhileIterator($this->{_collection}->GetEnumerator(),$this->{_predicate}));
  }
};


1;
