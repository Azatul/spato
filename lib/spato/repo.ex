defmodule Spato.Repo do
  use Ecto.Repo,
    otp_app: :spato,
    adapter: Ecto.Adapters.Postgres
end
