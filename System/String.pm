package System::String; {
  use base "System::Object";
  
  use strict;
  use warnings;

  use Scalar::Util();
  use CSharp;
  use System::Exceptions;

  use System::StringComparison;
  use System::StringSplitOptions;
  use System::StringComparer;  
  require System::Linq;
  use overload 
    '""'=>\&ToString,
    '+'=>\&Concat,
    'cmp'=>\&_Compare,
    '=='=>\&_Equals,
    'eq'=>\&_Equals,
    '!='=>\&_NotEquals,
    'ne'=>\&_NotEquals
    ;

  use constant Empty=>"";

  # true when a reference cannot be turned into a string (unblessed or lacking ToString)
  sub _IsInvalidStringArg($) {
    my($value)=@_;
    return(ref($value) && !(Scalar::Util::blessed($value) && $value->can('ToString')));
  }

  #region instance methods
  sub new {
    my($class)=shift(@_);
    my($text)=@_;
    throw(System::ArgumentException->new('text')) if(_IsInvalidStringArg($text));
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
    my $data=$this->{_data};
    # classic .NET Framework 32-bit string hash (djb2 variant over even/odd characters)
    my $hash1=(5381<<16)+5381;
    my $hash2=$hash1;
    for(my $i=0;$i<length($data);++$i){
      my $value=ord(substr($data,$i,1));
      if($i&1){
        $hash2=((($hash2<<5)+$hash2)^$value)&0xFFFFFFFF;
      }else {
        $hash1=((($hash1<<5)+$hash1)^$value)&0xFFFFFFFF;
      }
    }
    return(($hash1+($hash2*1566083941))&0xFFFFFFFF);
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
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    my $otherText=CSharp::_ToString($what);
    return(index($this->{_data},$otherText)>=0);
  }

  sub IndexOf($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    my $otherText=CSharp::_ToString($what);
    return(index($this->{_data},$otherText));
  }

  sub LastIndexOf($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    my $otherText=CSharp::_ToString($what);
    return(rindex($this->{_data},$otherText));
  }

  sub Equals($$;$) {
    my($this,$what,$comparison)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    $comparison=StringComparison::CurrentCulture unless(defined($comparison));
    my $comparer=_GetComparerForComparison($comparison);
    throw(System::NullReferenceException->new()) unless(defined($comparer));
    return($comparer->Equals($this,$what));
  }

  sub _Equals($$;$) {
    my($this,$what,$swapped)=@_;
    return $this->Equals($what);
  }

  sub _NotEquals($$;$) {
    my($this,$what,$swapped)=@_;
    return !$this->Equals($what);
  }

  sub EndsWith($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    my $otherText=CSharp::_ToString($what);
    my $data=$this->{_data};
    my $otherLen=length($otherText);
    my $dataLen=length($data);
    return($dataLen>=$otherLen && substr($data,$dataLen-$otherLen,$otherLen) eq $otherText);
  }

  sub StartsWith($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
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
    throw(System::ArgumentNullException->new('what')) unless(defined($what));
    throw(System::ArgumentException->new('what')) if(_IsInvalidStringArg($what));
    throw(System::ArgumentException->new('replacement')) if(_IsInvalidStringArg($replacement));
    my $result=CSharp::_ToString($this);
    $what=CSharp::_ToString($what);
    $replacement=CSharp::_ToString($replacement);
    # .NET forbids replacing the empty string (and a naive scan would never terminate)
    throw(System::ArgumentException->new('String cannot be of zero length.','what')) if(length($what)==0);
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
    my ($this, $totalWidth, $paddingChar) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $paddingChar = ' ' unless defined($paddingChar);
    $paddingChar = substr($paddingChar, 0, 1) if length($paddingChar) > 1;
    
    my $data = $this->{_data} || '';
    my $len = length($data);
    return $this if $totalWidth <= $len;
    
    my $padCount = $totalWidth - $len;
    my $padding = $paddingChar x $padCount;
    
    return System::String->new($padding . $data);
  }

  sub PadRight($$;$) {
    my ($this, $totalWidth, $paddingChar) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $paddingChar = ' ' unless defined($paddingChar);
    $paddingChar = substr($paddingChar, 0, 1) if length($paddingChar) > 1;
    
    my $data = $this->{_data} || '';
    my $len = length($data);
    return $this if $totalWidth <= $len;
    
    my $padCount = $totalWidth - $len;
    my $padding = $paddingChar x $padCount;
    
    return System::String->new($data . $padding);
  }

  sub Remove($$;$) {
    my ($this, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $data = $this->{_data} || '';
    my $len = length($data);
    
    throw(System::ArgumentOutOfRangeException->new('startIndex', $startIndex)) 
      if $startIndex < 0 || $startIndex > $len;
    
    if (!defined($count)) {
      # Remove from startIndex to end
      return System::String->new(substr($data, 0, $startIndex));
    } else {
      throw(System::ArgumentOutOfRangeException->new('count', $count)) if $count < 0;
      throw(System::ArgumentOutOfRangeException->new('count', $count)) 
        if $startIndex + $count > $len;
      
      my $before = substr($data, 0, $startIndex);
      my $after = substr($data, $startIndex + $count);
      return System::String->new($before . $after);
    }
  }

  sub Split($$;$$) {
    my($this,$splitter,$count,$options)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentException->new()) unless(defined($splitter));
    $count=-1 unless(defined($count));
    $options=System::StringSplitOptions::None unless(defined($options));
    require System::Array;
    return(System::Array->new()) if($count==0);
    my @result=();
    my $length=$this->Length;
    my $pos=0;
    my $text=CSharp::_ToString($this);
    $splitter=CSharp::_ToString($splitter);
    my $splitterLength=length($splitter);
    # $count limits the total number of parts (.NET), so stop splitting one part early
    while($count!=1){
      my $index=index($text,$splitter,$pos);
      last if($index<0);
      push(@result,__PACKAGE__->new(substr($text,$pos,$index-$pos)));
      $pos=$index+$splitterLength;
      --$count if($count>0);
    }
    # .NET always yields the remainder, even when it is empty ("" splits into one empty part)
    push(@result,__PACKAGE__->new(substr($text,$pos,$length-$pos)));
    return(System::Array->new(@result));
  }

  sub Substring($$;$) {
    my($this,$start,$count)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my $length=length($this->{_data});
    throw(System::ArgumentOutOfRangeException->new('startIndex')) if($start<0 || $start>$length);
    return(System::String->new(substr($this->{_data},$start))) unless(defined($count));
    throw(System::ArgumentOutOfRangeException->new('length')) if($count<0 || $start+$count>$length);
    return(System::String->new(substr($this->{_data},$start,$count)));
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
    throw(System::ArgumentException->new('text')) if(_IsInvalidStringArg($text));
    $text=CSharp::_ToString($text);
    return !(defined($text) && ($text ne Empty));
  }

  sub IsNullOrWhitespace($) {
    my($text)=@_;
    throw(System::ArgumentException->new('text')) if(_IsInvalidStringArg($text));
    return(System::String->new($text)->Trim()->ToString() eq Empty);
  }

  sub Format(@) {
    my $text=shift;
    throw(System::ArgumentException->new('text')) if(_IsInvalidStringArg($text));
    $text=CSharp::_ToString($text);
    my @args=@_;

    # handle escaped braces and place holders in a single left-to-right pass like .NET,
    # so adjacent braces ("{{{0}}}") pair up correctly
    $text=~s/(\{\{)|(\}\})|\{([0-9]+)(?:,(.*?))?(?::(.*?))?\}/
      defined($1)?'{':defined($2)?'}':CSharp::_ToString($args[$3],$5,$4)
    /xeg;
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
  }
  #endregion

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  BEGIN{CSharp::_PackageAlsoKnownAs(__PACKAGE__,"string");}
};

1;