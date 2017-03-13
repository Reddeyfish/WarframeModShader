Shader "Custom/ModShader"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset] _HeightTex ("HeightMap", 2D) = "white" {}
        [PerRendererData] _OffsetVector ("OffsetVector", Vector) = (0, 0, 0, 0)
		_BumpTex1 ("First Moving BumpTex", 2D) = "white" {}
		_BumpTex2 ("Second Moving BumpTex", 2D) = "white" {}
        _MovementVector ("BumpTex Movement Vectors", Vector) = (0.1, 0, -0.1, 0)
        _LightDir ("LightDirection (Worldspace)", Vector) = (1, 1, 1, 0)
        _Shininess ("Shininess Coefficient", Float) = 15
        _Albedo ("Albedo", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags {  "RenderType"="Opaque" 
			    "IgnoreProjector" = "True"
			    "PreviewType" = "Plane" }
		LOD 100

		Pass
		{
            ZWrite On
            Blend One Zero

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
                float4 tangent : TANGENT;
	            float3 normal : NORMAL;
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
                float3 tangent : TANGENT;
	            float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 bumpUV1 : TEXCOORD1;
				float2 bumpUV2 : TEXCOORD2;
				float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD3;
			};

			sampler2D _MainTex;
			sampler2D _HeightTex;
            
			float2 _OffsetVector;

			sampler2D _BumpTex1;
            float4 _BumpTex1_ST;
			sampler2D _BumpTex2;
            float4 _BumpTex2_ST;

            float4 _MovementVector; //x and y are the 2D movement vector for BumpTex1, and z and w are the 2D movement vector for BumpTex2
			float3 _LightDir;
            float _Shininess;

            fixed3 _Albedo;

			v2f vert (appdata v)
			{
				v2f o;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldNormal(v.tangent);
				o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewDir = UnityWorldSpaceViewDir(v.vertex);

				o.uv = v.uv;
                o.bumpUV1 = TRANSFORM_TEX((_Time.x * _MovementVector.xy) + v.uv, _BumpTex1);
                o.bumpUV2 = TRANSFORM_TEX((_Time.x * _MovementVector.zw) + v.uv, _BumpTex2);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the heightmap to determine our actual UV for the maintexture
                float height = tex2D(_HeightTex, i.uv).r;
                float2 textureUV = i.uv + _OffsetVector * height;
				fixed4 col = tex2D(_MainTex, textureUV);

                //now calculate lighting

                //starting with our normal
                float4 sampledBump = (tex2D(_BumpTex1, i.bumpUV1) + 1 - tex2D(_BumpTex2, i.bumpUV2));
                float3 bump = UnpackNormal(normalize(sampledBump));

                float3 bitangent = cross( normalize(i.normal), normalize(i.tangent.xyz) );
                float3 normalMappedNormal = bump.x * i.tangent.xyz + bump.y * bitangent + bump.z * i.normal;

                //see Blinn-Phong
                float3 h = normalize(normalize(_LightDir) + normalize(i.viewDir));
                float3 lighting = _Albedo * max(0, pow(max(0, dot(h, normalMappedNormal)), _Shininess));

                col.xyz += lighting;

                //TODO: the lighting resembles cellophane

                /*
                float4 result = float4(0,0,0,1);
                result.xyz += sampledBump;
                return result;
                */

				return col;
			}
			ENDCG
		}
	}
}
