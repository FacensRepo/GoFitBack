defmodule Gofitback.Games do
  use Ash.Domain,
    otp_app: :gofitback

  resources do
    resource Gofitback.Games.GameType
    resource Gofitback.Games.UserHistoric
  end
end
