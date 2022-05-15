defmodule Service do
  @moduledoc """
  Documentation for `Service`.
  """
  @values ["1", "7", "0", "2", "3", "5", "4", "6", "9", "8"]


  def start(path), do: start(path, 100)
  def start(path, newWidth) do
    # read image
    :wx.new()
    image = path |> String.to_charlist() |> :wxImage.new()

    # resize image
    if newWidth > 0 do
      {width, height} = {:wxImage.getWidth(image), :wxImage.getHeight(image)}
      newHeight = ((newWidth * height) / width) |> trunc()
      ^image = image |> :wxImage.rescale(newWidth, newHeight)
    end

    # get image data
    dataNumber = image 
      |> :wxImage.getData() 
      |> :binary.bin_to_list()
      |> Enum.chunk_every(3)
      |> Enum.map(fn x -> pixel_value(Enum.at(x, 0), Enum.at(x, 1), Enum.at(x, 2)) end)
      |> data_number()

    # get image in ascii art
    time_started = System.monotonic_time(:millisecond)
    asciiArt = dataNumber |> validate_odd |> ascii_art(False)
    time_elapsed = System.monotonic_time(:millisecond) - time_started
    IO.puts("Time elapsed: #{time_elapsed} ms")

    # print image in ascii art
    print_stadistics(asciiArt)
    print_image(dataNumber, newWidth)
    print_image(asciiArt, newWidth)
    {:ok, "ASCII art generated"}
  end

  defp print_stadistics(dataNumber) do
    IO.puts("-----Data number: #{dataNumber}")
    isPrime = Prime.is_prime(dataNumber)
    IO.puts("-----Is prime dataNumber: #{isPrime}")
    sumDigits = sum_digits(dataNumber)
    IO.puts("-----Digits sum: #{sumDigits}")
    isPrimeDigits = Prime.is_prime(sumDigits)
    IO.puts("-----Is prime sumDigits: #{isPrimeDigits}")
  end

  defp validate_odd(number) do
    unless rem(number, 2) == 0, do: number, else: number + 1
  end

  defp ascii_art(dataNumber, True), do: dataNumber - 2 
  defp ascii_art(dataNumber, _isPrime) do
    # validate sum digits is prime
    isPrime = dataNumber
      |> sum_digits()
      |> Prime.is_prime()
    # validate dataNumber is prime
    isPrime = if isPrime == True, do: Prime.is_prime(dataNumber), else: False
    ascii_art(dataNumber + 2, isPrime)
  end

  defp pixel_value(r, g, b) do
    # get pixel in grayscale
    gray_scale = (r * 0.299 + g * 0.587 + b * 0.114) |> trunc()

    # get divider range for ascii art characters 
    divider = 255 / length(@values)

    # get ascii art character index
    index = gray_scale / divider |> trunc()

    Enum.at(@values, index)
  end

  defp sum_digits(dataNumber) do
    dataNumber 
      |> Integer.digits()
      |> Enum.reduce(fn x, acc ->  x + acc end)
  end

  defp data_number(dataList) do
    dataList 
      |> List.to_string() 
      |> String.to_integer()
  end

  defp print_image(dataNumber, width) do
    dataNumber 
      |> Integer.to_string()
      |> String.split("", trim: true)
      |> Enum.chunk_every(width)
      |> Enum.map(fn x -> x |> List.to_string() end)
      |> Enum.map(fn x -> x |> IO.inspect() end)
  end

end
