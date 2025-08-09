package System::Linq::ZipIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$$) {
    my $class=shift(@_);
    my ($enumerator1, $enumerator2, $resultSelector)=@_;
    bless {
      _enumerator1 => $enumerator1,
      _enumerator2 => $enumerator2,
      _resultSelector => $resultSelector,
      _current => null
    },ref($class)||$class;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator1}->Dispose() if defined($this->{_enumerator1});
    $this->{_enumerator2}->Dispose() if defined($this->{_enumerator2});
    $this->{_enumerator1} = null;
    $this->{_enumerator2} = null;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator1}->Reset();
    $this->{_enumerator2}->Reset();
    $this->{_current} = null;
  }

  sub MoveNext($) {
    my($this)=@_;
    # Both enumerators must have next elements
    if ($this->{_enumerator1}->MoveNext() && $this->{_enumerator2}->MoveNext()) {
      my $item1 = $this->{_enumerator1}->Current;
      my $item2 = $this->{_enumerator2}->Current;
      $this->{_current} = &{$this->{_resultSelector}}($item1, $item2);
      return true;
    }
    $this->{_current} = null;
    return false;
  }

  sub Current($) {
    my($this)=@_;
    return $this->{_current};
  }
};
  
package System::Linq::ZipCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$$) {
    my $class=shift(@_);
    my ($collection1, $collection2, $resultSelector)=@_;
    bless {
      _collection1 => $collection1,
      _collection2 => $collection2,
      _resultSelector => $resultSelector
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::ZipIterator(
      $this->{_collection1}->GetEnumerator(),
      $this->{_collection2}->GetEnumerator(),
      $this->{_resultSelector}
    ));
  }
};

1;