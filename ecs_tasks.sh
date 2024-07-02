#!/bin/bash

load_translations() {
  local lang_url="$1"
  local lang_file="/tmp/translation.json"

  curl -s -o "$lang_file" "$lang_url"

  if [ ! -f "$lang_file" ]; then
    echo "Translation file not found!"
    exit 1
  fi

  choose_profile=$(jq -r '.choose_profile' "$lang_file")
  new_profile=$(jq -r '.new_profile' "$lang_file")
  configure_sso=$(jq -r '.configure_sso' "$lang_file")
  login_previous_profile=$(jq -r '.login_previous_profile' "$lang_file")
  exit=$(jq -r '.exit' "$lang_file")
  invalid_option=$(jq -r '.invalid_option' "$lang_file")
  you_selected_profile=$(jq -r '.you_selected_profile' "$lang_file")
  no_clusters_found=$(jq -r '.no_clusters_found' "$lang_file")
  choose_cluster=$(jq -r '.choose_cluster' "$lang_file")
  choose_service=$(jq -r '.choose_service' "$lang_file")
  no_active_tasks=$(jq -r '.no_active_tasks' "$lang_file")
  choose_task=$(jq -r '.choose_task' "$lang_file")
  task_id_is=$(jq -r '.task_id_is' "$lang_file")
  bye=$(jq -r '.bye' "$lang_file")
  execute_command_not_enabled=$(jq -r '.execute_command_not_enabled' "$lang_file")
}

echo "1) Português"
echo "2) English"
echo "3) Español"
read -p "Option: " lang_option

base_url="https://raw.githubusercontent.com/kleytonmr/ecs-task-management/main/translations/translations"

case $lang_option in
  1)
    lang_url="${base_url}_pt.json"
    ;;
  2)
    lang_url="${base_url}_en.json"
    ;;
  3)
    lang_url="${base_url}_es-419.json"
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

load_translations "$lang_url"

list_profiles() {
  profiles=($(aws configure list-profiles))
  profiles=("$new_profile" "${profiles[@]}")
  profiles=("$exit" "${profiles[@]}")
}

while true; do
  list_profiles
  profile=$(printf "%s\n" "${profiles[@]}" | fzf --prompt="$choose_profile: ")

  if [[ "$profile" == "$new_profile" ]]; then
    aws configure sso
    clear
    continue
  elif [[ "$profile" == "$exit" ]]; then
    clear
    echo "$bye"
    exit 1
  elif [ -n "$profile" ]; then
    # check active session
    if ! aws sts get-caller-identity --profile $profile > /dev/null 2>&1; then
      echo "$configure_sso"
      aws sso login --profile $profile
    fi
    break
  else
    echo "$invalid_option"
  fi
done

clear
echo "$you_selected_profile $profile"

clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

if [ ${#clusters[@]} -eq 0 ]; then
  echo -e "\n"
  echo "$no_clusters_found"
  echo "$configure_sso"
  echo "$login_previous_profile"
  echo "$exit"
  read choice

  case $choice in
    1)
      aws configure sso &
      wait $!
      exit 0
      ;;
    2)
      aws sso login --profile $profile &
      wait $!
      ;;
    3)
      echo "$bye"
      exit 1
      ;;
    *)
      echo "$invalid_option"
      exit 1
      ;;
  esac
fi

clear
cluster_name=$(printf "%s\n" "${clusters[@]}" | fzf --prompt="$choose_cluster: ")

clear
services=($(aws ecs list-services --cluster $cluster_name --profile $profile | jq -r '.serviceArns[] | split("/") | last'))

if [ ${#services[@]} -eq 0 ]; then
  echo "$no_active_tasks"
  exit 1
fi

service_name=$(printf "%s\n" "${services[@]}" | fzf --prompt="$choose_service: ")

clear
tasks=($(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --profile $profile | jq -r '.taskArns[]'))

if [ ${#tasks[@]} -eq 0 ]; then
  echo "$no_active_tasks"
  exit 1
fi

task_arn=$(printf "%s\n" "${tasks[@]}" | fzf --prompt="$choose_task: ")

task_id=$(echo $task_arn | awk -F'/' '{print $NF}')
echo "$task_id_is $task_id"

cluster_name=$(echo $task_arn | awk -F'/' '{print $(NF-1)}')

container_names=($(aws ecs describe-tasks --cluster $cluster_name --tasks $task_id --profile $profile | jq -r '.tasks[0].containers[].name'))
container_name=""

for name in "${container_names[@]}"; do
  if [[ "$name" != aws-guardduty-agent* ]]; then
    container_name="$name"
    break
  fi
done

if [ -z "$container_name" ]; then
  container_name="${container_names[0]}"
fi

if [ -z "$container_name" ]; then
  echo "$execute_command_not_enabled"
  exit 1
fi

aws ecs execute-command \
  --region us-east-1 \
  --cluster $cluster_name \
  --task $task_id \
  --container $container_name \
  --command '/bin/bash' \
  --interactive --profile $profile
