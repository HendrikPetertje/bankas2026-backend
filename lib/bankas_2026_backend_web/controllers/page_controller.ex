defmodule Bankas2026BackendWeb.PageController do
  use Bankas2026BackendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
