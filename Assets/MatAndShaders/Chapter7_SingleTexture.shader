Shader "Unity Shader Book/Chapter 7/Single Texture"
{
    Properties
    {
        _Color("Diffuse", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
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
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half4 _Specular;
            float _Gloss;
            CBUFFER_END

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal, true);
                o.positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half3 worldNormal = normalize(i.normalWS);
                half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half3 diffuse = albedo * light.color * saturate(dot(worldNormal, lightDir));

                half3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
                half3 halfDir = normalize(viewDir + lightDir);
                half3 specular = _Specular.rgb * light.color * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                half3 color = ambient + diffuse + specular;
                return half4(color, 1.0);
            }
            
            ENDHLSL
        }
    }

    Fallback "Specular"

}