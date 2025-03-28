#!/bin/bash

OWNER=${1}
REPO=${2}
WORKFLOW_ID=${3}
REF=${4}


function get_workflow_runs () {
		workflows=`gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_ID}/runs"`
		echo ${workflows}
}

function get_workflow_ids_in_progress () {
		workflows=`get_workflow_runs`
		echo ${workflows} | jq -c '.workflow_runs[] | select((.status | contains("in_progress")) or (.status | contains("queued"))) | .id'
}

function get_final_status_of_workflows() {
		success=()
		failure=()
		workflows=`get_workflow_runs "status=completed" | jq -c '.workflow_runs[]'`
		for workflow_id in ${@}
		do
				echo WORKFLOW_ID = ${workflow_id}
				workflow_conclusion=`echo ${workflows} | jq -c "select(.id | contains(${workflow_id})) | .conclusion"`
				if [ ${workflow_conclusion} == "\"success\"" ]
				then
						success+=(${workflow_id})
				else
						failure+=(${workflow_id})
				fi
		done
		
		echo \# Success = ${#success[@]}
		echo \# Failure = ${#failure[@]}

		errors=0
		total=$((${#success[@]} + ${#failure[@]}))

		if [ ${total} -ne ${#@} ]
		then
				echo Numbers don\'t match!
				errors+=1
		fi

		if [ ${#failure[@]} -gt 0 ]
		then
				errors+=1
		fi

		if [ ${errors} -gt 0 ]
		then
				echo Datamesh Deployment FAILED
				return 1
		else
				echo Datamesh Deployment SUCCESSFUL
				return 0
		fi
}


##############################################
# Poll Status of Running Deployment Workflow #
##############################################
echo Get Id\(s\) of running workflows
running_workflow_ids=`get_workflow_ids_in_progress`
still_running_workflows=${running_workflow_ids}
while [ ${still_running_workflows[0]} ]
do
		still_running_workflows=`get_workflow_ids_in_progress`
		echo Waiting for ${#still_running_workflows[@]} running workflows to finish ...
		echo ${still_running_workflows}
		sleep 10
done
echo All ${WORKFLOW_ID} workflows finished!


#########################################
# Validate of Deployment was Successful #
#########################################
echo Now check if all were successfull ...
get_final_status_of_workflows ${running_workflow_ids[@]}
