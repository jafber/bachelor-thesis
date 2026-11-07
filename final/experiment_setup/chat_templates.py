"""Model-specific options for Hugging Face chat templates."""


def chat_template_kwargs(model_id, thinking=False):
    # Qwen3.5 supports switching its chat template between thinking modes.
    if model_id.startswith("Qwen/Qwen3.5-"):
        return {"enable_thinking": thinking}
    if thinking:
        raise ValueError(f"--thinking is not supported for {model_id}")
    return {}
