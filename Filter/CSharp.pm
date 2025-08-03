### <summary>
### This code filter allows using C# syntax to produce a perl program.
### It converts typical C# statement like using, namespace, class into valid perl syntax.
### It also introduces the concepts of fields and properties, constants and static readonlies.
### It goes well along the .NET typesystem for perl, allows foreach with lazy evaluation and lambdas.
### </summary>
package Filter::CSharp;{

  use strict;
  use CSharp;
  
  use Filter::Simple;
  
  use constant EX_NOT_IDISPOSABLE=>"Only supported on classes implementing System::IDisposable";
  use constant METACLASS=>"CSharp::__Meta";
  
  use constant DEBUG=>0;
  
  # when to allow passing contents to external filter
  use constant ALLOW_EXTERNAL_FILTER=>1 && $^O=~m/MSWin32/;
  # name of the external filter
  use constant EXTERNAL_FILTER_NAME=>"D:\\PerlSharpFilter.exe";
  # the temporary filename to use for passing contents to external filter
  use constant TEMP_FILE_MASK=>($ENV{TEMP}||"")."/${$}_tmp_\$index.tmp";
  
  #region methods used by the code filter
  
  # for implementing "using(var x){}"
  sub _Using($$$){
    my($oldArgs,$var,$call)=@_;
    throw(System::ArgumentException->new(EX_NOT_IDISPOSABLE)) unless ($var->isa("System::IDisposable"));
    try(sub{
      $call->($var,$oldArgs);
    },finally(sub{
      $var->Dispose();
    }));
  }
   
  # get meta info for package if possible
  sub _GetMetaForPackage($){
    my($package)=@_;
    my $result=eval("return(\$".$package."::__meta);");
    return(ref($result)eq METACLASS?$result:undef);
  }
  
  # for storing various meta information for a class, as well as its scope guard
  sub _CreateMeta($$$;$$$){
    my($package,$fileName,$classShortName,$inheritanceChain,$isStatic,$modifiers)=@_;
    $inheritanceChain||="";
    {
      # remove duplicates & get meta from base classes
      my %temp=();
      @temp{split(/\s*,\s*/,$inheritanceChain)}=1;
      $inheritanceChain=[map{_GetMetaForPackage($_)||{package=>$_}} keys(%temp)];
    }
    return(bless{
      propertyInfos=>{},
      fieldInfos=>{},
      initFields=>[],
      fullName=>$package,
      className=>$classShortName,
      fileName=>$fileName,
      baseClasses=>$inheritanceChain,
      isStatic=>$isStatic?1:0,
      modifiers=>$modifiers||"internal",
      guard=>_ConstructScopeGuard($package,$classShortName),
    },METACLASS);
  }
  
  # registers a field in the meta info
  sub _RegisterField($$$$$$$$$;$){
    my($meta,$type,$isStatic,$isCompilerGenerated,$isReadable,$isWriteable,$file,$line,$name,$defaultValue)=@_;
    $meta->{fieldInfos}->{$name}={
      name=>$name,
      file=>$file,
      line=>$line,
      type=>$type,
      isStatic=>$isStatic,
      isCompilerGenerated=>$isCompilerGenerated,
      isReadable=>$isReadable,
      isWriteable=>$isWriteable,
      hasDefaultValue=>defined($defaultValue),
    };
    return if($isStatic);
    push(@{$meta->{initFields}},[$name,$defaultValue,_GetDefaultValueForType($type)]);
  }
  
  # registers a property in the meta info
  sub _RegisterProperty($$$$$$$$){
    my($meta,$type,$isStatic,$isReadable,$isWriteable,$file,$line,$name)=@_;
    $meta->{propertyInfos}->{$name}={
      name=>$name,
      file=>$file,
      line=>$line,
      type=>$type,
      isStatic=>$isStatic,
      isReadable=>$isReadable,
      isWriteable=>$isWriteable,
    };
  }
  
  # reads a field value
  sub _GetFieldValue($$@){
    my($class,$fieldName,$this)=@_;
    throw System::NullReferenceException->new() unless(defined($this));
    throw System::ArgumentException->new() unless($this->isa($class));
    return($this->{$fieldName});
  }
  
  # write a field value
  sub _SetFieldValue($$@){
    my($class,$fieldName,$this,$value)=@_;
    throw System::NullReferenceException->new() unless(defined($this));
    throw System::ArgumentException->new() unless($this->isa($class));
    $this->{$fieldName}=$value;
  }
  
  # read/write a field value
  sub _GetSetFieldValue($$@){
    my($class,$fieldName,$this,$value)=@_;
    throw System::NullReferenceException->new() unless(defined($this));
    throw System::ArgumentException->new() unless($this->isa($class));
    $this->{$fieldName}=$value if(scalar(@_)>3);
    return($this->{$fieldName});
  }

  # gets the default value for a given type (eg.0 for numbers, otherwise undef)
  sub _GetDefaultValueForType($){
    my($typeName)=@_;
    return($typeName=~m/(byte)|(Byte)|(System::Byte)|(sbyte)|(SByte)|(System::SByte)|(ushort)|(UInt16)|(System::UInt16)|(short)|(Int16)|(System::Int16)|(uint)|(UInt32)|(System::UInt32)|(int)|(Int32)|(System::Int32)|(ulong)|(UInt64)|(System::UInt64)|(long)|(Int64)|(System::UInt64)|(float)|(Single)|(System::Single)|(double)|(Double)|(System::Double)|(decimal)|(Decimal)|(System::Decimal)/?0:undef);
  }
  
  # calls an instance method if available
  sub _CallIfCan($$;@){
    my($this,$method,@parameters)=@_;
    my $call=$this->can($method);
    $call->($this,@parameters) if($call);
  }
  
  # gets a base method from a given package
  sub _GetSuperMethod($$){
    my($package,$method)=@_;
    
    # Note: We need to change the package before trying to access SUPER because this pseudo-class refers always to the active package!
    my $result=eval("package $package;return('$package'->can('SUPER::$method'));");
    return($result);
  }
  
  # constructs a pure object using the base ctor if possible
  sub _ConstructObject($$;@){
    my($class,$package,@parameters)=@_;
    my $baseCtor=_GetSuperMethod($package,"new");
    my $this=bless($baseCtor ? $baseCtor->(@parameters) : {}, ref $class || $class || $package);
    return($this);
  }
  
  # constructs all fields which are init fields according to meta info
  sub _ConstructFields($$){
    my($this,$meta)=@_;
    foreach my $fieldInfo(@{$meta->{initFields}}){
      my($name,$call,$default)=@{$fieldInfo};
      $this->{$name}=$call?$call->($this):$default;
    }
  }
  
  # constructs a scope guard for the class to make sure that static ctor and dtor get called
  sub _ConstructScopeGuard($$){
    my($package,$classShortName)=@_;
    CSharp::_ScopeGuard->new(sub{_BasicCctor($package,$classShortName)},sub{_BasicCdtor($package,$classShortName)});
  }
  
  # calls the cctor if available
  sub _BasicCctor($$){
    my($package,$classShortName)=@_;
    _CallIfCan($package,"__cctor_$classShortName");
  }
  
  # calls the cdtor if available
  sub _BasicCdtor($$){
    my($package,$classShortName)=@_;
    _CallIfCan($package,"__cdtor_$classShortName");
  }
  
  # constructs all init fields and calls ctor
  sub _BasicCtor($$$;@){
    my($package,$classShortName,$meta,$class,@parameters)=@_;
    my $this=_ConstructObject($class,$package,@parameters);
    _ConstructFields($this,$meta);
    _CallIfCan($this,"__ctor_$classShortName",@parameters);
    return($this);
  }

  # calls dtor and base dtor upon object destruction
  sub _BasicDtor($$@){
    my($package,$classShortName,$this)=@_;
    _CallIfCan($this,"__dtor_$classShortName");
    my $baseDtor=_GetSuperMethod($package,"DESTROY");
    $baseDtor->($this)if($baseDtor);
  }
  
  #endregion
  
  my $fileIndex=0;
  FILTER_ONLY all=>sub{
    
    my $plainData=$_;
    
    if(ALLOW_EXTERNAL_FILTER && -e EXTERNAL_FILTER_NAME){
      
      #HACK: Performance improvement
      #When under win32 and external filter executable is found,
      #generate a temp file and write the content to be filtered 
      #to it, then call the filter file and read the output file.
      my $content=$_;
      local $/=undef;
      my $fileName=TEMP_FILE_MASK;
      $fileName=~s/\$index/$fileIndex/;
      $fileIndex++;
      
      open(my $handle,">",$fileName);
        print $handle $content;
      close($handle);
      
      system('"'.EXTERNAL_FILTER_NAME.'" "'.$fileName.'" "'.$fileName.'"');
      
      open($handle,"<",$fileName);
        binmode($handle);
        $content=<$handle>;
      close($handle);
      
      unlink($fileName);
      
      $_=$content;
      return;
    }
    
    no warnings;
    
    #### handle class definitions
    # namespace Test{static class ClassName{
    # namespace Test{public static class ClassName{
    # namespace Test{private static class ClassName{
    # namespace Test{protected static class ClassName{
    # namespace Test{internal static class ClassName{
    # namespace Test::Sub{internal static class ClassName{
    # namespace Test{static class ClassName:BaseClass{
    # namespace Test{public static class ClassName:BaseClass{
    # namespace Test{private static class ClassName:BaseClass{
    # namespace Test{protected static class ClassName:BaseClass{
    # namespace Test{internal static class ClassName:BaseClass{
    # namespace Test::Sub{internal static class ClassName:BaseClass{
    # namespace Test{internal static class ClassName::Sub:BaseClass{
    # namespace Test{class ClassName{
    # namespace Test{public class ClassName{
    # namespace Test{private class ClassName{
    # namespace Test{protected class ClassName{
    # namespace Test{internal class ClassName{
    # namespace Test::Sub{internal class ClassName{
    # namespace Test{class ClassName:BaseClass{
    # namespace Test{public class ClassName:BaseClass{
    # namespace Test{private class ClassName:BaseClass{
    # namespace Test{protected class ClassName:BaseClass{
    # namespace Test{internal class ClassName:BaseClass{
    # namespace Test::Sub{internal class ClassName:BaseClass{
    my $replacer=sub{
      my($s0,$namespace,$s1,$accessModifier,$isStatic,$isPartial,$className,$baseNames,$s2)=@_;
      my $result="";
      $result.="package${s0}${namespace}::${className};${s1}";
      $result.="use base ".(defined($baseNames)?(join",",map{"'$_'"}split(/\s*,\s*/,$baseNames)).",":"")."'System::Object';$s2";
      $result.="use CSharp;";
      $result.="our \$__meta=Filter::CSharp::_CreateMeta(__PACKAGE__,__FILE__,'$className','$baseNames','$isStatic','$accessModifier');";# unless($isPartial);
      $result.="sub new(\$;\@){return(Filter::CSharp::_BasicCtor(__PACKAGE__,'$className',\$__meta,\@_));}sub DESTROY(\$){Filter::CSharp::_BasicDtor(__PACKAGE__,'$className',\@_);}" unless($isPartial||$isStatic);
      return($result);
    };
    s/(?<=\s)namespace(\s+)([a-z_A-Z][a-z_A-Z0-9]*(?:::[a-z_A-Z][a-z_A-Z0-9]*)*)(\s*\{\s*)(?:(private|public|protected|internal)(?:\s+))?(?:(static)(?:\s+))?(?:(partial)(?:\s+))?class(?:\s+)([a-z_A-Z][a-z_A-Z0-9]*)(?:\s*:\s*((?:[a-z_A-Z][a-z_A-Z0-9]*(?:::[a-z_A-Z][a-z_A-Z0-9]*)*)(?:\s*,\s*(?:[a-z_A-Z][a-z_A-Z0-9]*(?:::[a-z_A-Z][a-z_A-Z0-9]*)*))*))?(\s*\{)/$replacer->($1,$2,$3,$4,$5,$6,$7,$8,$9)/eg;
  
  
    #### handle static ctor/dtor
    # static ctor(){
    s/(?<=\s)((?:package\s+)(?:[a-z_A-Z][a-z_A-Z0-9]*::)*([a-z_A-Z][a-z_A-Z0-9]*)\s*;.*?\s)(?:(?:public|private|internal|protected)(\s+))?static(\s+)\2(\s*)\((.*?)\)(\s*\{)/$1sub $3$4__cctor_$2$5(\$;\@)$7my(\$class,$6)=\@_;shift(\@_);/gs;
    
    # static ~ctor(){
    s/(?<=\s)((?:package\s+)(?:[a-z_A-Z][a-z_A-Z0-9]*::)*([a-z_A-Z][a-z_A-Z0-9]*)\s*;.*?\s)(?:(?:public|private|internal|protected)(\s+))?static(\s+)~\2(\s*)\((.*?)\)(\s*\{)/$1sub $3$4__cdtor_$2$5(\$;\@)$7my(\$class,$6)=\@_;shift(\@_);/gs;
    
    #### handle instance ctor/dtor
    # ctor(){
    s/(?<=\s)((?:package\s+)(?:[a-z_A-Z][a-z_A-Z0-9]*::)*([a-z_A-Z][a-z_A-Z0-9]*)\s*;.*?\s)(?:(?:public|private|internal|protected)(\s+))?\2(\s*)\((.*?)\)(\s*\{)/$1sub $3$4__ctor_$2(\$;\@)$6my(\$this,$5)=\@_;shift(\@_);/gs;
    
    # ~ctor(){
    s/(?<=\s)((?:package\s+)(?:[a-z_A-Z][a-z_A-Z0-9]*::)*([a-z_A-Z][a-z_A-Z0-9]*)\s*;.*?\s)(?:(?:public|private|internal|protected)(\s+))?~\2(\s*)\((.*?)\)(\s*\{)/$1sub $3$4__dtor_$2(\$;\@)$6my(\$this,$5)=\@_;shift(\@_);/gs;
  
    #### handle static methods
    # static method(){
    # public static method(){
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))?static(\s+)(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]+)(\s*)\((\s*)\)(\s*\{)/sub $1$2$3$4$5($6)$7/g;
    
    # static method($a){
    # public static method($a){
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))?static(\s+)(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]+)(\s*)\((.*?)\)(\s*\{)/sub $1$2$3$4$5(\@)$7my($6)=\@_;/g;
  
    #### handle instance methods
    # private method(){
    # public method($a){
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]+)(\s*)\((.*?)\)(\s*\{)/sub $1$2$3$4(\$;\@)$6my(\$this,$5)=\@_;shift(\@_);/g;
  
    #### handle static properties
    # public static int test {get;private set;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*)\{(\s*)(?:(?:public|private|protected|internal)\s+)?get;(\s*)(?:(?:public|private|protected|internal)\s+)?set;(\s*)\}/$1$2$4Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,1,1,__FILE__,__LINE__,'$5');Filter::CSharp::_RegisterField(\$__meta,'$3',1,1,1,1,__FILE__,__LINE__,'__$5_k__BackingField');\{my \$__$5_k__BackingField; sub $5(\$;\$)$6\{my(\$class,\$value)=\@_;shift(\@_); throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__); $7return(\$__$5_k__BackingField) if(scalar(\@_)<1); $8\$__$5_k__BackingField=\$value;}$9}/g;
    # public static int test {private set;get;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*)\{(\s*)(?:(?:public|private|protected|internal)\s+)?set;(\s*)(?:(?:public|private|protected|internal)\s+)?get;(\s*)\}/$1$2$4Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,1,1,__FILE__,__LINE__,'$5');Filter::CSharp::_RegisterField(\$__meta,'$3',1,1,1,1,__FILE__,__LINE__,'__$5_k__BackingField');\{my \$__$5_k__BackingField; sub $5(\$;\$)$6\{my(\$class,\$value)=\@_;shift(\@_); throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__); $7return(\$__$5_k__BackingField) if(scalar(\@_)<1); $8\$__$5_k__BackingField=\$value;}$9}/g;
    # public static int test {get;}
    # static int test {public get;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*)\{(\s*)(?:(?:public|private|protected|internal)\s+)?get;(\s*)\}/$1$2$4Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,1,0,__FILE__,__LINE__,'$5');Filter::CSharp::_RegisterField(\$__meta,'$3',1,1,1,0,__FILE__,__LINE__,'__$5_k__BackingField');\{my \$__$5_k__BackingField; sub $5(\$)$6\{my(\$class)=\@_;shift(\@_); throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__); $7return(\$__$5_k__BackingField);}$8}/g;
    # public static int test {set;}
    # static int test {public set;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*)\{(\s*)(?:(?:public|private|protected|internal)\s+)?set;(\s*)\}/$1$2$4Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,0,1,__FILE__,__LINE__,'$5');Filter::CSharp::_RegisterField(\$__meta,'$3',1,1,0,1,__FILE__,__LINE__,'__$5_k__BackingField');\{my \$__$5_k__BackingField; sub $5(\$\$)$6\{my(\$class,\$value)=\@_;shift(\@_); throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__); $7\$__$5_k__BackingField=\$value;}$8}/g;
    # public static void test { get {...} set {...} }
    # public static void test { private get {...} set {...} }
    # public static void test { get {...} private set {...} }
    # static void test { get {...} set {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)\s*{(\s*)(?:(?:public|private|protected|internal)\s+)?get\s*{(\s*)(.*?)(\s*)}(\s*)(?:(?:public|private|protected|internal)\s+)?set\s*{/$1$2$3Filter::CSharp::_RegisterProperty(\$__meta,'',1,1,1,__FILE__,__LINE__,'$4');sub $4(\$;\$){my(\$class,\$value)=\@_;shift(\@_); throw(System::ArgumentException->new('class')) unless(defined(\$class)&&\$class eq \__PACKAGE__);$5if(scalar(\@_)<1) {$6$7$8}$9else{/g;
    # public static void test { set {...} get {...} }
    # public static void test { private set {...} get {...} }
    # public static void test { set {...} private get {...} }
    # static void test { set {...} get {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)\s*{(\s*)(?:(?:public|private|protected|internal)\s+)?set\s*{(\s*)(.*?)(\s*)}(\s*)(?:(?:public|private|protected|internal)\s+)?get\s*{/$1$2$3Filter::CSharp::_RegisterProperty(\$__meta,'',1,1,1,__FILE__,__LINE__,'$4');sub $4(\$;\$){my(\$class,\$value)=\@_;shift(\@_); throw(System::ArgumentException->new('class')) unless(defined(\$class)&&\$class eq \__PACKAGE__);$5unless(scalar(\@_)<1) {$6$7$8}$9else{/g;
    # allow 'public static void test { set {...} }
    # allow 'public static void test { private set {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)set(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,0,1,__FILE__,__LINE__,'$5');sub $1$2$4$5(\$\$)$6my(\$class,\$value)=\@_;shift(\@_);throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__);$7/mg;
    # allow 'public static void test { get {...} }
    # allow 'public static void test { private get {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?static(\s+)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)get(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$3',1,1,0,__FILE__,__LINE__,'$5');sub $1$2$4$5(\$)$6my(\$class)=\@_;shift(\@_);throw(System::ArgumentException->new('class'))unless(defined(\$class)&&\$class eq \__PACKAGE__);$7/mg;
    
    #### handle instance properties
    # allow 'public int test {get;private set;}'
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*\{\s*)(?:(?:public|private|protected|internal)(\s+))?get;(\s*)(?:(?:public|private|protected|internal)(\s+))?set;(\s*\})/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,1,__FILE__,__LINE__,'$4');Filter::CSharp::_RegisterField(\$__meta,'$2',0,1,1,1,__FILE__,__LINE__,'<$4>k__BackingField');sub $1$3$4(\$;\$)$5$6return(Filter::CSharp::_GetSetFieldValue(__PACKAGE__,'<$4>k__BackingField',\@_));$9/g;
    # allow 'public int test {private set;get;}'
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*\{\s*)(?:(?:public|private|protected|internal)(\s+))?set;(\s*)(?:(?:public|private|protected|internal)(\s+))?get;(\s*\})/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,1,__FILE__,__LINE__,'$4');Filter::CSharp::_RegisterField(\$__meta,'$2',0,1,1,1,__FILE__,__LINE__,'<$4>k__BackingField');sub $1$3$4(\$;\$)$5$6return(Filter::CSharp::_GetSetFieldValue(__PACKAGE__,'<$4>k__BackingField',\@_));$9/g;
    # public int test {get;}
    # int test {public get;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*\{\s*)(?:(?:public|private|protected|internal)(\s+))?get;(\s*\})/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,0,__FILE__,__LINE__,'$4');Filter::CSharp::_RegisterField(\$__meta,'$2',0,1,1,0,__FILE__,__LINE__,'<$4>k__BackingField');sub $1$3$4(\$)$5$6return(Filter::CSharp::_GetFieldValue(__PACKAGE__,'<$4>k__BackingField',\@_));$7/g;
    # public int test {set;}
    # int test {public set;}
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]*)(\s*\{\s*)(?:(?:public|private|protected|internal)(\s+))?set;(\s*\})/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,0,1,__FILE__,__LINE__,'$4');Filter::CSharp::_RegisterField(\$__meta,'$2',0,1,0,1,__FILE__,__LINE__,'<$4>k__BackingField');sub $1$3$4(\$\$)$5$6Filter::CSharp::_SetFieldValue(__PACKAGE__,'<$4>k__BackingField',\@_);$7/g;
    # allow 'public void test { get {...} set {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)(?:(?:public|private|protected|internal)\s+)?get(\s*{\s*)(.*?)(\s*}\s*)(?:(?:public|private|protected|internal)\s+)?set(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,1,__FILE__,__LINE__,'$4');sub $1$3$4(\$;\$)$5my(\$this,\$value)=\@_;shift(\@_); throw(System::NullReferenceException->new())unless(defined(\$this)&&\$this->isa(\__PACKAGE__));if(scalar(\@_)<1)$6$7$8else$9/mg;
    # allow 'public void test { set {...} get {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)(?:(?:public|private|protected|internal)\s+)?set(\s*{\s*)(.*?)(\s*}\s*)(?:(?:public|private|protected|internal)\s+)?get(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,1,__FILE__,__LINE__,'$4');sub $1$3$4(\$;\$)$5my(\$this,\$value)=\@_;shift(\@_); throw(System::NullReferenceException->new())unless(defined(\$this)&&\$this->isa(\__PACKAGE__));unless(scalar(\@_)<1)$6$7$8else$9/mg;
    # allow 'public void test { set {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)set(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,0,1,__FILE__,__LINE__,'$4');sub $1$3$4(\$\$)$5my(\$this,\$value)=\@_;shift(\@_);throw(System::NullReferenceException->new()) unless(defined(\$this));$6/mg;
    # allow 'public void test { get {...} }
    s/(?<=\s)(?:(?:public|private|protected|internal)(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*{\s*)get(\s*{)/Filter::CSharp::_RegisterProperty(\$__meta,'$2',0,1,0,__FILE__,__LINE__,'$4');sub $1$3$4(\$)$5my(\$this)=\@_;shift(\@_);throw(System::NullReferenceException->new()) unless(defined(\$this));$6/mg;
    
    # const int a=
    # private const int a=
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))?const(\s+)(?:[a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-zA-Z_0-9]+)(\s*)=/$1use$2constant$3$4$5=>/g;
    
    # private static int a=
    # private static int a;
    s/(?<=\s)private(\s+)static(\s+)(?:readonly(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*\s*)([=;])/$1Filter::CSharp::_RegisterField(\$__meta,'$4',1,0,1,1,__FILE__,__LINE__,'$6');my$2$3$5\$$6$7/g;
    
    # static int a=
    # static int a;
    # public static int a=
    s/(?<=\s)(?:(?:public|protected|internal)(\s+))?static(\s+)(?:readonly(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*\s*)([=;])/$1Filter::CSharp::_RegisterField(\$__meta,'$4',1,0,1,1,__FILE__,__LINE__,'$6');our$2$3$5\$$6$7/g;
    
    # private int a=
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))(?:readonly(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*)=(\s*)(.*?);/$1$2$4Filter::CSharp::_RegisterField(\$__meta,'$3',0,0,1,1,__FILE__,__LINE__,'$5',sub{return($6$7$8);});/g;
    
    # private int a;
    s/(?<=\s)(?:(?:private|public|internal|protected)(\s+))(?:readonly(\s+))?([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s+)([a-z_A-Z][a-z_A-Z0-9]*)(\s*);/$1$2$4Filter::CSharp::_RegisterField(\$__meta,'$3',0,0,1,1,__FILE__,__LINE__,'$5');$6/g;
  
    # this.Method(
    s/(?<=[^a-zA-Z0-9_\$\@\%\&])this\.([a-z_A-Z][a-z_A-Z0-9]*)\(/\$this->$1(/g;
    
    # this.field
    s/(?<=[^a-zA-Z0-9_\$\@\%\&])this\.([a-z_A-Z][a-z_A-Z0-9]*)/\$this->{'$1'}/g;
    
    # using module;
    s/(?<=\s)using(\s+)([a-z_A-Z][a-z_A-Z0-9]*(?:::[a-z_A-Z][a-z_A-Z0-9]*)*)(\s*;)/use $1$2$3/g;
    
    # var $a=
    # var $a;
    # var @a;
    s/(?<=\s)var\s+([\$\@\%\&])/my $1/g;
    
    # ()=>{...}
    s/(\(\s*\)\s*)=>(\s*\{)/sub $1$2/g;
    # $a=>{...}
    s/(([\$\@\%\&])[a-z_A-Z][a-z_A-Z0-9]*)(\s*)=>(\s*\{)/sub $3$4my $1=\$_[0];/g;
    # ($a,$b)=>{...}
    s/(\(\s*[\$\@\%\&][a-z_A-Z][a-z_A-Z0-9]*(?:\s*,\s*[\$\@\%\&][a-z_A-Z][a-z_A-Z0-9]*)*\s*\)\s*)=>(\s*\{)/sub $2my$1=\@_;/g;
    
    # new className(
    s/(?<=[^a-z_A-Z0-9])new(\s+)([a-z_A-Z][a-z_A-Z0-9]*(?:::[a-z_A-Z][a-z_A-Z0-9]*)*)(\s*\()/$1$2->new$3/mg;
    
    # allow 'foreach (var $a in $b) {...}'
    s/^(\s*)foreach\s*\(\s*var\s+\$([a-z_A-Z][a-z_A-Z0-9]*)\s+in\s+(.*?)\)\s*{/$1my \$enumeration_$2=($3);throw(System::NotSupportedException->new('foreach can only be called on enumerations')) unless(\$enumeration_$2->isa('System::Collections::IEnumerable'));my \$enumerator_$2=\$enumeration_$2->GetEnumerator();while(\$enumerator_$2->MoveNext()) {  my \$$2=\$enumerator_$2->Current;/mg;
    
    # allow 'using(var $a){...}'
    s/(?<=\s)using(\s*)\((\s*)([a-z_A-Z0-9][a-z_A-Z0-9\:\,\.\<\>\[\]]*)(\s*)(\$[a-z_A-Z][a-z_A-Z0-9]*)(\s*)=(.*?)\)(\s*){/$1$2Filter::CSharp::_Using \\\@_,$4$6$7,sub $8\{my $5=\$_[0];\@_=\@{\$_[1]};/mg;
    
    use warnings;
    
    if(DEBUG){
      my $r=$_;
      my ($package,$file,$line,$method,$hasArgs,$wantsArray,$evalText,$isRequire,$hints,$bitMask,$hintHash)=caller(4);
      
      my $i=$line;
      print "\n".('-' x 80)."\nFilename: $file\n";
      print sprintf("%4d: %s\n",$i++,$_) foreach(split(/\n/,$_));
      $_=$r;
    }
  };

};

1;