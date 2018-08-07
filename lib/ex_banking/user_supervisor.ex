defmodule ExBanking.UserSupervisor do
  use DynamicSupervisor
  alias ExBanking.UserServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def make_user(user_name) do
    child_spec = %{
      id: UserServer,
      start: {UserServer, :start_link, [user_name]}
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
