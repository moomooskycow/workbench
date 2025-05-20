#!/usr/bin/env python3
"""
GitHub Repository Analyzer

This script fetches public repositories for a given GitHub username and outputs
detailed information in either JSON or Markdown format, including repository stats,
contributor details, and latest commit information.
"""

import argparse
import json
import os
import requests
import sys
import time
from typing import Dict, List, Optional, Tuple, Union
from datetime import datetime


def fetch_repositories(username: str, token: Optional[str] = None) -> List[Dict]:
    """
    Fetch public repositories for the given GitHub username.
    
    Args:
        username: GitHub username to fetch repositories for
        token: Optional GitHub API token for authentication
        
    Returns:
        List of repository data dictionaries
        
    Raises:
        ValueError: If the GitHub API request fails
    """
    api_url = f"https://api.github.com/users/{username}/repos"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    # Add token to headers if provided
    if token:
        headers["Authorization"] = f"token {token}"
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()  # Raise exception for 4XX/5XX responses
        return response.json()
    except requests.exceptions.RequestException as e:
        raise ValueError(f"Failed to fetch repositories: {e}")


def fetch_latest_commit(repo_owner: str, repo_name: str, token: Optional[str] = None) -> Dict:
    """
    Fetch the latest commit information for a repository.
    
    Args:
        repo_owner: Repository owner username
        repo_name: Repository name
        token: Optional GitHub API token for authentication
        
    Returns:
        Dictionary with latest commit information or empty dict if not available
        
    Raises:
        ValueError: If the GitHub API request fails
    """
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/commits"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    # Add token to headers if provided
    if token:
        headers["Authorization"] = f"token {token}"
    
    try:
        # Fetch only the latest commit by limiting to 1 result
        response = requests.get(f"{api_url}?per_page=1", headers=headers)
        
        # If rate limited, wait and try again
        if response.status_code == 403 and 'X-RateLimit-Remaining' in response.headers and int(response.headers['X-RateLimit-Remaining']) == 0:
            reset_time = int(response.headers['X-RateLimit-Reset'])
            sleep_time = max(1, reset_time - int(time.time()))
            print(f"Rate limited. Waiting {sleep_time} seconds...")
            time.sleep(sleep_time)
            response = requests.get(f"{api_url}?per_page=1", headers=headers)
        
        response.raise_for_status()
        commits = response.json()
        
        if commits and len(commits) > 0:
            return {
                "sha": commits[0].get("sha", ""),
                "date": commits[0].get("commit", {}).get("committer", {}).get("date", ""),
                "message": commits[0].get("commit", {}).get("message", "").split("\n")[0],  # Get first line of commit message
                "author": commits[0].get("commit", {}).get("author", {}).get("name", "")
            }
        return {}
    except requests.exceptions.RequestException as e:
        print(f"Warning: Failed to fetch latest commit for {repo_owner}/{repo_name}: {e}", file=sys.stderr)
        return {}


def fetch_contributors(repo_owner: str, repo_name: str, token: Optional[str] = None) -> List[Dict]:
    """
    Fetch contributor information for a repository.
    
    Args:
        repo_owner: Repository owner username
        repo_name: Repository name
        token: Optional GitHub API token for authentication
        
    Returns:
        List of contributor dictionaries or empty list if not available
        
    Raises:
        ValueError: If the GitHub API request fails
    """
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/contributors"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    # Add token to headers if provided
    if token:
        headers["Authorization"] = f"token {token}"
    
    try:
        response = requests.get(api_url, headers=headers)
        
        # If rate limited, wait and try again
        if response.status_code == 403 and 'X-RateLimit-Remaining' in response.headers and int(response.headers['X-RateLimit-Remaining']) == 0:
            reset_time = int(response.headers['X-RateLimit-Reset'])
            sleep_time = max(1, reset_time - int(time.time()))
            print(f"Rate limited. Waiting {sleep_time} seconds...")
            time.sleep(sleep_time)
            response = requests.get(api_url, headers=headers)
        
        response.raise_for_status()
        contributors = response.json()
        
        return [
            {
                "username": contributor.get("login", ""),
                "contributions": contributor.get("contributions", 0),
                "url": contributor.get("html_url", "")
            }
            for contributor in contributors
        ]
    except requests.exceptions.RequestException as e:
        print(f"Warning: Failed to fetch contributors for {repo_owner}/{repo_name}: {e}", file=sys.stderr)
        return []


def process_repositories(repositories: List[Dict], include_details: bool = True, token: Optional[str] = None) -> List[Dict]:
    """
    Process and filter repository data to extract relevant information.
    
    Args:
        repositories: List of repository data from GitHub API
        include_details: Whether to include detailed information like commits and contributors
        token: Optional GitHub API token for authentication
        
    Returns:
        List of dictionaries with processed repository information
    """
    processed_repos = []
    
    for repo in repositories:
        repo_owner = repo.get("owner", {}).get("login", "")
        repo_name = repo.get("name", "")
        
        # Extract basic information
        processed_repo = {
            "name": repo_name,
            "url": repo.get("html_url", ""),
            "description": repo.get("description", ""),
            "language": repo.get("language", ""),
            "stars": repo.get("stargazers_count", 0),
            "forks": repo.get("forks_count", 0),
            "watchers": repo.get("watchers_count", 0),
            "issues": repo.get("open_issues_count", 0),
            "created_at": repo.get("created_at", ""),
            "updated_at": repo.get("updated_at", ""),
            "pushed_at": repo.get("pushed_at", ""),  # Last push date (may differ from last commit)
            "is_fork": repo.get("fork", False),
            "size": repo.get("size", 0),  # Size in KB
            "default_branch": repo.get("default_branch", "main")
        }
        
        # Add detailed information if requested
        if include_details:
            print(f"Fetching detailed information for {repo_owner}/{repo_name}...")
            
            # Get latest commit information
            latest_commit = fetch_latest_commit(repo_owner, repo_name, token)
            processed_repo["latest_commit"] = latest_commit
            
            # Get contributor information (top 5 contributors)
            contributors = fetch_contributors(repo_owner, repo_name, token)
            processed_repo["contributors"] = contributors[:5]  # Limit to top 5 contributors
            processed_repo["total_contributors"] = len(contributors)
            
            # Add a small delay to avoid hitting rate limits
            time.sleep(0.5)
        
        processed_repos.append(processed_repo)
    
    # Sort repositories by stars (most first)
    return sorted(processed_repos, key=lambda x: x["stars"], reverse=True)


