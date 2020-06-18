TIMESTAMP:=$(shell date --rfc-3339=seconds | tr -d ' :-' | cut -b 1-12)
.ONESHELL:

# LoggingConfig (lc) layer
install-lc-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd logging_config && pipenv install

pack-lc-layer: install-lc-deps
	bash pack_layer.sh logging_config lc_layer_pack_$(TIMESTAMP).zip

deploy-lc-layer: pack-lc-layer
	aws cloudformation deploy --force --template-file logging_config/template.yaml --stack-name predict-lambda-layers --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=lc_layer_pack


# requests HTTP client library
install-requests-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd requests && pipenv install

pack-requests-layer: install-requests-deps
	bash pack_layer.sh requests requests_layer_pack_$(TIMESTAMP).zip

deploy-requests-layer: pack-requests-layer
	aws cloudformation deploy --force --template-file requests/template.yaml --stack-name predict-requests-layer --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=requests_layer_pack


## Monitoring: AWS X-Ray SDK + Sentry
install-monitoring-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd monitoring && pipenv install

pack-monitoring-layer: install-monitoring-deps
	bash pack_layer.sh monitoring monitoring_layer_pack_$(TIMESTAMP).zip

deploy-monitoring-layer: pack-monitoring-layer
	aws cloudformation deploy --force --template-file monitoring/template.yaml --stack-name monitoring-layer --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=monitoring_layer_pack





