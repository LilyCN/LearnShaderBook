Shader "Unity Shader Book/Chapter 10/Glass Refraction"
{
    Properties
    {
        _BaseMap("Main Texture", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        [NoScaleOffset]_Cubemap("Environment Cubemap", Cube) = "_Skybox" {}
        _Distortion("Distortion", Range(0, 100)) = 10
        _RefractAmount("Refraction Amount", Range(0, 1.0)) = 1.0
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _BaseMap;
            sampler2D _BumpMap;
            samplerCUBE _Cubemap;
            sampler2D _CameraOpaqueTexture;
            float4 _CameraOpaqueTexture_TexelSize;
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float _Distortion;
            float _RefractAmount;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 tsToWorld0 : TEXCOORD2;
                float4 tsToWorld1 : TEXCOORD3;
                float4 tsToWorld2 : TEXCOORD4;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS, true);
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                float3 bitangentWS = v.tangentOS.w * cross(normalWS, tangentWS);

                o.tsToWorld0 = float4(tangentWS.x, bitangentWS.x, normalWS.x, positionWS.x);
                o.tsToWorld1 = float4(tangentWS.y, bitangentWS.y, normalWS.y, positionWS.y);
                o.tsToWorld2 = float4(tangentWS.z, bitangentWS.z, normalWS.z, positionWS.z);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                float3 positionWS = float3(i.tsToWorld0.w, i.tsToWorld1.w, i.tsToWorld2.w);
                half3 viewDir = normalize(GetWorldSpaceViewDir(positionWS));

                half3 albedo = tex2D(_BaseMap, i.uv).rgb;

                half4 packedNormal = tex2D(_BumpMap, i.uv);
                half3 normalTS = UnpackNormal(packedNormal);
                half3 normalWS = normalize(half3(dot(i.tsToWorld0.xyz, normalTS), dot(i.tsToWorld1.xyz, normalTS), dot(i.tsToWorld2.xyz, normalTS)));

                float2 offset = normalTS.xy * _Distortion * _CameraOpaqueTexture_TexelSize.xy;
                float2 screenPos = offset.xy + i.positionCS.xy / _ScreenParams.xy;
                half3 refractionColor = tex2D(_CameraOpaqueTexture, screenPos).rgb;

                half3 reflectDir = reflect(-viewDir, normalWS);
                half3 reflectionColor = texCUBE(_Cubemap, reflectDir).rgb * albedo;

                half3 color = reflectionColor * (1.0 - _RefractAmount) + refractionColor * _RefractAmount;

                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }


}