#!/usr/bin/env bash
mkdir -p dist
cp -R src/*.py dist/
cd src
python3 -m venv v-env
source v-env/bin/activate
pip install -r requirements.txt
deactivate
cp -R v-env/lib/python3.5/site-packages/* ../dist/
cd .. || return
