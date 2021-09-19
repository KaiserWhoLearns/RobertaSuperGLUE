// =================== Configurable Settings ======================

// In 'debug' mode, we only train t5-small over a few instances on 2 GPUs.
// Otherwise we train t5-11b on 8 GPUs (less than 8 GPUs won't work).
local debug = true;

// This is probably necessary for t5-11b unless you have more than 8 GPUs.
local activation_checkpointing = true;

// Set to `false` if you want to skip validation.
local validate = true;

// AMP is currently unusably slow with t5-11b, which be due to a bug bug within FairScale,
// but I'm not sure yet.
local use_amp = false;

// These are reasonable defaults.
local source_length = 256;
local target_length = 50;

// Only set to `true` if you're running this on Beaker batch.
local on_beaker = false;

// ================================================================

// ------ !! You probably don't need to edit below here !! --------

local model_name = if debug then "roberta-base" else "roberta-large";
local batch_size_per_gpu = if debug then 4 else 1;

local train_data = "train";
local test_data = "test";
local dev_data = "dev";

local dataset_reader = {
    "type": "imdb",
    "tokenizer": {
        "type": "pretrained_transformer",
        "model_name": model_name,
    },
    "token_indexers": {
        "tokens": {
            "type": "pretrained_transformer",
            "model_name": model_name,
            "namespace": "tokens",
        }
    },
};

local data_loader = {
    "batch_size": batch_size_per_gpu,
    "shuffle": true,
};

local wandb_callback = {
    "type": "wandb",
    "project": "HyperstarNL",
    "watch_model": false,
    "summary_interval": 1,
    "should_log_parameter_statistics": false,
    "should_log_learning_rate": false,
};

{
    "train_data_path": train_data,
    [if validate then "validation_data_path"]: dev_data,
    "dataset_reader": dataset_reader + {
        [if debug then "max_instances"]: batch_size_per_gpu * 40,
    },
    "validation_dataset_reader": dataset_reader + {
        "max_instances": if debug then batch_size_per_gpu * 4 else batch_size_per_gpu * 10,
    },
    "model": {
        "type": "transformer_classification_tt",
        "transformer_model": model_name,
    },
    "data_loader": data_loader + {
        [if !debug then "max_instances_in_memory"]: batch_size_per_gpu * 128,
        [if !debug then "num_workers"]: 1,
    },
    "validation_data_loader": data_loader,
    "trainer": {
        "use_amp": use_amp,
        [if use_amp then "grad_scaling"]: false,  # TODO: use grad scaling once it's fixed in FairScale.
        "num_epochs": 6,
        // "validation_metric": "+accuracy",
        "optimizer": {
            "type": "huggingface_adamw",
            "weight_decay": 0.01,
            "parameter_groups": [[["bias", "LayerNorm\\.weight", "layer_norm\\.weight"], {"weight_decay": 0}]],
            "lr": 1e-5,
            "eps": 1e-8,
            "correct_bias": true
          },
          "learning_rate_scheduler": {
            "type": "linear_with_warmup",
            "warmup_steps": 100
          },
        // "grad_norm": 1.0,
        "validation_metric": "+accuracy",
        [if !debug then "callbacks"]: [wandb_callback],
    },
}