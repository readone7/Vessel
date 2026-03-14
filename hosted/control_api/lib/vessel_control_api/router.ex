defmodule VesselControlApi.Router do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  get "/v1/events/schema" do
    payload = %{
      event: "deploy.started|deploy.succeeded|deploy.failed|drift.detected",
      required_fields: ["org_id", "project_id", "operation_id", "timestamp", "payload"]
    }

    send_resp(conn, 200, Jason.encode!(payload))
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

