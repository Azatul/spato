defmodule Spato.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :title, :string
      add :message, :text
      add :type, :string
      add :status, :string, default: "unread"
      add :user_id, references(:users, on_delete: :nothing)
      add :admin_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:admin_id])
  end
end
