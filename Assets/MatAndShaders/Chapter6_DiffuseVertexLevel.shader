Shader "Unity Shader Book/Chapter 6/Diffuse Vertex Level"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
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

            half4 _Diffuse;

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 color : COLOR;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.vertex);
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                half3 normalWS = TransformObjectToWorldNormal(v.normal);
                float3 positionWS = TransformObjectToWorld(v.vertex);
                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half3 diffuse = _Diffuse.rgb * light.color * max(0, dot(normalWS, lightDir));
                o.color = ambient + diffuse;

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                return half4(i.color, 1.0);
            }
            
            ENDHLSL
        }
    }

}