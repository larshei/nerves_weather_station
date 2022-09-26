defmodule Opt3001.Config do
  defstruct conversion_time: :low,
            fault_count_before_interrupt: 8,
            interrupt_pin_polarity: :low_active,
            latch: :window,
            mode: :single_shot,
            sensitivity: :automatic

  def new(), do: struct(__MODULE__)
  def new(opts), do: struct(__MODULE__, opts)

  def create_config_register_bits(%__MODULE__{} = config) do
    overflow_ro = 0
    conversion_ready_ro = 0
    flag_high_ro = 0
    flag_low_ro = 0
    mask_exponent = 0

    <<register::16>> = <<
      sensitivity_bits(config.sensitivity)::4,
      conversion_time_bits(config.conversion_time)::1,
      mode_bits(config.mode)::2,
      overflow_ro::1,
      conversion_ready_ro::1,
      flag_high_ro::1,
      flag_low_ro::1,
      latch_bits(config.latch)::1,
      interrupt_pin_bits(config.interrupt_pin_polarity)::1,
      mask_exponent::1,
      fault_count_before_interrupt_bits(config.fault_count_before_interrupt)::2
    >>

    register
  end

  defp sensitivity_bits(:automatic), do: 0b1100
  defp sensitivity_bits(integer), do: Bitwise.&&&(integer, 0x0F)

  defp conversion_time_bits(:low), do: 0b0
  defp conversion_time_bits(:high), do: 0b1
  defp conversion_time_bits(100), do: 0b0
  defp conversion_time_bits(800), do: 0b1

  defp conversion_time_bits(_),
    do:
      raise(
        "Opt3001 - Invalid conversion time: Allowed values are 100 or 800 (ms) or :low, :high"
      )

  defp mode_bits(:shutdown), do: 0b00
  defp mode_bits(:single_shot), do: 0b01
  defp mode_bits(:continuous), do: 0b10

  defp mode_bits(_),
    do: raise("Opt3001 invalid mode. Allowed are :shutdown, :single_shot or :continuous")

  defp interrupt_pin_bits(:low_active), do: 0b0
  defp interrupt_pin_bits(:high_active), do: 0b0

  defp interrupt_pin_bits(_),
    do:
      raise(
        "Opt3001 invalid interrupt pin mode. Allowed are :low_active (default) or :high_active"
      )

  defp latch_bits(:window), do: 0b1
  defp latch_bits(:hysteresis), do: 0b0

  defp latch_bits(_),
    do: raise("Opt3001 invalid latch mode. Allowed are :window (default) or :hysteresis")

  defp fault_count_before_interrupt_bits(1), do: 0b00
  defp fault_count_before_interrupt_bits(2), do: 0b01
  defp fault_count_before_interrupt_bits(4), do: 0b10
  defp fault_count_before_interrupt_bits(8), do: 0b11

  defp fault_count_before_interrupt_bits(_),
    do: raise("Opt3001 invalid fault count before interrupt. Allowed are 1, 2, 4, 8")
end
