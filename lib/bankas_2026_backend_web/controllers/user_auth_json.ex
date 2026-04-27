defmodule Bankas2026BackendWeb.UserAuthJSON do
  def auth(%{token: token, garden: garden}) do
    %{token: token, garden: garden}
  end
end
