
#!/bin/bash

# Lista todos os clusters disponíveis
clusters=($(aws ecs list-clusters | jq -r '.clusterArns[] | split("/") | last'))

# Exibe a lista de clusters e solicita a escolha do cluster
select cluster_name in "${clusters[@]}"
do
  if [ -n "$cluster_name" ]; then
    break
  else
    echo "Escolha um cluster válido."
  fi
done

# Lista todos os serviços no cluster escolhido
services=($(aws ecs list-services --cluster $cluster_name | jq -r '.serviceArns[] | split("/") | last'))

# Exibe a lista de serviços e solicita a escolha do serviço
select service_name in "${services[@]}"
do
  if [ -n "$service_name" ]; then
    break
  else
    echo "Escolha um serviço válido."
  fi
done

# Lista todas as tasks do serviço escolhido
tasks=($(aws ecs list-tasks --cluster $cluster_name --service-name $service_name | jq -r '.taskArns[]'))

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
      --command 'launcher bash' \
      --interactive

    break
  else
    echo "Escolha uma task válida."
  fi
done

