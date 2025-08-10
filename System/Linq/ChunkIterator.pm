package System::Linq::ChunkIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator, $size)=@_;
    bless {
      _enumerator=>$enumerator,
      _size=>$size,
      _current=>null,
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
    $this->{_finished}=false;
  }

  sub MoveNext($) {
    my($this)=@_;
    return false if $this->{_finished};
    
    my @chunk;
    my $count = 0;
    
    while($count < $this->{_size} && $this->{_enumerator}->MoveNext()) {
      push @chunk, $this->{_enumerator}->Current;
      $count++;
    }
    
    if ($count == 0) {
      $this->{_finished} = true;
      $this->{_current} = null;
      return false;
    }
    
    require System::Array;
    $this->{_current} = System::Array->new(@chunk);
    return true;
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};

package System::Linq::ChunkCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  sub new($$$) {
    my $class=shift(@_);
    my ($collection, $size)=@_;
    bless {
      _collection=>$collection,
      _size=>$size
    },ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::ChunkIterator($this->{_collection}->GetEnumerator(), $this->{_size}));
  }
};

1;