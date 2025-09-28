#!/usr/bin/env nu
# AWS Nushell Login - Comprehensive Examples and Patterns
# Copy and paste these patterns for common AWS profile management scenarios

source ./aws-login.nu

# =============================================================================
# BASIC PROFILE ALIASES (Most Common Pattern)
# =============================================================================

# Simple development environment alias
export def awsl-dev []: nothing -> nothing {
    aws-login development
    print "🚀 Connected to Development Environment"
    aws-status
}

# Simple staging environment alias  
export def awsl-staging []: nothing -> nothing {
    aws-login staging
    print "🔄 Connected to Staging Environment"
    aws-status
}

# Production alias with confirmation safety
export def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")
    if $confirm != "y" { 
        print "❌ Production connection cancelled"
        return 
    }
    aws-login production --sso  # Force SSO for production
    print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
    aws-status
}

# =============================================================================
# SSO-SPECIFIC ALIASES
# =============================================================================

# SSO Development with automatic re-login
export def awsl-sso-dev []: nothing -> nothing {
    print "🔐 Connecting to SSO Development..."
    aws-login sso-development --sso
    print "✅ SSO Development Ready"
    aws-status
}

# SSO Production with extra safety
export def awsl-sso-prod []: nothing -> nothing {
    print "⚠️  SSO PRODUCTION LOGIN"
    let confirm = (input "Type 'production' to confirm: ")
    if $confirm != "production" {
        print "❌ Confirmation failed - cancelling"
        return
    }
    aws-login sso-production --sso
    print "🔒 SSO Production Active - Exercise Extreme Caution"
    aws-status
}

# =============================================================================
# CONFIGURATION EXAMPLES
# =============================================================================

# Example ~/.aws/config for SSO
export def show-sso-config-example []: nothing -> nothing {
    print "📋 Example ~/.aws/config for AWS SSO:"
    print ""
    print "[default]"
    print "region = us-east-1"
    print "output = json"
    print ""
    print "[profile sso-development]"
    print "sso_start_url = https://your-org.awsapps.com/start"
    print "sso_region = us-east-1"  
    print "sso_account_id = 123456789012"
    print "sso_role_name = DeveloperRole"
    print "region = us-east-1"
    print "output = json"
    print ""
    print "[profile sso-production]"
    print "sso_start_url = https://your-org.awsapps.com/start"
    print "sso_region = us-east-1"
    print "sso_account_id = 123456789012"
    print "sso_role_name = AdministratorRole" 
    print "region = us-west-2"
    print "output = json"
}

# Example ~/.aws/credentials for traditional profiles
export def show-credentials-example []: nothing -> nothing {
    print "📋 Example ~/.aws/credentials for traditional profiles:"
    print ""
    print "[default]"
    print "aws_access_key_id = AKIAIOSFODNN7EXAMPLE"
    print "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    print ""
    print "[development]"  
    print "aws_access_key_id = AKIAI44QH8DHBEXAMPLE"
    print "aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY"
    print ""
    print "[production]"
    print "aws_access_key_id = AKIAIOSFODNN7ANOTHER"  
    print "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    print ""
    print "⚠️  Note: Never commit real credentials to version control!"
}