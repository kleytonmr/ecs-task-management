# Script para Gerenciamento Interativo de Tarefas no Amazon ECS

Este script Bash interativo permite que você escolha um cluster ECS, um serviço e, em seguida, uma task dentro desse serviço. Após escolher a task, você pode executar um comando interativo na task selecionada.

## Pré-requisitos

Antes de usar o script, certifique-se de ter o seguinte instalado em seu sistema:

1. **AWS CLI**: Certifique-se de que a AWS CLI esteja instalada e configurada com as credenciais e região corretas. Você pode instalá-la seguindo as [instruções da AWS](https://aws.amazon.com/cli/). Bonus: [How to set up AWS CLI with AWS Single Sign-On (SSO)](https://medium.com/@pushkarjoshi0410/how-to-set-up-aws-cli-with-aws-single-sign-on-sso-acf4dd88e056).

2. **jq**: O script faz uso do utilitário `jq` para processar saídas JSON. Você pode instalá-lo no macOS ou na maioria das distribuições Linux usando o gerenciador de pacotes. Exemplo para o macOS com o Homebrew:

    ```bash
    brew install jq
    ```

    Exemplo para sistemas Linux com apt:

    ```bash
    sudo apt-get install jq
    ```

## Como Usar
- MacOS, siga as instruções:
```bash
brew tap kleytonmr/tap
brew install ecs-task-management
```
https://github.com/kleytonmr/homebrew-tap#readme

- Linux/MacOS(without homebrew):

Para usar o script de gerenciamento de tasks ECS de forma global, siga os passos abaixo:

1. Clone o repositório

    ```bash
    git@github.com:kleytonmr/ecs-task-management.git
    ```

2. Navegue até o Diretórioa

    ```bash
    cd ecs-task-management
    ```

3. Tornar o Script Executável
Para macOS/Linux

    ```bash
    chmod +x ecs_tasks.sh
    ```

4. Adicionar ao PATH
Para tornar o script visível em todo o sistema e executável de qualquer diretório, adicione-o ao seu diretório bin pessoal. Certifique-se de que o diretório bin esteja incluído no seu PATH.

	a. Encontre o Diretório `bin` Pessoal

	Você pode encontrar o diretório bin pessoal executando o seguinte comando no terminal:

    ```bash
    echo $HOME/bin
    ```

	b. Copie o Script para o Diretório `bin`

    ```bash
    cp ecs_tasks.sh ~/bin/
    ```

5. Teste o Comando Global
Agora, você pode executar o script de qualquer diretório sem precisar especificar o caminho completo. Por exemplo:

    ```bash
    ecs_tasks.sh
    ```

