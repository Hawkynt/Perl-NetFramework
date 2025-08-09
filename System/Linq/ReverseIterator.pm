package System::Linq::ReverseIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator)=@_;
    
    # For reverse, we need to materialize the collection first
    my @items = ();
    while ($enumerator->MoveNext()) {
      push @items, $enumerator->Current;
    }
    $enumerator->Dispose();
    
    bless {
      _items => \@items,
      _index => scalar(@items), # Start at end
      _current => null
    }, ref($class)||$class;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_items} = [];
    $this->{_index} = 0;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_index} = scalar(@{$this->{_items}});
    $this->{_current} = null;
  }

  sub MoveNext($) {
    my($this)=@_;
    if ($this->{_index} > 0) {
      $this->{_index}--;
      $this->{_current} = $this->{_items}->[$this->{_index}];
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
  
package System::Linq::ReverseCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection)=@_;
    bless {
      _collection=>$collection
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::ReverseIterator($this->{_collection}->GetEnumerator()));
  }
};

1;