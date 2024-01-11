job "observability" {
  datacenters = ["local"]
  type = "service"

  group "ui" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "grafana" {
        to = 3000
      }
    }

    task "grafana" {
      driver = "docker"
      config {
        image = "grafana/grafana:8.1.2"
        ports = ["grafana"]

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }
      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin"
        GF_AUTH_DISABLE_LOGIN_FORM = "true"
      }

      # TODO volumes:
      # - ./support/observability/grafana-datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml

      service {
        name = "grafana"
        tags = ["urlprefix-/grafana"] # Fabio
        port = "grafana"
        check {
          name     = "Grafana Alive State"
          port     = "grafana"
          type     = "http"
          method   = "GET"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  group "metrics" {
    count = 1

    network {
      port "prometheus" {
        static = 9090
      }
    }

    task "prometheus" {
      driver = "docker"
      config {
        image = "prom/prometheus:latest"
        #command = "--config.file=/etc/prometheus/prometheus.yml"
        ports = ["prometheus"]

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      service {
        name = "prometheus"
        tags = ["urlprefix-/prometheus"] # Fabio
        port = "prometheus"
        check {
          name     = "Prometheus Alive State"
          port     = "prometheus"
          type     = "http"
          method   = "GET"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }

      # TODO volumes:
      # - ./support/observability/prometheus.yaml:/etc/prometheus.yaml
      # TODO Configure to use consul for service discovery
    }
  }

  group "logs" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "loki" {
        static = 3100
      }
    }

    task "loki" {
      driver = "docker"
      config {
        image = "grafana/loki:2.3.0"
        command = "-config.file=/etc/loki/local-config.yaml"
        ports = ["loki"]

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      service {
        name = "loki"
        tags = ["urlprefix-/loki"] # Fabio
        port = "loki"
        check {
          name     = "Loki Alive State"
          port     = "loki"
          type     = "http"
          method   = "GET"
          path     = "/ready"
          interval = "10s"
          timeout  = "2s"
        }
      }

      # TODO Integrate into tracing
      # env {
      #   JAEGER_AGENT_HOST = tempo
      #   JAEGER_ENDPOINT = http://tempo:14268/api/traces # send traces to Tempo
      #   JAEGER_SAMPLER_TYPE = const
      #   JAEGER_SAMPLER_PARAM = 1
      # }
    }
  }

  group "traces" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      # UI
      port "jaeger_ui" {
        static = 16686
      }

      port "jaeger_sampling" {
        static = 5778
      }

      port "jaeger_agent" {
        static = 6831
      }

      # ???
      port "jaeger_14250" {
        static = 14250
      }

      # Zipkin
      port "jaeger_zipkin_host" {
        static = 9411
      }

      # TODO CHECK USE
      port "jaeger_zipkin_http" {
        static = 19411
      }

      port "tempo_sampling" {

      }
    }

    task "tempo" {
      driver = "docker"
      config {
        image = "grafana/tempo:latest"
        command = "['-config.file=/etc/tempo.yaml']"

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      service {
        name = "tempo"
        tags = ["urlprefix-/tempo"] # Fabio
        port = "tempo_sampling"
        check {
          name     = "Tempo Alive State"
          port     = "tempo_sampling"
          type     = "http"
          method   = "GET"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      // TODO add volume or in a different way - templates?
    }

    task "jaeger" {
      # TODO Configure loki logging driver
      driver = "docker"
      config {
        image = "jaegertracing/all-in-one"
        ports = [
          "jaeger_ui",
          "jaeger_sampling",
          "jaeger_agent",
          "jaeger_14250",
          "jaeger_zipkin_host",
          "jaeger_zipkin_http"
        ]

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      env {
        COLLECTOR_ZIPKIN_HTTP_PORT = "19411"
        COLLECTOR_ZIPKIN_HOST_PORT = ":9411"
      }

      resources {
        cpu    = 200 # MHzg
        memory = 300 # MB
      }

      service {
        name = "jaeger"
        tags = ["urlprefix-/jaeger"] # Fabio
        port = "jaeger_ui"
        check {
          name     = "Jaeger Alive State"
          port     = "jaeger_ui"
          type     = "http"
          method   = "GET"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
