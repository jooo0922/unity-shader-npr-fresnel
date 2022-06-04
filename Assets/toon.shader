Shader "Custom/toon"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Fresnel 을 응용하면 1Pass 만 가지고도 외곽선을 만들 수 있음.
        // 우선 2Pass 에서 사용했던 코드들 중 두번째 패스(셀 쉐이딩) 계산하는 부분만 가져오도록 함.
        CGPROGRAM

        // 끊어지는 음영(셀 쉐이딩)을 계산할 커스텀라이팅 함수 Toon 을 선언함. 
        #pragma surface surf Toon

        sampler2D _MainTex;
        sampler2D _BumpMap;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);

            // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌. -> 노말맵에서 추출한 노멀벡터 적용
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }

        // 끊어지는 음영(셀 쉐이딩)을 계산할 Toon 커스텀라이팅 함수
        float4 LightingToon(SurfaceOutput s, float3 lightDir, float atten) {
            // 노멀벡터(surf 함수에서 노말맵의 노말벡터를 추출해 적용한 상태)와 조명벡터 내적값을 Half-Lambert 공식을 사용해서 -1 ~ 1 범위를 0 ~ 1 로 맵핑시킴.
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // 이후, Half-Lambert 가 적용된 내적값을 cutoff 값 0.7을 기준으로 1 또는 0.3 으로 만들어버림.
            if (ndotl > 0.7) {
                ndotl = 1;
            }
            else {
                ndotl = 0.3;
            }

            // 이제 surf 함수에서 적용한 s.Albedo 텍스쳐 색상값, 위에서 cutoff 해준 내적값, 빛의 강도 및 색상(_LightColor 내장변수)을 모두 적용한 최종색상 final 을 계산해서 리턴해 줌.
            float4 final;
            final.rgb = s.Albedo * ndotl * _LightColor0.rgb;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
