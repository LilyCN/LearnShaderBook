Shader "Unity Shader Book/Chapter 11/Image Sequence Animation"
{
    Properties
    {
        _BaseColor("Main Color", Color) = (1, 1, 1, 1)
        _BaseMap("Main Texture", 2D) = "white" {}
        _HorizontalAmount("Horizontal Amount", Float) = 8
        _VerticalAmount("Vertical Amount", Float) = 8
        _Speed("Speed", Range(1, 100)) = 30
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            // -------------------------------------
            // Universal Pipeline keywords

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _BaseMap;
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                float time = floor(_Time.y * _Speed);
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _HorizontalAmount;
                half2 uv = (i.uv + half2(column, -row)) / half2(_HorizontalAmount, _VerticalAmount);

                half4 color = tex2D(_BaseMap, uv) * _BaseColor;

                return color;
            }
            
            ENDHLSL
        }
    }


}