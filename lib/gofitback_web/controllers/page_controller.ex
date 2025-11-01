defmodule GofitbackWeb.PageController do
  use GofitbackWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
