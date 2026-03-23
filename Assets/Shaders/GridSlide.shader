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
                // THE CHANGES DID NOT REALLY CHANGE ANYTHING, BUT I WILL KEEP IT IN HERE REGARDLESS FOR REFERENCE
                // NOTE: material UV transform is scaling my UVs, making it look zoomed in and not showing the entire grid of tiles
                //OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv = IN.uv; // should ignore material tiling/offset and forces the UVs to be [0, 1] cleanly
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // determine the current tile for this pixel (based on current pixel UV)
                float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)
                float gridCount = 4.0; // number of tiles in the grid on one side of the square

                // which tile index
                // tile index (which of the gridCount^2 tiles the current pixel is in)
                float2 tile = floor(uv * gridCount); // tile coordinates [0, gridCount-1] in x/y directions of the grid

                // where inside that tile
                // local UV coordinates inside that tile
                float2 uvLocal = frac(uv * gridCount); // local coordinates [0, 1] inside the tile

                // use smooth phase motion so that the image movement is continuous and not jumpy
                float phaseOffset = 1.0; // phase offset to align the whole image with the shaders video
                                         // shifts which moment the whole image lines up
                float phaseContinuous = _Time.y * phaseSpeed + phaseOffset; // time-based phase progression
                float phaseIndex = floor(fmod(phaseContinuous, 4.0)); // 0,1,2,3 repeating
                float phaseProgress = frac(phaseContinuous); // progress within the current phase [0, 1)

                // tiles in the shaders video have an alternating motion pattern like a checkerboard
                // adjacent tiles in X and Y alternate directions to match the movement between/within rows in the shaders video
                float directionSign = (fmod(tile.x + tile.y, 2.0) < 0.5) ? 1.0 : -1.0; // +1 or -1 based on the parity of the tile

                // movement amount is measured in tile UV space and normalized to [0, 1]
                float moveAmount = 1.0; // 1 means one full tile travel distance in magnitude in tile UV space (along the active axis of movement)

                // movement path based on the shaders video starting point:
                // for the very top-left tile in the video, the sequence immediately after the whole image lines up is RIGHT -> UP -> LEFT -> DOWN
                // because directionSignFlipped depends on tile parity, the actual left/right/up/down will flip on alternating tiles

                // flip the direction sign so that the starting direction matches the shaders video
                float directionSignFlipped = -directionSign;

                // calculate the shift amount for the current phase based on the phase index and progress within tile space
                // 1 means one tile fully traveled
                float2 shift = float2(0.0, 0.0); // reset shift (updated by phase below)
                // set the correct axis movement
                if (phaseIndex < 0.5)         shift = float2(directionSignFlipped * moveAmount * phaseProgress, 0.0);                                          // phase 0: move left or right based on directionSignFlipped
                else if (phaseIndex < 1.5)    shift = float2(directionSignFlipped * moveAmount, directionSignFlipped * moveAmount * phaseProgress);            // phase 1: move up or down based on directionSignFlipped
                else if (phaseIndex < 2.5)    shift = float2(directionSignFlipped * moveAmount * (1.0 - phaseProgress), directionSignFlipped * moveAmount);    // phase 2: move left or right based on directionSignFlipped
                else                          shift = float2(0.0, directionSignFlipped * moveAmount * (1.0 - phaseProgress));                                  // phase 3: move up or down based on directionSignFlipped
                
                // shift the sampling UV coordinates while keeping the final image split across the full/entire grid of all tiles
                float2 tileCoordinate = tile + uvLocal + shift; // tile + uvLocal is the continuous tile space coordinate
                                                           // shift offsets it BEFORE wrapping
                float2 tileCoordinateWrapped = frac(tileCoordinate / gridCount) * gridCount; // wrap tile space coordinate back into [0, gridCount) to prevent edge stretching in UV space
                float2 uvSample = tileCoordinateWrapped / gridCount; // convert wrapped tile space coordinate back into normalized UV space [0, 1]

                // sample the texture with the uvSample coordinate
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvSample) * _BaseColor;

                // return the final color
                return color;

                /*
                // THIS IS WRONG
                // PHASE CALCULATION
                // add the 4-phase state from the lecture slides PDF shown in class
                // phase: 0,1,2,3 repeating
                float phaseSpeed = 1.0; // speed of the phase change, higher = faster
                float phaseRaw = ceil(_Time.y * phaseSpeed); // ceil() rounds up to the nearest integer
                                                             // get the phase as a raw value based on time progression
                float phase = fmod(phaseRaw, 4.0); // 0,1,2,3 repeating
                                                   // fmod() is the modulo operator, gives the remainder of the division
                                                   // 4.0 is the number of phases, so the phase will repeat every 4 seconds
                                                   // phase raw is the increasing integer count, so fmod() makes it into a phase index
                */

                /*
                // THIS IS WRONG
                // one-tile shift PER PHASE: right, up, left, down
                // changed from 0.5 -> 0.25 to make the tiles show up better on the plane
                float2 shift = float2(0.0, 0.0);
                if (phase < 0.5)         shift = float2(0.25, 0.0);   // phase 0: right
                else if (phase < 1.5)    shift = float2(0.0, 0.25);   // phase 1: up
                else if (phase < 2.5)    shift = float2(-0.25, 0.0);  // phase 2: left
                else                     shift = float2(0.0, -0.25);  // phase 3: down
                */

                /*
                // THIS IS WRONG
                // wrap the source tile in [0, gridCount-1] range
                //float2 srcTile = fmod(tile - shift + gridCount, gridCount);
                */

                /*
                // THESE ARE WRONG

                // rebuild the UV coordinates to sample the source tile
                //float2 uvSample = (srcTile + uvLocal) / gridCount;

                // shift the local UV coordinates by the shift amount
                float2 uvSample = frac(uvLocal + shift);
                */

                /*
                // THIS IS WRONG
                // TEMPORARY: show gridCount^2 repeated copies of the texture for debugging/validation purposes
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvLocal) * _BaseColor;
                return color;
                */

                /*
                // get UVs
                //float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)

                // NOTE: the word "quadrant" can be easily replaced by "tile" or "cell"
                //       I just used "quadrant" because I wanted to FIRST test out the shader on a smaller 2x2 grid scale

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

                /*
                // PHASE CYCLE TESTING
                // test that phase cycle works by returning different tints PER PHASE (before any sliding is added)
                // the colors will cycle through the 4 states in order, and then repeat
                if (phase < 0.5)         return half4(1, 0.6, 0.6, 1); // phase 0: red
                else if (phase < 1.5)    return half4(0.6, 1, 0.6, 1); // phase 1: green
                else if (phase < 2.5)    return half4(0.6, 0.6, 1, 1); // phase 2: blue
                else                     return half4(1, 1, 0.6, 1); // phase 3: yellow
                */

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
