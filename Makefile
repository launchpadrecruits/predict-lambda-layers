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


## AWS X-Ray SDK
install-xray-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd aws-xray-sdk-python && pipenv install

pack-xray-layer: install-xray-deps
	bash pack_layer.sh aws-xray-sdk-python xray_layer_pack_$(TIMESTAMP).zip

deploy-xray-layer: pack-xray-layer
	aws cloudformation deploy --template-file aws-xray-sdk-python/template.yaml --stack-name aws-xray-sdk-layer --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=xray_layer_pack





