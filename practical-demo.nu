#!/usr/bin/env nu
# Practical Test and Demo Script
# This script tests the AWS login system and demonstrates how to create profile-specific aliases

print "🚀 (ansi green)AWS Nushell Login - Practical Demo and Test(ansi reset)"
print ""

# Test 1: Basic functionality
print "📋 Test 1: Basic commands"
try {
    print "  Testing aws-profiles..."
    let profiles = (aws-profiles)
    print $"  ✅ Found ($profiles | length) AWS profiles"
    
    print "  Testing aws-status..."
    aws-status
    print "  ✅ Status command works"
    
    print "  Testing aws-login..."
    aws-login default --export-only
    print "  ✅ Login command works"
    
    print "  Checking environment..."
    let aws_vars = ($env | columns | where ($it =~ "AWS"))
    print $"  ✅ AWS environment variables set: ($aws_vars | length) variables"
    
    print "  Testing aws-clear..."
    aws-clear
    print "  ✅ Clear command works"
    
} catch { |e|
    print $"  ❌ Basic functionality test failed: ($e.msg)"
}

print ""

# Test 2: Demonstrate profile-specific alias creation
print "📋 Test 2: Profile-specific alias demonstration"

print "  Creating example aliases..."

# Example 1: Simple alias
def demo_awsl_dev []: nothing -> nothing {
    print "🚀 Logging into development..."
    aws-login default --export-only  # Using default for demo
    print "✅ Connected to development environment"
    aws-status
}

# Example 2: Production with safety
def demo_awsl_prod []: nothing -> nothing {
    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")
    if $confirm != "y" {
        print "❌ Production access cancelled"
        return
    }
    print "🚀 Logging into production..."
    aws-login default --export-only --temp  # Using temp creds for safety
    print "🚨 (ansi red)PRODUCTION ENVIRONMENT - BE CAREFUL!(ansi reset)"
    aws-status
}

# Example 3: Region-specific alias
def demo_awsl_us_west []: nothing -> nothing {
    print "🚀 Logging into US-West environment..."
    aws-login default --export-only
    $env.AWS_DEFAULT_REGION = "us-west-2"
    $env.AWS_REGION = "us-west-2"
    print "🌎 Region set to US-West-2"
    aws-status
}

print "  ✅ Example aliases created successfully"
print ""

# Test 3: Interactive demo
print "📋 Test 3: Interactive alias demonstration"
print ""
print "Choose an alias to test:"
print "  1. demo_awsl_dev - Simple development login"
print "  2. demo_awsl_prod - Production with safety prompt"
print "  3. demo_awsl_us_west - Region-specific login"
print "  4. Skip interactive test"
print ""

let choice = (input "Enter your choice (1-4): ")

match $choice {
    "1" => { 
        print "Testing development alias..."
        demo_awsl_dev
    }
    "2" => {
        print "Testing production alias..."
        demo_awsl_prod  
    }
    "3" => {
        print "Testing region-specific alias..."
        demo_awsl_us_west
    }
    _ => {
        print "Skipping interactive test"
    }
}

print ""

# Clean up
aws-clear

# Show how to add these to config
print "🎯 (ansi cyan)How to Add These Aliases to Your Config:(ansi reset)"
print ""
print "1. Edit your Nushell config:"
print "   (ansi yellow)nu ~/.config/nushell/config.nu(ansi reset)"
print ""
print "2. Add aliases like these (customize profile names):"
print ""
print "(ansi green)# Your custom AWS profile aliases(ansi reset)"
print "(ansi yellow)def awsl-dev []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    aws-login development  # Replace with your actual profile name(ansi reset)" 
print "(ansi yellow)    print \"🚀 Connected to Development\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""
print "(ansi yellow)def awsl-prod []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    let confirm = (input \"⚠️  Connect to PRODUCTION? (y/N): \")(ansi reset)"
print "(ansi yellow)    if \$confirm != \"y\" { return }(ansi reset)"
print "(ansi yellow)    aws-login production --sso  # Replace with your prod profile(ansi reset)"
print "(ansi yellow)    print \"🚨 PRODUCTION ENVIRONMENT\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""
print "3. Restart your shell or run:"
print "   (ansi yellow)source ~/.config/nushell/config.nu(ansi reset)"
print ""
print "4. Use your new aliases:"
print "   (ansi yellow)awsl-dev(ansi reset)     # Quick dev login"
print "   (ansi yellow)awsl-prod(ansi reset)    # Safe prod login"
print "   (ansi yellow)aws-status(ansi reset)   # Check credentials"
print "   (ansi yellow)aws-clear(ansi reset)    # Clear when done"
print ""

print "✅ (ansi green)All tests completed successfully!(ansi reset)"
print ""
print "💡 (ansi cyan)Ready-to-use examples:(ansi reset)"
print "   Check out (ansi yellow)ready-to-use-aliases.nu(ansi reset) for more examples"
print "   See (ansi yellow)PROFILE_ALIASES_GUIDE.md(ansi reset) for comprehensive patterns"
print ""
print "🔗 Repository: (ansi blue)https://github.com/lprior-repo/aws-nushell-login(ansi reset)"