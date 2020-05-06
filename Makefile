TIMESTAMP:=$(shell date +%s)
.ONESHELL:
install-requests-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd requests && pipenv install

pack-requests-layer: install-requests-deps
	find requests/.venv/lib/python3.7/site-packages/ -name "*.pyc" -type f -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "__pycache__" -type d -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "wheel*" -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "pip" -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "setuptools*" -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "pkg_resources" -delete
	find requests/.venv/lib/python3.7/site-packages/ -name "*dist-info" -delete
	mv requests/.venv python
	zip -r requests_layer_pack_$(TIMESTAMP).zip python/lib/python3.7/site-packages/
	rm -rf python
	aws s3 cp requests_layer_pack_$(TIMESTAMP).zip s3://predict-lambda-layers
	rm -f requests_layer_pack_*.zip

install-lc-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd logging_config && pipenv install

pack-lc-layer: install-lc-deps
	cp logging_config/logging_set_up.py logging_config/.venv/lib/python3.7/site-packages/
	find logging_config/.venv/lib/python3.7/site-packages/ -name "*.pyc" -type f -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "__pycache__" -type d -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "wheel*" -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "pip" -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "setuptools*" -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "pkg_resources" -delete
	find logging_config/.venv/lib/python3.7/site-packages/ -name "*dist-info" -delete
	mv logging_config/.venv python
	zip -r lc_layer_pack_$(TIMESTAMP).zip python/lib/python3.7/site-packages/
	rm -rf python
	aws s3 cp lc_layer_pack_$(TIMESTAMP).zip s3://predict-lambda-layers
	rm -f lc_layer_pack_*.zip


deploy-layers: pack-requests-layer, pack-lc-layer
	aws cloudformation deploy --template-file template.yaml --stack-name predict-lambda-layers --parameter-overrides Timestamp=$(TIMESTAMP)
