job "search" {
  datacenters = ["local"]
  type = "service"

  group "elasticsearch" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "kibana_ui" {
        to = 5601
      }

      port "elasticsearch_http" {
        to = 9200
      }

    }

    task "kibana" {
      driver = "docker"
      config {
        image = "docker.elastic.co/kibana/kibana:7.13.1"
        ports = ["kibana_ui"]

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      env {
        #ELASTICSEARCH_URL = "http://elasticsearch.service.consul:${NOMAD_PORT_elasticsearch_http}/"
        ELASTICSEARCH_HOSTS = "http://host.docker.internal:${NOMAD_HOST_PORT_elasticsearch_http}/"
      }

      resources {
        cpu    = 512 # MHz
        memory = 512 # MB
      }

      service {
        name = "kibana"
        tags = ["urlprefix-/kibana"] # Fabio
        port = "kibana_ui"
        check {
          name     = "Kibana Alive State"
          port     = "kibana_ui"
          type     = "http"
          method   = "GET"
          path     = "/api/status"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    task "elasticsearch" {
      driver = "docker"
      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:7.13.1"
        ports = ["elasticsearch_http"]

        ulimit {
          memlock = "-1"
        }

        logging {
          type = "loki"
          config {
            loki-url = "http://host.docker.internal:3100/loki/api/v1/push"
            labels = "namespace"
          }
        }
      }

      env = {
        "node.name" = "es"
        "cluster.name" = "es-cluster"
        "bootstrap.memory_lock" = "true"
        #"cluster.initial_master_nodes" = "es"
        "discovery.type" = "single-node"
        ES_JAVA_OPTS = "-Xms512m -Xmx512m"
      }

      resources {
        cpu    = 1024 # MHz
        memory = 1024 # MB
      }

      service {
        name = "elasticsearch"
        tags = ["urlprefix-/elasticsearch"] # Fabio
        port = "elasticsearch_http"
        check {
          name     = "Elasticsearch Alive State"
          port     = "elasticsearch_http"
          type     = "http"
          method   = "GET"
          path     = "/_cat/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
