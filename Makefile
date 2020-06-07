TIMESTAMP:=$(shell date --rfc-3339=seconds | tr -d ' :-' | cut -b 1-12)
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

deploy-requests-layer: pack-requests-layer
	aws cloudformation deploy --template-file requests/template.yaml --stack-name predict-requests-layer --parameter-overrides Timestamp=$(TIMESTAMP)
