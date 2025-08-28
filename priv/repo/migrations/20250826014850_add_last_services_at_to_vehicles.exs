defmodule Spato.Repo.Migrations.AddLastServicesAtToVehicles do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :last_services_at, :date
    end

  end
end
