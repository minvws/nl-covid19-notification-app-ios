#!/usr/bin/env bash

echo "Installing Mockolo"
brew install mockolo

echo "Install xcodegen"
brew install xcodegen

echo "Generate project"
xcodegen
