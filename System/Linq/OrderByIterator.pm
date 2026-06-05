package System::Linq::OrderByIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator,$criteria)=@_;

    my $this=bless {
      _enumerator=>$enumerator,
      _criteria=>$criteria,
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
    my $criteria=$this->{_criteria};
    my @items;
    $enumerator->Reset();
    while($enumerator->MoveNext()) {
      push(@items,$enumerator->Current);
    }

    # Precompute all keys for every criterion so the selectors only run once per
    # item. Each entry is [item, key0, key1, ...] following criterion order.
    my @decorated=map {
      my $item=$_;
      my @row=($item);
      foreach my $criterion (@{$criteria}) {
        push(@row,&{$criterion->[0]}($item));
      }
      \@row;
    } @items;

    # Stable multi-key sort: Perl's sort has been stable since 5.8, so equal
    # rows keep their original relative order. We still tie-break across all
    # criteria explicitly so each ThenBy/ThenByDescending level is honoured.
    @decorated=sort {
      my $result=0;
      my $index=1;
      foreach my $criterion (@{$criteria}) {
        my $descending=$criterion->[1];
        my $cmp=CSharp::_compare($a->[$index],$b->[$index]);
        $cmp=-$cmp if($descending);
        if($cmp!=0) {
          $result=$cmp;
          last;
        }
        ++$index;
      }
      $result;
    } @decorated;

    my @sorted=map {$_->[0]} @decorated;
    $this->{_data}=\@sorted;
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

  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;

  # An ordered enumerable mirroring .NET's IOrderedEnumerable<T>.
  # Holds the underlying collection plus an ordered list of sort criteria,
  # each criterion being [keySelector, descending]. OrderBy/OrderByDescending
  # create one with a single criterion; ThenBy/ThenByDescending append a
  # further criterion of lower precedence.
  sub new($$$$) {
    my $class=shift(@_);
    my ($collection,$descending,$selector)=@_;
    $selector=sub{return($_[0]);} unless defined($selector);
    bless {
      _collection=>$collection,
      _criteria=>[[$selector,$descending]],
    },ref($class)||$class;
  }

  sub _Append($$$) {
    my($this,$descending,$selector)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    $selector=sub{return($_[0]);} unless defined($selector);
    my @criteria=(@{$this->{_criteria}},[$selector,$descending]);
    my $result=bless {
      _collection=>$this->{_collection},
      _criteria=>\@criteria,
    },ref($this);
    return($result);
  }

  sub ThenBy($;&) {
    my($this,$selector)=@_;
    return($this->_Append(0,$selector));
  }

  sub ThenByDescending($;&) {
    my($this,$selector)=@_;
    return($this->_Append(1,$selector));
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::OrderByIterator($this->{_collection}->GetEnumerator(),$this->{_criteria}));
  }
};

1;
