defmodule Gofitback.Accounts.User do
  use Ash.Resource,
    otp_app: :gofitback,
    domain: Gofitback.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshGraphql.Resource]

    require Ash.Query

  authentication do
    # add_ons do
    #   log_out_everywhere do
    #     apply_on_password_change? true
    #   end

    #   confirmation :confirm_new_user do
    #     monitor_fields [:email]
    #     confirm_on_create? true
    #     confirm_on_update? false
    #     require_interaction? true
    #     confirmed_at_field :confirmed_at
    #     auto_confirm_actions [:sign_in_with_magic_link, :reset_password_with_token]
    #     sender Gofitback.Accounts.User.Senders.SendNewUserConfirmationEmail
    #   end
    # end

    tokens do
      enabled? true
      token_resource Gofitback.Accounts.Token
      signing_secret Gofitback.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      password :password do
        identity_field :email
        hash_provider AshAuthentication.BcryptProvider

        resettable do
          sender Gofitback.Accounts.User.Senders.SendPasswordResetEmail
          # these configurations will be the default in a future release
          password_reset_action_name :reset_password_with_token
          request_password_reset_action_name :request_password_reset_token
        end
      end
    end
  end

  graphql do
    type :user

    queries do
      read_one :sign_in, :sign_in_with_password, type_name: :user_with_token
      # list :list_users, :read_paginated

      list :list_users, :read
      list :weekly_ranking, :weekly_ranking
      # hide_inputs: [:id]
      # get :get_by_token, :get_by_subject
    end

    mutations do
      action :request_password_reset_token, :request_password_reset_token
      create :create_user, :register_with_password
      update :user_update_active, :user_update_active
      # update :update_user, :update_user
      # update :reset_password_with_token, :reset_password_with_token
      # update :update_opened, :update_opened
    end
  end

  postgres do
    table "users"
    repo Gofitback.Repo
  end

  actions do
    defaults [:read]

    read :weekly_ranking do
      prepare fn query, _ ->
        query
        |> Ash.Query.load(:weekly_points)
        |> Ash.Query.sort(weekly_points: :desc)
      end
    end

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    update :change_password do
      # Use this action to allow users to change their password by providing
      # their current password and a new password.

      require_atomic? false
      accept []
      argument :current_password, :string, sensitive?: true, allow_nil?: false

      argument :password, :string,
        sensitive?: true,
        allow_nil?: false,
        constraints: [min_length: 8]

      argument :password_confirmation, :string, sensitive?: true, allow_nil?: false

      validate confirm(:password, :password_confirmation)

      validate {AshAuthentication.Strategy.Password.PasswordValidation,
                strategy_name: :password, password_argument: :current_password}

      change {AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password}
    end

    read :sign_in_with_password do
      graphql(type: :user_with_token, expose_metadata?: true)

      description "Attempt to sign in using a email and password."
      get? true

      argument :email, :ci_string do
        description "The email to use for retrieving the user."
        allow_nil? false
      end

      argument :password, :string do
        description "The password to check for the matching user."
        allow_nil? false
        sensitive? true
      end

      # validates the provided email and password and generates a token
      prepare AshAuthentication.Strategy.Password.SignInPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    read :sign_in_with_token do
      # In the generated sign in components, we validate the
      # email and password directly in the LiveView
      # and generate a short-lived token that can be used to sign in over
      # a standard controller action, exchanging it for a standard token.
      # This action performs that exchange. If you do not use the generated
      # liveviews, you may remove this action, and set
      # `sign_in_tokens_enabled? false` in the password strategy.

      description "Attempt to sign in using a short-lived sign in token."
      get? true

      argument :token, :string do
        description "The short-lived sign in token."
        allow_nil? false
        sensitive? true
      end

      # validates the provided sign in token and generates a token
      prepare AshAuthentication.Strategy.Password.SignInWithTokenPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    create :register_with_password do
      description "Register a new user with a email and password."

      argument :name, :string do
        allow_nil? false
      end

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      # Sets the email from the argument
      change set_attribute(:email, arg(:email))
      change set_attribute(:name, arg(:name))

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    update :user_update_active do
      require_atomic? false

      change fn changeset, _ ->
        value = Ash.Changeset.get_attribute(changeset, :active)
        Ash.Changeset.change_attribute(changeset, :active, not value)
      end
    end

    action :request_password_reset_token do
      description "Send password reset instructions to a user if they exist."

      argument :email, :ci_string do
        allow_nil? false
      end

      # creates a reset token and invokes the relevant senders
      run {AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email}
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get_by :email
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      # validates the provided reset token
      validate AshAuthentication.Strategy.Password.ResetTokenValidation

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end

    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action(:register_with_password) do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if always()
    end

    policy action(:weekly_ranking) do
      authorize_if always()
    end

    policy action(:sign_in_with_password) do
      # authorize_if always()
      authorize_if expr(active == true)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :name, :string, allow_nil?: false, public?: true

    attribute :active, :boolean, allow_nil?: false, public?: true, default: false

    create_timestamp :created_at, public?: true
    update_timestamp :updated_at, public?: true

    # attribute :confirmed_at, :utc_datetime_usec
  end

  aggregates do
    sum :weekly_points, :user_historics, :points do
      filter expr(
        created_at >= fragment("date_trunc('week', CURRENT_TIMESTAMP AT TIME ZONE 'UTC')")
      )
      public? true
    end
  end

  relationships do
    has_many :user_historics, Gofitback.Games.UserHistoric, public?: true
    has_many :checkins, Gofitback.Games.Checkin, public?: true
  end

  identities do
    identity :unique_email, [:email]
  end
end
