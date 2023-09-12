# Script para Gerenciamento Interativo de Tarefas no Amazon ECS

Este script Bash interativo permite que você escolha um cluster ECS, um serviço e, em seguida, uma task dentro desse serviço. Após escolher a task, você pode executar um comando interativo na task selecionada.

## Pré-requisitos

- [AWS Command Line Interface (CLI)](https://aws.amazon.com/cli/)
- [jq](https://stedolan.github.io/jq/) (um processador JSON de linha de comando)

Certifique-se de que você configurou a AWS CLI com suas credenciais e região AWS corretas antes de usar o script.

## Como Usar

1. Clone o repositório:

   ```bash
   git@github.com:kleytonmr/ecs-task-management.git

