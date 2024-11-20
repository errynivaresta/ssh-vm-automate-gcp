#!/bin/bash

# Define the CSV file path
CSV_FILE="instances_list.csv"
LOG_FILE="ssh_errors.log"
FAILED_LIST_FILE="failed_instances.txt"
REMOTE_COMMAND="echo Hello from $(hostname)"
EMAIL_SUBJECT="SSH Connection Failure Alert"
EMAIL_RECIPIENT="xxxxxxxx@gmail.com" # Replace with your email address

# Clear log files at the start
echo "Starting SSH check for instances..." > "$LOG_FILE"
> "$FAILED_LIST_FILE"

# Check if the CSV file exists
if [[ ! -f $CSV_FILE ]]; then
    echo "Error: CSV file $CSV_FILE not found!"
    exit 1
fi

# Variables to track status
FAILED_INSTANCES=0
TOTAL_INSTANCES=0

# Read the CSV file into an array to prevent stdin conflicts
mapfile -t INSTANCE_LIST < <(tail -n +2 "$CSV_FILE") # Skip the header row

# Process each instance in the list
for INSTANCE_ENTRY in "${INSTANCE_LIST[@]}"; do
    # Extract instance name and zone
    INSTANCE_NAME=$(echo "$INSTANCE_ENTRY" | cut -d',' -f1)
    ZONE=$(echo "$INSTANCE_ENTRY" | cut -d',' -f2)

    # Skip empty or malformed lines
    if [[ -z "$INSTANCE_NAME" || -z "$ZONE" ]]; then
        continue
    fi

    TOTAL_INSTANCES=$((TOTAL_INSTANCES + 1))
    echo "Attempting to connect to $INSTANCE_NAME in $ZONE using IAP tunnel..."

    # Attempt SSH connection through IAP and execute the command
    gcloud compute ssh "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --tunnel-through-iap \
        --command="$REMOTE_COMMAND" 2>>"$LOG_FILE"

    # Check if SSH was successful
    if [[ $? -eq 0 ]]; then
        echo "Successfully connected to $INSTANCE_NAME. Command executed."
    else
        echo "Failed to connect to $INSTANCE_NAME. Logging error and adding to failed list."
        echo "$INSTANCE_NAME,$ZONE" >> "$FAILED_LIST_FILE"
        FAILED_INSTANCES=$((FAILED_INSTANCES + 1))
    fi

    echo "Finished processing $INSTANCE_NAME. Moving to the next instance..."
done

# Summarize the results
SUMMARY="SSH check completed for $TOTAL_INSTANCES instances. Failures: $FAILED_INSTANCES."
echo "$SUMMARY" | tee -a "$LOG_FILE"

# Send email notification if there are failed instances
if [[ $FAILED_INSTANCES -gt 0 ]]; then
    # Compose the email body
    EMAIL_BODY="The SSH check completed, but $FAILED_INSTANCES instance(s) failed to connect.\n\nFailed instances:\n"
    EMAIL_BODY+="$(cat $FAILED_LIST_FILE)"

    # Send the email with the list of failed instances
    (
        echo "Subject: $EMAIL_SUBJECT"
        echo "To: $EMAIL_RECIPIENT"
        echo
        echo -e "$EMAIL_BODY"
    ) | msmtp "$EMAIL_RECIPIENT"

    echo "Failure notification sent to $EMAIL_RECIPIENT."
else
    echo "No failures detected. No email notification sent."
fi