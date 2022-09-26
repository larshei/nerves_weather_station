defmodule Opt3001 do
  use GenServer
  alias Opt3001.Config
  alias Opt3001.Interface

  ## Client API
  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_last_reading() do
    GenServer.call(__MODULE__, :get_last_reading)
  end

  ## Server API
  @impl true
  def init(%{address: address, bus_name: bus_name} = args) do
    i2c = Interface.open(bus_name)

    config =
      args
      |> Map.take([
        :conversion_time,
        :fault_count_before_interrupt,
        :interrupt_pin_polarity,
        :latch,
        :mode,
        :sensitivity
      ])
      |> Config.new()

    state = %{
      address: address,
      i2c: i2c,
      last_reading: nil,
      config: config
    }

    :timer.send_interval(10_000, :measure)

    {:ok, state}
  end

  @impl true
  def init(args) do
    {:ok, {i2c, address}} = Interface.discover()

    defaults =
      args
      |> Map.put(:address, address)
      |> Map.put(:bus_name, i2c)

    init(defaults)
  end

  @impl true
  def handle_info(:measure, %{i2c: i2c, address: address, config: config} = state) do
    state =
      with :ok <- Interface.trigger_single_measurement(i2c, address, config),
           :ok <- Process.sleep(delay_for_conversion_setting(config.conversion_time)),
           result <- Interface.read_result(i2c, address) do
        Map.put(state, :last_reading, result)
      else
        _ -> state
      end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_last_reading, _from, %{last_reading: last_reading} = state) do
    {:reply, last_reading, state}
  end

  defp delay_for_conversion_setting(:low), do: 110
  defp delay_for_conversion_setting(100), do: 110
  # covers 800, :high and unknown settings
  defp delay_for_conversion_setting(_), do: 810
end
