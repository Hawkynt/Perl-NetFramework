package System::IO::FileInfo; {
  use base 'System::IO::FileSystemInfo';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::FileStream;
  require System::IO::StreamReader;
  require System::IO::StreamWriter;
  require System::IO::DirectoryInfo;
  use File::Basename qw(basename dirname);
  use File::Copy;
  
  # FileInfo - provides instance methods for file operations
  
  sub new {
    my ($class, $fileName) = @_;
    my $this = $class->SUPER::new($fileName);
    return bless $this, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return basename($this->{_fullPath});
  }
  
  sub Extension {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $name = $this->Name();
    my $lastDot = rindex($name, '.');
    return ($lastDot >= 0) ? substr($name, $lastDot) : '';
  }
  
  sub DirectoryName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return dirname($this->{_fullPath});
  }
  
  sub Directory {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return System::IO::DirectoryInfo->new($this->DirectoryName());
  }
  
  sub Length {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    return -s $this->{_fullPath};
  }
  
  sub IsReadOnly {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      # Setter
      my $mode = -w $this->{_fullPath} ? 0644 : 0444;
      $mode = $value ? 0444 : 0644;
      chmod($mode, $this->{_fullPath});
    } else {
      # Getter
      return !-w $this->{_fullPath};
    }
  }
  
  # File operations
  sub Create {
    my ($this, $bufferSize) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Create the file and return a FileStream
    return System::IO::FileStream->new($this->{_fullPath}, 'Create', 'Write', 'None', $bufferSize);
  }
  
  sub CreateText {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $stream = System::IO::FileStream->new($this->{_fullPath}, 'Create', 'Write');
    return System::IO::StreamWriter->new($stream);
  }
  
  sub OpenRead {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    return System::IO::FileStream->new($this->{_fullPath}, 'Open', 'Read', 'Read');
  }
  
  sub OpenWrite {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return System::IO::FileStream->new($this->{_fullPath}, 'OpenOrCreate', 'Write', 'None');
  }
  
  sub OpenText {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    my $stream = $this->OpenRead();
    return System::IO::StreamReader->new($stream);
  }
  
  sub AppendText {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $stream = System::IO::FileStream->new($this->{_fullPath}, 'Append', 'Write');
    return System::IO::StreamWriter->new($stream);
  }
  
  sub CopyTo {
    my ($this, $destFileName, $overwrite) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('destFileName')) unless defined($destFileName);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $overwrite //= 0;
    
    if (!$overwrite && -e $destFileName) {
      throw(System::IOException->new("Destination file already exists: $destFileName"));
    }
    
    File::Copy::copy($this->{_fullPath}, $destFileName) or 
      throw(System::IOException->new("Failed to copy file: $!"));
    
    return System::IO::FileInfo->new($destFileName);
  }
  
  sub MoveTo {
    my ($this, $destFileName) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('destFileName')) unless defined($destFileName);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    File::Copy::move($this->{_fullPath}, $destFileName) or
      throw(System::IOException->new("Failed to move file: $!"));
    
    # Update this object's paths
    $this->{_originalPath} = $destFileName;
    $this->{_fullPath} = $destFileName;
    $this->Refresh();
  }
  
  sub Delete {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    unlink($this->{_fullPath}) or 
      throw(System::IOException->new("Failed to delete file: $!"));
    
    $this->Refresh();
  }
  
  # Replace method
  sub Replace {
    my ($this, $destinationFileName, $destinationBackupFileName) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('destinationFileName')) unless defined($destinationFileName);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    # If backup is requested, copy destination to backup first
    if (defined($destinationBackupFileName)) {
      if (-e $destinationFileName) {
        File::Copy::copy($destinationFileName, $destinationBackupFileName) or
          throw(System::IOException->new("Failed to create backup: $!"));
      }
    }
    
    # Replace destination with this file
    File::Copy::move($this->{_fullPath}, $destinationFileName) or
      throw(System::IOException->new("Failed to replace file: $!"));
    
    # Update this object's paths
    $this->{_originalPath} = $destinationFileName;
    $this->{_fullPath} = $destinationFileName;
    $this->Refresh();
    
    return System::IO::FileInfo->new($destinationFileName);
  }
  
  # Convenience methods for reading/writing
  sub ReadAllText {
    my ($this, $encoding) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    # For simplicity, ignore encoding parameter for now
    open(my $fh, '<', $this->{_fullPath}) or 
      throw(System::IOException->new("Cannot open file for reading: $!"));
    
    my $content = do { local $/; <$fh> };
    close($fh);
    
    return $content // '';
  }
  
  sub ReadAllLines {
    my ($this, $encoding) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    # For simplicity, ignore encoding parameter for now
    open(my $fh, '<', $this->{_fullPath}) or 
      throw(System::IOException->new("Cannot open file for reading: $!"));
    
    my @lines = <$fh>;
    chomp(@lines);
    close($fh);
    
    return \@lines;
  }
  
  sub WriteAllText {
    my ($this, $contents, $encoding) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('contents')) unless defined($contents);
    
    # For simplicity, ignore encoding parameter for now
    open(my $fh, '>', $this->{_fullPath}) or 
      throw(System::IOException->new("Cannot open file for writing: $!"));
    
    print $fh $contents;
    close($fh);
    
    $this->Refresh();
  }
  
  sub WriteAllLines {
    my ($this, $contents, $encoding) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('contents')) unless defined($contents);
    
    # For simplicity, ignore encoding parameter for now
    open(my $fh, '>', $this->{_fullPath}) or 
      throw(System::IOException->new("Cannot open file for writing: $!"));
    
    for my $line (@$contents) {
      print $fh $line . "\n";
    }
    close($fh);
    
    $this->Refresh();
  }
  
  # Protected methods
  sub _RefreshExistence {
    my ($this) = @_;
    $this->{_exists} = (-e $this->{_fullPath} && -f $this->{_fullPath}) ? 1 : 0;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;