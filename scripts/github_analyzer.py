#!/usr/bin/env python3
"""
GitHub Repository Analyzer

This script fetches public repositories for a given GitHub username and outputs
the basic information in either JSON or Markdown format.
"""

import argparse
import json
import os
import requests
import sys
from typing import Dict, List, Optional, Union


def fetch_repositories(username: str) -> List[Dict]:
    """
    Fetch public repositories for the given GitHub username.
    
    Args:
        username: GitHub username to fetch repositories for
        
    Returns:
        List of repository data dictionaries
        
    Raises:
        ValueError: If the GitHub API request fails
    """
    api_url = f"https://api.github.com/users/{username}/repos"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()  # Raise exception for 4XX/5XX responses
        return response.json()
    except requests.exceptions.RequestException as e:
        raise ValueError(f"Failed to fetch repositories: {e}")


def process_repositories(repositories: List[Dict]) -> List[Dict]:
    """
    Process and filter repository data to extract relevant information.
    
    Args:
        repositories: List of repository data from GitHub API
        
    Returns:
        List of dictionaries with processed repository information
    """
    processed_repos = []
    
    for repo in repositories:
        # Extract only the relevant information
        processed_repo = {
            "name": repo.get("name", ""),
            "url": repo.get("html_url", ""),
            "description": repo.get("description", ""),
            "language": repo.get("language", ""),
            "stars": repo.get("stargazers_count", 0),
            "forks": repo.get("forks_count", 0),
            "created_at": repo.get("created_at", ""),
            "updated_at": repo.get("updated_at", ""),
            "is_fork": repo.get("fork", False)
        }
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
        
        # Convert dates to a more readable format
        created_date = repo["created_at"].split("T")[0] if repo["created_at"] else "Unknown"
        updated_date = repo["updated_at"].split("T")[0] if repo["updated_at"] else "Unknown"
        
        markdown += f"- **Created:** {created_date}\n"
        markdown += f"- **Last Updated:** {updated_date}\n"
        markdown += f"- **Fork:** {'Yes' if repo['is_fork'] else 'No'}\n\n"
    
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
    
    args = parser.parse_args()
    
    try:
        # Fetch repositories from GitHub
        print(f"Fetching repositories for {args.username}...")
        repositories = fetch_repositories(args.username)
        
        # Process the repository data
        processed_repos = process_repositories(repositories)
        
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