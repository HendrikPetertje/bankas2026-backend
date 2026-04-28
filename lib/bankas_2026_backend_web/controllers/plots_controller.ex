defmodule Bankas2026BackendWeb.PlotsController do
  use Bankas2026BackendWeb, :controller

  alias Bankas2026Backend.Farms
  alias Bankas2026BackendWeb.Plugs.RequestAuth

  plug RequestAuth

  def clean(conn, %{"plot_number" => plot_number}) do
    with {:ok, plot_number} <- parse_plot_number(plot_number),
         {:ok, %{garden: garden}} <- Farms.clean_plot(conn.assigns.current_user.id, plot_number) do
      render(conn, :show, garden: garden)
    else
      error -> handle_action_error(conn, error)
    end
  end

  def seed(conn, %{"plot_number" => plot_number, "plant_kind" => plant_kind}) do
    with {:ok, plot_number} <- parse_plot_number(plot_number),
         {:ok, %{garden: garden}} <-
           Farms.seed_plot(conn.assigns.current_user.id, plot_number, plant_kind) do
      render(conn, :show, garden: garden)
    else
      error -> handle_action_error(conn, error)
    end
  end

  def seed(conn, _params), do: handle_action_error(conn, {:error, :invalid_input})

  def water(conn, %{"plot_number" => plot_number}) do
    with {:ok, plot_number} <- parse_plot_number(plot_number),
         {:ok, %{garden: garden}} <- Farms.water_plot(conn.assigns.current_user.id, plot_number) do
      render(conn, :show, garden: garden)
    else
      error -> handle_action_error(conn, error)
    end
  end

  def harvest(conn, %{"plot_number" => plot_number}) do
    with {:ok, plot_number} <- parse_plot_number(plot_number),
         {:ok, %{garden: garden}} <- Farms.harvest_plot(conn.assigns.current_user.id, plot_number) do
      render(conn, :show, garden: garden)
    else
      error -> handle_action_error(conn, error)
    end
  end

  defp parse_plot_number(plot_number) when is_binary(plot_number) do
    case Integer.parse(plot_number) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :invalid_plot_number}
    end
  end

  defp handle_action_error(conn, {:error, reason}), do: handle_action_error(conn, reason)

  defp handle_action_error(conn, :invalid_plot_state) do
    conn
    |> put_status(:conflict)
    |> json(%{errors: %{detail: "Plot action conflicts with the current plot state"}})
  end

  defp handle_action_error(conn, :watering_required) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      errors: %{detail: "Plot must be watered within the last 30 minutes before seeding"}
    })
  end

  defp handle_action_error(conn, :invalid_plant_kind) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Plant kind is invalid"}})
  end

  defp handle_action_error(conn, :not_ready_for_harvest) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Plant is not ready for harvest"}})
  end

  defp handle_action_error(conn, :invalid_plot_number) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Plot number is invalid"}})
  end

  defp handle_action_error(conn, :plot_not_found) do
    conn
    |> put_status(:conflict)
    |> json(%{errors: %{detail: "Plot was not found for the current farm"}})
  end

  defp handle_action_error(conn, :not_found) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Farm not found for user"}})
  end

  defp handle_action_error(conn, :invalid_input) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Request input is invalid"}})
  end

  defp handle_action_error(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: translate_errors(changeset)})
  end

  defp handle_action_error(conn, reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: error_detail(reason)}})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%\{(\w+)\}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp error_detail(reason) when is_atom(reason) do
    reason
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp error_detail(_reason), do: "Request could not be processed"
end
