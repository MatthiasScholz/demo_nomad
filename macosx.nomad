job "macosx" {
  datacenters = ["local"]
  type = "service"

  group "monitoring" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      # TODO Check if a dynamic port configuration is possible as well
      #      Should be when prometheus is using consul sd :).
      port "nodeexporter" {
        static = 9100
      }
    }

    task "nodeexporter" {
      driver = "raw_exec"
      config {
        command = "local/node_exporter-1.2.2.darwin-amd64/node_exporter"
      }

      artifact {
        source = "https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.darwin-amd64.tar.gz"
      }


      service {
        name = "macosx"
        tags = ["urlprefix-/macosx"] # Fabio
        port = "nodeexporter"
        check {
          name     = "MacOSX Node Exporter Alive State"
          port     = "nodeexporter"
          type     = "http"
          method   = "GET"
          path     = "/metrics"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
