package System::Linq::WhereIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$predicate)=@_;
    bless {
      _enumerator=>$enumerator,
      _predicate=>$predicate,
      _current=>null
    },ref($class)||$class;
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
    while($this->{_enumerator}->MoveNext()) {
      my $current=$this->{_enumerator}->Current;
      if(&{$this->{_predicate}}($current)) {
        $this->{_current}=$current;
        return(true);
      }
    }
    $this->{_current}=null;
    return(false);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::WhereCollection; {
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
    return(new System::Linq::WhereIterator($this->{_collection}->GetEnumerator(),$this->{_predicate}));
  }
};

1;