#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::IO::FileInfo;
require System::IO::DirectoryInfo;
require System::IO::File;
require System::IO::Directory;
# Test plan: comprehensive tests for FileInfo and DirectoryInfo classes
# plan tests => 45;  # Using done_testing() instead

# Create a temporary directory for testing
my $tempDir = "temp_test_$$";
mkdir($tempDir) or die "Cannot create temp directory: $!";

# Ensure cleanup
END {
  if (-d $tempDir) {
    system("rm -rf $tempDir") if ($^O ne 'MSWin32');
    system("rmdir /s /q $tempDir") if ($^O eq 'MSWin32');
  }
}

# ============================================================================
# FileInfo Tests
# ============================================================================

# Test FileInfo creation and basic properties
{
  my $testFile = "$tempDir/test.txt";
  
  # Create a test file
  open(my $fh, '>', $testFile) or die "Cannot create test file: $!";
  print $fh "Hello, World!\nThis is a test file.\n";
  close($fh);
  
  my $fileInfo = System::IO::FileInfo->new($testFile);
  
  ok(defined($fileInfo), 'FileInfo can be created');
  ok($fileInfo->isa('System::IO::FileInfo'), 'FileInfo has correct type');
  ok($fileInfo->isa('System::IO::FileSystemInfo'), 'FileInfo inherits from FileSystemInfo');
  
  is($fileInfo->Name(), 'test.txt', 'FileInfo Name property correct');
  is($fileInfo->Extension(), '.txt', 'FileInfo Extension property correct');
  ok($fileInfo->Exists(), 'FileInfo Exists returns true for existing file');
  is($fileInfo->Length(), -s $testFile, 'FileInfo Length property correct');
  
  ok(-f $fileInfo->FullName(), 'FileInfo FullName points to actual file');
  isa_ok($fileInfo->Directory(), 'System::IO::DirectoryInfo', 'FileInfo Directory property');
}

# Test FileInfo file operations
{
  my $sourceFile = "$tempDir/source.txt";
  my $destFile = "$tempDir/destination.txt";
  
  # Create source file
  open(my $fh, '>', $sourceFile) or die "Cannot create source file: $!";
  print $fh "Source file content\n";
  close($fh);
  
  my $fileInfo = System::IO::FileInfo->new($sourceFile);
  
  # Test CopyTo
  my $copiedFileInfo = $fileInfo->CopyTo($destFile);
  ok($copiedFileInfo->Exists(), 'FileInfo CopyTo creates destination file');
  is($copiedFileInfo->Name(), 'destination.txt', 'Copied file has correct name');
  
  # Test file content was copied
  my $content = $copiedFileInfo->ReadAllText();
  is($content, "Source file content\n", 'File content copied correctly');
  
  # Test ReadAllLines
  my $lines = $fileInfo->ReadAllLines();
  is(scalar(@$lines), 1, 'ReadAllLines returns correct number of lines');
  is($lines->[0], 'Source file content', 'ReadAllLines content correct');
}

# Test FileInfo write operations
{
  my $writeFile = "$tempDir/write_test.txt";
  my $fileInfo = System::IO::FileInfo->new($writeFile);
  
  # Test WriteAllText
  $fileInfo->WriteAllText("Written content\nSecond line\n");
  ok($fileInfo->Exists(), 'WriteAllText creates file');
  
  my $content = $fileInfo->ReadAllText();
  is($content, "Written content\nSecond line\n", 'WriteAllText content correct');
  
  # Test WriteAllLines
  $fileInfo->WriteAllLines(['Line 1', 'Line 2', 'Line 3']);
  my $lines = $fileInfo->ReadAllLines();
  is(scalar(@$lines), 3, 'WriteAllLines writes correct number of lines');
  is($lines->[1], 'Line 2', 'WriteAllLines content correct');
}

# Test FileInfo MoveTo
{
  my $originalFile = "$tempDir/original.txt";
  my $movedFile = "$tempDir/moved.txt";
  
  # Create original file
  open(my $fh, '>', $originalFile) or die "Cannot create original file: $!";
  print $fh "Original content\n";
  close($fh);
  
  my $fileInfo = System::IO::FileInfo->new($originalFile);
  ok($fileInfo->Exists(), 'Original file exists before move');
  
  $fileInfo->MoveTo($movedFile);
  ok($fileInfo->Exists(), 'FileInfo still exists after move');
  is($fileInfo->Name(), 'moved.txt', 'FileInfo name updated after move');
  ok(!-e $originalFile, 'Original file no longer exists');
  ok(-e $movedFile, 'Moved file exists at new location');
}

# Test FileInfo Delete
{
  my $deleteFile = "$tempDir/delete_me.txt";
  
  # Create file to delete
  open(my $fh, '>', $deleteFile) or die "Cannot create file to delete: $!";
  print $fh "Delete me\n";
  close($fh);
  
  my $fileInfo = System::IO::FileInfo->new($deleteFile);
  ok($fileInfo->Exists(), 'File exists before delete');
  
  $fileInfo->Delete();
  ok(!$fileInfo->Exists(), 'File no longer exists after delete');
  ok(!-e $deleteFile, 'File physically removed');
}

# ============================================================================
# DirectoryInfo Tests
# ============================================================================

