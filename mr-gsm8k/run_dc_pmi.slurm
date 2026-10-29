#!/bin/bash
#SBATCH --job-name=mr-gsm8k-dc-pmi
#SBATCH --account=sci-demelo
#SBATCH --partition=gpu-batch
#SBATCH --constraint=ARCH:X86&GPU_MEM:40GB
#SBATCH --gpus=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --signal=B:TERM@120
#SBATCH --chdir=/sc/home/jan.berndt/better-nli/mr-gsm8k
#SBATCH --output=logs/dc_pmi_%j.log

set -euo pipefail

export TOKENIZERS_PARALLELISM=false
export PYTHONUNBUFFERED=1

mkdir -p logs cache
nvidia-smi

exec /sc/home/jan.berndt/conda3/envs/better-nli/bin/python -u score_dc_pmi.py \
    --sample-size 1000 \
    --seed 42 \
    --target-batch-size 8 \
    --checkpoint-every 10
