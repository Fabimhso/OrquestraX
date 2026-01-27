defmodule OrquestraXWeb.PageController do
  use OrquestraXWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