def generate_json_output(repositories: List[Dict]) -> str:
    """
    Generate JSON output from repository data.
    
    Args:
        repositories: List of processed repository information
        
    Returns:
        JSON string representation of the repositories
    """
    return json.dumps({"repositories": repositories}, indent=2)


def generate_markdown_output(repositories: List[Dict]) -> str:
    """
    Generate Markdown output from repository data.
    
    Args:
        repositories: List of processed repository information
        
    Returns:
        Markdown string representation of the repositories
    """
    markdown = "# GitHub Repositories\n\n"
    
    for repo in repositories:
        markdown += f"## [{repo['name']}]({repo['url']})\n\n"
        
        if repo["description"]:
            markdown += f"{repo['description']}\n\n"
        
        markdown += "**Details:**\n\n"
        
        # Add language if available
        if repo["language"]:
            markdown += f"- **Language:** {repo['language']}\n"
        
        markdown += f"- **Stars:** {repo['stars']}\n"
        markdown += f"- **Forks:** {repo['forks']}\n"
        markdown += f"- **Watchers:** {repo['watchers']}\n"
        markdown += f"- **Open Issues:** {repo['issues']}\n"
        markdown += f"- **Size:** {repo['size']} KB\n"
        
        # Convert dates to a more readable format
        created_date = repo["created_at"].split("T")[0] if repo["created_at"] else "Unknown"
        updated_date = repo["updated_at"].split("T")[0] if repo["updated_at"] else "Unknown"
        pushed_date = repo["pushed_at"].split("T")[0] if repo["pushed_at"] else "Unknown"
        
        markdown += f"- **Created:** {created_date}\n"
        markdown += f"- **Last Updated:** {updated_date}\n"
        markdown += f"- **Last Push:** {pushed_date}\n"
        markdown += f"- **Fork:** {'Yes' if repo['is_fork'] else 'No'}\n"
        markdown += f"- **Default Branch:** {repo['default_branch']}\n"
        
        # Add latest commit information if available
        if "latest_commit" in repo and repo["latest_commit"]:
            commit = repo["latest_commit"]
            commit_date = commit.get("date", "").split("T")[0] if commit.get("date") else "Unknown"
            
            markdown += "\n**Latest Commit:**\n\n"
            markdown += f"- **Date:** {commit_date}\n"
            markdown += f"- **Message:** {commit.get('message', 'No message')}\n"
            markdown += f"- **Author:** {commit.get('author', 'Unknown')}\n"
            
        # Add contributor information if available
        if "contributors" in repo and repo["contributors"]:
            markdown += "\n**Top Contributors:**\n\n"
            
            for contributor in repo["contributors"]:
                markdown += f"- [{contributor['username']}]({contributor['url']}) - {contributor['contributions']} contributions\n"
            
            total = repo.get("total_contributors", len(repo["contributors"]))
            if total > len(repo["contributors"]):
                markdown += f"\n_...and {total - len(repo['contributors'])} more contributors_\n"
        
        markdown += "\n---\n\n"
    
    return markdown


def generate_output(repositories: List[Dict], format_type: str) -> str:
    """
    Generate output in the specified format (json or markdown).
    
    Args:
        repositories: List of processed repository information
        format_type: Output format ('json' or 'markdown')
        
    Returns:
        Formatted string representation of the repositories
        
    Raises:
        ValueError: If the format type is not supported
    """
    if format_type.lower() == "json":
        return generate_json_output(repositories)
    elif format_type.lower() == "markdown":
        return generate_markdown_output(repositories)
    else:
        raise ValueError(f"Unsupported output format: {format_type}")


def write_output(content: str, output_file: str) -> None:
    """
    Write the content to the specified output file.
    
    Args:
        content: Content to write
        output_file: Path to the output file
        
    Raises:
        IOError: If writing to the file fails
    """
    try:
        # Ensure the directory exists
        os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
        
        with open(output_file, "w") as f:
            f.write(content)
    except IOError as e:
        raise IOError(f"Failed to write to {output_file}: {e}")


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description="Fetch GitHub repository information for a user")
    parser.add_argument("--username", required=True, help="GitHub username")
    parser.add_argument("--output", required=True, help="Output file path")
    parser.add_argument("--format", choices=["json", "markdown"], default="json",
                      help="Output format (default: json)")
    parser.add_argument("--token", help="GitHub API token for authentication (optional, increases rate limit)")
    parser.add_argument("--no-details", action="store_true", 
                      help="Skip fetching detailed information like commits and contributors")
    
    args = parser.parse_args()
    
    try:
        # Fetch repositories from GitHub
        print(f"Fetching repositories for {args.username}...")
        repositories = fetch_repositories(args.username, args.token)
        
        # Process the repository data
        include_details = not args.no_details
        processed_repos = process_repositories(repositories, include_details, args.token)
        
        # Generate output in the specified format
        output_content = generate_output(processed_repos, args.format)
        
        # Write to the output file
        write_output(output_content, args.output)
        
        print(f"Successfully wrote {len(processed_repos)} repositories to {args.output}")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()