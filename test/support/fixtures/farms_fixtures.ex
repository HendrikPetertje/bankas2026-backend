defmodule Bankas2026Backend.FarmsFixtures do
  @moduledoc false

  alias Bankas2026Backend.AccountsFixtures
  alias Bankas2026Backend.Farms

  def farm_fixture(user_attrs \\ %{}) do
    user = AccountsFixtures.user_fixture(user_attrs)
    {:ok, farm} = Farms.create_farm(user.id)
    %{user: user, farm: farm}
  end
end
