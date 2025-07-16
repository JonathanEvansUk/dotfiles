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

function classpath {
  mvn dependency:build-classpath -Dmdep.outputFile=target/classpath.txt -DskipTests
}

function delombok {
  mvn compile lombok:delombok -DskipTests
}

function prepare_finance_services_for_analysis {
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
    if (cd "$dir" && mvn clean compile -U lombok:delombok dependency:build-classpath -Dmdep.outputFile=target/classpath.txt -DskipTests > /dev/null 2>&1); then
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

function prepare_all_services_for_analysis {
  # Define the base directory
    local base_dir="${ALL_SERVICES_PATH}"
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
      if (cd "$dir" && mvn clean compile -U lombok:delombok dependency:build-classpath -Dmdep.outputFile=target/classpath.txt -DskipTests > /dev/null 2>&1); then
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



