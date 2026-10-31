#!/bin/bash
#SBATCH --job-name=qwen35-4b-dcpmi-smoke
#SBATCH --account=sci-demelo
#SBATCH --partition=pot-hpi-gpu-batch
#SBATCH --constraint=ARCH:X86&GPU_MEM:40GB
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:10:00
#SBATCH --chdir=/sc/home/jan.berndt/better-nli/final
#SBATCH --output=logs/dcpmi_qwen35_4b_smoke_%j.log

# sbatch slurm_jobs/dcpmi_qwen35_4b_smoke.slurm  (from final/)
set -euo pipefail
export TOKENIZERS_PARALLELISM=false
export PYTHONUNBUFFERED=1

exec /sc/home/jan.berndt/conda3/envs/better-nli/bin/python -u run_experiment.py dc_pmi \
    --model Qwen/Qwen3.5-4B \
    --sample-size 4 \
    --batch-size 1 \
    --inference-batch-size 1 \
    --seed 42 \
    --results runs/dcpmi_qwen35_4b_smoke.csv
