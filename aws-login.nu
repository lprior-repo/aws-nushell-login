#!/usr/bin/env nu
# AWS CLI Login and Credential Export Script
# 
# This script handles AWS authentication via various methods (SSO, profile switching)
# and exports credentials for use in the current shell session
#
# Usage:
#   aws-login.nu [profile] [--sso] [--export-only] [--verbose]
#
# Examples:
#   aws-login.nu                    # Use default profile
#   aws-login.nu production --sso   # Login to production with SSO
#   aws-login.nu dev --export-only  # Just export existing credentials for dev profile

use std log

# Configuration constants
const DEFAULT_PROFILE = "default"
const AWS_CONFIG_DIR = "~/.aws"
const CREDENTIAL_TIMEOUT = 3600  # 1 hour in seconds

# AWS credential record type
def get_aws_credentials [profile: string]: nothing -> record {
    let credentials_file = $"($AWS_CONFIG_DIR)/credentials" | path expand
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    if not ($credentials_file | path exists) {
        error make {
            msg: "AWS credentials file not found"
            label: {
                text: $"Expected at: ($credentials_file)"
                span: (metadata $profile).span
            }
            help: "Run 'aws configure' to set up credentials"
        }
    }
    
    # Parse credentials file
    let credentials = try {
        open $credentials_file 
        | lines 
        | where $it != "" and not ($it | str starts-with "#")
        | reduce -f {} { |line, acc|
            if ($line | str starts-with "[") and ($line | str ends-with "]") {
                let section = $line | str replace -r '^\[(.+)\]$' '${1}'
                $acc | insert current_section $section
            } else if ($line | str contains "=") {
                let parts = $line | split column "=" key value | first
                let key = $parts.key | str trim
                let value = $parts.value | str trim
                let section = $acc.current_section? | default "default"
                
                if $section == $profile {
                    $acc | insert $key $value
                } else {
                    $acc
                }
            } else {
                $acc
            }
        }
    } catch { |e|
        error make {
            msg: $"Failed to parse AWS credentials file: ($e.msg)"
            help: "Check the format of ~/.aws/credentials"
        }
    }
    
    # Validate required fields
    let required_fields = ["aws_access_key_id", "aws_secret_access_key"]
    let missing_fields = $required_fields | where { |field| not ($field in ($credentials | columns)) }
    
    if ($missing_fields | length) > 0 {
        error make {
            msg: $"Missing AWS credentials for profile '($profile)'"
            label: {
                text: $"Missing fields: ($missing_fields | str join ', ')"
                span: (metadata $profile).span
            }
            help: "Run 'aws configure --profile ($profile)' to set up credentials"
        }
    }
    
    $credentials | reject current_section?
}

# Check if AWS CLI is installed and accessible
def check_aws_cli []: nothing -> bool {
    try {
        ^aws --version | complete | get exit_code | $in == 0
    } catch {
        false
    }
}

# Validate AWS credentials by making a test call
def validate_credentials [profile: string]: nothing -> record {
    log info $"Validating credentials for profile: ($profile)"
    
    let result = try {
        ^aws sts get-caller-identity --profile $profile 
        | complete
    } catch { |e|
        error make {
            msg: $"Failed to validate AWS credentials: ($e.msg)"
            help: "Check your AWS configuration and network connectivity"
        }
    }
    
    if $result.exit_code != 0 {
        error make {
            msg: "AWS credentials validation failed"
            label: {
                text: $result.stderr
                span: (metadata $profile).span
            }
            help: "Run 'aws configure --profile ($profile)' to fix credentials"
        }
    }
    
    try {
        $result.stdout | from json
    } catch {
        error make {
            msg: "Failed to parse AWS identity response"
            help: "AWS CLI may have returned unexpected output"
        }
    }
}

