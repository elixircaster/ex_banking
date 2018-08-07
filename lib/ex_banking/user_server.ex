defmodule ExBanking.UserServer do
  use GenServer

  import ExBanking.Helper

  def start_link(user_name) do
    GenServer.start_link(
      __MODULE__,
      %{currencies: %{}},
      name: {:global, "#{user_name}"},
      debug: [:statistics]
    )
  end

  def init(state) do
    {:ok, state}
  end

  def deposit(user, amount, currency) do
    pid = get_user_pid(user)

    case Process.info(pid, :message_queue_len) do
      {_, len} when len > 10 -> {:error, :too_many_requests_to_user}
      _ -> GenServer.call(pid, {:deposit, amount, currency})
    end
  end

  def withdraw(user, amount, currency) do
    pid = get_user_pid(user)

    case Process.info(pid, :message_queue_len) do
      {_, len} when len > 10 -> {:error, :too_many_requests_to_user}
      _ -> GenServer.call(pid, {:withdraw, amount, currency})
    end
  end

  def get_balance(user, currency) do
    pid = get_user_pid(user)

    case Process.info(pid, :message_queue_len) do
      {_, len} when len > 10 -> {:error, :too_many_requests_to_user}
      _ -> GenServer.call(pid, {:getbalance, user, currency})
    end
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    value = get_in(state, [:currencies, :"#{currency}"])

    state =
      case value do
        nil ->
          put_in(state, Enum.map([:currencies, :"#{currency}"], &Access.key(&1, %{})), amount)

        _ ->
          update_in(state, [:currencies, :"#{currency}"], &(&1 + amount))
      end

    {:reply, {:ok, amount + (value || 0)}, state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    value = get_in(state, [:currencies, :"#{currency}"])

    {reply, state} =
      case value do
        nil when is_nil(value) ->
          {{:error, :not_enough_money},
           put_in(state, Enum.map([:currencies, :"#{currency}"], &Access.key(&1, %{})), 0)}

        value when value == 0 ->
          {{:error, :not_enough_money}, state}

        value when amount > value ->
          {{:error, :not_enough_money}, state}

        value when value > 0 or value <= amount ->
          {{:ok, value - amount}, update_in(state, [:currencies, :"#{currency}"], &(&1 - amount))}
      end

    {:reply, reply, state}
  end

  def handle_call({:getbalance, _user, currency}, _from, state) do
    value = get_in(state, [:currencies, :"#{currency}"])

    state =
      case value do
        nil -> put_in(state, Enum.map([:currencies, :"#{currency}"], &Access.key(&1, %{})), 0)
        _ -> state
      end

    {:reply, {:ok, value || 0}, state}
  end
end
