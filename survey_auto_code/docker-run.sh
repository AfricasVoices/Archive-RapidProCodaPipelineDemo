#!/bin/bash

set -e

IMAGE_NAME=demo-survey-auto-code

# Check that the correct number of arguments were provided.
if [ $# -ne 6 ]; then
    echo "Usage: sh docker-run.sh <user> <json-input-path> <key-of-raw> <json-output-path> <coding-mode> <coded-output-path>"
    exit
fi

# Assign the program arguments to bash variables.
USER=$1
INPUT_JSON=$2
KEY_OF_RAW=$3
OUTPUT_JSON=$4
CODING_MODE=$5
CODING_DIR=$6

# Build an image for this pipeline stage.
docker build -t "$IMAGE_NAME" .

# Create a container from the image that was just built.
container="$(docker container create --env USER="$USER" --env KEY_OF_RAW="$KEY_OF_RAW" --env CODING_MODE="$CODING_MODE" "$IMAGE_NAME")"

function finish {
    # Tear down the container when done.
    docker container rm "$container" >/dev/null
}
trap finish EXIT

# Copy input data into the container
docker cp "$INPUT_JSON" "$container:/data/input.json"

# Run the image as a container.
docker start -a -i "$container"

# Copy the output data back out of the container
mkdir -p "$(dirname "$OUTPUT_JSON")"
docker cp "$container:/data/output.json" "$OUTPUT_JSON"

mkdir -p "$CODING_DIR"
docker cp "$container:/data/coding/." "$CODING_DIR"
