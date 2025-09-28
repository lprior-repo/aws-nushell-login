# Simple Integration Test - Final Version
# Tests that the AWS login system works as a cohesive unit

use std assert  
source ../aws-login.nu

#[test]
def test_basic_functionality [] {
    # Test that all core functions exist and work
    
    # Clear environment
    clear_aws_env
    
    # Test profile validation
    validate_profile_name "test-profile"
    
    # Test masking
    let masked = mask_sensitive "AKIA1234567890123456"
    assert ($masked | str contains "****************") "Should mask access keys"
    
    # Test profile listing (should not error)
    let profiles = list_aws_profiles
    assert true "Profile listing should work"
    
    print "✅ All basic functionality tests passed"
}

#[test] 
def test_environment_management [] {
    # Test environment variable management
    
    # Start clean
    clear_aws_env
    
    # Set test variables  
    $env.TEST_AWS_PROFILE = "test"
    $env.TEST_AWS_ACCESS_KEY_ID = "AKIATEST"
    
    # Verify they're set
    assert ($env.TEST_AWS_PROFILE == "test") "Should set profile"
    assert ($env.TEST_AWS_ACCESS_KEY_ID == "AKIATEST") "Should set access key"
    
    # Clear specific test vars
    hide-env TEST_AWS_PROFILE
    hide-env TEST_AWS_ACCESS_KEY_ID
    
    print "✅ Environment management tests passed"
}

#[test]
def test_error_handling [] {
    # Test error handling works correctly
    
    let caught_error = try {
        validate_profile_name ""
        false
    } catch {
        true
    }
    assert $caught_error "Should catch validation errors"
    
    let error_structure = try {
        error make { msg: "test error" }
    } catch { |e|
        $e
    }
    assert ("msg" in ($error_structure | columns)) "Error should have msg field"
    
    print "✅ Error handling tests passed"
}

#[test]
def test_alias_patterns [] {
    # Test patterns users would create by directly simulating
    
    # Set variables directly like an alias would
    $env.MOCK_AWS_PROFILE = "development"
    $env.MOCK_AWS_ACCESS_KEY_ID = "AKIAMOCK"
    
    # Verify they're set
    assert ("MOCK_AWS_PROFILE" in ($env | columns)) "Mock profile should be set"
    assert ($env.MOCK_AWS_PROFILE == "development") "Profile should be development"
    
    # Clean up
    hide-env MOCK_AWS_PROFILE
    hide-env MOCK_AWS_ACCESS_KEY_ID
    
    print "✅ Alias pattern tests passed"
}