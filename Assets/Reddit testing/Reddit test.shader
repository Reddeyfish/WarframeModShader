Shader "Voxel Shaders/Chunk"
{
	Properties
	{
		_Brightness("Brightness", Range(0.0, 1.0)) = 1.0
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Brightness;

			struct Out
			{
				float4 position : SV_POSITION;
				float4 colour : COLOR;
				float3 normal : TEXCOORD0;
				float3 object_pos : TEXCOORD1;
			};

			Out vert(appdata_full i)
			{
				Out output;
				output.position = UnityObjectToClipPos(i.vertex);
				output.colour = i.color;
				output.normal = i.normal;
				output.object_pos = i.vertex;
				return output;
			}

			fixed4 frag(Out vo) : SV_TARGET 
			{
				float3 e = (2 * vo.object_pos) - vo.normal;
				e.x = abs(e.x);
				e.y = abs(e.y);
				e.z = abs(e.z);
				float max_distance = max(max(e.x, e.y), e.z);
				float distance_from_edge = 1.0 - max_distance;

				float width = 0.15;
				float d = distance_from_edge/width; 

				float k = 5.0;
				float dist = pow(pow(e.x, k) + pow(e.y, k) + pow(e.z, k), 1.0/k);

				float4 colour_in = float4(0.5 + 0.5*sin(_Time.y*0.5), 0.5 + 0.5*sin(_Time.y), 0.5 + 0.5*sin(_Time.y*2), 1.0);

					
				if (max_distance > -width) {
					return float4(colour_in.x*d, colour_in.y*d, colour_in.z*d, 1.0);
				}
				else if (dist > 0.4) {    // 0.1 thickness
					return float4(1.0 - 0.5*vo.object_pos - 0.5, 1.0);
				}
				else{
					return colour_in;
					//colour_out = vec4(0.5 + 0.5 * sin(pos_fragment), 1.0);
				}
					
			}

			ENDCG
		}
	}
}