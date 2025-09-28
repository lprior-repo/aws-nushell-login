#!/usr/bin/env nu
# Quick Setup Guide for Profile-Specific AWS Aliases
#
# This script shows you exactly how to create convenient profile-specific 
# aliases for your AWS environments after installing aws-nushell-login

print "🎯 (ansi green)AWS Profile-Specific Aliases Setup Guide(ansi reset)"
print ""

print "📋 (ansi cyan)Step 1: Check your current AWS profiles(ansi reset)"
print "Run this to see what profiles you have:"
print "  (ansi yellow)aws-profiles(ansi reset)"
print ""

print "📝 (ansi cyan)Step 2: Add aliases to your Nushell config(ansi reset)"
print "Edit ~/.config/nushell/config.nu and add lines like these:"
print ""

print "# (ansi green)Basic profile aliases - customize names for your environments(ansi reset)"
print "(ansi yellow)alias awsl-dev = aws-login development(ansi reset)"
print "(ansi yellow)alias awsl-staging = aws-login staging --sso(ansi reset)"
print "(ansi yellow)alias awsl-prod = aws-login production --sso(ansi reset)"
print "(ansi yellow)alias awsl-sandbox = aws-login sandbox(ansi reset)"
print ""

print "🔒 (ansi cyan)Step 3: Add safety for production(ansi reset)"
print "For production environments, use a function with confirmation:"
print ""
print "(ansi yellow)def awsl-prod []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    let confirm = (input \"⚠️  Connecting to PRODUCTION. Continue? (y/N): \")(ansi reset)"
print "(ansi yellow)    if $confirm != \"y\" {(ansi reset)"
print "(ansi yellow)        print \"❌ Production access cancelled\"(ansi reset)"
print "(ansi yellow)        return(ansi reset)"
print "(ansi yellow)    }(ansi reset)"
print "(ansi yellow)    aws-login production --sso(ansi reset)"
print "(ansi yellow)    print \"🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!\"(ansi reset)"
print "(ansi yellow)    aws-status(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""

print "🌍 (ansi cyan)Step 4: Add region-specific aliases (optional)(ansi reset)"
print "(ansi yellow)def awsl-prod-us []: nothing -> nothing {(ansi reset)"
print "(ansi yellow)    awsl-prod(ansi reset)"
print "(ansi yellow)    $env.AWS_DEFAULT_REGION = \"us-east-1\"(ansi reset)"
print "(ansi yellow)    $env.AWS_REGION = \"us-east-1\"(ansi reset)"
print "(ansi yellow)    print \"🌎 Production US-East-1\"(ansi reset)"
print "(ansi yellow)}(ansi reset)"
print ""

print "⚡ (ansi cyan)Step 5: Test your aliases(ansi reset)"
print "After adding aliases, restart your shell and test:"
print "  (ansi yellow)awsl-dev(ansi reset)      # Login to development"
print "  (ansi yellow)aws-status(ansi reset)    # Check what's active"
print "  (ansi yellow)awsl-prod(ansi reset)     # Login to production (with safety prompt)"
print "  (ansi yellow)aws-clear(ansi reset)     # Clear credentials"
print ""

print "📚 (ansi cyan)Step 6: See more examples(ansi reset)"
print "Check out these files for comprehensive examples:"
print "  (ansi yellow)PROFILE_ALIASES_GUIDE.md(ansi reset) - Complete guide with patterns"
print "  (ansi yellow)profile-specific-examples.nu(ansi reset) - Ready-to-use functions"
print "  (ansi yellow)profile-aliases-template.nu(ansi reset) - Customizable template"
print ""

print "🎉 (ansi green)That's it! You now have convenient AWS profile switching!(ansi reset)"
print ""
print "💡 (ansi cyan)Pro Tips:(ansi reset)"
print "• Use descriptive names that match your team's terminology"
print "• Always use --sso for production environments"
print "• Add confirmation prompts for sensitive environments"
print "• Group related aliases with comments in your config"
print ""
print "🔗 Full repository: (ansi blue)https://github.com/lprior-repo/aws-nushell-login(ansi reset)"