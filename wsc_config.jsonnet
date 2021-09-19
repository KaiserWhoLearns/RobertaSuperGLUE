{
    "dataset_reader": {
        "type": "wsc",
        "token_indexers": {
            "tokens": {
                "type": "pretrained_transformer",
                "max_length": 512,
                "model_name": "roberta-base"
            }
        },
        "tokenizer": {
            "type": "pretrained_transformer",
            "max_length": 512,
            "model_name": "roberta-base"
        }
    },
    "model": {
        "type": "basic_classifier",
        "namespace": "tags",
        "seq2vec_encoder": {
            "type": "bert_pooler",
            "dropout": 0.1,
            "pretrained_model": "roberta-base"
        },
        "text_field_embedder": {
            "token_embedders": {
                "tokens": {
                    "type": "pretrained_transformer",
                    "max_length": 512,
                    "model_name": "roberta-base"
                }
            }
        }
    },
    // "model": {
    //     "type": "transformer_classification_tt",
    //     "transformer_model": "roberta-base",
    //   },
    "train_data_path": "train",
    "test_data_path": "dev",
    "trainer": {
        "num_epochs": 6,
	 "learning_rate_scheduler": {
	    // "type": "slanted_triangular",
	    // "cut_frac": 0.06		
        "type": "polynomial_decay"
	},
        "optimizer": {
            "type": "huggingface_adamw",
            "lr": 2e-05
            // "weight_decay": 0.1
        },
        "callbacks": [
            {
              "type": "console_logger",
              "should_log_inputs": true
            }
          ],
    },
    "evaluate_on_test": true,
    "data_loader": {
        "batch_sampler": {
            "type": "bucket",
            "batch_size": 8,
            "sorting_keys": [
                "tokens"
            ]
        }
    }
}