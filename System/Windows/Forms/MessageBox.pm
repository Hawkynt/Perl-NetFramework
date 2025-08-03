package System::Windows::Forms::MessageBox; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use System;
  use System::IO;
  use System::Resources;
  use System::Windows::Forms::DialogResult;
  use System::Windows::Forms::MessageBoxIcon;
  use System::Windows::Forms::MessageBoxButtons;
  use System::Windows::Forms::MessageBoxDefaultButton;  
  
  my $BMP_ERROR='Stop.png';
  my $BMP_WARNING='Warning.png';
  my $BMP_QUESTION='Question.png';
  my $BMP_INFORMATION='Information.png';
  
  sub new($$;$$$$){
    my($class,$message,$title,$buttons,$icon,$defaultButton)=@_;
    return(bless({
      _message=>$message,
      _title=>defined($title)?$title:System::IO::Path::GetFileNameWithoutExtension($0||"MessageBox"),
      _buttons=>defined($buttons)?$buttons:MessageBoxButtons::OK,
      _icon=>defined($icon)?$icon:MessageBoxIcon::None,
      _defaultButton=>defined($defaultButton)?$defaultButton:MessageBoxDefaultButton::Button1,
      _dialogResult=>DialogResult::None,
      _minWidth=>256,
      _minHeight=>128,
    },ref($class)||$class||__PACKAGE__));
  }
  
  sub DialogResult($;$){
    my($this,$value)=@_;
    $this->{_dialogResult}=$value if(scalar(@_)>1);
    return($this->{_dialogResult});
  }
  
  sub ShowDialog($){
    my($this)=@_;
    my $mainWindow=$this->_Construct();
    Tk::MainLoop();
    return($this->DialogResult);
  }
  
  sub _GetIcon($){
    my($messageBoxIcon)=@_;
    return(Path::Combine(Path::GetDirectoryName(__FILE__), $BMP_ERROR)) if($messageBoxIcon==MessageBoxIcon::Error);
    return(Path::Combine(Path::GetDirectoryName(__FILE__), $BMP_WARNING)) if($messageBoxIcon==MessageBoxIcon::Warning);
    return(Path::Combine(Path::GetDirectoryName(__FILE__), $BMP_QUESTION)) if($messageBoxIcon==MessageBoxIcon::Question);
    return(Path::Combine(Path::GetDirectoryName(__FILE__), $BMP_INFORMATION)) if($messageBoxIcon==MessageBoxIcon::Information);
    return(null);
  }
  
  sub _ConstructButton($$&$){
    my($parent,$text,$call,$isDefault)=@_;
    my $result=$parent->Button(-text=>$text,-command=>$call,-width=>16);
    $result->pack(-side=>"right",-padx=>8,-pady=>8);
    $result->focus() if($isDefault);
    return($result);
  }
  
  sub _Construct($){
    my($this)=@_;
    require Tk;
    require Tk::PNG;
    
    my $mw=Tk::MainWindow->new(-title=>$this->{_title});
    my $text=$this->{_message};
    my $icon=_GetIcon($this->{_icon});
    my $image=defined($icon)&&System::IO::File::Exists($icon)?$mw->Photo(-file=>$icon):null;
    
    
    $mw->bind('<Unmap>',sub{$mw->deiconify});
    
    my $expWidth=(
      sort {$b<=>$a}
      map {length($_)}
      split(/\n/,$text)
    )[0]||0;
    my $expHeight=[split(/\n/,$text)];
    $expHeight=scalar(@{$expHeight})||0;
    
    $expWidth*=6;
    $expHeight*=14;
        
    $expWidth+=32 if(defined($image));
    $expHeight+=64+14;
    
    $expWidth=$this->{_minWidth} if($expWidth<$this->{_minWidth});
    $expHeight=$this->{_minHeight} if($expHeight<$this->{_minHeight});
        
    $mw->minsize($expWidth,$expHeight);
    $mw->geometry($expWidth."x".$expHeight);
    $mw->resizable(0,0);
    
    if(defined($image)){
      
      # when window icon should be set, copy image, remove transparency and set it to icon
      my $width=$image->width;
      my $height=$image->height;
      require Image::Xbm;
      my $xbm=Image::Xbm->new(-width=>$width,-height=>$height);
      for(my $y=0;$y<$height;++$y){
        for(my $x=0;$x<$width;++$x){
          my $color=$image->get($x,$y);
          my $alpha=(($color->[0] eq 0)&&($color->[1] eq 0)&&($color->[2] eq 0))?0:255;
          $xbm->xy($x,$y,$alpha==255);
        }
      }
      require System::IO::Path;
      my $fileName=Path::GetTempFileName();
      $xbm->save($fileName);
      $mw->iconimage($image) ;
      $mw->iconmask("\@$fileName");
      $mw->idletasks();
      require System::IO::File;
      System::IO::File::Delete($fileName);
    }
    
    my $frame=$mw->Frame(-background=>"#ffffff")->pack(-side=>"top",-fill=>"both",-expand=>true);
    my $buttonFrame=$mw->Frame()->pack(-side=>"bottom",-fill=>"x",-expand=>true);
    $frame->Label(-image=>$image,-background=>"#ffffff")->pack(-side=>"left",-padx=>8,-pady=>16) if(defined($image));
    
    switch $this->{_buttons},
      case MessageBoxButtons::OKCancel,sub{
        _ConstructButton($buttonFrame,System::Resources::BT_CANCEL,sub{$this->{_dialogResult}=DialogResult::Cancel;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button2);
        _ConstructButton($buttonFrame,System::Resources::BT_OK,sub{$this->{_dialogResult}=DialogResult::OK;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      },
      case MessageBoxButtons::AbortRetryIgnore,sub{
        _ConstructButton($buttonFrame,System::Resources::BT_IGNORE,sub{$this->{_dialogResult}=DialogResult::Ignore;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button3);
        _ConstructButton($buttonFrame,System::Resources::BT_RETRY,sub{$this->{_dialogResult}=DialogResult::Retry;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button2);
        _ConstructButton($buttonFrame,System::Resources::BT_ABORT,sub{$this->{_dialogResult}=DialogResult::Abort;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      },
      case MessageBoxButtons::YesNoCancel,sub{
        _ConstructButton($buttonFrame,System::Resources::BT_CANCEL,sub{$this->{_dialogResult}=DialogResult::Cancel;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button3);
        _ConstructButton($buttonFrame,System::Resources::BT_NO,sub{$this->{_dialogResult}=DialogResult::No;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button2);
        _ConstructButton($buttonFrame,System::Resources::BT_YES,sub{$this->{_dialogResult}=DialogResult::Yes;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      },
      case MessageBoxButtons::YesNo,sub{
        _ConstructButton($buttonFrame,System::Resources::BT_NO,sub{$this->{_dialogResult}=DialogResult::No;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button2);
        _ConstructButton($buttonFrame,System::Resources::BT_YES,sub{$this->{_dialogResult}=DialogResult::Yes;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      },
      case MessageBoxButtons::RetryCancel,sub{
        _ConstructButton($buttonFrame,System::Resources::BT_CANCEL,sub{$this->{_dialogResult}=DialogResult::Cancel;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button2);
        _ConstructButton($buttonFrame,System::Resources::BT_RETRY,sub{$this->{_dialogResult}=DialogResult::Retry;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      },
      default {
        _ConstructButton($buttonFrame,System::Resources::BT_OK,sub{$this->{_dialogResult}=DialogResult::OK;$mw->destroy();},$this->{_defaultButton}==MessageBoxDefaultButton::Button1);
      };
    
    $frame->Label(-text=>$text,-anchor=>"w",-background=>"#ffffff")->pack(-side=>"right",-padx=>8,-pady=>16,-fill=>"x",-expand=>true);
    
    return($mw) if($^O=~/MSWin32/i);
    
    my $call=sub{
      $mw->minsize($expWidth,$expHeight);
      my $width=$mw->reqwidth;
      $width=$expWidth if($width<$expWidth);
      my $height=$mw->reqheight;
      $height=$expHeight if($height<$expHeight);
      $mw->geometry($width."x".$height);
    };
    $call->();
    $mw->repeat(100,$call) ;
    return($mw);
  }
  
  sub Show($;$$$$){
    my($message,$title,$buttons,$icons,$defaultButton)=@_;
    my $box=__PACKAGE__->new($message,$title,$buttons,$icons,$defaultButton);
    return($box->ShowDialog);
  }
    
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}

};

#MessageBox::Show("text text ...","Caption",MessageBoxButtons::OKCancel,MessageBoxIcon::Error);
#MessageBox::Show("text text ...","Caption",MessageBoxButtons::YesNo,MessageBoxIcon::Question);
#MessageBox::Show("text text ...","Caption",MessageBoxButtons::OK,MessageBoxIcon::Warning);
#MessageBox::Show("text text ...","Caption",MessageBoxButtons::AbortRetryIgnore,MessageBoxIcon::Information);

1;