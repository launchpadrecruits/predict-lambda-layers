# lc — logging & config
TIMESTAMP:=$(shell date +%s)
install-lc-deps:
	cd logging_config
	export PIPENV_VENV_IN_PROJECT=1
	pipenv install

pack-lc-layer: install-lc-deps
	cp logging_config/logging_set_up.py logging_config/.venv/lib/python3.7/site-packages/
	rm -rf logging_config/.venv/lib/python3.7/site-packages/*.pyc
	rm -rf logging_config/.venv/lib/python3.7/site-packages/*__pycache__
	rm -rf logging_config/.venv/lib/python3.7/site-packages/wheel*
	zip logging_config/lc_layer_pack_$(TIMESTAMP).zip logging_config/.venv/lib/python3.7/site-packages/*
	aws s3 cp logging_config/lc_layer_pack_$(TIMESTAMP).zip s3://predict-lambda-layers

deploy-lc-layer: pack-lc-layer
	aws cloudformation deploy --template-file template.yaml --stack-name predict-lambda-layers --parameter-overrides Timestamp=$(TIMESTAMP)
