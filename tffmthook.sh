#!/usr/bin/env bash

[[ -z $(terraform fmt "$@") ]]
