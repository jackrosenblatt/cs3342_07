defmodule Ex03 do

  @moduledoc """

  `Enum.map` takes a collection, applies a function to each element in
  turn, and returns a list containing the result. It is an O(n)
  operation.

  Because there is no interaction between each calculation, we could
  process all elements of the original collection in parallel. If we
  had one processor for each element in the original collection, that
  would turn it into an O(1) operation in terms of elapsed time.

  However, we don't have that many processors on our machines, so we
  have to compromise. If we have two processors, we could divide the
  map into two chunks, process each independently on its own
  processor, then combine the results.

  You might think this would halve the elapsed time, but the reality
  is that the initial chunking of the collection and the eventual
  combining of the results both take time. As a result, the speed up
  will be less that a factor of two. If the work done in the mapping
  function is time consuming, then the speedup factor will be greater,
  as the overhead of chunking and combining will be relatively less.
  If the mapping function is trivial, then parallelizing the code will
  actually slow it down.

  Your mission is to implement a function

	  pmap(collection, process_count, func)

  This will take the collection, split it into n chunks, where n is
  the process count, and then run each chunk through a regular map
  function, but with each map running in a separate process. It then
  combines the results (in the correct order). It should use
  spawn and message passing (and not agents, tasks, or genservers).
  It should not use any conditional logic (if/cond/case).

  Useful functions include `Enum.map/3`, `Enum.chunk_every/4`, and
  `Enum.flat_map/1`.

  Feel free to use one or more helper functions... (there may be some
  extra credit for code that is well factored and that looks good).
  My solution is about 40 lines (including some blank ones) and
  six helper functions.

  35 points:
	 it works and passes all tests:    25
	 it contains no conditional logic:  3
	 it is nicely structured            7
  """

	def pmap(collection, process_count, function) do
		splitCollection(collection, process_count)
		|> mapCollections(function)
	end
	
	#Divides the collection into n groups where n is process_count
	def splitCollection(collection, process_count) do
		collection |> Enum.chunk_every(trunc(Enum.count(collection) / process_count))
	end
	
	#Maps each sub collection to a process
	def mapCollections(collections, function) do
		Enum.map(collections, fn collection -> spawnProcess(collection, function) end)
		|> Enum.flat_map(fn pid -> (receive do {^pid, val} -> val end) end)
	end
	
	#Spawns a process on the sub collection
	def spawnProcess(collection, function) do
		spawn Ex03, :runFunction, [collection, function, self()]
	end
	
	#Runs the function on the sub collection and returns the sub collection after the function run
	def runFunction(collection, function, from) do
		newCollection = collection |> Enum.map(fn value -> function.(value) end)
		send from, {self(), newCollection}
	end

end



######### no changes below here #############

ExUnit.start
defmodule TestEx03 do
  use ExUnit.Case
  import Ex03

  @expected 2..11 |> Enum.into([])

  test "pmap with 1 process" do
	assert pmap(1..10, 1, &(&1+1)) == @expected
  end

  test "pmap with 2 processes" do
	assert pmap(1..10, 2, &(&1+1)) == @expected
  end

  test "pmap with 3 processes (doesn't evenly divide data)" do
	assert pmap(1..10, 3, &(&1+1)) == @expected
  end

  test "actually reduces time" do
	range = 1..6

	# random calculation to burn some time.
	# Note that the sleep value reduces
	# with successive values, so the
	# later values will complete firest. Does
	# your code correctl;y gather the results in the
	# right order?

	calc  = fn n -> :timer.sleep(10-n); n*3 end

	{ time1, result1 } = :timer.tc(fn -> pmap(range, 1, calc) end)
	{ time2, result2 } = :timer.tc(fn -> pmap(range, 2, calc) end)
	{ time3, result3 } = :timer.tc(fn -> pmap(range, 3, calc) end)

	expected = 1..6 |> Enum.map(&(&1*3))
	assert result1 == expected
	assert result2 == expected
	assert result3 == expected

	assert time2 < time1 * 0.75   # in theory should be 0.5
	assert time3 < time1 * 0.45   # and 0.33
  end

end
