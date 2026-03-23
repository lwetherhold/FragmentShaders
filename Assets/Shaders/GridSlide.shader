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


                //half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                //return color;
            }
            ENDHLSL
        }
    }
}
