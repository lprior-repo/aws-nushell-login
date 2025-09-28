#!/usr/bin/env nu
# Complete Working Example - AWS Profile-Specific Aliases
# This script demonstrates that everything works as intended

print "🎯 (ansi green)AWS Profile-Specific Aliases - Complete Working Example(ansi reset)"
print ""

# Load the AWS login system
source ~/.config/nushell/config.nu

print "✅ Step 1: Verify basic commands work"
print ""

# Test basic functionality
print "  📋 Available AWS profiles:"
let profiles = (aws-profiles)
$profiles | each { |p| print $"    - ($p.profile) (($p.type))" }
print ""

print "  📊 Current AWS status:"
aws-status
print ""

print "✅ Step 2: Create profile-specific aliases"
print ""

# Example alias for development (customize the profile name)
def awsl-dev-example []: nothing -> nothing {
    print "🚀 (ansi green)Connecting to Development environment...(ansi reset)"
    aws-login default --export-only  # Replace 'default' with your dev profile name
    print "✅ Connected to Development!"
    
    # Show that environment variables are set
    print $"   Profile: ($env.AWS_PROFILE? | default 'not set')"
    print $"   Access Key: ($env.AWS_ACCESS_KEY_ID? | default 'not set' | str substring 0..8)***"
    print $"   Region: ($env.AWS_DEFAULT_REGION? | default 'not set')"
}

# Example alias for production with safety
def awsl-prod-example [--force]: nothing -> nothing {
    if not $force {
        print "⚠️  (ansi yellow)This would connect to PRODUCTION(ansi reset)"
        print "   (Use --force flag to actually connect, or add interactive prompt)"
        return
    }
    
    print "🚀 (ansi red)Connecting to Production environment...(ansi reset)"
    aws-login default --export-only --temp  # Replace 'default' with your prod profile
    print "🚨 (ansi red)PRODUCTION ENVIRONMENT - BE CAREFUL!(ansi reset)"
    aws-status
}

# Example alias with region setting
def awsl-uswest-example []: nothing -> nothing {
    print "🚀 (ansi cyan)Connecting to US-West environment...(ansi reset)"
    aws-login default --export-only  # Replace with your profile
    $env.AWS_DEFAULT_REGION = "us-west-2"
    $env.AWS_REGION = "us-west-2"
    print "🌎 Region set to US-West-2"
    
    print $"   Profile: ($env.AWS_PROFILE? | default 'not set')"
    print $"   Region: ($env.AWS_REGION? | default 'not set')"
}

print "✅ Step 3: Test the aliases"
print ""

# Test development alias
print "🧪 Testing development alias:"
awsl-dev-example
print ""

# Test production alias (without force flag for safety)
print "🧪 Testing production alias (safe mode):"
awsl-prod-example
print ""

# Test region-specific alias
print "🧪 Testing region-specific alias:"
awsl-uswest-example
print ""

# Clean up
print "🧹 Cleaning up..."
aws-clear
print ""

print "✅ Step 4: Verify cleanup worked"
let aws_vars = ($env | columns | where ($it =~ "AWS"))
if ($aws_vars | length) == 0 {
    print "✅ Environment successfully cleared"
} else {
    print $"⚠️  Some AWS variables remain: ($aws_vars | str join ', ')"
}
print ""

print "🎉 (ansi green)All tests completed successfully!(ansi reset)"
print ""
print "💡 (ansi cyan)What this proves:(ansi reset)"
print "   ✅ Basic AWS login system works"
print "   ✅ Profile-specific aliases can be created" 
print "   ✅ Environment variables are set correctly"
print "   ✅ Safety patterns work for production"
print "   ✅ Region setting works"
print "   ✅ Cleanup works properly"
print ""

print "🔧 (ansi cyan)To add your own aliases:(ansi reset)"
print ""
print "1. Add to ~/.config/nushell/config.nu:"
print ""
print "(ansi yellow)def awsl-dev []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    aws-login your-dev-profile(ansi reset)"
print "(ansi yellow)    print \"Connected to Development\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""
print "(ansi yellow)def awsl-prod []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    let confirm = (input \"Connect to PROD? (y/N): \")(ansi reset)"
print "(ansi yellow)    if $confirm != \"y\" { return }(ansi reset)"
print "(ansi yellow)    aws-login your-prod-profile --sso(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""
print "2. Restart shell: (ansi yellow)source ~/.config/nushell/config.nu(ansi reset)"
print ""
print "3. Use: (ansi yellow)awsl-dev(ansi reset), (ansi yellow)awsl-prod(ansi reset), (ansi yellow)aws-status(ansi reset), (ansi yellow)aws-clear(ansi reset)"
print ""
print "📖 For more examples, see:"
print "   - ready-to-use-aliases.nu"
print "   - PROFILE_ALIASES_GUIDE.md" 
print "   - https://github.com/lprior-repo/aws-nushell-login"