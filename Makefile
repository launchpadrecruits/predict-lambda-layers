TIMESTAMP:=$(shell date --rfc-3339=seconds | tr -d ' :-' | cut -b 1-12)
.ONESHELL:
# requests HTTP client library

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
	echo "Package size:" `du -hs requests_layer_pack_$(TIMESTAMP).zip`
	aws s3 cp requests_layer_pack_$(TIMESTAMP).zip s3://predict-lambda-layers
	rm -f requests_layer_pack_*.zip

deploy-requests-layer: pack-requests-layer
	aws cloudformation deploy --template-file requests/template.yaml --stack-name predict-requests-layer --parameter-overrides Timestamp=$(TIMESTAMP)


## AWS X-Ray SDK
install-xray-deps:
	export PIPENV_VENV_IN_PROJECT=1
	cd aws-xray-sdk-python && pipenv install

pack-xray-layer: install-xray-deps
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "*.pyc" -type f -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "__pycache__" -type d -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "wheel*" -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "pip" -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "setuptools*" -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "pkg_resources" -delete
	find aws-xray-sdk-python/.venv/lib/python3.7/site-packages/ -name "*dist-info" -delete
	mv aws-xray-sdk-python/.venv python
	zip -r xray_layer_pack_$(TIMESTAMP).zip python/lib/python3.7/site-packages/
	rm -rf python
	echo "Package size:" `du -hs xray_layer_pack_$(TIMESTAMP).zip`
	aws s3 cp xray_layer_pack_$(TIMESTAMP).zip s3://predict-lambda-layers
	rm -f xray_layer_pack_*.zip

deploy-xray-layer: pack-xray-layer
	aws cloudformation deploy --template-file aws-xray-sdk-python/template.yaml --stack-name aws-xray-sdk-layer --parameter-overrides Timestamp=$(TIMESTAMP) LayerBundle=xray_layer_pack





