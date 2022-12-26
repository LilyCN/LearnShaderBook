Shader "Unity Shader Book/Chapter 11/Billboard"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _VerticalBillboard("Vertical Restraints", Range(0, 1)) = 1
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "DisableBatching" = "True" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
            // -------------------------------------
            // Universal Pipeline keywords

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
            float _VerticalBillboard;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;

                float3 center = float3(0.0, 0.0, 0.0);
                float3 viewerOS = TransformWorldToObject(_WorldSpaceCameraPos);

                float3 normalOS = viewerOS - center;
                normalOS.y *= _VerticalBillboard;
                normalOS = normalize(normalOS);

                float3 up = abs(normalOS.y) > 0.99 ? float3(0.0, 0.0, 1.0) : float3(0.0, 1.0, 0.0);
                float3 right = normalize(cross(up, normalOS));
                up = normalize(cross(normalOS, right));

                float3 offset = v.positionOS - center;
                float3 pos = center + offset.x * right + offset.y * up + offset.z * normalOS;
                
                o.positionCS = TransformObjectToHClip(pos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 color = tex2D(_MainTex, i.uv);
                color.rgb *= _Color.rgb;
                return color;
            }
            
            ENDHLSL
        }
    }

    Fallback "Transparent/VertexLit"

}