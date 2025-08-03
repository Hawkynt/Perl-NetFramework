package System::Linq::TakeIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$count)=@_;
    bless {
      _enumerator=>$enumerator,
      _count=>$count,
      _index=>$count,
      _current=>null,
    },ref($class)||$class;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_index}=$this->{_count};
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
  }

  sub MoveNext($) {
    my($this)=@_;
    return(false) if($this->{_index}<1);
    $this->{_index}--;
    
    my $result=$this->{_enumerator}->MoveNext();
    $this->{_current}=$result?$this->{_enumerator}->Current:null;
    return($result);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::TakeCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$count)=@_;
    bless {
      _collection=>$collection,
      _count=>$count
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::TakeIterator($this->{_collection}->GetEnumerator(),$this->{_count}));
  }
};


1;
