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

        // Fresnel �� �����ϸ� 1Pass �� ������ �ܰ����� ���� �� ����.
        // �켱 2Pass ���� ����ߴ� �ڵ�� �� �ι�° �н�(�� ���̵�) ����ϴ� �κи� ���������� ��.
        CGPROGRAM

        // �������� ����(�� ���̵�)�� ����� Ŀ���Ҷ����� �Լ� Toon �� ������. 
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

            // UnpackNormal() �Լ��� ��ȯ�� �븻�� �ؽ��� ������ DXTnm ���� ���ø��ؿ� �ؼ��� float4�� ���ڷ� �޾� float3 �� ��������. -> �븻�ʿ��� ������ ��ֺ��� ����
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }

        // �������� ����(�� ���̵�)�� ����� Toon Ŀ���Ҷ����� �Լ�
        float4 LightingToon(SurfaceOutput s, float3 lightDir, float atten) {
            // ��ֺ���(surf �Լ����� �븻���� �븻���͸� ������ ������ ����)�� ������ �������� Half-Lambert ������ ����ؼ� -1 ~ 1 ������ 0 ~ 1 �� ���ν�Ŵ.
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // ����, Half-Lambert �� ����� �������� cutoff �� 0.7�� �������� 1 �Ǵ� 0.3 ���� ��������.
            if (ndotl > 0.7) {
                ndotl = 1;
            }
            else {
                ndotl = 0.3;
            }

            // ���� surf �Լ����� ������ s.Albedo �ؽ��� ����, ������ cutoff ���� ������, ���� ���� �� ����(_LightColor ���庯��)�� ��� ������ �������� final �� ����ؼ� ������ ��.
            float4 final;
            final.rgb = s.Albedo * ndotl * _LightColor0.rgb;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
