defmodule Spato.Repo.Migrations.AddAdminIdToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :admin_id, references(:users, on_delete: :nothing)
    end

    create index(:notifications, [:admin_id])
  end
end
