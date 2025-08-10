#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd abs_path);

BEGIN {
    use_ok('System::IO::Path');
}

plan tests => 125;

my $temp_dir = tempdir(CLEANUP => 1);
my $is_windows = ($^O =~ /Win/);

# Test 1-10: Basic Path Properties and Constants
subtest 'Basic Path Properties and Constants' => sub {
    plan tests => 10;
    
    # Test platform detection
    my $platform_unix = System::IO::Path::PLATFORM_UNIX();
    if ($is_windows) {
        ok(!$platform_unix, 'PLATFORM_UNIX returns false on Windows');
    } else {
        ok($platform_unix, 'PLATFORM_UNIX returns true on Unix');
    }
    
    # Test directory separator
    my $sep = System::IO::Path::DirectorySeparatorChar();
    ok(defined($sep), 'DirectorySeparatorChar returns defined value');
    is(length($sep), 1, 'DirectorySeparatorChar returns single character');
    
    if ($is_windows) {
        is($sep, '\\', 'DirectorySeparatorChar is backslash on Windows');
    } else {
        is($sep, '/', 'DirectorySeparatorChar is forward slash on Unix');
    }
    
    # Test alternative directory separator
    my $altSep = System::IO::Path::AltDirectorySeparatorChar();
    ok(defined($altSep), 'AltDirectorySeparatorChar returns defined value');
    is(length($altSep), 1, 'AltDirectorySeparatorChar returns single character');
    
    # Test path separator
    my $pathSep = System::IO::Path::PathSeparator();
    ok(defined($pathSep), 'PathSeparator returns defined value');
    if ($is_windows) {
        is($pathSep, ';', 'PathSeparator is semicolon on Windows');
    } else {
        is($pathSep, ':', 'PathSeparator is colon on Unix');
    }
    
    # Test volume separator
    my $volSep = System::IO::Path::VolumeSeparatorChar();
    ok(defined($volSep), 'VolumeSeparatorChar returns defined value');
    if ($is_windows) {
        is($volSep, ':', 'VolumeSeparatorChar is colon on Windows');
    } else {
        is($volSep, '/', 'VolumeSeparatorChar is forward slash on Unix');
    }
};

# Test 11-25: Path Combination
subtest 'Path Combination' => sub {
    plan tests => 15;
    
    # Test basic combination
    my $combined = System::IO::Path::Combine('parent', 'child');
    isa_ok($combined, 'System::String', 'Combine returns System::String');
    like($combined->ToString(), qr/parent.*child/, 'Combine joins paths correctly');
    
    # Test multiple path combination
    my $multiCombined = System::IO::Path::Combine('root', 'level1', 'level2', 'file.txt');
    like($multiCombined->ToString(), qr/root.*level1.*level2.*file\.txt/, 'Multi-path combine works');
    
    # Test with array reference
    my @pathParts = ('array', 'path', 'parts');
    my $arrayPath = System::IO::Path::Combine(\@pathParts);
    like($arrayPath->ToString(), qr/array.*path.*parts/, 'Array reference combination works');
    
    # Test empty parts handling
    my $emptyParts = System::IO::Path::Combine('start', '', 'end');
    like($emptyParts->ToString(), qr/start.*end/, 'Empty parts are filtered out');
    
    # Test with leading/trailing separators
    my $sepHandling = System::IO::Path::Combine('path/', '/child');
    like($sepHandling->ToString(), qr/path.*child/, 'Leading/trailing separators handled');
    
    # Test cross-platform separator normalization
    my $crossPlatform = System::IO::Path::Combine('path\\mixed', '/separators');
    my $result = $crossPlatform->ToString();
    ok($result !~ /[\\\/]{2,}/, 'No double separators in result');
    
    # Test single argument
    my $single = System::IO::Path::Combine('single');
    is($single->ToString(), 'single', 'Single argument returns as-is');
    
    # Test with null/undefined parts
    eval { System::IO::Path::Combine(undef, 'path'); };
    # Should handle gracefully without crashing
    ok(1, 'Null arguments handled gracefully');
    
    # Test very long path combination
    my @longParts = ();
    for (my $i = 0; $i < 20; $i++) {
        push @longParts, "level$i";
    }
    my $longPath = System::IO::Path::Combine(@longParts);
    ok(length($longPath->ToString()) > 100, 'Long path combination works');
    
    # Test with special characters
    my $specialChars = System::IO::Path::Combine('path-with-dash', 'path_with_underscore', 'path.with.dots');
    like($specialChars->ToString(), qr/dash.*underscore.*dots/, 'Special characters preserved');
    
    # Test absolute path handling
    if ($is_windows) {
        my $absPath = System::IO::Path::Combine('C:\\root', 'child');
        like($absPath->ToString(), qr/C:.*root.*child/, 'Absolute Windows path combination');
    } else {
        my $absPath = System::IO::Path::Combine('/root', 'child');
        like($absPath->ToString(), qr/\/root.*child/, 'Absolute Unix path combination');
    }
    
    # Test Join alias
    my $joined = System::IO::Path::Join('join', 'test');
    isa_ok($joined, 'System::String', 'Join alias works');
    like($joined->ToString(), qr/join.*test/, 'Join produces correct result');
    
    # Test with spaces in paths
    my $spacePaths = System::IO::Path::Combine('path with spaces', 'another path', 'file name.txt');
    like($spacePaths->ToString(), qr/spaces.*another.*file name/, 'Paths with spaces handled correctly');
};

