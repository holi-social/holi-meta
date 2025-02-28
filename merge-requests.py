import argparse
import gitlab
import os
from collections import defaultdict
from colorama import init, Fore, Back, Style

# Initialize colorama
init(autoreset=True)

# Function to authenticate with GitLab
def get_gitlab_client(token=None):
    token = token or os.getenv('GITLAB_ACCESS_TOKEN')
    if not token:
        raise ValueError("GitLab access token is required")
    return gitlab.Gitlab('https://gitlab.holi.team', private_token=token)

# Function to fetch and group merge requests by title
def group_merge_requests_by_title(gitlab_client):
    merge_requests = defaultdict(list)
    projects = gitlab_client.projects.list(all=True, archived=False)

    for project in projects:
        mrs = project.mergerequests.list(state='opened')
        for mr in mrs:
            merge_requests[mr.title].append((project, mr))
    
    return merge_requests

# Function to get the pipeline status of the last pipeline for an MR
def get_last_pipeline_status(project, mr):
    pipelines = project.pipelines.list(ref=mr.source_branch, per_page=1, get_all=False)
    if not pipelines:
        return None, None  # No pipeline found
    last_pipeline = pipelines[0]
    return last_pipeline.status, last_pipeline.web_url

# Function to format MR information with color and links
def format_mr_info(mr, pipeline_status, pipeline_link):
    mr_link = mr.web_url
    status_as_string = pipeline_status or "unknown"
    status_colored = {
        'success': Fore.GREEN + status_as_string + Style.RESET_ALL,
        'failed': Fore.RED + status_as_string + Style.RESET_ALL,
        'pending': Fore.YELLOW + status_as_string + Style.RESET_ALL,
        'running': Fore.CYAN + status_as_string + Style.RESET_ALL,
        'skipped': Fore.MAGENTA + status_as_string + Style.RESET_ALL,
    }.get(pipeline_status, Fore.WHITE + status_as_string + Style.RESET_ALL)
    
    return f"MR: {mr_link}\nPipeline: {pipeline_link} ({status_colored})"

# Function to merge or close MRs based on user input
def handle_merge_requests(mr_group, action, merge_green_only=False):
    for project, mr in mr_group:
        if merge_green_only:
            pipeline_status, _ = get_last_pipeline_status(project, mr)
            if pipeline_status != 'success':
                print(f"Skipping MR {mr.title} in project {project.name} due to non-green pipeline status")
                continue

        if action == "merge":
            print(f"Merging MR {mr.title} in project {project.name}")
            mr.merge()
        elif action == "close":
            print(f"Closing MR {mr.title} in project {project.name}")
            mr.state_event = 'close'
            mr.save()

# Function to interactively ask the user how to handle each group of MRs
def prompt_user_for_action(mr_group):
    print(f"\nGroup contains {len(mr_group)} MRs")
    print("Choose an action for this group:")
    print("1: Work on none of the MRs")
    print("2: Work on green MRs only")
    print("3: Work on all MRs")
    
    action_choice = input("Enter choice (1/2/3): ").strip()
    
    if action_choice == "1":
        return None  # Don't work on any MR
    elif action_choice == "2":
        return "green"  # Only green MRs
    elif action_choice == "3":
        return "all"  # All MRs
    else:
        print("Invalid choice, please try again.")
        return prompt_user_for_action(mr_group)

# Function to print section headers with underlining
def print_section1_header(text):
    print(Fore.BLUE + Style.BRIGHT + f"\n{text}")
    print(Fore.BLUE + "-" * len(text))

def print_section2_header(text):
    print(Fore.LIGHTBLUE_EX + Style.BRIGHT + f"\n{text}")

# Main function to handle the script logic
def main():
    parser = argparse.ArgumentParser(description="Handle renovate updates for multiple GitLab repositories")
    parser.add_argument('--token', help='GitLab access token', default=None)
    args = parser.parse_args()

    # Initialize GitLab client
    gitlab_client = get_gitlab_client(args.token)
    
    # Group merge requests by title
    merge_requests = {item[0]: item[1] for item in group_merge_requests_by_title(gitlab_client).items() if len(item[1])>1}

    # Sort groups by the number of MRs in descending order
    sorted_groups = sorted(merge_requests.items(), key=lambda x: len(x[1]), reverse=True)

    # For each group of MRs with the same title
    for title, mr_group in sorted_groups:
        print_section1_header(f"Group of MRs with title: {title}")
        
        # Subgroup by pipeline status
        pipeline_groups = defaultdict(list)
        for project, mr in mr_group:
            pipeline_status, pipeline_link = get_last_pipeline_status(project, mr)
            pipeline_groups[pipeline_status].append((mr, pipeline_link))
        
        # Output MR information grouped by pipeline status
        for status, grouped_mrs in pipeline_groups.items():
            print_section2_header(f"Pipeline Status: {status}")
            for mr, pipeline_link in grouped_mrs:
                mr_info = format_mr_info(mr, status, pipeline_link)
                print(mr_info)
        
        # Prompt the user for action
        user_action = prompt_user_for_action(mr_group)
        if user_action is None:
            print(f"Skipping group '{title}' - no MRs will be worked on.")
        else:
            merge_green_only = (user_action == "green")
            # Ask the user whether to merge or close
            action_choice = input("Do you want to merge or close the MRs? (merge/close): ").strip().lower()
            if action_choice in ["merge", "close"]:
                handle_merge_requests(mr_group, action_choice, merge_green_only=merge_green_only)
            else:
                print("Invalid action. Skipping this group.")

if __name__ == "__main__":
    main()
