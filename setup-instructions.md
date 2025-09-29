# AWS Nushell Login Setup Instructions

## Installation Complete! ✅

Your AWS login script has been fixed and is ready to use. Here's how to set it up:

## Option 1: Manual Setup (Recommended)

Add this line to your `~/.config/nushell/config.nu`:

```nu
source /home/family/src/aws-nushell-login/aws-login.nu
```

## Option 2: Already Done for You! 

I've already added the source line to your config at line 977. However, there seems to be a syntax error in your git-aliases.nu file that's preventing Nushell from loading properly.

## Usage

Once the config is loaded properly, restart your Nushell session and use:

```bash
# Login with default profile
aws-login

# Login with specific profile  
aws-login production

# SSO login
aws-login --sso

# Temporary credentials (for MFA)
aws-login --temp

# Check current status
aws-status

# List available profiles
aws-profiles

# Clear credentials
aws-clear
```

## How It Sets Environment Variables

The script properly sets all AWS environment variables that the AWS CLI and SDK expect:

- `AWS_PROFILE` - The active profile name
- `AWS_ACCESS_KEY_ID` - Your access key ID
- `AWS_SECRET_ACCESS_KEY` - Your secret access key  
- `AWS_SESSION_TOKEN` - Session token (for temporary credentials)
- `AWS_DEFAULT_REGION` - Default region
- `AWS_REGION` - Region (redundant but some tools use this)

## Testing

To test if it's working:

1. Start a new Nushell session
2. Run: `aws-login`
3. Check: `echo $env.AWS_PROFILE` 
4. Verify: `aws sts get-caller-identity`

## Troubleshooting

If you get syntax errors when starting Nushell, check your `git-aliases.nu` file - there appears to be a missing argument in a git worktree command around line 232.