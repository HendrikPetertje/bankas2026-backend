defmodule Bankas2026BackendWeb.Plugs.ApiCors do
  @behaviour Plug

  import Plug.Conn

  @allowed_origins MapSet.new([
                     "https://lager.bankasviken",
                     "http://localhost:3000"
                   ])

  @allowed_methods "GET, POST, OPTIONS"
  @allowed_headers "authorization, content-type"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{path_info: ["api" | _rest]} = conn, _opts) do
    conn = maybe_put_cors_headers(conn)

    if conn.method == "OPTIONS" do
      conn
      |> send_resp(:no_content, "")
      |> halt()
    else
      conn
    end
  end

  def call(conn, _opts), do: conn

  defp maybe_put_cors_headers(conn) do
    case get_req_header(conn, "origin") do
      [origin] ->
        if MapSet.member?(@allowed_origins, origin) do
          conn
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("access-control-allow-methods", @allowed_methods)
          |> put_resp_header("access-control-allow-headers", @allowed_headers)
          |> put_resp_header("vary", "origin")
        else
          conn
        end

      _ ->
        conn
    end
  end
end
