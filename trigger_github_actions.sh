#!/bin/bash

OWNER=${1}
REPO=${2}
WORKFLOW_ID=${3}
REF=${4}

function send_workflow_run_request () {
		gh api --method POST \
			 -H "Accept: application/vnd.github+json" \
			 -H "X-GitHub-Api-Version: 2022-11-28" \
			 /repos/${1}/${2}/actions/workflows/${3}/dispatches \
			 -f "ref=${4}"
}

#########################
# Trigger Re-Deployment #
#########################
echo Send Re-Deployment Request
send_workflow_run_request ${OWNER} ${REPO} ${WORKFLOW_ID} ${REF}
echo Wait ...
sleep 2
