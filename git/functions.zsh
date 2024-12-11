export FINANCE_SERVICES_PATH="$HOME/scripts/finance_services"

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
  open_urls "$(find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} sh -c "cd {}; gh pr list --json url -q .[].url" | tr n n)"
}

function list_prs {
  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I {} sh -c "cd {} && gh pr list"
}


#function list_prs_parallel {
#  find "${FINANCE_SERVICES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort | xargs -P 8 -I {} sh -c "cd {} && gh pr list "
#}

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

function go_to_finance_services {
  cd "${FINANCE_SERVICES_PATH}"
}