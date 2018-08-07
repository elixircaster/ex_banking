defmodule ExBanking do
  alias ExBanking.{UserSupervisor, UserServer}
  import ExBanking.Helper

  def create_user(user_name) when is_binary(user_name) do
    case UserSupervisor.make_user(user_name) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def create_user(_) do
    {:error, :wrong_arguments}
  end

  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    result =
      case user_exists?(user) do
        true -> UserServer.deposit(user, amount, currency)
        false -> {:error, :user_does_not_exist}
      end

    handle_result(result)
  end

  def deposit(_, _, _) do
    {:error, :wrong_arguments}
  end

  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    result =
      case user_exists?(user) do
        true -> UserServer.withdraw(user, amount, currency)
        false -> {:error, :user_does_not_exist}
      end

    handle_result(result)
  end

  def withdraw(_, _, _) do
    {:error, :wrong_arguments}
  end

  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    result =
      case user_exists?(user) do
        true -> UserServer.get_balance(user, currency)
        false -> {:error, :user_does_not_exist}
      end

    handle_result(result)
  end

  def get_balance(_, _) do
    {:error, :wrong_arguments}
  end

  def send(from_user, to_user, amount, currency) do
    with {:ok, _sender} <- check_sender_exists(from_user),
         {:ok, _receiver} <- check_receiver_exists(to_user),
		 {:ok,from_balance} <- UserServer.withdraw(from_user, amount, currency),
		 {:ok, to_balance} <- UserServer.deposit(to_user, amount, currency) 
	do							
		{:ok, format_number(from_balance), format_number(to_balance)}
    else
      {:error, :sender_does_not_exist} -> {:error, :sender_does_not_exist}
      {:error, :receiver_does_not_exist} -> {:error, :receiver_does_not_exist}
      {:error, :not_enough_money} -> {:error, :not_enough_money}
      {:error, :too_many_requests_to_user} -> {:error, :too_many_requests_to_user}
    end 
  end
end
