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
                //float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)

                // NOTE: the word "quadrant" can be easily replaced by "tile" or "cell"
                //       I just used "quadrant" because I wanted to FIRST test out the shader on a smaller 2x2 grid scale

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

                /*
                // PHASE CYCLE TESTING
                // test that phase cycle works by returning different tints PER PHASE (before any sliding is added)
                // the colors will cycle through the 4 states in order, and then repeat
                if (phase < 0.5)         return half4(1, 0.6, 0.6, 1); // phase 0: red
                else if (phase < 1.5)    return half4(0.6, 1, 0.6, 1); // phase 1: green
                else if (phase < 2.5)    return half4(0.6, 0.6, 1, 1); // phase 2: blue
                else                     return half4(1, 1, 0.6, 1); // phase 3: yellow
                */

                // determine the destination tile (based on current pixel uv)
                float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)
                float gridCount = 4.0; // number of tiles in the grid on one side of the square

                // local UV coordinates inside each tile [0, 1], repeating across the entire grid
                float2 uvLocal = frac(uv * gridCount); // local coordinates inside the grid [0, 1]

                // TEMPORARY: show gridCount^2 repeated copies of the texture for debugging/validation purposes
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvLocal) * _BaseColor;
                return color;

                /*
                // IMPLEMENTATION OF A FAULTY GRID SLIDE EFFECT FOR A 2X2 GRID
                // destIndex: 0=bottom-left, 1=bottom-right, 2=top-left, 3=top-right
                float xSide = step(0.5, uv.x);
                float ySide = step(0.5, uv.y);
                float destIndex = ySide * 2.0 + xSide;
                
                // choose source quadrant PER PHASE so that when phase==3, it returns to identity (phase 0)
                float srcIndex = fmod(destIndex + (3.0 - phase), 4.0);

                // map source index to source origin (top/bottom + left/right origins for each of the 4 quadrants)
                float2 srcOrigin;
                if (srcIndex < 0.5)         srcOrigin = float2(0.0, 0.0); // 0: bottom-left
                else if (srcIndex < 1.5)    srcOrigin = float2(0.5, 0.0); // 1: bottom-right
                else if (srcIndex < 2.5)    srcOrigin = float2(0.0, 0.5); // 2: top-left
                else                        srcOrigin = float2(0.5, 0.5); // 3: top-right

                // next, convert local coordinates back into a full [0, 1] UV coordinate for sampling the texture
                float2 uvSample = srcOrigin + uvLocal * 0.5; // multiply by 0.5 to get the full [0, 1] UV coordinate

                // sample the texture with the uvSample coordinate
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvSample) * _BaseColor;

                // return the final color
                return color;
                */
            }
            ENDHLSL
        }
    }
}
