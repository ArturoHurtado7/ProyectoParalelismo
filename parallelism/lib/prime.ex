defmodule Prime do
  @moduledoc """
  Documentation for `Prime`.
  """
  alias :rand, as: Rand

  def is_prime(number) do
    number |> is_prime(1000)
  end

  def is_prime(number, tries) do
    number |> miller_rabin?(tries)
  end

  #miller_Rabin
  defp modular_exp(x, y, mod) do
    with [_|bits] = Integer.digits(y, 2) do
      Enum.reduce bits, x, fn(bit, acc) -> acc * acc |> (&(if bit == 1, do: &1 * x, else: &1)).() |> rem(mod) end
    end
  end

  defp miller_rabin(d, s) when rem(d, 2) == 0, do: {s, d}
  defp miller_rabin(d, s), do: miller_rabin(div(d, 2), s + 1)

  defp miller_rabin?(n, g) do
       {s, d} = miller_rabin(n - 1, 0)
       miller_rabin(n, g, s, d)
  end

  defp miller_rabin(_, 0, _, _), do: True
  defp miller_rabin(n, g, s, d) do
    a = 1 + Rand.uniform(n - 3)
    x = modular_exp(a, d, n)
    if x == 1 or x == n - 1 do
      miller_rabin(n, g - 1, s, d)
    else
      if miller_rabin(n, x, s - 1) == True, do: miller_rabin(n, g - 1, s, d), else: False
    end
  end

  defp miller_rabin(_, _, r) when r <= 0, do: False
  defp miller_rabin(n, x, r) do
    x = modular_exp(x, 2, n)
    unless x == 1 do
      unless x == n - 1, do: miller_rabin(n, x, r - 1), else: True
    else
      False
    end
  end

end