defmodule VesselControlApi.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: VesselControlApi.Router, options: [port: 4315]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: VesselControlApi.Supervisor)
  end
end

