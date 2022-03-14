#!/usr/bin/env bash

SMEE_URL="$1"
JENKINS_URL="$2"

curl -s -N -H "Accept: text/event-stream" "$SMEE_URL" | while read -r LINE; do
  if [ -n "$LINE" ]; then
    if echo "$LINE" | grep -q '^data:'; then
      echo "$LINE" | cut -d":" -f2- > /tmp/smee-data
    fi
  else
    EVENT_KEY=$(jq -r .\"x-event-key\" /tmp/smee-data)
    BODY="$(jq .body /tmp/smee-data)"
    if [[ $EVENT_KEY != "null" ]] || [[ $BODY != "null" ]]; then
      echo curl -s --retry 3 --retry-delay 0 --connect-timeout 10 --max-time 30 -X POST "$JENKINS_URL" -H "Content-Type: application/json" -H "x-event-key: $EVENT_KEY" -d "$BODY"
      curl -s --retry 3 --retry-delay 0 --connect-timeout 10 --max-time 30 -X POST "$JENKINS_URL" -H "Content-Type: application/json" -H "x-event-key: $EVENT_KEY" -d "$BODY"
      echo
    fi
  fi
done
