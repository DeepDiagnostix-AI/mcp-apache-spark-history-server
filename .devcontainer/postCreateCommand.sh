#!/usr/bin/env bash
set -ex

curl -LsSf https://astral.sh/uv/install.sh | sh

uv tool install go-task-bin

uv python install --default
