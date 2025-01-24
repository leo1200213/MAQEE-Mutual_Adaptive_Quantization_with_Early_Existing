#!/bin/bash

# Activate conda environment
conda activate lgvit

# Set paths to necessary directories
project_root="/home/u7946530/LGViT"
model_path="$project_root/models/deit_highway"

# Ensure the correct paths are included in PYTHONPATH without duplication
if [[ ":$PYTHONPATH:" != *":$project_root:"* ]]; then
    export PYTHONPATH="$project_root:$PYTHONPATH"
fi

if [[ ":$PYTHONPATH:" != *":$model_path:"* ]]; then
    export PYTHONPATH="$model_path:$PYTHONPATH"
fi

# Set model and dataset parameters
BACKBONE=ViT # ViT, DeiT
MODEL_TYPE=${BACKBONE}-base
MODEL_NAME=facebook/deit-base-distilled-patch16-224
DATASET=cifar100 # cifar100, Food101, Maysee/tiny-imagenet, imagenet-1k
TRAIN_STRATEGY=distillation
# Set dataset name
if [ "$DATASET" = "Maysee/tiny-imagenet" ]; then
    DATANAME=tiny-imagenet
else
    DATANAME=$DATASET
fi

# Set other parameters
EXIT_STRATEGY=confidence # entropy, confidence, patience, patient_and_confident
HIGHWAY_TYPE=LGViT # linear, LGViT, vit, self_attention, conv_normal
PAPER_NAME=LGViT  # base, SDN, PABEE, PCEE, BERxiT, ViT-EE, LGViT

# Set CUDA device
export CUDA_VISIBLE_DEVICES=0,1

# Uncomment if using wandb for logging
# export WANDB_PROJECT=${BACKBONE}_${DATANAME}_eval

# Run evaluation script
python -m torch.distributed.run --nproc_per_node=2 --master_port=29566 --nnodes=1 ../examples/run_highway_deit.py \
    --run_name ${BACKBONE}_${EXIT_STRATEGY}_${HIGHWAY_TYPE}_${TRAIN_STRATEGY}_${PAPER_NAME} \
    --image_processor_name $MODEL_NAME \
    --config_name $MODEL_NAME \
    --model_name_or_path "$project_root/saved_models/$MODEL_TYPE/$DATASET/${HIGHWAY_TYPE}/stage2_${TRAIN_STRATEGY}_${PAPER_NAME}/" \
    --dataset_name $DATASET \
    --output_dir ../outputs/$MODEL_TYPE/$DATASET/$PAPER_NAME/$EXIT_STRATEGY/ \
    --remove_unused_columns False \
    --backbone $BACKBONE \
    --exit_strategy $EXIT_STRATEGY \
    --do_train False \
    --do_eval \
    --per_device_eval_batch_size 1 \
    --seed 777 \
    --report_to wandb\
    --sqnr True\
    --quant_bits 6\
    --target_block 6\
    --output_hidden_states True
