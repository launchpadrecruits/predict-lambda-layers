#!/bin/bash
# Usage: pack_layer.sh dir bundle_name
#
# Example: pack_layer.sh requests requests_layer_pack_$(TIMESTAMP).zip

layer_dir=$1
layer_bundle_filename=$2

echo "Bundling $layer_dir into $layer_bundle_filename"

cp $layer_dir/*.py $layer_dir/.venv/lib/python3.7/site-packages/
find $layer_dir/.venv/lib/python3.7/site-packages -name "*.pyc" -print -type f -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "__pycache__" -print -type d -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "wheel*" -print -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "pip*" -print -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "setuptools*" -print -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "pkg_resources" -print -exec rm -rf {} \;
find $layer_dir/.venv/lib/python3.7/site-packages -name "*dist-info" -print -exec rm -rf {} \;
mv $layer_dir/.venv python
zip -r $layer_bundle_filename python/lib/python3.7/site-packages/
rm -rf python
echo "Package size:" `du -hs $layer_bundle_filename`
aws s3 cp $layer_bundle_filename s3://predict-lambda-layers
rm -f $layer_bundle_filename
