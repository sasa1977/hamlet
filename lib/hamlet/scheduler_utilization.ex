defmodule Hamlet.SchedulerUtilization do
  use GenServer

  def start_link(arg),
    do: GenServer.start_link(__MODULE__, arg)

  @impl GenServer
  def init(_arg) do
    schedule_next_sample()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(:sample, state) do
    schedule_next_sample()
    {:noreply, state}
  end

  defp schedule_next_sample,
    do: Process.send_after(self(), :sample, :timer.seconds(1))
end
