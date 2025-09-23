# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Spato.Repo.insert!(%Spato.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Spato.Repo
alias Spato.Accounts.User

# Admin account
admin_attrs = %{
  email: "admin@gmail.com",
  password: "admin1234567",  # must meet min 12 chars
  role: "admin"
}

%User{}
|> User.registration_changeset(admin_attrs)
|> Repo.insert!()

# Regular user account
user_attrs = %{
  email: "user@gmail.com",
  password: "user12345678",
  role: "user"
}

%User{}
|> User.registration_changeset(user_attrs)
|> Repo.insert!()
