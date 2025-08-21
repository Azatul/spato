defmodule Spato.Repo.Migrations.AddGenderToProfile do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add :gender, :string
    end

  end
end
