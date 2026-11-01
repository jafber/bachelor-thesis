import torch

print(f"Cuda is: {'available' if torch.cuda.is_available() else 'not available'}")
print(f"Version: {torch.version.cuda}")
print(f"Device:  {torch.cuda.get_device_name()}")