using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Learn.ShaderBook
{
    [Serializable, VolumeComponentMenuForRenderPipeline("Additional Post-processing/Brightness Saturation Contrast", typeof(UniversalRenderPipeline))]
    public sealed class BSCVolume : VolumeComponent, IPostProcessComponent
    {
        [Header("Brightness Saturation Contrast")]
        public ClampedFloatParameter brightness = new ClampedFloatParameter(1.0f, 0.0f, 3.0f);
        public ClampedFloatParameter saturation = new ClampedFloatParameter(1.0f, 0.0f, 3.0f);
        public ClampedFloatParameter contrast = new ClampedFloatParameter(1.0f, 0.0f, 3.0f);

        public bool IsActive()
        {
            return active;
        }

        public bool IsTileCompatible() => false;
    }
}