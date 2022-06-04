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

            // UnpackNormal() �Լ��� ��ȯ�� �븻�� �ؽ��� ������ DXTnm ���� ���ø��ؿ� �ؼ��� float4�� ���ڷ� �޾� float3 �� ��������. -> �븻�ʿ��� ������ ��ֺ��� ����
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }

        // �������� ����(�� ���̵�)�� ����� Toon Ŀ���Ҷ����� �Լ�
        float4 LightingToon(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) { // �� ���ؽ����� ī�޶� ���ϴ� �交��(viewDir) �� �� ��° ���ڷ� �����;� ��.
            // ��ֺ���(surf �Լ����� �븻���� �븻���͸� ������ ������ ����)�� ������ �������� Half-Lambert ������ ����ؼ� -1 ~ 1 ������ 0 ~ 1 �� ���ν�Ŵ.
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // ����, Half-Lambert �� ����� �������� cutoff �� 0.7�� �������� 1 �Ǵ� 0.3 ���� ��������.
            if (ndotl > 0.7) {
                ndotl = 1;
            }
            else {
                ndotl = 0.3;
            }

            // �̹����� rim ���� ���ؼ� 1Pass �ܰ����� ��������.
            // �켱 �븻�ʿ��� ������ �븻���Ϳ� ī�޶���(viewDir)�� �����ؼ� Fresnel ���� ����.
            // ��������� -1 ~ 1������ ���� �����ϹǷ�, �������� ���ֱ� ���� abs() �� �����.
            float rim = abs(dot(s.Normal, viewDir));

            // ������ Fresnel �� ���� �� 1 - rim ���� rim���� ������������,
            // �̹����� �����ڸ��� ������ 0�� ��������� rim���� �״�� ����ص� ��. �ܰ����� ������ �����ڸ��� ��ο��� �ϴϱ�!
            if (rim > 0.3) {
                // rim���� 0.3���� ū ������ rim ���� ���� 1�� �ʱ�ȭ�ؼ� �Ʒ� final���� ������ �� ������ final ������ �������� ��.
                rim = 1;
            }
            else {
                // rim���� 0.3���� ���� ���� (���� �����ڸ� �α��̰���)�� -1�� final�� �����༭ ����ȭ��Ŵ.
                // �̰Ŵ� 0���� �൵ ���� �ʳ�? �� ���� -1�� �ʱ�ȭ����? 
                // �ֳ��ϸ�, 0���� ������� �Ʒ����� final.rgb�� (0, 0, 0)���� �ʱ�ȭ�� �� �Ƴ�?
                // �̰� �״�� ���� ���������� ĥ����������, ���� noambient �� �����༭ ȯ�汤�� �״�� �����ֱ� ������
                // ���������� ȯ�汤 ������ Ambient Color �� final �� �������鼭 (0, 0, 0) ���� ���� ������ ���͹���...
                // ������ noambient �� �����ؼ� ȯ�汤�� ���ָ� �׳� rim �� 0���� ���൵ �ܰ����� ���������� �� ����.
                rim = -1;
            }

            // ���� surf �Լ����� ������ s.Albedo �ؽ��� ����, ������ cutoff ���� ������, ���� ���� �� ����(_LightColor ���庯��)�� ��� ������ �������� final �� ����ؼ� ������ ��.
            float4 final;
            final.rgb = s.Albedo * ndotl * _LightColor0.rgb * rim;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