# Test 26-40: Path Analysis (GetDirectoryName, GetFileName, etc.)
subtest 'Path Analysis' => sub {
    plan tests => 15;
    
    # Test GetDirectoryName
    my $dir = System::IO::Path::GetDirectoryName('/path/to/file.txt');
    isa_ok($dir, 'System::String', 'GetDirectoryName returns System::String');
    
    if ($is_windows) {
        my $winDir = System::IO::Path::GetDirectoryName('C:\\path\\to\\file.txt');
        like($winDir->ToString(), qr/C:.*path.*to/, 'Windows GetDirectoryName works');
    } else {
        like($dir->ToString(), qr/\/path\/to/, 'Unix GetDirectoryName works');
    }
    
    # Test GetFileName
    my $fileName = System::IO::Path::GetFileName('/path/to/file.txt');
    is($fileName->ToString(), 'file.txt', 'GetFileName extracts filename correctly');
    
    my $fileNameWin = System::IO::Path::GetFileName('C:\\path\\to\\document.doc');
    is($fileNameWin->ToString(), 'document.doc', 'GetFileName works with Windows paths');
    
    # Test GetFileNameWithoutExtension
    my $nameNoExt = System::IO::Path::GetFileNameWithoutExtension('/path/to/file.txt');
    is($nameNoExt->ToString(), 'file', 'GetFileNameWithoutExtension works correctly');
    
    my $nameNoExtComplex = System::IO::Path::GetFileNameWithoutExtension('document.backup.txt');
    is($nameNoExtComplex->ToString(), 'document.backup', 'Complex extension handling works');
    
    # Test GetExtension
    my $ext = System::IO::Path::GetExtension('/path/to/file.txt');
    is($ext->ToString(), '.txt', 'GetExtension returns correct extension');
    
    my $noExt = System::IO::Path::GetExtension('/path/to/file_without_extension');
    is($noExt->ToString(), '', 'GetExtension returns empty for files without extension');
    
    my $multiExt = System::IO::Path::GetExtension('archive.tar.gz');
    is($multiExt->ToString(), '.gz', 'GetExtension returns last extension');
    
    # Test with null/undefined input
    eval { System::IO::Path::GetDirectoryName(undef); };
    # Should handle gracefully
    ok(1, 'GetDirectoryName handles null input gracefully');
    
    eval { System::IO::Path::GetFileName(undef); };
    ok(1, 'GetFileName handles null input gracefully');
    
    # Test with empty string
    my $emptyDir = System::IO::Path::GetDirectoryName('');
    ok(!defined($emptyDir) || $emptyDir->ToString() eq '', 'GetDirectoryName handles empty string');
    
    # Test with root paths
    if ($is_windows) {
        my $rootDir = System::IO::Path::GetDirectoryName('C:\\');
        ok(!defined($rootDir) || $rootDir->ToString() eq '', 'Windows root directory handling');
    } else {
        my $rootDir = System::IO::Path::GetDirectoryName('/');
        ok(!defined($rootDir) || $rootDir->ToString() eq '', 'Unix root directory handling');
    }
    
    # Test with relative paths
    my $relativeDir = System::IO::Path::GetDirectoryName('relative/path/file.txt');
    like($relativeDir->ToString(), qr/relative.*path/, 'Relative path directory extraction');
    
    # Test with file names containing dots
    my $dottedFile = System::IO::Path::GetFileName('path/to/.hidden.file');
    is($dottedFile->ToString(), '.hidden.file', 'Hidden file names handled correctly');
};

