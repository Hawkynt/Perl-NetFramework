package System::Linq::GroupByIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;
  require System::Object;
  require System::Linq::WhereIterator;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$selector)=@_;
    bless {
      _collection=>$collection,
      _enumerator=>$collection->GetEnumerator(),
      _selector=>$selector,
      _current=>null,
      _alreadyVisited=>{}
    },ref($class)||$class||__PACKAGE__;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_collection}=null;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
    $this->{_alreadyVisited}=null;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
    $this->{_alreadyVisited}={};
  }

  sub MoveNext($) {
    my($this)=@_;
    my $selector=$this->{_selector};
    while(my $result=$this->{_enumerator}->MoveNext()) {
      my $current=$this->{_enumerator}->Current;
      $current=&{$selector}($current)if(defined($selector));
      next if($this->{_alreadyVisited}->{$current});
      $this->{_current}=System::Linq::GroupByEntry->new(System::Linq::WhereCollection->new($this->{_collection},defined($selector)?sub{System::Object::Equals(&{$selector}($_[0]),$current,true);}:sub{System::Object::Equals($_[0],$current,true);}),$current);
      $this->{_alreadyVisited}->{$current}=true;
      return(true);
    }
    $this->{_current}=null;
    return(false);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::GroupByEntry;{
  use base 'System::Object','System::Collections::IEnumerable';
  
  use strict;
  use warnings;
  
  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$key)=@_;
    bless {
      _collection=>$collection,
      _key=>$key,
    },ref($class)||$class||__PACKAGE__;
  }

  sub Key($){
    my($this)=@_;
    return($this->{_key});
  }
  
  sub GetEnumerator($) {
    my($this)=@_;
    return($this->{_collection}->GetEnumerator());
  }
};

package System::Linq::GroupByCollection; {
  use base 'System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection,$selector)=@_;
    bless {
      _collection=>$collection,
      _selector=>$selector,
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::GroupByIterator($this->{_collection},$this->{_selector}));
  }
};

1;