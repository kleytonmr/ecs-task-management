#!/bin/bash

list_profiles() {
  profiles=($(aws configure list-profiles))
  echo -e "Escolha um perfil AWS:\n"
  echo "0) Novo perfil (aws configure sso)"
}

# Displays the list of profiles/prompts to choose a profile
while true; do
  list_profiles
  select profile in "${profiles[@]}"
  do
    if [ "$REPLY" -eq 0 ]; then
      aws configure sso
      clear
      break
    elif [ -n "$profile" ]; then
      break 2
    else
      echo "Escolha um perfil válido."
    fi
  done
done

# Clear the screen before listing clusters
clear

echo "Você selecionou o perfil: $profile"

# List all clusters available in the profile
clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

# Check if the cluster list is empty
if [ ${#clusters[@]} -eq 0 ]; then
  echo -e "\n"
  echo "Não foi possível listar os clusters para o perfil selecionado."
  echo "Escolha uma das opções a seguir:"
  echo "1. Configurar AWS SSO"
  echo "2. Fazer login com o perfil escolhido anteriormente"
  echo "3. Sair"
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
      echo "Bye!"
      exit 1
      ;;
    *)
      echo "Opção inválida."
      exit 1
      ;;
  esac
fi

# Clear the screen before listing clusters
clear
echo "Escolha um cluster:"

# Display the list of clusters and ask to choose the cluster
select cluster_name in "${clusters[@]}"
do
  if [ -n "$cluster_name" ]; then
    break
  else
    echo "Escolha um cluster válido."
  fi
done

# Clear the screen before listing services
clear

echo "Escolha um serviço:"

# List all services in the chosen cluster
services=($(aws ecs list-services --cluster $cluster_name --profile $profile | jq -r '.serviceArns[] | split("/") | last'))

# Displays the list of services and asks to choose the service
select service_name in "${services[@]}"
do
  if [ -n "$service_name" ]; then
    break
  else
    echo "Escolha um serviço válido."
  fi
done

# Clear the screen before listing tasks
clear

# List all tasks of the chosen service
tasks=($(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --profile $profile | jq -r '.taskArns[]'))

# Check if the task list is empty
if [ ${#tasks[@]} -eq 0 ]; then
  echo "Não há tasks ativas para o serviço selecionado."
  exit 1
fi

echo "Escolha uma task_id:"

# Displays the list of tasks and prompts you to choose
select task_arn in "${tasks[@]}"
do
  if [ -n "$task_arn" ]; then
    task_id=$(echo $task_arn | awk -F'/' '{print $NF}')
    echo "O ID da task é: $task_id"

    cluster_name=$(echo $task_arn | awk -F'/' '{print $(NF-1)}')
    container_name=$(aws ecs describe-tasks --cluster $cluster_name --tasks $task_id --profile $profile | jq -r '.tasks[0].containers[0].name')

    aws ecs execute-command \
      --region us-east-1 \
      --cluster $cluster_name \
      --task $task_id \
      --container $container_name \ # @gil27, you helped me fix a bug without knowing it. :P
      --command '/bin/bash' \       # https://github.com/kleytonmr/ecs-task-management/issues/8
      --interactive --profile $profile

    break
  else
    echo "Escolha uma task válida."
  fi
done