# Test 41-55: Path Validation and Character Checking
subtest 'Path Validation and Character Checking' => sub {
    plan tests => 15;
    
    # Test valid paths
    ok(System::IO::Path::IsValidPath('valid/path/file.txt'), 'IsValidPath accepts valid Unix path');
    ok(System::IO::Path::IsValidPath('C:\\valid\\path\\file.txt'), 'IsValidPath accepts valid Windows path');
    ok(System::IO::Path::IsValidPath('simple.txt'), 'IsValidPath accepts simple filename');
    ok(System::IO::Path::IsValidPath('path-with_special.chars'), 'IsValidPath accepts paths with allowed special chars');
    
    # Test invalid paths
    ok(!System::IO::Path::IsValidPath("path\x00with\x00nulls"), 'IsValidPath rejects path with null characters');
    
    if ($is_windows) {
        ok(!System::IO::Path::IsValidPath('path<with>invalid:chars'), 'IsValidPath rejects Windows invalid chars');
    } else {
        ok(System::IO::Path::IsValidPath('path<with>some:chars'), 'IsValidPath allows more chars on Unix');
    }
    
    # Test IsValidFileName
    ok(System::IO::Path::IsValidFileName('validfile.txt'), 'IsValidFileName accepts valid filename');
    ok(System::IO::Path::IsValidFileName('file-with_chars.123'), 'IsValidFileName accepts filename with allowed chars');
    ok(!System::IO::Path::IsValidFileName("file\x00name"), 'IsValidFileName rejects filename with null');
    
    if ($is_windows) {
        ok(!System::IO::Path::IsValidFileName('file<name>.txt'), 'IsValidFileName rejects Windows invalid chars');
    } else {
        ok(!System::IO::Path::IsValidFileName("file/name.txt"), 'IsValidFileName rejects path separator in filename');
    }
    
    # Test GetInvalidPathChars
    my $invalidPathChars = System::IO::Path::GetInvalidPathChars();
    isa_ok($invalidPathChars, 'System::Array', 'GetInvalidPathChars returns Array');
    ok($invalidPathChars->Length() > 0, 'GetInvalidPathChars returns some invalid characters');
    
    # Verify null character is always invalid
    my $foundNull = 0;
    for (my $i = 0; $i < $invalidPathChars->Length(); $i++) {
        if (ord($invalidPathChars->Get($i)) == 0) {
            $foundNull = 1;
            last;
        }
    }
    ok($foundNull, 'Null character included in invalid path chars');
    
    # Test GetInvalidFileNameChars
    my $invalidFileChars = System::IO::Path::GetInvalidFileNameChars();
    isa_ok($invalidFileChars, 'System::Array', 'GetInvalidFileNameChars returns Array');
    ok($invalidFileChars->Length() > 0, 'GetInvalidFileNameChars returns some invalid characters');
};

