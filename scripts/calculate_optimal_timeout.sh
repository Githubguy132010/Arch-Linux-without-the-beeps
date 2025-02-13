#!/bin/bash

# Script to calculate the optimal timeout time using the output from other scripts

# Function to calculate the optimal timeout time
calculate_optimal_timeout() {
  # Get the average run time from the log file
  average_run_time=$(./scripts/adjust_timeout.sh)

  # Get the system load adjustment
  system_load_adjustment=$(./scripts/monitor_system_load.sh)

  # Get the build complexity adjustment
  build_complexity_adjustment=$(./scripts/analyze_build_complexity.sh)

  # Calculate the optimal timeout time
  optimal_timeout=$((average_run_time + system_load_adjustment + build_complexity_adjustment))

  echo "Optimal timeout time: $optimal_timeout minutes"

  # Update the timeout value in the workflow files
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $optimal_timeout/" .github/workflows/build-check.yaml
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $optimal_timeout/" .github/workflows/build.yaml
}

# Calculate the optimal timeout time
calculate_optimal_timeout
