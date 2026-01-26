# GitHub Repository Setup Guide

## Quick Setup

### Option 1: Using the Automated Script (Recommended)

1. **Get a GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Name it: "FitnessAI Repo Setup"
   - Select scopes: `repo` (full control of private repositories)
   - For organization repos, also select: `admin:org` (if you have permission)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again)

2. **Run the setup script:**
   ```bash
   ./setup_github_repo.sh
   ```
   When prompted, paste your token.

   Or provide the token directly:
   ```bash
   ./setup_github_repo.sh fitnessai YOUR_GITHUB_TOKEN
   ```

### Option 2: Manual Setup

1. **Create the repository on GitHub:**
   - Go to: https://github.com/organizations/ShayestehInc/repositories/new
   - Repository name: `fitnessai`
   - Description: "Fitness AI - AI-powered fitness training platform"
   - Choose Public or Private
   - **Do NOT** initialize with README, .gitignore, or license
   - Click "Create repository"

2. **Update remote and push:**
   ```bash
   # Update remote
   git remote set-url origin https://github.com/ShayestehInc/fitnessai.git
   
   # Or if you prefer SSH:
   git remote set-url origin git@github.com:ShayestehInc/fitnessai.git
   
   # Commit any uncommitted changes (if needed)
   git add -A
   git commit -m "Initial commit: Fitness AI project"
   
   # Push to GitHub
   git push -u origin main
   ```

## Repository Details

- **Organization:** ShayestehInc
- **Repository Name:** fitnessai
- **URL:** https://github.com/ShayestehInc/fitnessai

## Notes

- The script will automatically handle:
  - Creating the repository via GitHub API
  - Setting up the git remote
  - Committing uncommitted changes (if you choose)
  - Pushing to GitHub

- If you encounter authentication issues:
  - Use a Personal Access Token (not your password)
  - Ensure the token has `repo` scope
  - For organization repos, ensure you have write access