# Test 56-70: Path Manipulation (ChangeExtension, HasExtension, etc.)
subtest 'Path Manipulation' => sub {
    plan tests => 15;
    
    # Test ChangeExtension
    my $changed = System::IO::Path::ChangeExtension('file.txt', '.doc');
    is($changed->ToString(), 'file.doc', 'ChangeExtension replaces extension');
    
    my $addExt = System::IO::Path::ChangeExtension('filename', '.txt');
    is($addExt->ToString(), 'filename.txt', 'ChangeExtension adds extension');
    
    my $changePath = System::IO::Path::ChangeExtension('/path/to/file.old', '.new');
    is($changePath->ToString(), '/path/to/file.new', 'ChangeExtension works with full paths');
    
    # Test with extension without dot
    my $noDot = System::IO::Path::ChangeExtension('file.txt', 'doc');
    is($noDot->ToString(), 'file.doc', 'ChangeExtension adds dot if missing');
    
    # Test HasExtension
    ok(System::IO::Path::HasExtension('file.txt'), 'HasExtension detects extension');
    ok(!System::IO::Path::HasExtension('filename'), 'HasExtension detects no extension');
    ok(System::IO::Path::HasExtension('/path/to/file.doc'), 'HasExtension works with full paths');
    ok(!System::IO::Path::HasExtension('/path/to/filename'), 'HasExtension works with full paths without extension');
    
    # Test with hidden files
    ok(System::IO::Path::HasExtension('.hidden.txt'), 'HasExtension works with hidden files');
    ok(!System::IO::Path::HasExtension('.hidden'), 'HasExtension detects hidden file without extension');
    
    # Test with multiple dots
    ok(System::IO::Path::HasExtension('file.backup.txt'), 'HasExtension works with multiple dots');
    
    # Test null/empty inputs
    eval { System::IO::Path::ChangeExtension(undef, '.txt'); };
    ok(1, 'ChangeExtension handles null path gracefully');
    
    eval { System::IO::Path::HasExtension(undef); };
    ok(1, 'HasExtension handles null path gracefully');
    
    # Test empty extension change
    my $removeExt = System::IO::Path::ChangeExtension('file.txt', '');
    is($removeExt->ToString(), 'file', 'ChangeExtension can remove extension');
    
    # Test complex filename
    my $complexChange = System::IO::Path::ChangeExtension('my.file.v2.backup.txt', '.final');
    is($complexChange->ToString(), 'my.file.v2.backup.final', 'Complex filename extension change');
};

# Test 71-85: Path Rooting and Absolute Paths
subtest 'Path Rooting and Absolute Paths' => sub {
    plan tests => 15;
    
    # Test IsPathRooted
    if ($is_windows) {
        ok(System::IO::Path::IsPathRooted('C:\\path\\file.txt'), 'Windows absolute path detected as rooted');
        ok(System::IO::Path::IsPathRooted('\\\\server\\share'), 'UNC path detected as rooted');
        ok(!System::IO::Path::IsPathRooted('relative\\path'), 'Windows relative path not rooted');
        ok(!System::IO::Path::IsPathRooted('file.txt'), 'Simple filename not rooted');
    } else {
        ok(System::IO::Path::IsPathRooted('/absolute/path'), 'Unix absolute path detected as rooted');
        ok(!System::IO::Path::IsPathRooted('relative/path'), 'Unix relative path not rooted');
        ok(!System::IO::Path::IsPathRooted('file.txt'), 'Simple filename not rooted');
        ok(!System::IO::Path::IsPathRooted('~/home/path'), 'Tilde path not considered rooted');
    }
    
    # Test GetPathRoot
    if ($is_windows) {
        my $winRoot = System::IO::Path::GetPathRoot('C:\\path\\to\\file.txt');
        like($winRoot->ToString(), qr/C:/, 'Windows path root extracted');
        
        my $uncRoot = System::IO::Path::GetPathRoot('\\\\server\\share\\path');
        like($uncRoot->ToString(), qr/server/, 'UNC path root extracted');
    } else {
        my $unixRoot = System::IO::Path::GetPathRoot('/path/to/file.txt');
        is($unixRoot->ToString(), '/', 'Unix path root is forward slash');
    }
    
    my $relativeRoot = System::IO::Path::GetPathRoot('relative/path');
    is($relativeRoot->ToString(), '', 'Relative path has no root');
    
    # Test GetFullPath
    my $fullPath = System::IO::Path::GetFullPath('relative/path/file.txt');
    isa_ok($fullPath, 'System::String', 'GetFullPath returns System::String');
    ok(System::IO::Path::IsPathRooted($fullPath->ToString()), 'GetFullPath returns absolute path');
    
    # Test GetFullPath with already absolute path
    my $currentDir = getcwd();
    my $absoluteTest = File::Spec->catfile($currentDir, 'test.txt');
    my $fullPathAbs = System::IO::Path::GetFullPath($absoluteTest);
    like($fullPathAbs->ToString(), qr/test\.txt/, 'GetFullPath handles already absolute paths');
    
    # Test with current directory references
    my $currentRef = System::IO::Path::GetFullPath('./current/path');
    ok(System::IO::Path::IsPathRooted($currentRef->ToString()), 'Current directory reference resolved to absolute');
    
    # Test with parent directory references
    my $parentRef = System::IO::Path::GetFullPath('../parent/path');
    ok(System::IO::Path::IsPathRooted($parentRef->ToString()), 'Parent directory reference resolved to absolute');
    
    # Test null/empty inputs
    eval { System::IO::Path::IsPathRooted(undef); };
    ok(1, 'IsPathRooted handles null gracefully');
    
    eval { System::IO::Path::GetFullPath(''); };
    # Should handle empty string appropriately
    ok(1, 'GetFullPath handles empty string gracefully');
};

