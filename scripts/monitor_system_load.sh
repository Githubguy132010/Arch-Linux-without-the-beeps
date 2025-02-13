#!/bin/bash

# Script to monitor system load and adjust the timeout value

# Function to get the current CPU usage
get_cpu_usage() {
  top -bn1 | grep "Cpu(s)" | \
  sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
  awk '{print 100 - $1}'
}

# Function to get the current memory usage
get_memory_usage() {
  free | grep Mem | awk '{print $3/$2 * 100.0}'
}

# Function to adjust the timeout value based on system load
adjust_timeout_based_on_load() {
  cpu_usage=$(get_cpu_usage)
  memory_usage=$(get_memory_usage)

  echo "Current CPU usage: $cpu_usage%"
  echo "Current memory usage: $memory_usage%"

  if (( $(echo "$cpu_usage > 80.0" | bc -l) )) || (( $(echo "$memory_usage > 80.0" | bc -l) )); then
    echo "High system load detected. Increasing timeout value."
    timeout_minutes=180
  else
    echo "Normal system load. Using default timeout value."
    timeout_minutes=120
  fi

  # Update the timeout value in the workflow files
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build-check.yaml
  sed -i "s/timeout-minutes: [0-9]\+/timeout-minutes: $timeout_minutes/" .github/workflows/build.yaml
}

# Adjust the timeout value based on system load
adjust_timeout_based_on_load
