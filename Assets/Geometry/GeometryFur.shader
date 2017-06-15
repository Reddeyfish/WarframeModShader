// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/GeometryFur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Factor ("Factor", Range(0., 2.)) = 0.2
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Back
		ZWrite On

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma target 4.6 //tesselation shaders

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

    		#pragma enable_d3d11_debug_symbols

			struct v2g
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed colValue : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2g vert (appdata_tan v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal = v.normal;
				o.tangent = v.tangent;
				o.lightDir = ObjSpaceLightDir(v.vertex);
				return o;
			}

			float rand(float2 co){
    			return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
			}

			float _Factor;

			
			[maxvertexcount(111)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;

				float3 lightDir = normalize(IN[0].lightDir + IN[1].lightDir + IN[2].lightDir);

				float3 normal = normalize(IN[0].normal + IN[1].normal + IN[2].normal);

				float nDotL = (((dot(normal, lightDir) * 0.5) + 0.5) * 0.7) + 0.3;

				//original triangle
				for(int i = 0; i < 3; i++)
				{
					o.pos = UnityObjectToClipPos(IN[i].vertex);
					o.uv = IN[i].uv;
					o.colValue = nDotL * 0.4;
					tristream.Append(o);
				}
				tristream.RestartStrip();

				float3 edgeA = IN[1].vertex - IN[0].vertex;
				float3 edgeB = IN[2].vertex - IN[0].vertex;
				float3 area = length(cross(edgeA, edgeB));

				//sqrt(area), bounded to the range [1..6] and floored
				float tesselation = min(6.0, max(1.0, floor(sqrt(area) * 8.0)));

				for(int x = 0; x < tesselation; x++) {
					for(int y = 0; y < tesselation - (1 + x); y++) {
						float fU = (x + 0.5) / tesselation;
						float fV = (y + 0.5) / tesselation;
						float fW = 1 - fU - fV;

						float3 normalFace = normalize(fU * IN[0].normal + fV * IN[1].normal + fW * IN[2].normal);

						float3 tangent = fU * IN[0].tangent + fV * IN[1].tangent + fW * IN[2].tangent;

						float3 bitangent = normalize(cross(tangent, normalFace));
						tangent = normalize(cross(bitangent, normalFace));

						float2 averageUV = (fU * IN[0].uv + fV * IN[1].uv + fW * IN[2].uv);

						float normalVariationStr = 1.0;

						float2 randomSample = normalVariationStr * float2(2 * rand(averageUV.xy) - 1, 2 * rand(averageUV.yx) - 1);

						float3 randomInTangent;
						randomInTangent.xy = randomSample;
						randomInTangent.z = sqrt(1.0 - saturate(dot(randomSample.xy, randomSample.xy)));

						float3 hairNormal = randomInTangent.x * tangent + randomInTangent.y * bitangent + randomInTangent.z * normalFace;

						float4 averageFace = (fU * IN[0].vertex + fV * IN[1].vertex + fW * IN[2].vertex);

						float3 viewDir = ObjSpaceViewDir(averageFace);

						float3 tangentHair = normalize(cross(viewDir, hairNormal)); //horizontal direction of the hair triangle
						//extruded triangle

							o.pos = UnityObjectToClipPos(averageFace + _Factor / 10.0 * tangentHair);
							o.uv = averageUV;
							o.colValue = nDotL * 0.5;
							tristream.Append(o);

							o.pos = UnityObjectToClipPos(averageFace - _Factor / 10.0 * tangentHair);
							o.uv = averageUV;
							o.colValue = nDotL * 0.5;
							tristream.Append(o);

							o.pos = UnityObjectToClipPos(averageFace + hairNormal);
							o.uv = averageUV;
							o.colValue = nDotL;
							tristream.Append(o);
				
						tristream.RestartStrip();
					}
				}
			}
			
			/*
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;

				float3 edgeA = IN[1].vertex - IN[0].vertex;
				float3 edgeB = IN[2].vertex - IN[0].vertex;
				float3 area = length(cross(edgeA, edgeB));

				//sqrt(area), bounded to the range [1..6] and floored
				float tesselation = min(6.0, max(1.0, floor(sqrt(area) * 8.0)));

				//original triangle
				for(int i = 0; i < 3; i++)
				{
					o.pos = UnityObjectToClipPos(IN[i].vertex);
					o.uv = IN[i].uv;
					o.colValue = tesselation / 6;
					tristream.Append(o);
				}
				tristream.RestartStrip();
			}
			*/

			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * i.colValue;
				return col;
				//return fixed4(i.colValue, i.colValue, i.colValue, 1);
			}
			ENDCG
		}
	} Fallback "VertexLit"
}