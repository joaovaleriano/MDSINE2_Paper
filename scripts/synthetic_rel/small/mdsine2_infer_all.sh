#!/bin/bash
set -e
source synthetic_rel/small/settings.sh

read_depth=25000
for (( trial = 0; trial < ${NUM_SAMPLE_TRIALS}; trial++ )); do
	# for noise_level in "low" "medium" "high"; do
	for noise_level in "low"; do
		negbin_seed=123
		dataset=${DATASET_DIR}/data/trial_${trial}/reads_${read_depth}/noise_${noise_level}/subjset.pkl
		replicates=${DATASET_DIR}/data/trial_${trial}/reads_${read_depth}/noise_${noise_level}/replicate.pkl
		trial_output_dir=${OUTPUT_DIR}/reads_${read_depth}/trial_${trial}/${noise_level}_noise

		negbin_out_dir=${trial_output_dir}/mdsine2_negbin
		inference_out_dir=${trial_output_dir}/mdsine2
		mkdir -p $inference_out_dir

		# ======= Fit NegBin qPCR model
		echo "[*] Fitting Negative binomial model."
		mdsine2 infer-negbin --input ${replicates} --seed ${negbin_seed} --burnin 1000 --n-samples 2000 --checkpoint 1 --basepath $negbin_out_dir
		mdsine2 visualize-negbin --chain "${negbin_out_dir}/replicate-${noise_level}/mcmc.pkl" --output-basepath "${negbin_out_dir}/replicate-${noise_level}"

		# ======= Run inference
		echo "[*] Running non-clustered mdsine2 inference (reads=${read_depth}, trial=${trial}, noise level=${noise_level})"
		# python synthetic/helpers/inference.py \
		python semisynthetic2/inference/mdsine2/helpers/mdsine2_ra.py \
				--input $dataset \
				--negbin ${negbin_out_dir}/replicate-${noise_level}/mcmc.pkl \
				--seed 0 \
				--burnin 1000 \
				--n-samples 2000 \
				--checkpoint 1 \
				--multiprocessing 0 \
				--basepath $inference_out_dir \
				--interaction-ind-prior "weak-agnostic" \
				--perturbation-ind-prior "weak-agnostic" \
				--nomodules \
				# --time_mask ${DATASET_DIR}/time_mask.tsv
		echo "[*] Finished mdsine2 inference."
	done
done
