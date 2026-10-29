You are a coding agent inside of the `better-nli` repository.
This repository contains various experiments pertaining to my bachelor thesis on the pointwise mutual information (PMI) scoring method in large language models.

## Working with jupyter notebooks

When writing jupyter notebooks, follow these conventions:

### Use markdown free text sparringly

Self-documenting code is best. A few comments to structure the code are also ok.

### Use asserts to keep code straightforward

Don't try to write fallbacks unless asked. Use assert statements to verify expected behavior. E.g. instead of

```python
if os.environ.get("HF_TOKEN").startswith("hf_"):
    login()
else:
    print("No login credentials found")
    login_notebook()
```

just write

```python
assert os.environ.get("HF_TOKEN").startswith("hf_"), "No HF_TOKEN configured"
login()
```
