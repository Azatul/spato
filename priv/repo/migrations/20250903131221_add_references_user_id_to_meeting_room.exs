defmodule Spato.Repo.Migrations.AddReferencesUserIdToMeetingRoom do
  use Ecto.Migration

  def change do
    alter table(:meeting_rooms) do
      add :user_id, references(:users, on_delete: :nothing)  # atau :delete_all kalau nak cascade
    end

    create index(:meeting_rooms, [:user_id])
  end
end
