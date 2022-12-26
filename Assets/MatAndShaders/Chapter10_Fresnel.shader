Shader "Unity Shader Book/Chapter 10/Fresnel"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _FresnelScale("Reflection Amount", Range(0, 1)) = 0.5
        _CubeMap("Reflection Cubemap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
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

            samplerCUBE _CubeMap;
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _FresnelScale;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 reflectionDirWS : TEXCOORD3;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
                output.reflectionDirWS = reflect(-output.viewDirWS, output.normalWS);

                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWS);

                half3 ambient = SampleSH(normalWS);

                Light light = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                half3 diffuse = _BaseColor.rgb * light.color * saturate(dot(normalWS, normalize(light.direction)));

                half3 reflection = texCUBE(_CubeMap, input.reflectionDirWS).rgb;
                half fresnel = _FresnelScale + (1.0 - _FresnelScale) * pow(1.0 - dot(viewDirWS, normalWS), 5.0);

                half3 color = ambient + lerp(diffuse, reflection, fresnel) * light.distanceAttenuation;
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }
}
