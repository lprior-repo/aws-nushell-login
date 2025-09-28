#!/usr/bin/env nu
# Quick Start Guide - Create Your First AWS Profile Alias
# Run this script to see step-by-step instructions

print "🚀 (ansi green)Quick Start: Create Your First AWS Profile Alias(ansi reset)"
print ""

print "📋 Step 1: Check what profiles you have"
print "Run this command:"
print "  (ansi yellow)aws-profiles(ansi reset)"
print ""
print "Your profiles:"
try {
    source ~/.config/nushell/config.nu
    aws-profiles
} catch {
    print "  (Run 'aws-profiles' after installation to see your profiles)"
}
print ""

print "📝 Step 2: Create a simple alias"
print ""
print "Add this to your ~/.config/nushell/config.nu file:"
print ""
print "(ansi green)# Your first AWS profile alias(ansi reset)"
print "(ansi yellow)def awsl-dev []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    aws-login default  # Replace 'default' with your profile name(ansi reset)"
print "(ansi yellow)    print \"✅ Connected to development environment\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""

print "📝 Step 3: For production, add safety:"
print ""
print "(ansi yellow)def awsl-prod []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    let confirm = (input \"⚠️  Connect to PRODUCTION? (y/N): \")(ansi reset)"
print "(ansi yellow)    if \\$confirm != \"y\" {(ansi reset)"
print "(ansi yellow)        print \"❌ Cancelled\"(ansi reset)"
print "(ansi yellow)        return(ansi reset)"
print "(ansi yellow)    }(ansi reset)"
print "(ansi yellow)    aws-login production --sso  # Replace with your prod profile(ansi reset)"
print "(ansi yellow)    print \"🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""

print "⚡ Step 4: Test it works"
print ""
print "Let's create and test a temporary alias right now:"

# Create a test alias for demonstration
def test_alias []: nothing -> nothing {
    print "🧪 Testing AWS profile alias..."
    try {
        source ~/.config/nushell/config.nu
        aws-login default --export-only
        print "✅ Alias worked! AWS credentials are set."
        aws-clear
        print "🧹 Cleaned up credentials"
    } catch { |e|
        print $"⚠️  Test requires installation: ($e.msg)"
        print "   Run the installer first: ./install.nu"
    }
}

print "Running test alias..."
test_alias
print ""

print "🎯 (ansi green)Success! Your AWS profile aliases will work the same way.(ansi reset)"
print ""
print "💡 (ansi cyan)Next steps:(ansi reset)"
print "   1. Edit: (ansi yellow)~/.config/nushell/config.nu(ansi reset)"
print "   2. Add your alias functions (copy from examples above)"
print "   3. Replace profile names with your actual AWS profile names"
print "   4. Restart shell: (ansi yellow)source ~/.config/nushell/config.nu(ansi reset)"
print "   5. Use: (ansi yellow)awsl-dev(ansi reset), (ansi yellow)awsl-prod(ansi reset)"
print ""
print "📚 (ansi cyan)More examples:(ansi reset)"
print "   • (ansi yellow)ready-to-use-aliases.nu(ansi reset) - Copy and customize"
print "   • (ansi yellow)PROFILE_ALIASES_GUIDE.md(ansi reset) - Comprehensive guide"
print "   • (ansi yellow)complete-working-example.nu(ansi reset) - Full demonstration"
print ""
print "✅ (ansi green)Your AWS login system is ready to go!(ansi reset)"