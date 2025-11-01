defmodule GofitbackWeb.ErrorJSONTest do
  use GofitbackWeb.ConnCase, async: true

  test "renders 404" do
    assert GofitbackWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert GofitbackWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
