TIMESTAMP:=$(shell date --rfc-3339=seconds | tr -d ' :-' | cut -b 1-12)
.ONESHELL:
# requests HTTP client library

install-requests-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd requests && pipenv install

pack-requests-layer: install-requests-deps
	bash pack_layer.sh requests requests_layer_pack_$(TIMESTAMP).zip

deploy-requests-layer: pack-requests-layer
	aws cloudformation deploy --template-file requests/template.yaml --stack-name predict-requests-layer --parameter-overrides Timestamp=$(TIMESTAMP)


## Monitoring: AWS X-Ray SDK + Sentry
install-monitoring-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd monitoring && pipenv install

pack-monitoring-layer: install-monitoring-deps
	bash pack_layer.sh monitoring monitoring_layer_pack_$(TIMESTAMP).zip

deploy-monitoring-layer: pack-monitoring-layer
	aws cloudformation deploy --template-file monitoring/template.yaml --stack-name monitoring-layer --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=monitoring_layer_pack





