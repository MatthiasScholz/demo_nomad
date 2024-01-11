datacenter = "local"

data_dir = "/tmp/nomad/data/client"

client {
  enabled       = true
}

# https://www.nomadproject.io/docs/drivers/raw_exec
plugin "raw_exec" {
  config {
    enabled = true
  }
}
