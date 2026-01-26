#!/bin/bash

# Script to create a new GitHub repository and push the fitnessai project
# Usage: ./setup_github_repo.sh [repo-name] [github-token]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_NAME="${1:-fitnessai}"
ORG_NAME="ShayestehInc"
GITHUB_TOKEN="${2:-}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 Setting up GitHub Repository${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if token is provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  GitHub token not provided as argument${NC}"
    echo -e "${YELLOW}   You can get a token from: https://github.com/settings/tokens${NC}"
    echo -e "${YELLOW}   Required scopes: repo, admin:org (for org repos)${NC}"
    echo ""
    read -sp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    echo ""
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ GitHub token is required${NC}"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is required but not installed${NC}"
    exit 1
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ git is required but not installed${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Repository: ${ORG_NAME}/${REPO_NAME}${NC}"
echo ""

# Check if repository already exists
echo -e "${BLUE}🔍 Checking if repository exists...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${ORG_NAME}/${REPO_NAME}")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${YELLOW}⚠️  Repository ${ORG_NAME}/${REPO_NAME} already exists${NC}"
    read -p "Do you want to use this existing repository? (y/n): " USE_EXISTING
    if [ "$USE_EXISTING" != "y" ] && [ "$USE_EXISTING" != "Y" ]; then
        echo -e "${RED}❌ Aborted${NC}"
        exit 1
    fi
    REPO_EXISTS=true
elif [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Repository does not exist, will create it${NC}"
    REPO_EXISTS=false
else
    echo -e "${RED}❌ Error checking repository: HTTP ${HTTP_CODE}${NC}"
    echo -e "${RED}   Please check your token permissions${NC}"
    exit 1
fi

# Create repository if it doesn't exist
if [ "$REPO_EXISTS" = false ]; then
    echo -e "${BLUE}📝 Creating repository...${NC}"
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${REPO_NAME}\",
            \"description\": \"Fitness AI - AI-powered fitness training platform\",
            \"private\": false,
            \"has_issues\": true,
            \"has_projects\": true,
            \"has_wiki\": false
        }" \
        "https://api.github.com/orgs/${ORG_NAME}/repos")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" != "201" ]; then
        echo -e "${RED}❌ Failed to create repository: HTTP ${HTTP_CODE}${NC}"
        echo -e "${RED}   Response: ${BODY}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Repository created successfully${NC}"
else
    echo -e "${GREEN}✅ Using existing repository${NC}"
fi

echo ""

# Configure git remote
echo -e "${BLUE}🔧 Configuring git remote...${NC}"
REPO_URL="https://github.com/${ORG_NAME}/${REPO_NAME}.git"

# Remove existing origin if it points to a different repo
CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null || echo "")
if [ ! -z "$CURRENT_ORIGIN" ] && [ "$CURRENT_ORIGIN" != "$REPO_URL" ]; then
    echo -e "${YELLOW}⚠️  Removing old remote origin: ${CURRENT_ORIGIN}${NC}"
    git remote remove origin
fi

# Add new origin
if git remote get-url origin &>/dev/null; then
    git remote set-url origin "$REPO_URL"
    echo -e "${GREEN}✅ Updated remote origin${NC}"
else
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✅ Added remote origin${NC}"
fi

echo ""

# Check git status
echo -e "${BLUE}📊 Checking git status...${NC}"
git status --short | head -10

# Ask about committing changes
UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    read -p "Do you want to commit all changes before pushing? (y/n): " COMMIT_CHANGES
    if [ "$COMMIT_CHANGES" = "y" ] || [ "$COMMIT_CHANGES" = "Y" ]; then
        echo -e "${BLUE}💾 Committing changes...${NC}"
        git add -A
        git commit -m "Initial commit: Fitness AI project" || {
            echo -e "${YELLOW}⚠️  No changes to commit or commit failed${NC}"
        }
    fi
fi

# Push to GitHub
echo ""
echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
echo -e "${YELLOW}   This may take a few minutes...${NC}"
echo ""

# Check if main branch exists
if git show-ref --verify --quiet refs/heads/main; then
    BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    BRANCH="master"
else
    echo -e "${RED}❌ No main or master branch found${NC}"
    exit 1
fi

# Push with token authentication
git push -u origin "${BRANCH}" || {
    echo ""
    echo -e "${YELLOW}⚠️  Push failed. You may need to authenticate.${NC}"
    echo -e "${YELLOW}   Trying alternative method...${NC}"
    
    # Try with token in URL
    TOKEN_URL="https://${GITHUB_TOKEN}@github.com/${ORG_NAME}/${REPO_NAME}.git"
    git remote set-url origin "$TOKEN_URL"
    git push -u origin "${BRANCH}" || {
        echo -e "${RED}❌ Push failed. Please check:${NC}"
        echo -e "${RED}   1. Your GitHub token has 'repo' permissions${NC}"
        echo -e "${RED}   2. You have write access to ${ORG_NAME}${NC}"
        echo -e "${RED}   3. Your token is valid${NC}"
        exit 1
    }
    
    # Reset to normal URL (without token)
    git remote set-url origin "$REPO_URL"
}

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}🔗 Repository URL:${NC}"
echo -e "   https://github.com/${ORG_NAME}/${REPO_NAME}"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   1. Visit the repository to verify the push"
echo -e "   2. Add a README if needed"
echo -e "   3. Set up branch protection rules"
echo -e "   4. Configure GitHub Actions if needed"
echo ""
