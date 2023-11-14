SHELL := /usr/bin/env bash

plugin:
	@echo creating plugin configuration file
	bash ./scripts/plugingen.sh -p $(PLUGIN)

lint:
	lint-lua lint-sh

lint-lua:
	luacheck *.lua lua/* tests/*

lint-sh:
	shfmt -f . | grep -v jdtls | xargs shellcheck

style: style-lua style-sh

style-lua:
	stylua --config-path .stylua.toml --check .

style-sh:
	shfmt -f . | grep -v jdtls | xargs shfmt -i 2 -ci -bn -l -d
	
