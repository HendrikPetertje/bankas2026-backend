defmodule Bankas2026Backend.AccountsFixtures do
  @moduledoc false

  alias Bankas2026Backend.Accounts

  def user_fixture(attrs \\ %{}) do
    unique_suffix = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        username: "player#{unique_suffix}",
        pin: "123456"
      })

    {:ok, user} = Accounts.create_user(attrs)
    user
  end
end
