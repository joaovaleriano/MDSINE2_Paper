#!/bin/bash
set -e
source synthetic_5sp_rel_new/small/settings.sh

read_depth=100000
# for (( trial = 0; trial < ${NUM_SAMPLE_TRIALS}; trial++ )); do
for (( cohort = 10; cohort < 11; cohort += 3 )); do
	for (( trial = 2; trial <= 6; trial+= 2 )); do
		# for noise_level in "low" "medium" "high"; do
		for noise_level in "low"; do
			negbin_seed=123
			dataset=${DATASET_DIR}/data/cohort${cohort}/trial_${trial}/reads_${read_depth}/noise_${noise_level}/subjset.pkl
			replicates=${DATASET_DIR}/data/cohort${cohort}/trial_${trial}/reads_${read_depth}/noise_${noise_level}/replicate.pkl
			trial_output_dir=${OUTPUT_DIR}/reads_${read_depth}/cohort${cohort}/trial_${trial}/${noise_level}_noise

			negbin_out_dir=${trial_output_dir}/mdsine2_negbin
			inference_out_dir=${trial_output_dir}/mdsine2
			mkdir -p $inference_out_dir

			# ======= Fit NegBin qPCR model
			echo "[*] Fitting Negative binomial model."
			mdsine2 infer-negbin --input ${replicates} --seed ${negbin_seed} --burnin 2000 --n-samples 5000 --checkpoint 1 --basepath $negbin_out_dir --multiprocessing --log-every 500
			mdsine2 visualize-negbin --chain "${negbin_out_dir}/replicate-${noise_level}/mcmc.pkl" --output-basepath "${negbin_out_dir}/replicate-${noise_level}"

			# ======= Run inference
			echo "[*] Running non-clustered mdsine2 inference (reads=${read_depth}, trial=${trial}, noise level=${noise_level})"
			# python synthetic/helpers/inference.py \

			# mdsine2 infer \
			python semisynthetic2/inference/mdsine2/helpers/mdsine2_ra.py \
					--input $dataset \
					--negbin ${negbin_out_dir}/replicate-${noise_level}/mcmc.pkl \
					--seed 0 \
					--burnin 5000 \
					--n-samples 15000 \
					--checkpoint 1 \
					--multiprocessing 0 \
					--basepath $inference_out_dir \
					--interaction-ind-prior "weak-agnostic" \
					--perturbation-ind-prior "weak-agnostic" \
					--nomodules \
					--log-every 500
					# --time_mask ${DATASET_DIR}/time_mask.tsv
			#
			
			# mdsine2 infer --input $dataset

			echo "[*] Finished mdsine2 inference."
		done
	done
done
