﻿using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Print Depth Map")]
    public sealed class PrintDepthMap : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(true);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}
