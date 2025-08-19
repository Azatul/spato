defmodule Spato.Repo.Migrations.UpdateUserprofileEnums do
  use Ecto.Migration

  def change do
    # Remove is_active
    alter table(:user_profiles) do
      remove :is_active
    end

    # Change gender type to enum with USING
    execute """
    ALTER TABLE user_profiles
    ALTER COLUMN gender TYPE gender_enum
    USING gender::gender_enum
    """

    # Change employment_status type to enum with USING
    execute """
    ALTER TABLE user_profiles
    ALTER COLUMN employment_status TYPE employment_status_enum
    USING employment_status::employment_status_enum
    """
  end
end
