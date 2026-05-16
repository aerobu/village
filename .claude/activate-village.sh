#!/bin/bash
# Activate the village conda environment
eval "$(conda shell.bash hook)"
conda activate village
echo "✓ Activated village environment (Node.js $(node --version), npm $(npm --version))"
echo "✓ Current branch: $(git branch --show-current)"
