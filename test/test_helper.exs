ExUnit.configure(capture_log: true)
# {:ok, _} = Application.ensure_all_started()
ExUnit.start(exclude: [:skip])

Ecto.Adapters.SQL.Sandbox.mode(Shuttertop.Repo, :manual)
