#!/usr/bin/env nu
# Test Script for AWS Nushell Login System
# This script tests all the functionality to ensure it works as intended

use std log

const TEST_PROFILE = "default"

# Test functions
def test_step [name: string, test_func: closure]: nothing -> record {
    print $"🧪 Testing: (ansi cyan)($name)(ansi reset)"
    
    try {
        do $test_func
        print $"   ✅ (ansi green)PASSED(ansi reset): ($name)"
        {test: $name, status: "PASSED", error: null}
    } catch { |e|
        print $"   ❌ (ansi red)FAILED(ansi reset): ($name) - ($e.msg)"
        {test: $name, status: "FAILED", error: $e.msg}
    }
}

def test_basic_commands []: nothing -> nothing {
    # Test help
    let help_result = (^nu ~/bin/aws-login.nu --help | complete)
    if $help_result.exit_code != 0 {
        error make { msg: "Help command failed" }
    }
    
    # Test profiles listing
    let profiles = (aws-profiles)
    if ($profiles | describe) != "table" {
        error make { msg: "aws-profiles did not return a table" }
    }
    
    # Test status command
    aws-status
}

def test_credential_export []: nothing -> nothing {
    # Clear environment first
    aws-clear
    
    # Test credential export
    aws-login $TEST_PROFILE --export-only
    
    # Check if credentials were exported
    let aws_profile_set = ("AWS_PROFILE" in ($env | columns))
    let aws_access_key_set = ("AWS_ACCESS_KEY_ID" in ($env | columns))
    let aws_secret_key_set = ("AWS_SECRET_ACCESS_KEY" in ($env | columns))
    
    if not ($aws_profile_set and $aws_access_key_set and $aws_secret_key_set) {
        error make { msg: "AWS credentials not properly exported to environment" }
    }
}

def test_alias_creation []: nothing -> nothing {
    # Test that we can create and use an alias
    # This simulates what a user would do
    
    # First clear any existing credentials
    aws-clear
    
    # Create a temporary alias function for testing
    def test_alias []: nothing -> nothing {
        aws-login $TEST_PROFILE --export-only
    }
    
    # Run the alias
    test_alias
    
    # Verify it worked
    let aws_profile_set = ("AWS_PROFILE" in ($env | columns))
    if not $aws_profile_set {
        error make { msg: "Profile-specific alias did not set credentials" }
    }
}

def test_environment_cleanup []: nothing -> nothing {
    # Set some AWS environment variables
    aws-login $TEST_PROFILE --export-only
    
    # Verify they're set
    let vars_set = ("AWS_PROFILE" in ($env | columns)) and ("AWS_ACCESS_KEY_ID" in ($env | columns))
    if not $vars_set {
        error make { msg: "Prerequisites not met - credentials not set" }
    }
    
    # Clear them
    aws-clear
    
    # Verify they're cleared
    let aws_profile_cleared = not ("AWS_PROFILE" in ($env | columns))
    let aws_access_key_cleared = not ("AWS_ACCESS_KEY_ID" in ($env | columns))
    
    if not ($aws_profile_cleared and $aws_access_key_cleared) {
        error make { msg: "Environment variables not properly cleared" }
    }
}

def test_profile_specific_alias [profile: string]: nothing -> nothing {
    # Create and test a profile-specific alias
    def test_profile_alias []: nothing -> nothing {
        aws-login $profile --export-only
        aws-status
    }
    
    # Run the alias
    test_profile_alias
    
    # Verify the profile was set correctly
    if $env.AWS_PROFILE != $profile {
        error make { msg: $"Profile not set correctly. Expected ($profile), got ($env.AWS_PROFILE? | default 'none')" }
    }
}

def test_production_safety_pattern []: nothing -> nothing {
    # Test a production-style safety function
    def test_prod_alias [confirm: bool]: nothing -> nothing {
        if not $confirm {
            print "❌ Production access cancelled"
            return
        }
        aws-login $TEST_PROFILE --export-only
        print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
    }
    
    # Test cancellation
    test_prod_alias false
    let profile_not_set = not ("AWS_PROFILE" in ($env | columns))
    if not $profile_not_set {
        error make { msg: "Production safety pattern failed - credentials were set when they should not have been" }
    }
    
    # Test confirmation
    test_prod_alias true
    let profile_is_set = ("AWS_PROFILE" in ($env | columns))
    if not $profile_is_set {
        error make { msg: "Production safety pattern failed - credentials were not set when they should have been" }
    }
}

