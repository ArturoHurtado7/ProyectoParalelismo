defmodule Service do
  @moduledoc """
  Documentation for `Service`.
  """

  alias :rand, as: Rand

  @values ["1", "7", "0", "2", "3", "5", "4", "6", "9", "8"]
  @divider (255 / length(@values))
  @threads 16

  def start(path), do: start(path, 25)
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

    # show and save original ascii art
    IO.puts("\nOriginal ASCII ART: \n")
    original = get_printable(asciiArt, newWidth)
    IO.puts(original)

    # save original ascii art to file
    save_file(original, "./result/original.txt")

    # get image in ascii art
    asciiArtPrime = get_ascii_art(asciiArt)

    # show and save prime number ascii art
    IO.puts("\nPrime Number ASCII ART: \n")
    prime = get_printable(asciiArtPrime, newWidth)
    IO.puts(prime)

    # save prime number ascii art to file
    save_file(prime, "./result/prime.txt")

    {:ok, "ASCII art generated"}
  end

  def get_data_number(image, width) do
    # get image in ascii art
    image |> :wxImage.getData() 
      |> :binary.bin_to_list()
      |> Enum.chunk_every(3) # Divide into chanels rgb
      |> Enum.chunk_every(width) # Divide into rows
      |> Enum.map(fn row -> Task.async(fn -> process_row(row) end) end)
      |> List.foldl("", fn elem, acc -> acc <> Task.await(elem) end)
  end

  defp process_row(row) do 
    # row processing each pixel
    row |> List.foldl("", fn elem, acc -> 
      pixel = pixel_value(Enum.at(elem, 0), Enum.at(elem, 1), Enum.at(elem, 2)) 
      acc <> pixel
    end)
  end

  defp validate_odd(number) do
    # validate odd number if number is even, return number + 1
    unless rem(number, 2) == 0, do: number, else: number + 1
  end

  defp get_ascii_art(asciiArt) do
    # get ascii art from image with multiple Tasks
    started_time = System.monotonic_time(:millisecond)
    {_, asciiArtPrime} = asciiArt 
      |> ascii_art_tasks() 
      |> ascii_art_results([]) 
    elapsed_time = (System.monotonic_time(:millisecond) - started_time) / 1000
    IO.puts("\nTime getting ASCII ART in Prime number: #{elapsed_time} s")
    asciiArtPrime
  end

  defp ascii_art_process(asciiArt) do
    # process ascii art in each task
    asciiArt |> get_seed()
      |> String.to_integer()
      |> validate_odd()
      |> ascii_art(False)
      |> Integer.to_string()
  end

  defp ascii_art_tasks(asciiArt) do
    # create tasks for ascii art
    for _ <- 1..@threads do
      Task.async(fn -> ascii_art_process(asciiArt) end)
    end
  end

  def ascii_art_results(_, [h|_]), do: h
  def ascii_art_results(tasks, []) do
    tasks_yield = Task.yield_many(tasks, 5000)
    results = tasks_yield 
      |> Enum.map(fn {_task, res} -> res end) 
      |> Enum.filter(fn(x) -> x != nil end)
    if results != [] do
      Enum.map(tasks_yield, fn {task, _} -> Task.shutdown(task, :brutal_kill) end)
    end
    ascii_art_results(tasks, results)
  end

  defp get_seed(asciiArt) do
    # modify the ascii art randomly to get a seed
    {head, tail} = asciiArt |> String.split_at(3)
    {_, newHead} = String.to_integer(head) + Rand.uniform(1000)
      |> Integer.to_string()
      |> String.split_at(-3)
    newHead <> tail
  end

  defp ascii_art(dataNumber, True), do: dataNumber - 2 
  defp ascii_art(dataNumber, False) do
    # validate if sum of digits is prime
    isPrime = dataNumber |> sum_digits() |> Prime.is_prime()
    # validate if number is prime only if sum of digits is prime
    isPrime = if isPrime == True, do: Prime.is_prime(dataNumber), else: False
    # recursive call
    ascii_art(dataNumber + 2, isPrime)
  end

  defp pixel_value(r, g, b) do
    # get pixel value in ascii art
    index = (r * 0.299 + g * 0.587 + b * 0.114) / @divider |> trunc()
    Enum.at(@values, index)
  end

  defp sum_digits(dataNumber) do
    # get sum of digits in number
    dataNumber 
      |> Integer.digits()
      |> Enum.reduce(fn x, acc ->  x + acc end)
  end

  defp get_printable(asciiArt, width) do
    # get printable ascii art with \n in every row
    asciiArt 
      |> Stream.unfold(&String.split_at(&1, width)) 
      |> Enum.take_while(&(&1 != "")) 
      |> Enum.join("\n")
  end

  defp save_file(info, name) do
    # save info to file
    {:ok, file} = File.open(name, [:write])
    File.write(name, info)
    File.close(file)
  end

end