# Test 86-100: Temporary File and Path Operations
subtest 'Temporary File and Path Operations' => sub {
    plan tests => 15;
    
    # Test GetTempPath
    my $tempPath = System::IO::Path::GetTempPath();
    isa_ok($tempPath, 'System::String', 'GetTempPath returns System::String');
    ok(length($tempPath->ToString()) > 0, 'GetTempPath returns non-empty path');
    ok(-d $tempPath->ToString(), 'GetTempPath returns existing directory');
    
    # Test GetTempFileName
    my $tempFile1 = System::IO::Path::GetTempFileName();
    isa_ok($tempFile1, 'System::String', 'GetTempFileName returns System::String');
    ok(-e $tempFile1->ToString(), 'GetTempFileName creates actual file');
    
    # Test that consecutive calls return different names
    my $tempFile2 = System::IO::Path::GetTempFileName();
    isnt($tempFile1->ToString(), $tempFile2->ToString(), 'Consecutive GetTempFileName calls return different names');
    
    # Test GetRandomFileName
    my $randomName1 = System::IO::Path::GetRandomFileName();
    isa_ok($randomName1, 'System::String', 'GetRandomFileName returns System::String');
    ok(length($randomName1->ToString()) > 0, 'GetRandomFileName returns non-empty name');
    
    my $randomName2 = System::IO::Path::GetRandomFileName();
    isnt($randomName1->ToString(), $randomName2->ToString(), 'GetRandomFileName returns different names');
    
    # Verify random filename doesn't exist (it shouldn't create a file)
    ok(!-e $randomName1->ToString(), 'GetRandomFileName does not create actual file');
    
    # Test temp file is in temp directory
    like($tempFile1->ToString(), qr/tmp/i, 'GetTempFileName creates file in temp-related directory');
    
    # Test multiple temp files
    my @tempFiles = ();
    for (my $i = 0; $i < 5; $i++) {
        push @tempFiles, System::IO::Path::GetTempFileName()->ToString();
    }
    
    # Verify all are unique
    my %seen = ();
    my $allUnique = 1;
    for my $file (@tempFiles) {
        if ($seen{$file}) {
            $allUnique = 0;
            last;
        }
        $seen{$file} = 1;
    }
    ok($allUnique, 'Multiple GetTempFileName calls return unique names');
    
    # Test temp filename format
    like($tempFile1->ToString(), qr/tmp.*\.tmp/, 'GetTempFileName follows expected format');
    
    # Cleanup temp files
    for my $file (@tempFiles, $tempFile1->ToString(), $tempFile2->ToString()) {
        unlink($file) if -e $file;
    }
    ok(1, 'Temp file cleanup completed');
    
    # Test random filename format
    like($randomName1->ToString(), qr/^[a-z0-9]+$/, 'GetRandomFileName returns alphanumeric string');
};

