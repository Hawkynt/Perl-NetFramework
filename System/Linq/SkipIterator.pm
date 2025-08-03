package System::Linq::SkipIterator; {
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
      _current=>null,
      _alreadySkipped=>false(),
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
      $this->{_alreadySkipped}=true();
      for(my $i=$this->{_count};$i>=0;--$i) {
        return(false()) unless($this->{_enumerator}->MoveNext());
      }
      $result=true();
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

package System::Linq::SkipCollection; {
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
    return(new System::Linq::SkipIterator($this->{_collection}->GetEnumerator(),$this->{_count}));
  }
};


1;