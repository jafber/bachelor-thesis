#!/bin/bash
#SBATCH --job-name=qwen35-4b-critic-smoke
#SBATCH --account=sci-demelo
#SBATCH --partition=pot-hpi-gpu-batch
#SBATCH --constraint=ARCH:X86&GPU_MEM:40GB
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --chdir=/sc/home/jan.berndt/better-nli/final
#SBATCH --output=logs/qwen35_4b_smoke_%j.log

# run from final/
# sbatch slurm_jobs/run_qwen35_4b_smoke.slurm

set -euo pipefail
export TOKENIZERS_PARALLELISM=false
export PYTHONUNBUFFERED=1

exec /sc/home/jan.berndt/conda3/envs/better-nli/bin/python -u run_critic_experiment.py \
    --model Qwen/Qwen3.5-4B \
    --sample-size 4 \
    --batch-size 16 \
    --seed 42 \
    --results runs/qwen35_4b_smoke.csv
