{:ok, _} = Node.start(:"safe_nif_test@127.0.0.1", :longnames)

ExUnit.start()
