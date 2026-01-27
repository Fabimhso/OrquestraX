defmodule OrquestraX.Repo do
  use Ecto.Repo,
    otp_app: :orquestra_x,
    adapter: Ecto.Adapters.Postgres
end
