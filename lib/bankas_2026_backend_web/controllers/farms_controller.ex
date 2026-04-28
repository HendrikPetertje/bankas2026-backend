defmodule Bankas2026BackendWeb.FarmsController do
  use Bankas2026BackendWeb, :controller

  alias Bankas2026Backend.Farms
  alias Bankas2026Backend.Farms.PlantCatalog
  alias Bankas2026BackendWeb.Plugs.RequestAuth

  plug RequestAuth when action in [:me]

  def plant_info(conn, _params) do
    render(conn, :plant_info, plants: PlantCatalog.all())
  end

  def me(conn, _params) do
    current_user = conn.assigns.current_user

    case Farms.get_farm_by_user_id(current_user.id) do
      {:ok, %{garden: garden}} ->
        render(conn, :me, garden: garden)

      {:error, :not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: "Farm not found for user"}})
    end
  end
end
