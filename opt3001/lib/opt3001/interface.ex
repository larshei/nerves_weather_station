defmodule Opt3001.Interface do
  alias Circuits.I2C
  alias Opt3001.Config
  require Logger

  @result_register <<0>>
  @config_register <<1>>

  # The Opt3001 has an address pin that can be tied to GND, VCC, SDA or SCL for 4 different
  # addresses.
  def discover(possible_addresses \\ [0x44, 0x45, 0x46, 0x47]) do
    I2C.discover_one(possible_addresses)
  end

  def open(bus_name) do
    {:ok, i2c} = I2C.open(bus_name)

    i2c
  end

  def trigger_single_measurement(bus_name, address, config) do
    register =
      config
      |> Map.put(:mode, :single_shot)
      |> Config.create_config_register_bits()

    I2C.write!(bus_name, address, <<@config_register, register>>)
  end

  def read_result(bus_name, address) do
    I2C.write!(bus_name, address, @result_register)

    result = I2C.read!(bus_name, address, 2)

    result
    |> convert_result_to_lux()
  end

  defp convert_result_to_lux(<<exponent::4, mantissa::12>>) do
    Logger.debug(
      "Exponent: #{inspect(exponent, base: :binary)}, Mantissa: #{inspect(mantissa, base: :binary)}"
    )

    0.01 * mantissa * 2 ** exponent
  end
end
