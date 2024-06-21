#!/bin/bash

list_profiles() {
  profiles=($(aws configure list-profiles))
  echo -e "Escolha um perfil AWS:n\n"
  echo "0) Novo perfil (aws configure sso)"
}

# Exibe a lista de perfis e solicita a escolha de um perfil
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

# Limpa a tela antes de listar os clusters
clear

echo "Você selecionou o perfil\n: $profile"

echo "Escolha um cluster:"

# Limpa a tela antes de escolher perfil caso não esteja logado
clear

# Lista todos os clusters disponíveis no perfil escolhido
clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

# Verifica se a lista de clusters está vazia
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

# Limpa a tela antes de listar os clusters
clear
echo "Escolha um cluster:"

clusters=($(aws ecs list-clusters --profile $profile | jq -r '.clusterArns[] | split("/") | last'))

# Exibe a lista de clusters e solicita a escolha do cluster
select cluster_name in "${clusters[@]}"
do
  if [ -n "$cluster_name" ]; then
    break
  else
    echo "Escolha um cluster válido."
  fi
done

# Limpa a tela antes de listar os serviços
clear

echo "Escolha um serviço:"

# Lista todos os serviços no cluster escolhido
services=($(aws ecs list-services --cluster $cluster_name --profile $profile | jq -r '.serviceArns[] | split("/") | last'))

# Exibe a lista de serviços e solicita a escolha do serviço
select service_name in "${services[@]}"
do
  if [ -n "$service_name" ]; then
    break
  else
    echo "Escolha um serviço válido."
  fi
done

# Limpa a tela antes de listar as tasks
clear

# Lista todas as tasks do serviço escolhido
tasks=($(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --profile $profile | jq -r '.taskArns[]'))

# Verifica se a lista de tasks está vazia
if [ ${#tasks[@]} -eq 0 ]; then
  echo "Não há tasks ativas para o serviço selecionado."
  exit 1
fi

echo "Escolha uma task_id:"

# Exibe a lista de tasks e solicita a escolha da task
select task_arn in "${tasks[@]}"
do
  if [ -n "$task_arn" ]; then
    task_id=$(echo $task_arn | awk -F'/' '{print $NF}')
    echo "O ID da task é: $task_id"

    # Extrai o nome do cluster a partir do nome da task
    cluster_name=$(echo $task_arn | awk -F'/' '{print $(NF-1)}')

    # Executar o comando interativo
    aws ecs execute-command \
      --region us-east-1 \
      --cluster $cluster_name \
      --task $task_id \
      --container bioritmo-smart-system \
      --command '/bin/bash' \
      --interactive --profile $profile

    break
  else
    echo "Escolha uma task válida."
  fi
done