# Test DirectoryInfo creation and basic properties
{
  my $dirInfo = System::IO::DirectoryInfo->new($tempDir);
  
  ok(defined($dirInfo), 'DirectoryInfo can be created');
  ok($dirInfo->isa('System::IO::DirectoryInfo'), 'DirectoryInfo has correct type');
  ok($dirInfo->isa('System::IO::FileSystemInfo'), 'DirectoryInfo inherits from FileSystemInfo');
  
  ok($dirInfo->Exists(), 'DirectoryInfo Exists returns true for existing directory');
  ok(-d $dirInfo->FullName(), 'DirectoryInfo FullName points to actual directory');
  
  my $parent = $dirInfo->Parent();
  ok(defined($parent), 'DirectoryInfo has Parent property');
  isa_ok($parent, 'System::IO::DirectoryInfo', 'Parent is DirectoryInfo');
}

# Test DirectoryInfo CreateSubdirectory
{
  my $dirInfo = System::IO::DirectoryInfo->new($tempDir);
  
  my $subDir = $dirInfo->CreateSubdirectory('subdir_test');
  ok($subDir->Exists(), 'CreateSubdirectory creates directory');
  is($subDir->Name(), 'subdir_test', 'Subdirectory has correct name');
  isa_ok($subDir, 'System::IO::DirectoryInfo', 'CreateSubdirectory returns DirectoryInfo');
}

# Test DirectoryInfo file and directory enumeration
{
  my $dirInfo = System::IO::DirectoryInfo->new($tempDir);
  
  # Create some test files and directories
  my $testFile1 = "$tempDir/enum_test1.txt";
  my $testFile2 = "$tempDir/enum_test2.log";
  my $testDir1 = "$tempDir/enum_dir1";
  my $testDir2 = "$tempDir/enum_dir2";
  
  open(my $fh1, '>', $testFile1); close($fh1);
  open(my $fh2, '>', $testFile2); close($fh2);
  mkdir($testDir1);
  mkdir($testDir2);
  
  # Test GetFiles
  my $files = $dirInfo->GetFiles();
  ok(scalar(@$files) >= 2, 'GetFiles returns multiple files');
  
  my $txtFiles = $dirInfo->GetFiles('*.txt');
  ok(scalar(@$txtFiles) >= 1, 'GetFiles with pattern filters correctly');
  
  # Test GetDirectories
  my $directories = $dirInfo->GetDirectories();
  ok(scalar(@$directories) >= 2, 'GetDirectories returns multiple directories');
  
  # Test GetFileSystemInfos
  my $allItems = $dirInfo->GetFileSystemInfos();
  ok(scalar(@$allItems) >= 4, 'GetFileSystemInfos returns files and directories');
  
  # Verify types in mixed results
  my $fileCount = 0;
  my $dirCount = 0;
  for my $item (@$allItems) {
    if ($item->isa('System::IO::FileInfo')) {
      $fileCount++;
    } elsif ($item->isa('System::IO::DirectoryInfo')) {
      $dirCount++;
    }
  }
  ok($fileCount > 0, 'GetFileSystemInfos includes FileInfo objects');
  ok($dirCount > 0, 'GetFileSystemInfos includes DirectoryInfo objects');
}

# Test DirectoryInfo Delete
{
  my $deleteDir = "$tempDir/delete_dir_test";
  mkdir($deleteDir);
  
  # Create a file inside the directory
  my $innerFile = "$deleteDir/inner.txt";
  open(my $fh, '>', $innerFile); close($fh);
  
  my $dirInfo = System::IO::DirectoryInfo->new($deleteDir);
  ok($dirInfo->Exists(), 'Directory exists before delete');
  
  # Test recursive delete
  $dirInfo->Delete(1); # recursive = true
  ok(!$dirInfo->Exists(), 'Directory no longer exists after recursive delete');
  ok(!-d $deleteDir, 'Directory physically removed');
}

# ============================================================================
# FileSystemInfo Base Class Tests
# ============================================================================

# Test DateTime properties
{
  my $testFile = "$tempDir/datetime_test.txt";
  
  # Create test file
  open(my $fh, '>', $testFile) or die "Cannot create test file: $!";
  print $fh "DateTime test\n";
  close($fh);
  
  my $fileInfo = System::IO::FileInfo->new($testFile);
  
  my $creationTime = $fileInfo->CreationTime();
  isa_ok($creationTime, 'System::DateTime', 'CreationTime returns DateTime');
  
  my $lastWriteTime = $fileInfo->LastWriteTime();
  isa_ok($lastWriteTime, 'System::DateTime', 'LastWriteTime returns DateTime');
  
  my $lastAccessTime = $fileInfo->LastAccessTime();
  isa_ok($lastAccessTime, 'System::DateTime', 'LastAccessTime returns DateTime');
  
  # Test Attributes
  my $attributes = $fileInfo->Attributes();
  ok(defined($attributes), 'Attributes property returns value');
  ok($attributes >= 0, 'Attributes is non-negative');
}

# Test Refresh functionality
{
  my $refreshFile = "$tempDir/refresh_test.txt";
  
  my $fileInfo = System::IO::FileInfo->new($refreshFile);
  ok(!$fileInfo->Exists(), 'File does not exist initially');
  
  # Create the file externally
  open(my $fh, '>', $refreshFile); close($fh);
  
  # Should still report not existing until refresh
  ok(!$fileInfo->Exists(), 'File still reports not existing before refresh');
  
  $fileInfo->Refresh();
  ok($fileInfo->Exists(), 'File exists after refresh');
  
  # Clean up
  unlink($refreshFile);
}

done_testing();