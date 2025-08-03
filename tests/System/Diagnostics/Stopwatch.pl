#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use Time::HiRes qw(sleep);

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
    
    sleep(0.05);
    $sw->Stop();
    
    my $secondElapsed = $sw->ElapsedMilliseconds();
    ok($secondElapsed < $firstElapsed, 'Restart resets the timer');
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
    my $sw = Stopwatch::StartNew();
    isa_ok($sw, 'System::Diagnostics::Stopwatch', 'StartNew returns Stopwatch');
    ok($sw->IsRunning(), 'StartNew creates running stopwatch');
    
    $sw->Stop();
    
    my $frequency = Stopwatch::Frequency();
    ok($frequency > 0, 'Frequency returns positive value');
    
    ok(Stopwatch::IsHighResolution(), 'IsHighResolution returns true');
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

test_stopwatch_creation();
test_stopwatch_start_stop();
test_stopwatch_restart();
test_stopwatch_reset();
test_stopwatch_static_methods();
test_stopwatch_elapsed_properties();

done_testing();