final: pack:
pack._merge (self: {
  label = pack.label + "_cuda";
  package.nccl.variants.cuda = true;
  package.nccl.variants.cuda_arch.none = false;
  package.nccl.variants.cuda_arch."80" = true;
  package.py-tensorflow.variants.cuda = true;
  package.py-tensorflow.variants.cuda_arch.none = false;
  package.py-tensorflow.variants.cuda_arch."80" = true;
  package.py-onnxruntime.variants.cuda = true;
  package.py-onnxruntime.variants.cuda_arch.none = false;
  package.py-onnxruntime.variants.cuda_arch."80" = true;
  package.py-torch.variants.cuda = true;
  package.py-torch.variants.cuda_arch.none = false;
  package.py-torch.variants.cuda_arch."80" = true;
  package.gloo.variants.cuda = true;
  package.magma.variants.cuda_arch.none = false;
  package.magma.variants.cuda_arch."80" = true;
})
