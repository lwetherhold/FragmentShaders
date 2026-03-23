Shader "Custom/SnowRoll"
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

            // helper function to generate random noise for frag() function
            // add random (snow) noise based on function given by prof
            // NOTE: prof uses the name randomNoise2() in the lecture slides PDF
            //       the 2 indicates that the seed is float2 (2D)
            float randomNoise2(float2 seed)
            {
                return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
            }

            // this is the fragment function
            half4 frag(Varyings IN) : SV_Target
            {
                // NOTE: snow noise will be visible on light AND dark parts of the texture

                // NOTE: we will be doing screen-style or screen-space snow
                //       texture uses scrolled UVs while snow uses unscrolled UVs (from IN.uv) + time
                //       -> image rolls, but snow stays in ITS OWN pattern on the texture, like real snow in front of the screen itself

                // get UVs
                //float2 uv = IN.uv.xy;

                float speedImage = 0.25;

                // use two UV pairs (one for image)
                float2 uvImage = IN.uv.xy;
                uvImage.y = frac (uvImage.y + _Time.y * speedImage);

                // use two UV pairs (one for snow)
                float2 uvSnow = IN.uv.xy; // there is no frac() roll here so that snow space is on the plane of the texture

                // after computing uv for the roll
                // build a new seed that changes over space + time for the snowing effect (vs static grain)
                float2 snowSeed = uvSnow * 200.0; // creates density
                                              // build snowSeed from uvSnow (scale + time), NOT from uvImage (which is scrolled)
                snowSeed += float2(_Time.y * 3.0, _Time.y * 1.7); // creates drift
                float noise = randomNoise2(snowSeed); // randomNoise2() gives 0-1 "random" from a seed without storing any state

                // use uv in SAMPLE_TEXTURE2D instead of original IN.uv
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvImage) * _BaseColor; // sample the texture with uvImage

                // the mist layer acts as a second noise of lower frequency with a smaller lerp toward white so the whole frame lifts toward white without just sharp, tiny dots
                // NOTE: mist is a subtle effect that adds a light layer of snow to the texture
                //       it is built from a random noise function that is scaled and time-shifted
                //       the noise is then smoothed and lerped onto the texture to create a light layer of snow
                float mist = randomNoise2(uvSnow * 30.0 + _Time.y);
                mist = smoothstep(0.3, 0.9, mist); // tuned for how foggy the mist appears
                color.rgb = lerp(color.rgb, half3(1,1,1), mist * 0.35f);

                // then turn noise into flakes with a threshold (bright dots)
                //float flake = smoothstep(0.97, 1.0, noise); // 0.97 is the amount of noise that will be turned into flakes
                                                           // smoothstep() keeps only rare high values which turns into sparse bright dots
                float flake = smoothstep(0.75, 0.98, noise); // soften the flake gate (for more flakes)

                // NOTE: removed the scroll on uvImage since it is duplicated here from when we used two UV pairs above (the one for image specifically)
                // before sampling texture, replace ONE component
                //uvImage.y = frac(uvImage.y + _Time.y * speedImage); // vertical roll/scroll/slide that repeats
                                                                    // sample the texture with uvImage

                // blend onto the texture so flakes are not invisible on white
                // by lerping toward white using flake
                //color.rgb = lerp(color.rgb, 1.0, flake * 0.7); // 0.7 is the strength of the flakes
                                                               // lerp() makes white snow that still pops out on bright parts of the texture
                color.rgb = lerp(color.rgb, half3(1,1,1), flake * 0.95f); // stronger white mix
                return color;
            }
            ENDHLSL
        }
    }
}
