package System::String; {
  use base "System::Object";
  
  use strict;
  use warnings;
  
  use CSharp;
  use System::Exceptions;

  use System::StringComparison;
  use System::StringSplitOptions;
  use System::StringComparer;  
  require System::Linq;
  use overload 
    '""'=>\&ToString,
    '+'=>\&Concat,
    'cmp'=>\&_Compare
    ;

  use constant Empty=>"";
    
  #region instance methods
  sub new {
    my($class)=shift(@_);
    my($text)=@_;
    throw(System::ArgumentException->new('text')) if(ref($text) && !$text->can('ToString'));
    bless {
      _data=>CSharp::_ToString($text)
    },ref($class)||$class||__PACKAGE__;
  }

  sub _GetComparerForComparison($){
    my($comparison)=@_;
    return(StringComparer::CurrentCulture) if($comparison==StringComparison::CurrentCulture);
    return(StringComparer::CurrentCultureIgnoreCase) if($comparison==StringComparison::CurrentCultureIgnoreCase);
    return(StringComparer::InvariantCulture) if($comparison==StringComparison::InvariantCulture);
    return(StringComparer::InvariantCultureIgnoreCase) if($comparison==StringComparison::InvariantCultureIgnoreCase);
    return(StringComparer::Ordinal) if($comparison==StringComparison::Ordinal);
    return(StringComparer::OrdinalIgnoreCase) if($comparison==StringComparison::OrdinalIgnoreCase);
    return(null);
  }
  
  sub _Compare($$) {
    my($this,$other)=@_;
    return(defined($other)?$this->{_data} cmp CSharp::_ToString($other):-1);
  }

  sub ToString($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(defined($this->{_data})?$this->{_data}:Empty);
  }

  sub GetHashCode($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $hash1=5381<<16;
    my $hash2=5381;
    my $data=$this->{_data};
    for(my $i=0;$i<length($data);++$i){
      my $char=substr($data,$i,1);
      my $value=ord($char);
      if($i&1){
        $hash2=(($hash2<<5)|($hash2>>27)^$value);
      }else {
        $hash1=(($hash1<<5)|($hash1>>27)^$value);
      }
    }
    my $result=($hash1^($hash2^1566083941));
    return($result);
  }
  
  sub Length($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(length($this->{_data}));  
  }

  sub Concat($$;$) {
    my($this,$other,$isSwapped)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $otherText=CSharp::_ToString($other);
    return(System::String->new($isSwapped?$otherText.$this->{_data}:$this->{_data}.$otherText));
  }

  sub Contains($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    my $otherText=CSharp::_ToString($what);
    return(index($this->{_data},$otherText)>=0);
  }

  sub IndexOf($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    my $otherText=CSharp::_ToString($what);
    return(index($this->{_data},$otherText));
  }

  sub LastIndexOf($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    my $otherText=CSharp::_ToString($what);
    return(rindex($this->{_data},$otherText));
  }

  sub Equals($$;$) {
    my($this,$what,$comparison)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    $comparison=StringComparison::CurrentCulture unless(defined($comparison));
    my $comparer=_GetComparerForComparison($comparison);
    throw(System::NullReferenceException->new()) unless(defined($comparer));
    return($comparer->Equals($this,$what));
  }

  sub EndsWith($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    my $otherText=CSharp::_ToString($what);
    my $data=$this->{_data};
    my $otherLen=length($otherText);
    my $dataLen=length($data);
    return($dataLen>=$otherLen && substr($data,$dataLen-$otherLen,$otherLen) eq $otherText);
  }

  sub StartsWith($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    my $otherText=CSharp::_ToString($what);
    my $data=$this->{_data};
    my $otherLen=length($otherText);
    my $dataLen=length($data);
    return($dataLen>=$otherLen && substr($data,0,$otherLen) eq $otherText);
  }

  sub Left($$) {
    my($this,$count)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::String->new(substr($this->{_data},0,$count)));
  }

  sub Right($$) {
    my($this,$count)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $data=$this->{_data};
    my $dataLen=length($data);
    $count=$dataLen if($count>$dataLen);
    return(System::String->new(substr($data,$dataLen-$count,$count)));
  }

  sub Replace($$$) {
    my($this,$what,$replacement)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(ref($what) && !$what->can('ToString'));
    throw(System::ArgumentException->new('replacement')) if(ref($replacement) && !$replacement->can('ToString'));
    my $result=CSharp::_ToString($this);
    $what=CSharp::_ToString($what);
    $replacement=CSharp::_ToString($replacement);
    my $index=0;
    my $whatLen=length($what);
    my $replacementLen=length($replacement);
    while(($index=index($result,$what,$index))>=0) {
      $result=($index==0?'':substr($result,0,$index)).$replacement.(substr($result,$index+$whatLen));
      $index+=$replacementLen;
    }
    return(System::String->new($result));
  }

  sub PadLeft($$;$) {
    throw(System::NotImplementedException->new());
  }

  sub PadRight($$;$) {
    throw(System::NotImplementedException->new());
  }

  sub Remove($$;$) {
    throw(System::NotImplementedException->new());
  }

  sub Split($$;$$) {
    my($this,$splitter,$count,$options)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new()) unless(defined($splitter));
    $count=-1 unless(defined($count));
    $options=System::StringSplitOptions::None unless(defined($options));
    my @result=();
    my $length=$this->Length;
    my $pos=0;
    my $text=CSharp::_ToString($this);
    $splitter=CSharp::_ToString($splitter);
    my $splitterLength=length($splitter);
    while($count!=0){
      my $index=index($text,$splitter,$pos);
      last if($index<0);
      push(@result,__PACKAGE__->new(substr($text,$pos,$index-$pos)));
      $pos=$index+$splitterLength;
      --$count if($count>0);
    }
    push(@result,__PACKAGE__->new(substr($text,$pos,$length-$pos))) if($pos<$length);
    require System::Array;
    return(System::Array->new(@result));
  }

  sub Substring($$;$) {
    my($this,$start,$count)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::String->new(defined($count)?substr($this->{_data},$start):substr($this->{_data},$start,$count)));
  }

  sub ToLower($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::String->new(lc($this->{_data})));
  }

  sub ToLowerInvariant($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return($this->ToLower());
  }

  sub ToUpper($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::String->new(uc($this->{_data})));
  }

  sub ToUpperInvariant($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return($this->ToUpper());
  }

  sub Trim($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $result=$this->{_data};
    $result=~s/^\s+|\s+$//sg;
    return(System::String->new($result));
  }

  sub TrimStart($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $result=$this->{_data};
    $result=~s/^\s+//sg;
    return(System::String->new($result));
  }

  sub TrimEnd($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $result=$this->{_data};
    $result=~s/\s+$//sg;
    return(System::String->new($result));
  }
  #endregion

  #region static methods
  sub Join($$) {
    my($delimiter,$enumeration)=@_;
    if(ref($enumeration)->isa('System::Array')) {
      return(System::String->new(join($delimiter,@{$enumeration})));
    } else {
      return(System::String->new(join($delimiter,@{$enumeration->ToArray()})));
    }
  }

  sub IsNullOrEmpty($) {
    my($text)=@_;
    throw(System::ArgumentException->new('text')) if(ref($text) && !$text->can('ToString'));
    $text=CSharp::_ToString($text);
    return !(defined($text) && ($text ne Empty));
  }

  sub IsNullOrWhitespace($) {
    my($text)=@_;
    throw(System::ArgumentException->new('text')) if(ref($text) && !$text->can('ToString'));
    return(System::String->new($text)->Trim()->ToString() eq Empty);
  }

  sub Format(@) {
    my $text=shift;
    throw(System::ArgumentException->new('text')) if(ref($text) && !$text->can('ToString'));
    $text=CSharp::_ToString($text);
    
    # add escaped brackets as first items in the list and replace all occurencies with the new index
    unshift(@_,'{');
    unshift(@_,'}');
    $text=~s/\{\{/{-1}/g;
    $text=~s/\}\}/{-2}/g;
    
    # replace all place holders
    $text=~s/\{([\-0-9]+)(?:,(.*?))?(?::(.*?))?\}/CSharp::_ToString($_[$1+2],$3,$2)/eg;
    return($text);
  }
  #endregion


  #region Tests
  sub Test() {
    my $a=System::String->new("");
    print "Line #".__LINE__." fails\n" unless($a eq "");
    print "Line #".__LINE__." fails\n" if($a eq undef);
    print "Line #".__LINE__." fails\n" if($a eq "abc");
    $a=System::String->new("abc");
    print "Line #".__LINE__." fails\n" unless($a eq "abc");
    print "Line #".__LINE__." fails\n" unless(Format("{0}",$a) eq "abc");
    print "Line #".__LINE__." fails\n" unless(Format("{0,-4}",$a) eq "abc ");
    print "Line #".__LINE__." fails\n" unless(Format("{0,4}",$a) eq " abc");
    print "All tests done.\n";
    <STDIN>;
  }
  #endregion

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  BEGIN{CSharp::_PackageAlsoKnownAs(__PACKAGE__,"string");}
};

1;