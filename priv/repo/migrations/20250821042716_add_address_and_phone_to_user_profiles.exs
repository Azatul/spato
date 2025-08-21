defmodule Spato.Repo.Migrations.AddAddressAndPhoneToUserProfiles do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add :address, :string
      add :phone_number, :string
    end
  end

end
