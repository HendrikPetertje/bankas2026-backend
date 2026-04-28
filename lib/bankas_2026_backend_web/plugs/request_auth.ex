defmodule Bankas2026BackendWeb.Plugs.RequestAuth do
  @behaviour Plug

  import Plug.Conn

  alias Bankas2026Backend.Accounts

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with [authorization] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.get_user_from_jwt(authorization) do
      assign(conn, :current_user, user)
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{errors: %{detail: "Unauthorized"}})
        |> halt()
    end
  end
end
