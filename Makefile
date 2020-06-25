LOGGING_CONFIG_LATEST_VERSION=$(shell aws s3api list-object-versions --bucket predict-lambda-layers --prefix lc_layer_pack.zip --query 'Versions[?IsLatest].[VersionId]' --output text)
REQUESTS_LATEST_VERSION=$(shell aws s3api list-object-versions --bucket predict-lambda-layers --prefix requests_layer_pack.zip --query 'Versions[?IsLatest].[VersionId]' --output text)
MONITORING_LATEST_VERSION=$(shell aws s3api list-object-versions --bucket predict-lambda-layers --prefix monitoring_layer_pack.zip --query 'Versions[?IsLatest].[VersionId]' --output text)

# LoggingConfig (lc) layer
install-lc-deps:
	export PIPENV_VENV_IN_PROJECT=1; \
	cd logging_config; \
	pipenv install

pack-lc-layer: install-lc-deps
	bash pack_layer.sh logging_config lc_layer_pack.zip

# requests HTTP client library
install-requests-deps:
	export PIPENV_VENV_IN_PROJECT=1; \
	cd requests; \
	pipenv install

pack-requests-layer: install-requests-deps
	bash pack_layer.sh requests requests_layer_pack.zip

## Monitoring: AWS X-Ray SDK + Sentry
install-monitoring-deps:
	export PIPENV_VENV_IN_PROJECT=1; \
	cd monitoring; \
	pipenv install

pack-monitoring-layer: install-monitoring-deps
	bash pack_layer.sh monitoring monitoring_layer_pack.zip

deploy-layers: pack-lc-layer pack-monitoring-layer pack-requests-layer
	aws cloudformation deploy \
		--force --template-file template.yaml \
		--stack-name predict-lambda-layers \
		--parameter-overrides \
			LCLatestVersion=$(LOGGING_CONFIG_LATEST_VERSION) \
			MonitoringLatestVersion=$(MONITORING_LATEST_VERSION) \
			RequestsLatestVersion=$(REQUESTS_LATEST_VERSION)