def test_region_setting []: nothing -> nothing {
    # Test region-specific alias pattern
    def test_region_alias [profile: string, region: string]: nothing -> nothing {
        aws-login $profile --export-only
        $env.AWS_DEFAULT_REGION = $region
        $env.AWS_REGION = $region
    }
    
    test_region_alias $TEST_PROFILE "us-west-2"
    
    if $env.AWS_DEFAULT_REGION != "us-west-2" or $env.AWS_REGION != "us-west-2" {
        error make { msg: "Region not set correctly" }
    }
}

def test_aws_cli_integration []: nothing -> nothing {
    # Test that AWS CLI can use the exported credentials
    aws-login $TEST_PROFILE --export-only
    
    # Test AWS CLI call
    let result = (^aws sts get-caller-identity | complete)
    if $result.exit_code != 0 {
        error make { msg: $"AWS CLI integration failed: ($result.stderr)" }
    }
    
    # Parse the result to verify it works
    let identity = ($result.stdout | from json)
    if not ("Account" in ($identity | columns)) {
        error make { msg: "AWS CLI call succeeded but returned unexpected format" }
    }
}

# Main test runner
def main [
    --verbose (-v)    # Verbose output
    --profile (-p): string = $TEST_PROFILE  # Profile to test with
]: nothing -> nothing {
    
    if $verbose {
        $env.LOG_LEVEL = "DEBUG"
    }
    
    print "🚀 (ansi green)AWS Nushell Login System - Comprehensive Test Suite(ansi reset)"
    print $"   Testing with profile: (ansi cyan)($profile)(ansi reset)"
    print ""
    
    # Define all tests
    let tests = [
        {name: "Basic Commands", func: {|| test_basic_commands }}
        {name: "Credential Export", func: {|| test_credential_export }}
        {name: "Alias Creation", func: {|| test_alias_creation }}
        {name: "Environment Cleanup", func: {|| test_environment_cleanup }}
        {name: "Profile-Specific Alias", func: {|| test_profile_specific_alias $profile }}
        {name: "Production Safety Pattern", func: {|| test_production_safety_pattern }}
        {name: "Region Setting", func: {|| test_region_setting }}
        {name: "AWS CLI Integration", func: {|| test_aws_cli_integration }}
    ]
    
    # Run all tests
    let results = ($tests | each { |test|
        test_step $test.name $test.func
    })
    
    # Clean up after tests
    try { aws-clear } catch { }
    
    # Summary
    print ""
    print "📊 (ansi cyan)Test Results Summary:(ansi reset)"
    let passed = ($results | where status == "PASSED" | length)
    let failed = ($results | where status == "FAILED" | length)
    let total = ($results | length)
    
    $results | each { |result|
        let status_color = if $result.status == "PASSED" { "green" } else { "red" }
        let status_icon = if $result.status == "PASSED" { "✅" } else { "❌" }
        print $"   ($status_icon) ($result.test): (ansi $status_color)($result.status)(ansi reset)"
        if $result.error != null {
            print $"      Error: ($result.error)"
        }
    }
    
    print ""
    if $failed == 0 {
        print $"🎉 (ansi green)ALL TESTS PASSED!(ansi reset) ($passed)/($total)"
        print ""
        print "✅ Your AWS Nushell Login system is working correctly!"
        print "✅ Profile-specific aliases will work as intended!"
        print "✅ You can create aliases like 'awsl-dev', 'awsl-prod' etc."
        print ""
        print "💡 Next steps:"
        print "   1. Add your desired aliases to ~/.config/nushell/config.nu"
        print "   2. Restart your shell"
        print "   3. Use your new aliases!"
    } else {
        print $"❌ (ansi red)SOME TESTS FAILED!(ansi reset) ($passed) passed, ($failed) failed out of ($total)"
        print ""
        print "🔧 Please fix the issues above before using the system."
        exit 1
    }
}

# Quick test function for CI/automation
export def quick_test []: nothing -> nothing {
    print "🔍 Quick functionality test..."
    
    try {
        aws-profiles | ignore
        aws-login default --export-only
        aws-status | ignore
        aws-clear
        print "✅ Quick test passed!"
    } catch { |e|
        print $"❌ Quick test failed: ($e.msg)"
        exit 1
    }
}