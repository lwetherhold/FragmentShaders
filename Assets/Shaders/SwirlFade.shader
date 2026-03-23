Shader "Custom/SwirlFade"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainTexture] _SecondMap("Second Map", 2D) = "white" {} // second texture to blend onto the base texture
        _SwirlAmount("Swirl Amount", Float) = 3.0 // strength/amount of the swirl effect
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

            TEXTURE2D(_SecondMap); // second texture to blend onto the base texture
            SAMPLER(sampler_SecondMap); // second sampler to sample the second texture

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                // only needed if TRANSFORM_TEX() is used on the second texture
                float4 _SecondMap_ST; // second texture's scale and offset
                float _SwirlAmount; // strength/amount of the swirl effect
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
                // same UV for both textures
                // center UVs -> the center (0.5, 0.5) of the texture stays fixed, and pixels farther out rotate MORE
                float2 uv = IN.uv.xy; // UV texture coordinates of the current pixel, normalized to [0, 1] (left->right, bottom->top on the mesh)
                float2 offsetFromCenter = uv - 0.5f; // moves the origin to the middle of the texture so that (0, 0) is the center of the texture
                                                     // rotating offsetFromCenter spins the image around the center of the texture (instead of around the corner)

                // speed of the fade and swirl effects
                float speed = 0.5f; // lower = slower fade and swirl
                                    // same speed -> same phase shift between fade and swirl

                // FADE EFFECT VARIABLES
                // NOTE: syncing fade and swirl speeds to have a shared speed variable
                // speed of the fade effect
                //float speedFade = 0.5f; // lower = slower crossfade

                // NOTE: syncing fade and swirl speeds to have a shared speed variable
                // speed of the swirl effect
                //float speedSwirl = 0.5f; // lower = slower swirl

                // SWIRL EFFECT VARIABLES
                // radius of the swirl effect
                float radius = length(offsetFromCenter); // length() is the distance from the center (0.5, 0.5) of the texture to the current pixel
                                                         // makes edges move more than the center
                // angle of the swirl effect
                float angleSwirl = radius * _SwirlAmount * sin(_Time.y * speed); // stronger swirl over time * stronger swirl for large strength

                // 2D rotation of offsetFromCenter
                float cosAngleSwirl = cos(angleSwirl);
                float sinAngleSwirl = sin(angleSwirl);
                float2 rotated = float2(
                    cosAngleSwirl * offsetFromCenter.x - sinAngleSwirl * offsetFromCenter.y,
                    sinAngleSwirl * offsetFromCenter.x + cosAngleSwirl * offsetFromCenter.y);

                // SAMPLE WITH SWIRL, THEN LERP WITH FADE

                // after rotating, we need to add the offset from the center back to the rotated offset
                float2 uvSwirl = rotated + 0.5f; // add 0.5f back to UV space to get the final UV coordinates

                // then sample both tetures with the swirled UV coordinates
                half4 imageA = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvSwirl) * _BaseColor; // base texture
                half4 imageB = SAMPLE_TEXTURE2D(_SecondMap, sampler_SecondMap, uvSwirl); // second texture
                
                // NOTE: original code has no twist / swirl effect, only the fade effect
                // sample the two textures
                //half4 imageA = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor; // base texture
                //half4 imageB = SAMPLE_TEXTURE2D(_SecondMap, sampler_SecondMap, uv); // second texture

                // weight to blend between the two textures
                float weight = (sin(_Time.y * speed) + 1.0f) * 0.5f; // sin() ranges from -1 to 1, so we add 1 and divide by 2 to get a value between 0 and 1
                                                                         // taken from the lecture slides PDF shown in class
                                                                         // alternatively, a student in class proposed the equation: 
                                                                         // y = sin(x)^2 or sin^2(x)

                /*
                PROPOSED ALTERNATIVES TO WEIGHT EQUATION:

                MULTIPLY:
                float sinTheta = sin(_Time.y * speedFade);
                float weight = sinTheta * sinTheta; // same as sin^2(theta), range [0, 1]

                POWER:
                float weight = pow(sin(_Time.y * speedFade), 2.0);
                */

                // blend the two textures
                half4 color = lerp(imageA, imageB, weight);

                // return the blended color
                return color;
            }
            ENDHLSL
        }
    }
}
