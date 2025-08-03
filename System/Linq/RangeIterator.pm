package System::Linq::RangeIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use CSharp;

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($start,$count)=@_;
    bless {
      _start=>$start,
      _count=>$count,
      _current=>null,
    },ref($class)||$class||__PACKAGE__;
  }

  sub Dispose($){
    my($this)=@_;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_current}=null;
  }

  sub MoveNext($) {
    my($this)=@_;
    if(defined($this->{_current})){
      ++$this->{_current};
    }else{
      $this->{_current}=$this->{_start};
    }
    return(($this->{_current}-$this->{_start})<$this->{_count});
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::RangeCollection; {
  use System::Collections::IEnumerable;
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($start,$count)=@_;
    bless {
      _start=>$start,
      _count=>$count
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::RangeIterator($this->{_start},$this->{_count}));
  }
};


1;