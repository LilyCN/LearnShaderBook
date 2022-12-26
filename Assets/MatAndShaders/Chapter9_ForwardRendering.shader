Shader "Unity Shader Book/Chapter 9/Forward Rendering"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
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
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Diffuse;
            half4 _Specular;
            float _Gloss;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS, true);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                return o;
            }

            half3 CalculateBlinnPhongLighting(Light light, half3 normalWS, half3 viewDir)
            {
                half3 lightDir = normalize(light.direction);
                // half3 lightColor = light.color * light.distanceAttenuation; 
                half3 lightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;  // Receive shadow
                half3 diffuse = _Diffuse.rgb * lightColor * saturate(dot(normalWS, lightDir));

                half3 hDir = normalize(viewDir + lightDir);
                half3 specular = _Specular.rgb * lightColor * pow(saturate(dot(viewDir, hDir)), _Gloss);
                
                return diffuse + specular;
            }

            half4 frag(Varyings i) : SV_TARGET
            {

                half3 normalWS = normalize(i.normalWS);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                half3 ambient = SampleSH(normalWS);

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 color = ambient + CalculateBlinnPhongLighting(light, normalWS, viewDir);

                uint lightsCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < lightsCount; ++lightIndex)
                {
                    light = GetAdditionalLight(lightIndex, i.positionWS);
                    color += CalculateBlinnPhongLighting(light, normalWS, viewDir);
                }
                
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Specular"

}