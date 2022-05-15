defmodule Service do
  @moduledoc """
  Documentation for `Service`.
  """

  @values ["1", "7", "0", "2", "3", "5", "4", "6", "9", "8"]
  @divider (255 / length(@values))
  #@cores 8

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

    # Process image Data with Data Parallelism
    asciiArt = get_data_number(image, newWidth)

    # print image in original ascii art
    IO.puts("\nOriginal ASCII ART: \n")
    print_image(asciiArt, newWidth)

    # get image in ascii art
    asciiArtPrime = get_ascii_art(asciiArt)

    # print image in prime number ascii art
    IO.puts("\nPrime Number ASCII ART: \n")
    print_image(asciiArtPrime, newWidth)

    {:ok, "ASCII art generated"}
  end

  def get_data_number(image, newWidth) do
    # get image in ascii art with the elapsed time
    started_time = System.monotonic_time(:microsecond)
    dataNumber = image 
      |> :wxImage.getData() 
      |> :binary.bin_to_list()
      |> Enum.chunk_every(3) # Divide into chanels
      |> Enum.chunk_every(newWidth) # Divide into rows
      |> Enum.map(fn row -> Task.async(fn -> process_row(row) end) end)
      |> List.foldl("", fn elem, acc -> acc <> Task.await(elem) end)
    elapsed_time = (System.monotonic_time(:microsecond) - started_time) / 1000000
    IO.puts("\nTime getting dataNumber: #{elapsed_time} s")
    dataNumber
  end

  defp process_row(row) do  
    row |> List.foldl("", fn elem, acc -> 
      pixel = pixel_value(Enum.at(elem, 0), Enum.at(elem, 1), Enum.at(elem, 2)) 
      acc <> pixel
    end)
  end

  defp validate_odd(number) do
    unless rem(number, 2) == 0, do: number, else: number + 1
  end

  defp get_ascii_art(asciiArt) do
    started_time = System.monotonic_time(:millisecond)
    asciiArtPrime = asciiArt 
      |> String.to_integer()
      |> validate_odd 
      |> ascii_art(False)
      |> Integer.to_string()
    elapsed_time = (System.monotonic_time(:millisecond) - started_time) / 1000
    IO.puts("\nTime getting ASCII ART in Prime number: #{elapsed_time} s")
    asciiArtPrime
  end

  defp ascii_art(dataNumber, True), do: dataNumber - 2 
  defp ascii_art(dataNumber, False) do
    isPrime = dataNumber 
      |> sum_digits() 
      |> Prime.is_prime()
    isPrime = if isPrime == True, do: Prime.is_prime(dataNumber), else: False
    ascii_art(dataNumber + 2, isPrime)
  end

  defp pixel_value(r, g, b) do
    index = (r * 0.299 + g * 0.587 + b * 0.114) / @divider |> trunc()
    Enum.at(@values, index)
  end

  defp sum_digits(dataNumber) do
    dataNumber 
      |> Integer.digits()
      |> Enum.reduce(fn x, acc ->  x + acc end)
  end

  defp print_image(asciiArt, width) do
    asciiArt 
      |> Stream.unfold(&String.split_at(&1, width)) 
      |> Enum.take_while(&(&1 != "")) 
      |> Enum.join("\n")
      |> IO.puts()
  end

end
