Shader "Matterless/Unlit/QRPlane"
{

    Properties
    {
        _GridThickness ("Grid Thickness", Float) = 0.01
        _GridSpacing ("Grid Spacing", Float) = 10.0
        [HDR]_GridColour ("Grid Colour", Color) = (0.5, 0.5, 0.5, 0.5)
        [HDR]_BaseColour ("Base Colour", Color) = (0.0, 0.0, 0.0, 0.0)
        [HDR]_LockColour ("Lock Colour", Color) = (0.0, 0.0, 0.0, 0.0)
        _Spawn ("Spawn", Range(0, 1)) = 0.0
        _Hover ("Hover", Range(0, 1)) = 0.0
        _Lock ("Lock", Range(0, 1)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }

        Pass
        {
           
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            // Define the vertex and fragment shader functions
            #pragma vertex vert
            #pragma fragment frag

            // Access Shaderlab properties
            float4 _GridColour;
            float4 _BaseColour;
            float4 _LockColour;
            float _Spawn;
            float _Hover;
            float _Lock;
            

            // Input into the vertex shader
            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // Output from vertex shader into fragment shader
            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            // VERTEX SHADER
            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                output.pos = UnityObjectToClipPos(input.vertex * _Spawn);
                // Calculate the world position coordinates to pass to the fragment shader
                output.worldPos = mul(unity_ObjectToWorld, input.vertex);
                output.uv = input.uv - 0.5f;

                return output;
            }


            float GridTextureGradBox(in float2 p, in float2 ddx, in float2 ddy, float N)
            {
                // filter kernel
                float2 w = max(abs(ddx), abs(ddy)) + 0.01;

                // analytic (box) filtering
                float2 a = p + 0.5 * w;
                float2 b = p - 0.5 * w;
                float2 i = (floor(a) + min(frac(a) * N, 1.0) -
                    floor(b) - min(frac(b) * N, 1.0)) / (N * w);
                //pattern
                return (1.0 - i.x) * (1.0 - i.y);
            }


            //Source for thi filterable grid texture https://iquilezles.org/articles/checkerfiltering
            float CheckersTextureGradBox(in float2 p, in float2 ddx, in float2 ddy)
            {
                // filter kernel
                float2 w = max(abs(ddx), abs(ddy)) + 0.01;
                // analytical integral (box filter)
                float2 i = 2.0 * (abs(frac((p - 0.5 * w) / 2.0) - 0.5) - abs(frac((p + 0.5 * w) / 2.0) - 0.5)) / w;
                // xor pattern
                return 0.5 - 0.5 * i.x * i.y;
            }


            #define TAU 6.28318530718
            #define PI 3.14159265359


            // FRAGMENT SHADER
            float4 frag(vertexOutput input) : COLOR
            {
                
                float2 uv = (input.uv - 0.12) * 4;// + displacement;
                float2 ddx2 = ddx(uv);
                float2 ddy2 = ddy(uv);
                float g = 1.0 - GridTextureGradBox(uv, ddx2, ddy2, 35.);
                float g3 = lerp(saturate(1.0 - CheckersTextureGradBox(uv*1.0 - 1, ddx2, ddy2))*0.25f, 0.0, 1 -_Lock);

                
                ddx2 = ddx(uv * 4.0);
                ddy2 = ddy(uv * 4.0);

                float g2 = 0.8 - GridTextureGradBox(uv * 4.0, ddx2, ddy2, 18.);
                
                float dsq = dot(input.uv, input.uv) * 1;
                float s = 0.045 ;
                float pulse = lerp(1, sin(_Time.y * PI * 1.3 * 0.5 - PI*0.56) * 1, _Hover * (1 - _Lock));
                float ag= abs(exp(-dsq * dsq / (2 * s * s)) * pulse);
                
                float4 color = lerp(_BaseColour, _GridColour, _Hover);
                color = lerp(color, _LockColour, _Lock);
                
                float4 r =max(0.0, max(max(g, g2),g3)) * (color + ag * 0.6) * ag;
                //r.a += ag * 0.8f; 
                return r;
                
                //max(max(g , g2),g3)  * _GridColour;
            }
            ENDCG
        }
    }
}