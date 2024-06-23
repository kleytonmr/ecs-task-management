#!/bin/bash

load_translations() {
  local lang_file="../translations/translations_$1.json"
  if [ ! -f "$lang_file" ]; then
    echo "Translation file not found!"
    exit 1
  fi

  eval "$(jq -r 'to_entries | .[] | "local \(.key)=\(.value|@sh) "' $lang_file)"
}

echo "1) Português"
echo "2) English"
echo "3) Español"
read -p "Option: " lang_option

case $lang_option in
  1)
    lang="pt"
    ;;
  2)
    lang="en"
    ;;
  3)
    lang="es-419"
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

load_translations $lang

list_profiles() {
  profiles=($(aws configure list-profiles))
  profiles=("Novo perfil (aws configure sso)" "${profiles[@]}")
}

while true; do
  list_profiles
  profile=$(printf "%s\n" "${profiles[@]}" | fzf --prompt="$choose_profile: ")

  if [[ "$profile" == "Novo perfil (aws configure sso)" ]]; then
    aws configure sso
    clear
    continue
  elif [ -n "$profile" ]; then
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
container_name=$(aws ecs describe-tasks --cluster $cluster_name --tasks $task_id --profile $profile | jq -r '.tasks[0].containers[0].name')

execute_command_enabled=$(aws ecs describe-tasks --cluster $cluster_name --tasks $task_id --profile $profile | jq -r '.tasks[0].overrides.containerOverrides[0].command')

if [ -z "$execute_command_enabled" ]; then
  echo "$execute_command_not_enabled"
  exit 1
fi

aws ecs execute-command \
  --region us-east-1 \
  --cluster $cluster_name \
  --task $task_id \
  --container $container_name \  # @gil27, you helped me fix a bug without knowing it. :P
  --command '/bin/bash' \        # https://github.com/kleytonmr/ecs-task-management/issues/8
  --interactive --profile $profile
