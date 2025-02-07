defmodule Hamlet.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: Hamlet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