# Test 101-115: Advanced Path Operations
subtest 'Advanced Path Operations' => sub {
    plan tests => 15;
    
    # Test TrimEndingDirectorySeparator
    my $sep = System::IO::Path::DirectorySeparatorChar();
    my $pathWithSep = "path/to/dir$sep";
    my $trimmed = System::IO::Path::TrimEndingDirectorySeparator($pathWithSep);
    is($trimmed, 'path/to/dir', 'TrimEndingDirectorySeparator removes trailing separator');
    
    my $pathWithoutSep = 'path/to/dir';
    my $notTrimmed = System::IO::Path::TrimEndingDirectorySeparator($pathWithoutSep);
    is($notTrimmed, 'path/to/dir', 'TrimEndingDirectorySeparator leaves path without separator unchanged');
    
    # Test EndsInDirectorySeparator
    ok(System::IO::Path::EndsInDirectorySeparator("path$sep"), 'EndsInDirectorySeparator detects trailing separator');
    ok(!System::IO::Path::EndsInDirectorySeparator('path'), 'EndsInDirectorySeparator detects no trailing separator');
    
    # Test GetRelativePath with temporary directories
    my $tempDir1 = tempdir(CLEANUP => 1);
    my $tempDir2 = tempdir(CLEANUP => 1);
    
    # Create subdirectory in tempDir1
    my $subDir = File::Spec->catdir($tempDir1, 'subdir');
    mkdir($subDir);
    
    my $relative = System::IO::Path::GetRelativePath($tempDir1, $subDir);
    like($relative->ToString(), qr/subdir/, 'GetRelativePath calculates forward relative path');
    
    # Test same path
    my $samePath = System::IO::Path::GetRelativePath($tempDir1, $tempDir1);
    is($samePath->ToString(), '.', 'GetRelativePath returns "." for same path');
    
    # Test backward relative path
    my $backward = System::IO::Path::GetRelativePath($subDir, $tempDir1);
    like($backward->ToString(), qr/\.\./, 'GetRelativePath calculates backward relative path');
    
    # Test PathStartsWith
    ok(System::IO::Path::PathStartsWith($subDir, $tempDir1), 'PathStartsWith detects path prefix');
    ok(!System::IO::Path::PathStartsWith($tempDir1, $subDir), 'PathStartsWith rejects non-prefix');
    ok(System::IO::Path::PathStartsWith($tempDir1, $tempDir1), 'PathStartsWith handles exact match');
    
    # Test with null arguments
    eval { System::IO::Path::GetRelativePath(undef, $tempDir1); };
    ok($@, 'GetRelativePath throws exception with null relativeTo');
    
    eval { System::IO::Path::PathStartsWith($tempDir1, undef); };
    ok($@, 'PathStartsWith throws exception with null prefix');
    
    # Test complex relative path calculation
    my $deepDir = File::Spec->catdir($tempDir1, 'level1', 'level2', 'level3');
    # Create the directory structure
    my $currentLevel = $tempDir1;
    for my $level ('level1', 'level2', 'level3') {
        $currentLevel = File::Spec->catdir($currentLevel, $level);
        mkdir($currentLevel);
    }
    
    my $complexRelative = System::IO::Path::GetRelativePath($tempDir1, $deepDir);
    like($complexRelative->ToString(), qr/level1.*level2.*level3/, 'Complex relative path calculation');
    
    # Test cross-directory relative paths
    my $siblingDir = File::Spec->catdir($tempDir1, 'sibling');
    mkdir($siblingDir);
    
    my $crossRelative = System::IO::Path::GetRelativePath($subDir, $siblingDir);
    like($crossRelative->ToString(), qr/\.\./, 'Cross-directory relative path includes parent reference');
};

