Shader "Unity Shader Book/Chapter 11/Scrolling Background"
{
    Properties
    {
        _MainTex("Base Layer", 2D) = "white" {}
        _DetailTex("2nd Layer", 2D) = "white" {}
        _ScrollX("Base Layer Scroll Speed", Float) = 1.0
        _Scroll2X("2nd Layer Scroll Speed", Float) = 1.0
        _Multiplier("Layer Multiplier", Float) = 1
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            // -------------------------------------
            // Universal Pipeline keywords

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _MainTex;
            sampler2D _DetailTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 firstColor = tex2D(_MainTex, i.uv.xy);
                half4 secondColor = tex2D(_DetailTex, i.uv.zw);
                half4 color = lerp(firstColor, secondColor, secondColor.a);
                color *= _Multiplier;
                
                return color;
            }
            
            ENDHLSL
        }
    }


}