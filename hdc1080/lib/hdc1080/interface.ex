defmodule Hdc1080.Interface do
  alias Circuits.I2C

  @result_length_bytes 4
  @config_register 0x02
  @start_measurement_register 0x00

  def discover(possible_addresses \\ [0x40, 0x41]) do
    I2C.discover_one(possible_addresses)
  end

  def open(bus_name) do
    {:ok, i2c} = I2C.open(bus_name)

    i2c
  end

  def write_config(config, bus_name, address) do
    register = Hdc1080.Config.create_config_register_bits(config)

    I2C.write!(bus_name, address, <<@config_register, register>>)
  end

  def read_result(bus_name, sensor) do
    case I2C.read(bus_name, sensor, @result_length_bytes) do
      {:ok, <<temp::16, hum::16>>} ->
        %{
          temperature: (temp / 65536 * 165 - 40) |> Float.round(2),
          humidity: (hum / 65536 * 100) |> Float.round(2)
        }

      error_tuple ->
        error_tuple
    end
  end

  def measure!(bus_name, sensor) do
    I2C.write!(bus_name, sensor, <<@start_measurement_register>>)
  end
end
