Shader "Unity Shader Book/Chapter 7/Ramp Texture"
{
    Properties
    {
        _Color("Diffuse", Color) = (1, 1, 1, 1)
        _RampTex("Ramp Texture", 2D) = "white" {}
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

            sampler2D _RampTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _RampTex_ST;
            half4 _Color;
            half4 _Specular;
            float _Gloss;
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
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.positionWS = TransformObjectToWorld(v.vertex.xyz);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
                
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                half3 normalWS = normalize(i.normalWS);
                half halfLambert = dot(normalWS, lightDir) * 0.5 + 0.5;
                half3 rampColor = tex2D(_RampTex, half2(halfLambert, halfLambert)).rgb;
                half3 diffuse = _Color.rgb * _MainLightColor.rgb * rampColor;

                half3 halfDir = normalize(lightDir + viewDir);
                half3 specular = _Specular.rgb * _MainLightColor.rgb * pow(saturate(dot(normalWS, halfDir)), _Gloss);

                half3 color = ambient + diffuse + specular;
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Specular"

}