# Perform AWS SSO login
def sso_login [profile: string]: nothing -> nothing {
    log info $"Initiating SSO login for profile: ($profile)"
    
    let result = ^aws sso login --profile $profile | complete
    
    if $result.exit_code != 0 {
        error make {
            msg: "AWS SSO login failed"
            label: {
                text: $result.stderr
                span: (metadata $profile).span
            }
            help: "Check your SSO configuration in ~/.aws/config"
        }
    }
    
    log info "SSO login completed successfully"
}

# Export AWS credentials as environment variables
def export_credentials [credentials: record, profile: string]: nothing -> nothing {
    log info $"Exporting AWS credentials for profile: ($profile)"
    
    # Export standard AWS environment variables
    $env.AWS_PROFILE = $profile
    $env.AWS_ACCESS_KEY_ID = $credentials.aws_access_key_id
    $env.AWS_SECRET_ACCESS_KEY = $credentials.aws_secret_access_key
    
    # Export session token if available (for temporary credentials)
    if "aws_session_token" in ($credentials | columns) {
        $env.AWS_SESSION_TOKEN = $credentials.aws_session_token
    } else {
        # Clear any existing session token
        hide-env AWS_SESSION_TOKEN
    }
    
    # Export region if specified
    if "region" in ($credentials | columns) {
        $env.AWS_DEFAULT_REGION = $credentials.region
        $env.AWS_REGION = $credentials.region
    }
    
    # Set credential expiration warning
    let expiry_time = (date now) + ($CREDENTIAL_TIMEOUT | into duration --unit sec)
    $env.AWS_CREDENTIAL_EXPIRY = ($expiry_time | format date "%Y-%m-%d %H:%M:%S")
    
    print $"✅ AWS credentials exported for profile: (ansi green)($profile)(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default 'not set')(ansi reset)"
    print $"   Account: (ansi cyan)($credentials.account_id? | default 'unknown')(ansi reset)"
    print $"   Expires: (ansi yellow)($env.AWS_CREDENTIAL_EXPIRY)(ansi reset)"
}

# Get temporary credentials for a profile (useful for MFA/AssumeRole)
def get_temporary_credentials [profile: string]: nothing -> record {
    log info $"Getting temporary credentials for profile: ($profile)"
    
    let result = try {
        ^aws sts get-session-token --profile $profile --duration-seconds $CREDENTIAL_TIMEOUT 
        | complete
    } catch { |e|
        error make {
            msg: $"Failed to get temporary credentials: ($e.msg)"
        }
    }
    
    if $result.exit_code != 0 {
        # Try without session token (might not be needed)
        log warning "Failed to get session token, using existing credentials"
        return (get_aws_credentials $profile)
    }
    
    let temp_creds = try {
        $result.stdout | from json | get Credentials
    } catch {
        error make {
            msg: "Failed to parse temporary credentials response"
        }
    }
    
    {
        aws_access_key_id: $temp_creds.AccessKeyId
        aws_secret_access_key: $temp_creds.SecretAccessKey
        aws_session_token: $temp_creds.SessionToken
        account_id: (validate_credentials $profile | get Account)
    }
}

# Display current AWS credential status
def show_credential_status []: nothing -> nothing {
    print "\n📊 Current AWS Credential Status:"
    print $"   Profile: (ansi green)($env.AWS_PROFILE? | default 'not set')(ansi reset)"
    print $"   Access Key: (ansi cyan)($env.AWS_ACCESS_KEY_ID? | default 'not set' | str substring 0..8)...(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default 'not set')(ansi reset)"
    
    if "AWS_CREDENTIAL_EXPIRY" in $env {
        print $"   Expires: (ansi yellow)($env.AWS_CREDENTIAL_EXPIRY)(ansi reset)"
    }
    
    # Test current credentials
    try {
        let identity = ^aws sts get-caller-identity | complete
        if $identity.exit_code == 0 {
            let info = $identity.stdout | from json
            print $"   Account: (ansi green)($info.Account)(ansi reset)"
            print $"   User/Role: (ansi green)($info.Arn | split row '/' | last)(ansi reset)"
            print $"   Status: (ansi green)✓ Valid(ansi reset)"
        } else {
            print $"   Status: (ansi red)✗ Invalid or expired(ansi reset)"
        }
    } catch {
        print $"   Status: (ansi red)✗ Cannot validate(ansi reset)"
    }
}

