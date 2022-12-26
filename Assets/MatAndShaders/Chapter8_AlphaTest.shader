Shader "Unity Shader Book/Chapter 8/Alpha Test"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _CutOff("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _CutOff;
            CBUFFER_END

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.positionWS = TransformObjectToWorld(input.vertex.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normal);
                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                half4 texColor = tex2D(_MainTex, input.uv);
                clip(texColor.a - _CutOff);

                half3 albedo = texColor.rgb * _Color.rgb;
                half3 normalWS = normalize(input.normalWS);
                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                half3 diffuse = albedo * light.color * max(0, dot(normalWS, lightDir));

                return half4(ambient + diffuse, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Transparent/Cutout/VertexLit"
}
