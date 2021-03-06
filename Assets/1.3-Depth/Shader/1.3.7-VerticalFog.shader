﻿//https://www.jianshu.com/p/80a932d1f11e

Shader "RoadOfShader/1.3-Depth/Vertical Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogDensity ("Fog Density", Float) = 1
        _StartY ("Start Y", Float) = 0
        _EndY ("End Y", Float) = 10
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZTest Always
            ZWrite Off
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 frustumDir: TEXCOORD1;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            float4 _FogColor;
            float _FogDensity;
            float _StartY;
            float _EndY;

            float4x4 _FrustumDir;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                
                //当有多个RenderTarget时，需要自己处理UV翻转问题
                #if UNITY_UV_STARTS_AT_TOP //DirectX之类的
                    if (_MainTex_TexelSize.y < 0) //开启了抗锯齿
                    output.uv.y = 1 - output.uv.y; //满足上面两个条件时uv会翻转，因此需要转回来
                #endif

                int ix = (int)output.uv.x;
                int iy = (int)output.uv.y;
                output.frustumDir = _FrustumDir[ix + 2 * iy];
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                float depth = SampleSceneDepth(input.uv);
                float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);

                float3 positionWS = GetCameraPositionWS() + input.frustumDir.xyz * linearEyeDepth;

                float fogDensity = (positionWS.y - _StartY) / (_EndY - _StartY);
                fogDensity = saturate(fogDensity * _FogDensity);
                
                half3 finalColor = lerp(_FogColor, col, fogDensity).xyz;
                return half4(finalColor, 1.0);
            }
            ENDHLSL
            
        }
    }
}