# Main command function
def main [
    profile: string = $DEFAULT_PROFILE  # AWS profile to use
    --sso                              # Use AWS SSO login
    --export-only                      # Only export existing credentials, don't validate
    --temp                             # Get temporary credentials (useful for MFA)
    --status                           # Show current credential status
    --verbose                          # Enable verbose logging
]: nothing -> nothing {
    
    # Configure logging level
    if $verbose {
        $env.LOG_LEVEL = "DEBUG"
    }
    
    # Show status if requested
    if $status {
        show_credential_status
        return
    }
    
    # Check AWS CLI availability
    if not (check_aws_cli) {
        error make {
            msg: "AWS CLI not found"
            help: "Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        }
    }
    
    log info $"AWS Login starting for profile: ($profile)"
    
    try {
        # Handle SSO login if requested
        if $sso {
            sso_login $profile
        }
        
        # Get credentials (temporary or regular)
        let credentials = if $temp {
            get_temporary_credentials $profile
        } else if $export_only {
            get_aws_credentials $profile
        } else {
            # Validate credentials first, then get them
            validate_credentials $profile | ignore
            get_aws_credentials $profile
        }
        
        # Export credentials to environment
        export_credentials $credentials $profile
        
        # Show final status
        show_credential_status
        
        print $"\n🎉 (ansi green)AWS login completed successfully!(ansi reset)"
        print "   Credentials are now available in your shell environment."
        print "   Use AWS CLI commands normally, or check status with: aws-login --status"
        
    } catch { |error|
        log error $"AWS login failed: ($error.msg)"
        print $"❌ (ansi red)AWS login failed: ($error.msg)(ansi reset)"
        
        if "help" in ($error | columns) {
            print $"💡 (ansi yellow)($error.help)(ansi reset)"
        }
        
        exit 1
    }
}

# Utility function to clear AWS credentials from environment
export def clear_aws_env []: nothing -> nothing {
    hide-env AWS_PROFILE?
    hide-env AWS_ACCESS_KEY_ID?
    hide-env AWS_SECRET_ACCESS_KEY?
    hide-env AWS_SESSION_TOKEN?
    hide-env AWS_DEFAULT_REGION?
    hide-env AWS_REGION?
    hide-env AWS_CREDENTIAL_EXPIRY?
    
    print "🧹 AWS credentials cleared from environment"
}

# Utility function to list available AWS profiles
export def list_aws_profiles []: nothing -> table {
    let credentials_file = $"($AWS_CONFIG_DIR)/credentials" | path expand
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    mut profiles = []
    
    # Parse credentials file for profiles
    if ($credentials_file | path exists) {
        let cred_profiles = open $credentials_file 
        | lines 
        | where ($it | str starts-with "[") and ($it | str ends-with "]")
        | each { |line| 
            $line | str replace -r '^\[(.+)\]$' '${1}'
        }
        $profiles = ($profiles | append $cred_profiles)
    }
    
    # Parse config file for profiles  
    if ($config_file | path exists) {
        let conf_profiles = open $config_file
        | lines
        | where ($it | str starts-with "[profile ") and ($it | str ends-with "]")
        | each { |line|
            $line | str replace -r '^\[profile (.+)\]$' '${1}'
        }
        $profiles = ($profiles | append $conf_profiles)
    }
    
    $profiles 
    | uniq 
    | sort 
    | each { |profile| 
        {
            profile: $profile
            type: (if ($profile | str contains "sso") { "SSO" } else { "Standard" })
        }
    }
}