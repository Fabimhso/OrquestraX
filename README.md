# OrquestraX

Plataforma Distribuída de Orquestração de Workflows Empresariais desenvolvida em Elixir.

Este projeto demonstra a criação de um sistema resiliente, distribuído e tolerante a falhas utilizando as capacidades da BEAM (Erlang VM), Ecto para persistência e Phoenix LiveView para monitoramento em tempo real.

## 🚀 Tecnologias Utilizadas

- **Elixir 1.16** / **Erlang OTP 26**: Linguagem e runtime para concorrência e distribuição.
- **Phoenix Framework 1.8**: Framework web.
- **Phoenix LiveView**: Atualizações em tempo real (WebSockets) via PubSub.
- **PostgreSQL**: Banco de dados relacional para persistência de estado e eventos.
- **Ecto**: ORM/Query Builder.
- **libcluster**: Biblioteca para descoberta automática de nós em cluster (Gossip Strategy).
- **Mise**: Gerenciador de versões (substituto moderno do asdf).

## 🏗️ Arquitetura do Sistema

O projeto foi criado como uma aplicação **Umbrella**, dividida em três aplicações principais:

1.  **`orquestra_x` (Core)**:
    -   Contém as regras de negócio, Schemas do Ecto e a lógica de orquestração.
    -   Gerencia o ciclo de vida dos workflows via `GenServer` (`WorkflowServer`).
    -   Persiste eventos de auditoria (`WorkflowEvent`).
    -   Possui o `Dispatcher`, responsável por enviar tarefas para execução em nós remotos.

2.  **`orquestra_x_web` (Interface)**:
    -   Aplicação Phoenix responsável pelo Dashboard.
    -   Utiliza LiveView para exibir o estado dos workflows em tempo real.
    -   Se inscreve no `Phoenix.PubSub` para receber atualizações do Core sem necessidade de polling.

3.  **`orquestra_x_worker` (Execução)**:
    -   Simula um nó de execução (Worker).
    -   Recebe comandos via RPC (`:rpc.cast` / `Task`).
    -   Executa o trabalho (simulado com `Process.sleep`) e reporta o resultado de volta ao Orchestrator.

### Fluxo de Funcionamento

1.  **Criação**: Um usuário cria um workflow via Dashboard (ou API). O registro é salvo no banco com status `pending`.
2.  **Inicialização**: O `WorkflowServer` é iniciado para aquele ID específico.
3.  **Execução**:
    -   O servidor muda o status para `running` e despacha o primeiro passo usando o módulo `Dispatcher`.
    -   O `Dispatcher` escolhe um nó disponível no cluster (`libcluster`) e executa a tarefa assincronamente no `orquestra_x_worker`.
4.  **Distribuição**: O Worker recebe a tarefa, executa, e envia uma mensagem (`:step_completed`) de volta para o PID do Orquestrador.
5.  **Conclusão**: O Orquestrador recebe a mensagem, grava o evento no banco, atualiza o status para `completed` e notifica o Dashboard via PubSub.
6.  **Visualização**: O Dashboard recebe a notificação e atualiza a tela instantaneamente para o usuário.

---

## 🛠️ Como o Projeto foi Criado (Passo a Passo)

### 1. Configuração do Ambiente
Como o ambiente não possuía **Elixir** instalado, utilizamos o **Mise** para instalar as versões exatas necessárias:
```bash
curl https://mise.run | sh
mise install erlang@26.2.1
mise install elixir@1.16.0-otp-26
```
Também instalamos dependências do sistema (`libncurses-dev`, `build-essential`) necessárias para compilar o Erlang.

### 2. Inicialização do Projeto
Criamos um projeto Umbrella sem dependências instaladas inicialmente:
```bash
mix phx.new . --app orquestra_x --umbrella --no-install
```

### 3. Configuração do Banco de Dados
Configuramos a conexão com o PostgreSQL local no `config/dev.exs` e criamos o banco:
```bash
mix ecto.create
```

### 4. Implementação do Core (`apps/orquestra_x`)
-   Adicionamos dependência `libcluster`.
-   Criamos as tabelas do banco: `workflows_definitions`, `workflows_instances` e `workflows_events`.
-   Implementamos o `WorkflowServer` (GenServer) para gerenciar o estado em memória.
-   Implementamos o `Dispatcher` para distribuir tarefas via RPC.

### 5. Criação do App Worker (`apps/orquestra_x_worker`)
Geramos uma nova app dentro da umbrella:
```bash
mix new apps/orquestra_x_worker --sup
```
-   Configuramos para conectar ao mesmo cluster.
-   Criamos o módulo `JobRunner` para receber e processar tarefas.

### 6. Interface Gráfica (`apps/orquestra_x_web`)
-   Criamos o Dashboard principal (`DashboardLive`).
-   Criamos a página de Detalhes (`WorkflowLive.Show`).
-   Estilizamos com TailwindCSS (padrão do Phoenix).

---

## ▶️ Como Executar

### Pré-requisitos
-   PostgreSQL rodando (porta 5432).
-   Elixir e Erlang instalados.

### Passos

1.  **Instalar dependências**:
    ```bash
    mix deps.get
    ```

2.  **Iniciar o servidor** (Orquestrador + Dashboard + Worker):
    ```bash
    iex -S mix phx.server
    ```
    *Rodamos dentro do `iex` para poder interagir com o terminal se necessário.*

3.  **Acessar**:
    Abra seu navegador em [http://localhost:4000](http://localhost:4000).

4.  **Testar**:
    -   Clique em **"New Test Workflow"**.
    -   Observe a mágica acontecer em tempo real! 🚀

## 🧪 Comandos Úteis

-   **Rodar Testes**: `mix test`
-   **Formatar Código**: `mix format`
-   **Resetar Banco**: `mix ecto.reset`

---