defmodule Gofitback.Games.GameType do
  use Ash.Resource,
    otp_app: :gofitback,
    domain: Gofitback.Games,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  @moduledoc """
  Resource for ResourceName.
  """

  graphql do
    type :game_type_type

    queries do
      get :get_game_type, :read
      list :list_game_type, :read_paginated
    end

    mutations do
      create :create_game_type, :create
      update :update_game_type, :update
    end
  end

  postgres do
    table "game_type"
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
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :weight, :integer, allow_nil?: false, public?: true

    create_timestamp :created_at, public?: true
    update_timestamp :update_at, public?: true
  end

  relationships do
    has_many :user_historics, Gofitback.Games.UserHistoric, public?: true
  end

  identities do
    identity :unique_name, [:name]
  end
end
