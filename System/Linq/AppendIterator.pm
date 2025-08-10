package System::Linq::AppendIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator, $element)=@_;
    bless {
      _enumerator=>$enumerator,
      _element=>$element,
      _current=>null,
      _appended=>false,
      _finished=>false
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
    $this->{_appended}=false;
    $this->{_finished}=false;
  }

  sub MoveNext($) {
    my($this)=@_;
    return false if $this->{_finished};
    
    if($this->{_enumerator}->MoveNext()) {
      $this->{_current} = $this->{_enumerator}->Current;
      return true;
    }
    
    if(!$this->{_appended}) {
      $this->{_current} = $this->{_element};
      $this->{_appended} = true;
      return true;
    }
    
    $this->{_finished} = true;
    $this->{_current} = null;
    return false;
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::AppendCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection, $element)=@_;
    bless {
      _collection=>$collection,
      _element=>$element
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::AppendIterator($this->{_collection}->GetEnumerator(), $this->{_element}));
  }
};

1;