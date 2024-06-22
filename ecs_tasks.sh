#!/bin/bash

list_profiles() {
  profiles=($(aws configure list-profiles))
  echo -e "Escolha um perfil AWS:n\n"
  echo "0) Novo perfil (aws configure sso)"
}

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

clear

echo "Você selecionou o perfil\n: $profile"

echo "Escolha um cluster:"

clear

clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

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

clear
echo "Escolha um cluster:"

clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

select cluster_name in "${clusters[@]}"
do
  if [ -n "$cluster_name" ]; then
    break
  else
    echo "Escolha um cluster válido."
  fi
done

clear

echo "Escolha um serviço:"

services=($(aws ecs list-services --cluster $cluster_name --profile $profile | jq -r '.serviceArns[] | split("/") | last'))

select service_name in "${services[@]}"
do
  if [ -n "$service_name" ]; then
    break
  else
    echo "Escolha um serviço válido."
  fi
done

clear

tasks=($(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --profile $profile | jq -r '.taskArns[]'))

if [ ${#tasks[@]} -eq 0 ]; then
  echo "Não há tasks ativas para o serviço selecionado."
  exit 1
fi

echo "Escolha uma task_id:"

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
      --container $container_name \  # @gil27, you helped me fix a bug without knowing it. :P
      --command '/bin/bash' \        # https://github.com/kleytonmr/ecs-task-management/issues/8
      --interactive --profile $profile

    break
  else
    echo "Escolha uma task válida."
  fi
done
