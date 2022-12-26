Shader "Unity Shader Book/Common/Bump Specular"
{
    Properties
    {
        _BaseColor("Main Color", Color) = (1, 1, 1, 1)
        _BaseMap("Main Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 32
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
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _Specular;
            float _Gloss;
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
                float4 tsToWorld0 : TEXCOORD1;
                float4 tsToWorld1 : TEXCOORD2;
                float4 tsToWorld2 : TEXCOORD3;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord * _BaseMap_ST.xy + _BaseMap_ST.zw;
                
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS, true);
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                float3 bitangentWS = v.tangentOS.w * cross(normalWS, tangentWS);

                o.tsToWorld0 = float4(tangentWS.x, bitangentWS.x, normalWS.x, positionWS.x);
                o.tsToWorld1 = float4(tangentWS.y, bitangentWS.y, normalWS.y, positionWS.y);
                o.tsToWorld2 = float4(tangentWS.z, bitangentWS.z, normalWS.z, positionWS.z);

                return o;
            }

            half3 CalculateBlinnPhongLighting(Light light, half3 albedo, half3 normalWS, half3 viewDir)
            {
                half3 lightDir = normalize(light.direction);
                half3 lightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;  // Receive shadow
                half3 diffuse = albedo * lightColor * saturate(dot(normalWS, lightDir));

                half3 hDir = normalize(viewDir + lightDir);
                half3 specular = _Specular.rgb * lightColor * pow(saturate(dot(viewDir, hDir)), _Gloss);
                
                return diffuse + specular;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half3 albedo = tex2D(_BaseMap, i.uv).rgb * _BaseColor.rgb;

                half4 packedNormal = tex2D(_BumpMap, i.uv);
                half3 normalTS = UnpackNormal(packedNormal);
                half3 normalWS = normalize(half3(dot(i.tsToWorld0.xyz, normalTS), dot(i.tsToWorld1.xyz, normalTS), dot(i.tsToWorld2.xyz, normalTS)));

                float3 positionWS = float3(i.tsToWorld0.w, i.tsToWorld1.w, i.tsToWorld2.w);
                half3 viewDir = normalize(GetWorldSpaceViewDir(positionWS));
                half3 ambient = SampleSH(normalWS);

                Light light = GetMainLight(TransformWorldToShadowCoord(positionWS));
                half3 color = ambient + CalculateBlinnPhongLighting(light, albedo, normalWS, viewDir);

                uint lightsCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < lightsCount; ++lightIndex)
                {
                    light = GetAdditionalLight(lightIndex, positionWS);
                    color += CalculateBlinnPhongLighting(light, albedo, normalWS, viewDir);
                }
                
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Specular"

}