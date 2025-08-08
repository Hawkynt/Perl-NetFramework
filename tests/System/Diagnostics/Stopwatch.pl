#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use Time::HiRes qw(sleep);

# Define constants
use constant true => 1;
use constant false => 0;

# Import the classes we need
use System::Diagnostics::Stopwatch;

BEGIN {
    use_ok('System::Diagnostics::Stopwatch');
}

sub test_stopwatch_creation {
    my $sw = System::Diagnostics::Stopwatch->new();
    isa_ok($sw, 'System::Diagnostics::Stopwatch', 'Stopwatch creation');
    ok(!$sw->IsRunning(), 'New stopwatch is not running');
    is($sw->ElapsedMilliseconds(), 0, 'New stopwatch has zero elapsed time');
}

sub test_stopwatch_start_stop {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    $sw->Start();
    ok($sw->IsRunning(), 'Stopwatch is running after Start');
    
    sleep(0.1); # Sleep 100ms
    
    $sw->Stop();
    ok(!$sw->IsRunning(), 'Stopwatch is not running after Stop');
    
    my $elapsed = $sw->ElapsedMilliseconds();
    ok($elapsed >= 90 && $elapsed <= 150, 'Elapsed time is approximately correct');
}

sub test_stopwatch_restart {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    $sw->Start();
    sleep(0.05);
    $sw->Stop();
    
    my $firstElapsed = $sw->ElapsedMilliseconds();
    ok($firstElapsed > 0, 'First measurement has elapsed time');
    
    $sw->Restart();
    ok($sw->IsRunning(), 'Stopwatch is running after Restart');
    
    # Immediately check that restart reset the elapsed time
    my $restartElapsed = $sw->ElapsedMilliseconds();
    ok($restartElapsed < $firstElapsed, 'Restart resets the timer');
    
    $sw->Stop();
}

sub test_stopwatch_reset {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    $sw->Start();
    sleep(0.05);
    $sw->Stop();
    
    ok($sw->ElapsedMilliseconds() > 0, 'Has elapsed time before reset');
    
    $sw->Reset();
    ok(!$sw->IsRunning(), 'Stopwatch is not running after Reset');
    is($sw->ElapsedMilliseconds(), 0, 'Elapsed time is zero after Reset');
}

sub test_stopwatch_static_methods {
    my $sw = System::Diagnostics::Stopwatch->StartNew();
    isa_ok($sw, 'System::Diagnostics::Stopwatch', 'StartNew returns Stopwatch');
    ok($sw->IsRunning(), 'StartNew creates running stopwatch');
    
    $sw->Stop();
    
    my $frequency = System::Diagnostics::Stopwatch::Frequency();
    ok($frequency > 0, 'Frequency returns positive value');
    
    ok(System::Diagnostics::Stopwatch::IsHighResolution(), 'IsHighResolution returns true');
    
    my $timestamp1 = System::Diagnostics::Stopwatch::GetTimestamp();
    sleep(0.001); # Sleep 1ms
    my $timestamp2 = System::Diagnostics::Stopwatch::GetTimestamp();
    ok($timestamp2 > $timestamp1, 'GetTimestamp values increase over time');
}

sub test_stopwatch_elapsed_properties {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    $sw->Start();
    sleep(0.1);
    $sw->Stop();
    
    my $ticks = $sw->ElapsedTicks();
    my $milliseconds = $sw->ElapsedMilliseconds();
    my $timespan = $sw->Elapsed();
    
    ok($ticks > 0, 'ElapsedTicks returns positive value');
    ok($milliseconds > 0, 'ElapsedMilliseconds returns positive value');
    isa_ok($timespan, 'System::TimeSpan', 'Elapsed returns TimeSpan');
}

sub test_stopwatch_microseconds {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    $sw->Start();
    sleep(0.001); # 1ms
    $sw->Stop();
    
    my $microseconds = $sw->ElapsedMicroseconds();
    ok($microseconds > 0, 'ElapsedMicroseconds returns positive value');
    ok($microseconds > $sw->ElapsedMilliseconds(), 'Microseconds > milliseconds');
}

sub test_stopwatch_multiple_sessions {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    # First session
    $sw->Start();
    sleep(0.01);
    $sw->Stop();
    my $firstElapsed = $sw->ElapsedMilliseconds();
    
    # Second session (should accumulate)
    $sw->Start();
    sleep(0.01);
    $sw->Stop();
    my $totalElapsed = $sw->ElapsedMilliseconds();
    
    ok($totalElapsed > $firstElapsed, 'Multiple sessions accumulate time');
}

sub test_stopwatch_idempotent_operations {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    # Multiple starts should be safe
    $sw->Start();
    ok($sw->IsRunning(), 'Running after first start');
    $sw->Start(); # Should be ignored
    ok($sw->IsRunning(), 'Still running after second start');
    
    # Multiple stops should be safe
    $sw->Stop();
    ok(!$sw->IsRunning(), 'Not running after first stop');
    $sw->Stop(); # Should be ignored
    ok(!$sw->IsRunning(), 'Still not running after second stop');
}

test_stopwatch_creation();
test_stopwatch_start_stop();
test_stopwatch_restart();
test_stopwatch_reset();
test_stopwatch_static_methods();
test_stopwatch_elapsed_properties();
test_stopwatch_microseconds();
test_stopwatch_multiple_sessions();
test_stopwatch_idempotent_operations();

done_testing();