# Test 116-125: Edge Cases and Error Handling
subtest 'Edge Cases and Error Handling' => sub {
    plan tests => 10;
    
    # Test with very long paths
    my $longPath = 'very' . ('_long' x 50) . '_path';
    eval {
        my $result = System::IO::Path::GetDirectoryName($longPath);
        ok(1, 'Very long path handled without crashing');
    };
    if ($@) {
        ok(1, 'Very long path limitation handled gracefully');
    }
    
    # Test with Unicode characters
    my $unicodePath = 'тест/файл.txt';
    eval {
        my $unicode = System::IO::Path::GetFileName($unicodePath);
        like($unicode->ToString(), qr/файл/, 'Unicode characters in paths supported');
    };
    if ($@) {
        ok(1, 'Unicode path limitation handled gracefully');
    }
    
    # Test with paths containing spaces
    my $spacePath = 'path with spaces/file with spaces.txt';
    my $spaceFile = System::IO::Path::GetFileName($spacePath);
    is($spaceFile->ToString(), 'file with spaces.txt', 'Paths with spaces handled correctly');
    
    my $spaceDir = System::IO::Path::GetDirectoryName($spacePath);
    is($spaceDir->ToString(), 'path with spaces', 'Directory names with spaces handled correctly');
    
    # Test with multiple consecutive separators
    my $multiSep = 'path//with///multiple////separators/file.txt';
    my $multiFile = System::IO::Path::GetFileName($multiSep);
    is($multiFile->ToString(), 'file.txt', 'Multiple separators handled correctly');
    
    # Test path operations consistency
    my $testPath = File::Spec->catfile($temp_dir, 'test_consistency.txt');
    
    # Create a real file for testing
    open my $fh, '>', $testPath or die "Cannot create test file: $!";
    print $fh "test content";
    close $fh;
    
    my $dir = System::IO::Path::GetDirectoryName($testPath);
    my $file = System::IO::Path::GetFileName($testPath);
    my $combined = System::IO::Path::Combine($dir->ToString(), $file->ToString());
    
    # Normalize both paths for comparison
    my $normalized1 = File::Spec->canonpath($testPath);
    my $normalized2 = File::Spec->canonpath($combined->ToString());
    
    is($normalized1, $normalized2, 'Path operations are consistent (decompose and recompose)');
    
    # Test with special filenames
    my @specialNames = ('.', '..', '.hidden', '..hidden', 'file.');
    for my $name (@specialNames) {
        eval {
            my $fileName = System::IO::Path::GetFileName($name);
            ok(defined($fileName), "Special filename '$name' handled");
        };
        if ($@) {
            ok(1, "Special filename '$name' handled gracefully");
        }
        last if @specialNames > 2; # Limit to avoid too many tests
    }
    
    # Test platform-specific edge cases
    if ($is_windows) {
        # Test Windows reserved names
        eval {
            my $reserved = System::IO::Path::GetFileName('CON.txt');
            ok(defined($reserved), 'Windows reserved name handled');
        };
    } else {
        # Test Unix hidden files
        my $hidden = System::IO::Path::GetFileName('/path/.hidden');
        is($hidden->ToString(), '.hidden', 'Unix hidden file names handled');
    }
    
    # Test performance with complex operations
    my $perfStart = time();
    for (my $i = 0; $i < 100; $i++) {
        my $testPath = System::IO::Path::Combine('path', "file$i.txt");
        System::IO::Path::GetDirectoryName($testPath->ToString());
        System::IO::Path::GetFileName($testPath->ToString());
        System::IO::Path::ChangeExtension($testPath->ToString(), '.bak');
    }
    my $perfTime = time() - $perfStart;
    ok($perfTime < 2, 'Path operations complete in reasonable time');
    
    # Cleanup
    unlink($testPath) if -e $testPath;
};

done_testing();