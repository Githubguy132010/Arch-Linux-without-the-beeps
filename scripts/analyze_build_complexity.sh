#!/bin/bash

# Script to analyze build complexity and adjust the timeout value

# Function to count the number of files in the build
count_files() {
  find . -type f | wc -l
}

# Function to count the number of lines of code in the build
count_lines_of_code() {
  find . -type f -name '*.sh' -o -name '*.yaml' -o -name '*.yml' -o -name '*.conf' -o -name '*.cfg' | xargs wc -l | tail -n 1 | awk '{print $1}'
}

# Function to count the number of dependencies in the build
count_dependencies() {
  grep -r 'dependencies:' . | wc -l
}

# Function to adjust the timeout value based on build complexity
adjust_timeout_based_on_complexity() {
  num_files=$(count_files)
  num_lines_of_code=$(count_lines_of_code)
  num_dependencies=$(count_dependencies)

  echo "Number of files: $num_files"
  echo "Number of lines of code: $num_lines_of_code"
  echo "Number of dependencies: $num_dependencies"

  complexity_score=$((num_files + num_lines_of_code + num_dependencies))

  if [ $complexity_score -gt 10000 ]; then
    echo "High build complexity detected. Increasing timeout value."
    timeout_minutes=180
  else
    echo "Normal build complexity. Using default timeout value."
    timeout_minutes=120
  fi

  # Update the timeout value in the workflow files
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build-check.yaml
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build.yaml
}

# Adjust the timeout value based on build complexity
adjust_timeout_based_on_complexity
