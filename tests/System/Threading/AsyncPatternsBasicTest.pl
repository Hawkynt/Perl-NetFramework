#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

# Test plan: basic verification of all four async programming models
plan tests => 18;

# ============================================================================
# 1. APM (Asynchronous Programming Model) - Basic functionality test
# ============================================================================

# Test IAsyncResult and AsyncResult classes
{
  require System::IAsyncResult;
  require System::Threading::AsyncResult;
  
  my $asyncResult = System::Threading::AsyncResult->new(undef, "test_state");
  ok(defined($asyncResult), 'AsyncResult can be created');
  ok($asyncResult->isa('System::IAsyncResult'), 'AsyncResult implements IAsyncResult');
  is($asyncResult->AsyncState(), "test_state", 'AsyncState preserved correctly');
  ok(!$asyncResult->IsCompleted(), 'AsyncResult initially not completed');
  
  # Test completion
  $asyncResult->_SetCompleted("test_result", undef, 1);
  ok($asyncResult->IsCompleted(), 'AsyncResult completed after _SetCompleted');
  ok($asyncResult->CompletedSynchronously(), 'AsyncResult completed synchronously');
  is($asyncResult->_GetResult(), "test_result", 'AsyncResult returns correct result');
}

# ============================================================================
# 2. EAP (Event-based Asynchronous Pattern) - Basic functionality test  
# ============================================================================

# Test AsyncCompletedEventArgs and ProgressChangedEventArgs
{
  require System::ComponentModel::AsyncCompletedEventArgs;
  require System::ComponentModel::ProgressChangedEventArgs;
  
  my $completedArgs = System::ComponentModel::AsyncCompletedEventArgs->new(undef, 0, "user_state");
  ok(defined($completedArgs), 'AsyncCompletedEventArgs can be created');
  is($completedArgs->UserState(), "user_state", 'AsyncCompletedEventArgs UserState correct');
  ok(!$completedArgs->Cancelled(), 'AsyncCompletedEventArgs not cancelled');
  ok(!defined($completedArgs->Error()), 'AsyncCompletedEventArgs has no error');
  
  my $progressArgs = System::ComponentModel::ProgressChangedEventArgs->new(50, "progress_state");
  ok(defined($progressArgs), 'ProgressChangedEventArgs can be created');
  is($progressArgs->ProgressPercentage(), 50, 'ProgressChangedEventArgs percentage correct');
  is($progressArgs->UserState(), "progress_state", 'ProgressChangedEventArgs UserState correct');
}

# ============================================================================
# 3. CB (Callback-Based) - Basic functionality test
# ============================================================================

# Test CallbackPatterns utility class
{
  require System::Threading::CallbackPatterns;
  
  ok(defined(&System::Threading::CallbackPatterns::ExecuteAsync), 'CallbackPatterns ExecuteAsync method exists');
  ok(defined(&System::Threading::CallbackPatterns::ExecuteWithTimeoutAsync), 'CallbackPatterns ExecuteWithTimeoutAsync method exists');
}

# ============================================================================
# 4. TPL (Task Parallel Library) - Basic functionality test
# ============================================================================

# Test Task creation and basic properties
{
  require System::Threading::Tasks::Task;
  
  my $task = System::Threading::Tasks::Task->new(sub { return "test"; });
  ok(defined($task), 'Task can be created');
  ok(!$task->IsCompleted(), 'Task initially not completed');
}

done_testing();