Shader "Custom/SwirlFade"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainTexture] _SecondMap("Second Map", 2D) = "white" {} // second texture to blend onto the base texture
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
                float2 uv = IN.uv.xy;
                
                // sample the two textures
                half4 imageA = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor; // base texture
                half4 imageB = SAMPLE_TEXTURE2D(_SecondMap, sampler_SecondMap, uv); // second texture

                // weight to blend between the two textures
                float weight = 0.5;

                // blend the two textures
                half4 color = lerp(imageA, imageB, weight);

                // return the blended color
                return color;
            }
            ENDHLSL
        }
    }
}
