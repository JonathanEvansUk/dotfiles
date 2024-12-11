function compile_projects {
  # Define the base directory
  local base_dir="${FINANCE_SERVICES_PATH}"
  # Define the output CSV file - with date and time
  local output_csv="compile_report_$(date +'%Y%m%d_%H%M%S').csv"

  # Write the CSV header
  echo "dir,status" > "$output_csv"

  # Loop through each subdirectory in the base directory
  for dir in "$base_dir"/*/; do
    echo "Running 'mvn clean compile' in $dir"
    if (cd "$dir" && mvn clean compile); then
      echo "$dir,SUCCESS" >> "$output_csv"
    else
      echo "$dir,FAILURE" >> "$output_csv"
    fi
  done

  echo "Compilation completed. Report saved to $output_csv."
}


function compile_projects_parallel {
  # Define the base directory
  local base_dir="${FINANCE_SERVICES_PATH}"
  # Define the output CSV file - with date and time
  local output_csv="compile_report_$(date +'%Y%m%d_%H%M%S').csv"
  # Write the CSV header
  echo "dir,status" > "$output_csv"

  # Create a temporary directory to store individual results
  local temp_dir
  temp_dir=$(mktemp -d)

  # Find all subdirectories and run `mvn clean compile` in parallel
  find "$base_dir" -mindepth 1 -maxdepth 1 -type d | \
  xargs -I {} -P 4 -S1024 sh -c '
    dir="{}"
    echo "Running: $dir"
    if (cd "$dir" && mvn clean compile > /dev/null 2>&1); then
      echo "$dir,SUCCESS" > "'$temp_dir'/$(basename "$dir").out"
    else
      echo "$dir,FAILURE" > "'$temp_dir'/$(basename "$dir").out"
    fi
    echo "Finished: $dir"
  '

  # Combine all individual results into the final CSV
  cat "$temp_dir"/*.out >> "$output_csv"

  # Clean up the temporary directory
  rm -rf "$temp_dir"

  echo "Compilation completed. Report saved to $output_csv."
}



function progress_display_test {

  # Disable job control to suppress output like [12] 25026
  set +m

  function update_status {
    local index="$1"
    local status"$2"
    local total=10
    local lines_to_move=$((total - index + 1))

    # Move the cursor up to the line of the task
    tput cuu $lines_to_move
    tput el
    echo "Task $index - status: $status - moved: $lines_to_move"

    # Move the cursor
    tput cud $((lines_to_move - 1 ))
  }

  # kick off some background tasks in parallel
  for i in {1..10}; do
    {
      delay=$(jot -r 1 1 5)
      echo "Task $i - started - $delay seconds"
      sleep $delay
#      sleep $i
#      echo -e "Task $i completed"
      update_status $i "completed"
    } &   # Background task without job control output
  done

  # wait for all background tasks to complete
  wait

  echo "All tasks completed"

  # Re-enable job control if needed
  set -m
}

function classpath {
  mvn dependency:build-classpath -Dmdep.outputFile=target/classpath.txt -DskipTests
}

function delombok {
  mvn compile lombok:delombok -DskipTests
}

function prepare_for_analysis {
  # Define the base directory
  local base_dir="${FINANCE_SERVICES_PATH}"
  # Define the output CSV file - with date and time
  local output_csv="compile_report_$(date +'%Y%m%d_%H%M%S').csv"
  # Write the CSV header
  echo "dir,status" > "$output_csv"

  # Create a temporary directory to store individual results
  local temp_dir
  temp_dir=$(mktemp -d)

  # Find all subdirectories and run `mvn clean compile` in parallel
  find "$base_dir" -mindepth 1 -maxdepth 1 -type d | \
  xargs -I {} -P 10 -S1024 sh -c '
    dir="{}"
    echo "Running: $dir"
    if (cd "$dir" && mvn compile lombok:delombok dependency:build-classpath -Dmdep.outputFile=target/classpath.txt -DskipTests > /dev/null 2>&1); then
      echo "$dir,SUCCESS" > "'$temp_dir'/$(basename "$dir").out"
    else
      echo "$dir,FAILURE" > "'$temp_dir'/$(basename "$dir").out"
    fi
    echo "Finished: $dir"
  '

  # Combine all individual results into the final CSV
  cat "$temp_dir"/*.out >> "$output_csv"

  # Clean up the temporary directory
  rm -rf "$temp_dir"

  echo "Compilation completed. Report saved to $output_csv."
}



