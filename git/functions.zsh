export FINANCE_SERVICES_PATH="$HOME/scripts/finance_services"
export ALL_SERVICES_PATH="$HOME/scripts/all_services"

function list_branches {
  for dir in $(find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort); do
    (
      echo "$dir" && cd "$dir" && for branch in `git branch -r | grep -v HEAD`;do echo -e `git show --format="%ci %cr" $branch | head -n 1` \\t$branch; done | sort -r; echo;
    )
  done

}

function urls_with_multiple_branches {
  {
    tmpfile=$(mktemp)  # Create a temporary file to store URLs
    trap 'rm -f "$tmpfile"' EXIT  # Ensure the temp file is deleted on exit

    find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r dir; do
      {
        cd "$dir"
        number_of_branches=$(git ls-remote --heads origin | wc -l)
        if [ $number_of_branches -ne 1 ]; then
          repoUrl=$(gh repo view --json url -q '.url')
          branchesUrl="${repoUrl}/branches/all"
          echo "$branchesUrl" >> "$tmpfile"  # Write to the temp file
        fi
       } &
    done

    wait  # Wait for all background processes to finish

    # Read URLs from the temp file into the urls array
    urls=($(<"$tmpfile"))

    echo ${urls[@]}
  } | xargs -n1 | sort
}

function open_urls_with_multiple_branches {
  open_urls $(urls_with_multiple_branches)
}

function open_prs {
#  open_urls "$(find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} sh -c "cd {}; gh pr list --json url -q .[].url" | tr n n)"
  open_urls "$(fetch_prs | jq -r 'to_entries[].value[].url' | tr n n)"
}

function list_prs {
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} sh -c "cd {} && gh pr list"
}

function list_prs_new {
  fetch_prs | jq '[to_entries[] | .key as $service | .value[] | {service: $service, title, url}] | sort_by(.service)' | jq -r '["service","title","url"], (. | map([.service, .title, .url])[]) | @tsv' | column -t -s $'\t'
}

function fetch_prs {
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} -P 10 sh -c "cd {} && gh pr list --json "title,url,headRepository" | jq '.  | if length == 0 then empty else . end | { (.[0]?.headRepository?.name) :  [ .[] | {title: .title, url: .url} ]  }'" | jq -n -S '[inputs] | add'
}

function list_prs_parallel {
  # Create a temporary directory to hold output files
  temp_dir=$(mktemp -d)

  # Find directories, sort them, and process in parallel using xargs
#  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | \
#  xargs -I {} -P 4 sh -c 'temp_file="'$temp_dir'/$(basename '{}').out" cd "{}" && gh pr list'

  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} -P 4 sh -c 'cd "{}" && gh pr list > "'$temp_dir'/$(basename "{}").out"'

  # After all parallel tasks are done, concatenate files in sorted order
  cat "$temp_dir"/*.out

  # Clean up temporary directory
  rm -rf "$temp_dir"
}

function update_repos {
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -P10 -I {} sh -c "cd {}; git pull"
}

function prune_repo {
  git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
}

function prune_reposOLD {
  # Export the function so subshells can see it
    export -f prune_repo

#  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -P10 -I {} sh -c "cd {}; prune_repo"
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -P10 -I {} zsh -c "cd {}; prune_repo" zsh {}
}

# Modified prune_repos - passing the function definition explicitly
function prune_repos {
  # Get the function's definition as a string.
  # 'typeset -f prune_repo' is a standard way in Zsh/Bash.
  local prune_repo_def
  prune_repo_def=$(typeset -f prune_repo)

  # Basic check to ensure we captured the definition
  if [[ -z "$prune_repo_def" ]]; then
    echo "Error: Failed to retrieve definition for function 'prune_repo'." >&2
    return 1
  fi

  # Use find + xargs + zsh -c
  # The key change is prepending the function definition to the command string
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d -print0 | \
    xargs -0 -P10 -I {} -- zsh -c \
      '# First, define the function using the passed-in definition string
       '"$prune_repo_def"'
       # Now execute the logic using the defined function
       noglob cd "$1" && prune_repo' \
      zsh {} # Pass 'zsh' as $0 and the directory '{}' as $1

  echo "--- prune_repos finished ---"
}

function go_to_finance_services {
  cd "${FINANCE_SERVICES_PATH}"
}