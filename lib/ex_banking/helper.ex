defmodule ExBanking.Helper do
  alias ExBanking.UserServer

  def user_exists?(user) do
    case get_user_pid(user) do
      pid when is_pid(pid) -> true
      nil -> false
    end
  end

  def check_sender_exists(entity) do
    case user_exists?(entity) do
      true -> {:ok, :sender_exists}
      false -> {:error, :sender_does_not_exist}
    end
  end

  def check_receiver_exists(entity) do
    case user_exists?(entity) do
      true -> {:ok, :receiver_exists}
      false -> {:error, :receiver_does_not_exist}
    end
  end

  def get_user_pid(user) do
    GenServer.whereis({:global, "#{user}"})
  end

  def format_number(number) do
    number
    |> Decimal.new()
    |> Decimal.round(2)
  end

  def handle_result(result) do
    case result do
      {:ok, amount} -> {:ok, format_number(amount)}
      other -> other
    end
  end

end
