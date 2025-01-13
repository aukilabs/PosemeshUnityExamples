Shader "Matterless/Unlit/QRModel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Hover ("Hover", Range(0, 1)) = 1
        _Spawn ("Spawn", Range(0, 1)) = 1
        _Alpha ("Transparancy", Range(0,1)) = 1
    }
    SubShader
    {
        Tags {             
            "RenderType"="Transparent"
            "Queue"="Transparent"  
        }
        LOD 100
        
        ZWrite Off
	    Blend SrcAlpha OneMinusSrcAlpha 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 objectPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Hover;
            float _Spawn;
            float _Lock;
            float _Alpha;

            float3 rot(float3 In, float3 Axis, float Rotation)
            {
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;

                Axis = normalize(Axis);
                float3x3 rot_mat = 
                {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                    one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                    one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
                };
                return  mul(rot_mat,  In);
            }

            #define TAU 6.28318530718
            #define PI 3.14159265359

            v2f vert (appdata v)
            {
                v2f o;
                o.objectPos = v.vertex;
                float deformation = saturate(1 - abs(v.vertex.x * v.vertex.x) *  2.0f) + 1.5;
                float defPhase = sin(_Time.y  * 1.3 * PI) * 0.1 ;
                float4 def = float4(v.vertex.x * defPhase, 0.2 + defPhase * deformation,  v.vertex.z * defPhase, 0);
                
                float4 pos = v.vertex + def * _Hover;
                pos = float4(rot(pos, float3(1, 1, 1), (_Spawn) * PI - PI),v.vertex.w);
                pos *= _Spawn;
                pos.y += sin((_Spawn) * PI) * 1.5;
                
                //pos = lerp(v.vertex, pos, _Factor);
                o.vertex = UnityObjectToClipPos(pos);
                o.normal = rot(v.normal, float3(1, 1, 1), (_Spawn) * PI - PI);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float NdotL = saturate(dot(i.normal, float3(1, 1, 0)));
                col.rgb *= saturate(NdotL + 0.4);
                col.a = _Alpha;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return saturate(1 - abs(i.objectPos.x) *  2.0f);
                
                return col;
            }
            ENDCG
        }
    }
}
