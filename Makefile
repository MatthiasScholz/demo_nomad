ui-kibana:
	open http://localhost:5601

ui-nomad:
	open http://localhost:4646

start:
	nomad agent -dev -config=config.hcl
