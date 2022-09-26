defmodule Hdc1080.Config do
  defstruct i2c_address: 0x40,
            measure_temp_and_humidity_simultaneously: true,
            # either 8, 11 or 14 bits
            resolution_humidity: :bits_14,
            # either 11 or 14 bits
            resolution_temperature: :bits_14,
            enable_heater: false

  def new(), do: struct(__MODULE__)
  def new(opts), do: struct(__MODULE__, opts)

  def create_config_register_bits(config) do
    sw_reset = 0
    reserved = 0
    battery_status_read_only = 0

    <<register::16>> = <<
      sw_reset::1,
      reserved::1,
      heater_enabled(config.enable_heater)::1,
      acquisition_mode(config.measure_temp_and_humidity_simultaneously)::1,
      battery_status_read_only::1,
      temperature_resolution(config.resolution_temperature)::1,
      humidity_resolution(config.resolution_humidity)::2,
      reserved::8
    >>

    register
  end

  defp humidity_resolution(:bits_8), do: 0b10
  defp humidity_resolution(:bits_11), do: 0b01
  defp humidity_resolution(:bits_14), do: 0b00
  # default to 14 bit.
  defp humidity_resolution(_), do: 0b00

  defp temperature_resolution(:bits_11), do: 0b1
  defp temperature_resolution(:bits_14), do: 0b0
  # default to 14 bit.
  defp temperature_resolution(_), do: 0b0

  defp heater_enabled(false), do: 0b0
  defp heater_enabled(true), do: 0b1
  # default to disabled
  defp heater_enabled(_), do: 0b0

  defp acquisition_mode(true), do: 0b1
  defp acquisition_mode(false), do: 0b0
  # default to measure temperature and then humidity in one go
  defp acquisition_mode(_), do: 0b1
end
