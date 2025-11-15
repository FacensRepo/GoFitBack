defmodule Gofitback.Games.Checkin do
  use Ash.Resource,
    otp_app: :gofitback,
    domain: Gofitback.Games,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  @moduledoc """
  Resource for daily check-ins at the gym.
  """

  graphql do
    type :checkin

    queries do
      get :get_checkin, :read
      list :list_checkin, :read
      list :list_user_checkins, :read_user_checkins
    end

    mutations do
      create :create_checkin, :create
      destroy :delete_checkin, :destroy
    end
  end

  postgres do
    table "checkins"
    repo Gofitback.Repo

    custom_indexes do
      index [:user_id, :day], unique: true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*]

    read :read_user_checkins do
      description "Get all check-ins for a specific user"

      argument :user_id, :uuid do
        allow_nil? false
      end

      filter expr(user_id == ^arg(:user_id))
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :day, :date do
      allow_nil? false
      public? true
      description "The date of the check-in"
    end

    create_timestamp :created_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    belongs_to :user, Gofitback.Accounts.User do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_user_checkin_per_day, [:user_id, :day]
  end
end
