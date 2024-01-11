define setup-launctl
	$(eval input=$(1))
	$(info Setting up: $(input))
	cp $(input).plist ~/Library/LaunchAgents/$(input).plist
	launchctl load ~/Library/LaunchAgents/$(input).plist
	launchctl start ~/Library/LaunchAgents/$(input).plist
	launchctl list | grep $(input)
endef

define setup-config
	$(eval input=$(1))
	$(info Setting up: $(input))
	cp $(i).hcl ~/.config/nomad/
endef

setup: setup-consul setup-nomad-server setup-nomad-client

setup-%:
	$(call setup-config, $*)
	$(call setup-launchctl, $*)

# SEE: https://www.hashicorp.com/blog/announcing-hashicorp-homebrew-tap
prerequisites:
	brew install hashicorp/tap/nomad
	brew install hashicorp/tap/consul

log_dir := /tmp/nomad/logs
data_dir := /tmp/nomad/data
test-run-nomad:
	mkdir -p $(log_dir)
	mkdir -p $(data_dir)
	nomad agent -config=nomad-server.hcl -data=$(data_dir) > $(log_dir)/nomad-server.log
	nomad agent client -config=nomad-client.hcl -data=$(data_dir) > $(log_dir)/nomad-client.log

test-cleanup:
	killall -9 nomad
	rm -rf $(log_dir)
	rm -rf $(data_dir)

open-ui:
	open http://localhost:4646
