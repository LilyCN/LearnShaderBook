Shader "Unity Shader Book/Chapter 7/Mask Texture"
{
    Properties
    {
        _Color("Diffuse", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1.0
        [NoScaleOffset]_SpecularMask("Specular Map", 2D) = "white" {}
        _SpecularScale("Specular Scale", Float) = 1.0
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _MainTex;
            sampler2D _BumpMap;
            sampler2D _SpecularMask;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _BumpScale;
            float _SpecularScale;
            half4 _Color;
            half4 _Specular;
            float _Gloss;
            CBUFFER_END

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                
                o.lightDir = mul(rotation, -TransformWorldToObject(_MainLightPosition.xyz));
                o.viewDir = mul(rotation, GetObjectSpaceNormalizeViewDir(v.vertex));

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                half3 lightDirTS = normalize(i.lightDir);
                half3 viewDirTS = normalize(i.viewDir);

                half4 packedNormal = tex2D(_BumpMap, i.uv);
                half3 normalTS = UnpackNormal(packedNormal);
                normalTS.xy *= _BumpScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));

                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;

                half3 diffuse = albedo * _MainLightColor.rgb * max(0, dot(normalTS, lightDirTS));

                half3 halfDir = normalize(lightDirTS + viewDirTS);
                half sMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
                half3 specular = _Specular.rgb * _MainLightColor.rgb * pow(saturate(dot(normalTS, halfDir)), _Gloss) * sMask;

                half3 color = ambient + diffuse + specular;
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Specular"

}