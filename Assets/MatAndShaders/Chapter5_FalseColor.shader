Shader "Unity Shader Book/Chapter 5/False Color"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR0;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // Visible normal
                o.color = v.normal * 0.5 + 0.5;
                // Visible tangent
                o.color = v.tangent * 0.5 + 0.5;
                // Visible bitangent
                float3 bitangent = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                o.color = bitangent * 0.5 + 0.5;
                // Visible texcoord
                o.color = v.texcoord.xyz;
                // Visible texcoord1
                o.color = v.texcoord1.xyz;
                // Visible texcoord2
                o.color = v.texcoord2.xyz;
                // Visible texcoord3
                o.color = v.texcoord3.xyz;
                // Visible color
                o.color = v.color.rgb;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                return fixed4(i.color, 1.0);
            }
            
            ENDCG
        }
    }
}