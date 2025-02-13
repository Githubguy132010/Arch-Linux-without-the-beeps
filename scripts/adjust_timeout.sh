#!/bin/bash

# Script to adjust the timeout value in workflow files based on historical run times

# Define the log file to store historical run times
LOG_FILE="workflow_run_times.log"

# Function to calculate the average run time from the log file
calculate_average_run_time() {
  if [ ! -f $LOG_FILE ]; then
    echo "Log file not found. Using default timeout value."
    return 0
  fi

  total_time=0
  count=0

  while read -r line; do
    total_time=$((total_time + line))
    count=$((count + 1))
  done < $LOG_FILE

  if [ $count -eq 0 ]; then
    echo "No historical run times found. Using default timeout value."
    return 0
  fi

  average_time=$((total_time / count))
  echo "Average run time: $average_time seconds"
  echo $average_time
}

# Function to adjust the timeout value in the workflow files
adjust_timeout_value() {
  average_time=$(calculate_average_run_time)
  if [ $average_time -eq 0 ]; then
    return
  fi

  timeout_minutes=$((average_time / 60))
  echo "Setting timeout value to $timeout_minutes minutes"

  # Update the timeout value in the workflow files
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build-check.yaml
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build.yaml
}

# Adjust the timeout value
adjust_timeout_value
