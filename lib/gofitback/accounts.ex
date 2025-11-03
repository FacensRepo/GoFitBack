defmodule Gofitback.Accounts do
  use Ash.Domain,
    otp_app: :gofitback

  resources do
    resource Gofitback.Accounts.Token
    resource Gofitback.Accounts.User
  end
end
