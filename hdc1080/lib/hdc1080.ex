defmodule Hdc1080 do
  use GenServer
  require Logger

  alias Hdc1080.{Interface, Config}

  ## CLIENT API

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_last_reading() do
    GenServer.call(__MODULE__, :get_last_reading)
  end

  ## SERVER API

  @impl true
  def init(%{address: address, bus_name: bus_name} = args) do
    i2c = Interface.open(bus_name)

    config =
      args
      |> Map.take([
        :enable_heater,
        :i2c_address,
        :measure_temp_and_humidity_simultaneously,
        :resolution_humidity,
        :resolution_temperature
      ])
      |> Config.new()

    Interface.write_config(config, i2c, address)
    :timer.send_interval(1000, :measure)

    state = %{
      address: address,
      config: config,
      i2c: i2c,
      last_reading: nil
    }

    {:ok, state}
  end

  def init(args) do
    Logger.info("No I2C Bus and Address specified, trying to discover HDC1080 ...")
    {:ok, {bus, address}} = Interface.discover()
    Logger.info("Probably found HDC1080 on #{bus} at address #{address}")

    defaults =
      args
      |> Map.put(:address, address)
      |> Map.put(:bus_name, bus)

    init(defaults)
  end

  @impl true
  def handle_info(:measure, %{i2c: i2c, address: address} = state) do
    state =
      with :ok = Interface.measure!(i2c, address),
           # 14 bit measurements take ~7ms for each temp and humidity.
           :ok <- Process.sleep(20),
           result <- Interface.read_result(i2c, address) do
        state |> Map.put(:last_reading, result)
      else
        _ -> state
      end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_last_reading, _from, state) do
    {:reply, state.last_reading, state}
  end
end
