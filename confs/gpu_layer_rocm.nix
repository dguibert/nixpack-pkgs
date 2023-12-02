final: pack:
pack._merge (self:
    with self; {
      label = pack.label + "_rocm";

      package.hip.variants.rocm = true;
      package.roctracer-dev.variants.rocm = true;
      package.roctracer-dev.variants.amdgpu_target.none = false;
      package.roctracer-dev.variants.amdgpu_target."gfx90a" = true;
      package.rccl.variants.amdgpu_target.auto = false;
      package.rccl.variants.amdgpu_target."gfx90a" = true;
    })
