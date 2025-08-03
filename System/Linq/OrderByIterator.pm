package System::Linq::OrderByIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$$) {
    my $class=shift(@_);
    my ($enumerator,$descending,$selector)=@_;
    $selector=sub{return($_[0]);} unless defined($selector);
      
    my $this=bless {
      _enumerator=>$enumerator,
      _descending=>$descending,
      _selector=>$selector,
      _current=>undef,
      _data=>undef,
    },ref($class)||$class;
    
    $this->Reset();
    
    return($this);
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
  }

  sub Reset($) {
    my($this)=@_;
    my $enumerator=$this->{_enumerator};
    my $descending=$this->{_descending};
    my $selector=$this->{_selector};
    my @items;
    $enumerator->Reset();
    while($enumerator->MoveNext()) {
      push(@items,$enumerator->Current);
    }
    if($descending){
      @items=map {$_->[1]} sort { -CSharp::_compare($a->[0],$b->[0]) } map { [&{$selector}($_),$_] } @items;
    }else{
      @items=map {$_->[1]} sort { CSharp::_compare($a->[0],$b->[0]) } map { [&{$selector}($_),$_] } @items;
    }
    $this->{_data}=\@items;
    $this->{_current}=undef;
  }

  sub MoveNext($) {
    my($this)=@_;
    my @items=@{$this->{_data}};
    if(@items) {
      $this->{_current}=shift(@items);
      $this->{_data}=\@items;
      return true;
    }
    $this->{_current}=undef;
    return false;
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::OrderByCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$$) {
    my $class=shift(@_);
    my ($collection,$descending,$selector)=@_;
    bless {
      _collection=>$collection,
      _selector=>$selector,
      _descending=>$descending,
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::OrderByIterator($this->{_collection}->GetEnumerator(),$this->{_descending},$this->{_selector}));
  }
};

1;
