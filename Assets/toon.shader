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
        #pragma surface surf Toon // noambient

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
        float4 LightingToon(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) { // 각 버텍스에서 카메라를 향하는 뷰벡터(viewDir) 은 세 번째 인자로 가져와야 함.
            // 노멀벡터(surf 함수에서 노말맵의 노말벡터를 추출해 적용한 상태)와 조명벡터 내적값을 Half-Lambert 공식을 사용해서 -1 ~ 1 범위를 0 ~ 1 로 맵핑시킴.
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // 이후, Half-Lambert 가 적용된 내적값을 cutoff 값 0.7을 기준으로 1 또는 0.3 으로 만들어버림.
            if (ndotl > 0.7) {
                ndotl = 1;
            }
            else {
                ndotl = 0.3;
            }

            // 이번에는 rim 값을 구해서 1Pass 외곽선을 만들어볼거임.
            // 우선 노말맵에서 추출한 노말벡터와 카메라벡터(viewDir)을 내적해서 Fresnel 값을 구함.
            // 내적계산은 -1 ~ 1사이의 값을 포함하므로, 음수값을 없애기 위해 abs() 를 사용함.
            float rim = abs(dot(s.Normal, viewDir));

            // 원래는 Fresnel 을 구할 때 1 - rim 으로 rim값을 뒤집어줬지만,
            // 이번에는 가장자리로 갈수록 0에 가까워지는 rim값을 그대로 사용해도 됨. 외곽선은 오히려 가장자리가 어두워야 하니까!
            if (rim > 0.3) {
                // rim값이 0.3보다 큰 지점은 rim 값을 전부 1로 초기화해서 아래 final에서 곱해줄 때 원래의 final 색상값이 나오도록 함.
                rim = 1;
            }
            else {
                // rim값이 0.3보다 작은 지점 (거의 가장자리 부근이겠지)은 -1로 final에 곱해줘서 음수화시킴.
                // 이거는 0으로 줘도 되지 않나? 왜 굳이 -1로 초기화하지? 
                // 왜냐하면, 0으로 줘버리면 아래에서 final.rgb가 (0, 0, 0)으로 초기화될 거 아냐?
                // 이게 그대로 가면 검정색으로 칠해지겠지만, 위에 noambient 를 안해줘서 환경광이 그대로 남아있기 때문에
                // 최종적으로 환경광 색깔인 Ambient Color 와 final 이 더해지면서 (0, 0, 0) 보다 밝은 색깔이 나와버림...
                // 실제로 noambient 를 설정해서 환경광을 꺼주면 그냥 rim 을 0으로 해줘도 외곽선이 검정색으로 잘 나옴.
                rim = -1;
            }

            // 이제 surf 함수에서 적용한 s.Albedo 텍스쳐 색상값, 위에서 cutoff 해준 내적값, 빛의 강도 및 색상(_LightColor 내장변수)을 모두 적용한 최종색상 final 을 계산해서 리턴해 줌.
            float4 final;
            final.rgb = s.Albedo * ndotl * _LightColor0.rgb * rim;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
