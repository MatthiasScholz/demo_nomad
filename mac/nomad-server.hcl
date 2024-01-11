datacenter = "local"

data_dir = "/tmp/nomad/data/server"

server {
  enabled          = true
  bootstrap_expect = 1
}
