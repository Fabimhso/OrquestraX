# OrquestraX

Distributed platform for orchestration of enterprise workflows developed in Elixir.

This project demonstrates the creation of a resilient, distributed, and fault-tolerant system using the capabilities of the BEAM (Erlang VM), Ecto for persistence, and Phoenix LiveView for monitoring and interaction.

## 🚀 Technologies Used

- **Elixir 1.16** / **Erlang OTP 26**: Language and runtime for concurrency and distribution.
- **Phoenix Framework 1.8**: Web framework.
- **Phoenix LiveView**: Real-time updates (WebSockets) via PubSub.
- **PostgreSQL**: Relational database for state and event persistence.
- **Ecto**: ORM/Query Builder.
- **libcluster**: Library for automatic node discovery in the cluster (Gossip Strategy).
- **Mise**: Version manager (modern replacement for asdf).

## 🏗️ System Architecture

The project was created as an **Umbrella** application, split into three main applications:

1. **`orquestra_x` (Core)**:
   - Contains business rules, Ecto Schemas, and orchestration logic.
   - Manages the lifecycle of workflows via a `GenServer` (`WorkflowServer`).
   - Persists audit events (`WorkflowEvent`).
   - Includes the `Dispatcher`, responsible for sending tasks for execution to remote nodes.

2. **`orquestra_x_web` (Interface)**:
   - Phoenix application responsible for the Dashboard.
   - Uses LiveView to display workflow states in real time.
   - Subscribes to `Phoenix.PubSub` to receive Core updates without polling.

3. **`orquestra_x_worker` (Execution)**:
   - Simulates an execution node (Worker).
   - Receives commands via RPC (`:rpc.cast` / `Task`).
   - Executes the job (simulated with `Process.sleep`) and reports the result back to the Orchestrator.

### Workflow Flow

1. **Creation**: A user creates a workflow via the Dashboard (or API). The record is saved in the database with status `pending`.
2. **Initialization**: The `WorkflowServer` is started for that specific ID.
3. **Execution**:
   - The server changes the status to `running` and dispatches the first step using the `Dispatcher` module.
   - The `Dispatcher` chooses an available node in the cluster (`libcluster`) and executes the task asynchronously on the `orquestra_x_worker`.
4. **Distribution**: The Worker receives the task, performs it, and sends a message (`:step_completed`) back to the Orchestrator's PID.
5. **Completion**: The Orchestrator receives the message, writes the event to the database, updates the status to `completed`, and notifies the Dashboard via PubSub.
6. **Visualization**: The Dashboard receives the notification and updates the UI instantly for the user.

---

## 🛠️ How the Project Was Created (Step-by-Step)

### 1. Environment Setup
Because the environment didn't have **Elixir** installed, we used **Mise** to install the exact required versions:
```bash
curl https://mise.run | sh
mise install erlang@26.2.1
mise install elixir@1.16.0-otp-26
```
We also installed system dependencies (`libncurses-dev`, `build-essential`) required to compile Erlang.

### 2. Project Initialization
We created an Umbrella project without installing dependencies initially:
```bash
mix phx.new . --app orquestra_x --umbrella --no-install
```

### 3. Database Configuration
Configured the connection to the local PostgreSQL in `config/dev.exs` and created the database:
```bash
mix ecto.create
```

### 4. Core Implementation (`apps/orquestra_x`)
- Added the `libcluster` dependency.
- Created database tables: `workflows_definitions`, `workflows_instances`, and `workflows_events`.
- Implemented the `WorkflowServer` (GenServer) to manage in-memory state.
- Implemented the `Dispatcher` to distribute tasks via RPC.

### 5. Worker App Creation (`apps/orquestra_x_worker`)
Generated a new app inside the umbrella:
```bash
mix new apps/orquestra_x_worker --sup
```
- Configured it to connect to the same cluster.
- Created the `JobRunner` module to receive and process tasks.

### 6. Graphical Interface (`apps/orquestra_x_web`)
- Created the main Dashboard (`DashboardLive`).
- Created the Details page (`WorkflowLive.Show`).
- Styled with TailwindCSS (Phoenix default).

---

## ▶️ How to Run

### Prerequisites
- PostgreSQL running (port 5432).
- Elixir and Erlang installed.

### Steps

1. **Install dependencies**:
   ```bash
   mix deps.get
   ```

2. **Start the server** (Orchestrator + Dashboard + Worker):
   ```bash
   iex -S mix phx.server
   ```
   *We run inside `iex` to be able to interact with the runtime if needed.*

3. **Access**:
   Open your browser at [http://localhost:4000](http://localhost:4000).

4. **Test**:
   - Click **"New Test Workflow"**.
   - Watch the magic happen in real time! 🚀

## 🧪 Useful Commands

- **Run Tests**: `mix test`
- **Format Code**: `mix format`
- **Reset Database**: `mix ecto.reset`

---
