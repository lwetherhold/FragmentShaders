Shader "Custom/GridSlide"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // get UVs
                float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)

                /*
                // QUADRANT TILING VALIDATION
                // color to set a quadrant to, used for debugging purposes / to prove tiling by quadrants is working
                half4 quadColor;

                // compute which quadrant each pixel is in
                if (uv.x < 0.5 && uv.y < 0.5) // bottom-left
                {
                    quadColor = half4(1, 0, 0, 1); // red
                }
                else if (uv.x >= 0.5 && uv.y < 0.5) // bottom-right
                {
                    quadColor = half4(0, 1, 0, 1); // green
                }
                else if (uv.x < 0.5 && uv.y >= 0.5) // top-left
                {
                    quadColor = half4(0, 0, 1, 1); // blue
                }
                else // top-right
                {
                    quadColor = half4(1, 1, 0, 1); // yellow
                }

                return quadColor;
                */

                // add the 4-phase state from the lecture slides PDF shown in class
                float phaseSpeed = 1.0; // speed of the phase change, higher = faster
                float phaseRaw = ceil(_Time.y * phaseSpeed); // ceil() rounds up to the nearest integer
                                                             // get the phase as a raw value
                float phase = fmod(phaseRaw, 4.0); // 0,1,2,3 repeating
                                                   // fmod() is the modulo operator, gives the remainder of the division
                                                   // 4.0 is the number of phases, so the phase will repeat every 4 seconds

                // test that phase cycle works by returning different tints PER PHASE (before any sliding is added)
                // the colors will cycle through the 4 states in order, and then repeat
                if (phase < 0.5)         return half4(1, 0.6, 0.6, 1); // phase 0: red
                else if (phase < 1.5)    return half4(0.6, 1, 0.6, 1); // phase 1: green
                else if (phase < 2.5)    return half4(0.6, 0.6, 1, 1); // phase 2: blue
                else                     return half4(1, 1, 0.6, 1); // phase 3: yellow

                //half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                //return color;
            }
            ENDHLSL
        }
    }
}
