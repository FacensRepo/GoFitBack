defmodule Gofitback.Games.UserHistoric do
  use Ash.Resource,
    otp_app: :nexus,
    domain: Gofitback.Games,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  @moduledoc """
  Resource for ResourceName.
  """

  policies do
    policy always() do
      authorize_if actor_present()
    end
  end

  graphql do
    type :user_historic_type

    queries do
      get :get_historic_type, :read
      list :list_historic_type, :read_paginated
    end

    mutations do
      create :create_historic_type, :create
      update :update_historic_type, :update
    end
  end

  postgres do
    table "user_historic"
    repo Gofitback.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :read_paginated do
      pagination do
        required? false
        keyset? true
        default_limit 10
        countable true
        max_page_size 10
      end
    end
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :points, :integer, allow_nil?: false, public?: true
    create_timestamp :created_at, public?: true
    update_timestamp :update_at, public?: true
  end

  relationships do
    belongs_to :user, Gofitback.Accounts.User, public?: true
    belongs_to :game_type, Gofitback.Games.GameType, public?: true
  end
end
