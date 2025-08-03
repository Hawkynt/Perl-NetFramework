package System::Linq::DefaultIfEmptyIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$defaultValue)=@_;
    bless {
      _enumerator=>$enumerator,
      _defaultValue=>$defaultValue,
      _isFirstRun=>true,
      _useEnumerator=>true,
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
    $this->{_isFirstRun}=true;
    $this->{_useEnumerator}=true;
  }

  sub MoveNext($) {
    my($this)=@_;
    if($this->{_isFirstRun}) {
      $this->{_isFirstRun}=false;
      my $result=$this->{_enumerator}->MoveNext();
      if($result){
        $this->{_useEnumerator}=true;
        $this->{_current}=$this->{_enumerator}->Current;
      } else {
        $this->{_useEnumerator}=false;
        $this->{_current}=$this->{_defaultValue};
      }
      return(true);
    } else {
      if($this->{'_useEnumerator'}){
        my $result=$this->{_enumerator}->MoveNext();
        $this->{_current}=$result?$this->{_enumerator}->Current:null;
        return($result);
      }
      return(false);
    }
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }

};

package System::Linq::DefaultIfEmptyCollection; {
  use base 'System::Object','System::Collections::IEnumerable';
  
  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$defaultValue)=@_;
    bless {
      _collection=>$collection,
      _defaultValue=>$defaultValue,
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::DefaultIfEmptyIterator($this->{_collection}->GetEnumerator(),$this->{_defaultValue}));
  }
};

1;