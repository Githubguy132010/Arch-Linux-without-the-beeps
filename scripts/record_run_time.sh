#!/bin/bash

# Script to record the duration of each workflow run

# Define the log file to store historical run times
LOG_FILE="workflow_run_times.log"

# Function to record the start time of the workflow
record_start_time() {
  START_TIME=$(date +%s)
  echo "Workflow started at: $(date -d @$START_TIME)"
}

# Function to record the end time of the workflow and calculate the duration
record_end_time() {
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  echo "Workflow ended at: $(date -d @$END_TIME)"
  echo "Workflow duration: $DURATION seconds"

  # Store the duration in the log file
  echo $DURATION >> $LOG_FILE
}

# Check the argument passed to the script
if [ "$1" == "start" ]; then
  record_start_time
elif [ "$1" == "end" ]; then
  record_end_time
else
  echo "Invalid argument. Use 'start' or 'end'."
  exit 1
fi
