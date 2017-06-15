//Reddeyfish 6/14/2017
Shader "Custom/TesselateFur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Factor ("Factor", Range(0., 2.)) = 0.2
		_Density("Fur Density", Float) = 8.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
            Tags {"LightMode" = "ForwardBase"}
			Cull Back
        	ZWrite On
        	
			CGPROGRAM
			#pragma vertex vert
			#pragma hull hull
			#pragma domain domain
			#pragma geometry geom
			#pragma fragment frag

			#pragma target 4.6 //tesselation shaders

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

    		#pragma enable_d3d11_debug_symbols
            #pragma multi_compile_fwdbase_fullshadows
            #pragma fragmentoption ARB_precision_hint_fastest

			struct v2h
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
			};

			struct h2dTesselation
			{
       			float TessFactor[3]    : SV_TessFactor;
        		float InsideTessFactor : SV_InsideTessFactor;
			};

			struct h2d
    		{
        		float3 pos    : POS;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
    		};

    		struct d2g
    		{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
    		};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 col : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2h vert (appdata_tan v)
			{
				v2h o;
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
    
    		h2dTesselation hullConstant( InputPatch<v2h, 3> Input )
    		{
        		h2dTesselation output;

				float3 edgeA = Input[1].vertex - Input[0].vertex;
				float3 edgeB = Input[2].vertex - Input[0].vertex;
				float3 area = length(cross(edgeA, edgeB));

				float tesselation = sqrt(area);

        		output.TessFactor[0] = output.TessFactor[1] = output.TessFactor[2] = min(32.0, max(1.0, tesselation * 8.0));
        		output.InsideTessFactor = min(32.0, max(1.0, tesselation * 8.0));    
        		return output;
    		}

    		[domain("tri")]
    		[partitioning("integer")]
    		[outputtopology("triangle_cw")]
    		[patchconstantfunc("hullConstant")]
    		[outputcontrolpoints(3)]
    		h2d hull( InputPatch<v2h, 3> Input, uint uCPID : SV_OutputControlPointID )
    		{
        		h2d Output;
        		Output.pos = Input[uCPID].vertex.xyz;
        		Output.uv = Input[uCPID].uv;
        		Output.normal = Input[uCPID].normal;
        		Output.tangent = Input[uCPID].tangent;
        		Output.lightDir = Input[uCPID].lightDir;
        		return Output;
    		}

    		[domain("tri")]
    		d2g domain( h2dTesselation HSConstantData, 
    					const OutputPatch<h2d, 3> Input, 
    					float3 BarycentricCoords : SV_DomainLocation)
    		{
        		d2g Output;
     
        		float fU = BarycentricCoords.x;
        		float fV = BarycentricCoords.y;
        		float fW = BarycentricCoords.z;
       
        		float3 pos = Input[0].pos * fU + Input[1].pos * fV + Input[2].pos * fW;
      
        		Output.vertex = float4(pos, 1.0);
        		Output.uv = Input[0].uv * fU + Input[1].uv * fV + Input[2].uv * fW;
        		Output.normal = Input[0].normal * fU + Input[1].normal * fV + Input[2].normal * fW;
        		Output.tangent = Input[0].tangent * fU + Input[1].tangent * fV + Input[2].tangent * fW;
				Output.lightDir = Input[0].lightDir * fU + Input[1].lightDir * fV + Input[2].lightDir * fW;

        		return Output;
    		}

			float _Factor;

			[maxvertexcount(24)]
			void geom(triangle d2g IN[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;

				float3 normalFace = normalize(IN[0].normal + IN[1].normal + IN[2].normal);

				float4 averageFace = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

				float3 lightDir = normalize(IN[0].lightDir + IN[1].lightDir + IN[2].lightDir);

				float nDotL = (((dot(normalFace, lightDir) * 0.5) + 0.5) * 0.7) + 0.3;

				//original triangle
				for(int i = 0; i < 3; i++)
				{
					o.pos = UnityObjectToClipPos(IN[i].vertex);
					o.uv = IN[i].uv;
					o.col = fixed4(nDotL * 0.4, nDotL * 0.4, nDotL * 0.4, 1.);
					tristream.Append(o);
				}
				tristream.RestartStrip();

				/*
				float3 edgeA = IN[1].vertex - IN[0].vertex;
				float3 edgeB = IN[2].vertex - IN[0].vertex;
				float3 normalFace = normalize(cross(edgeA, edgeB));
				*/

				float3 tangent = IN[0].tangent + IN[1].tangent + IN[2].tangent;

				float3 bitangent = normalize(cross(tangent, normalFace));
				tangent = normalize(cross(bitangent, normalFace));

				float2 averageUV = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

				float normalVariationStr = 1.0;

				float2 randomSample = normalVariationStr * float2(rand(averageUV.xy), rand(averageUV.yx));

				float3 randomInTangent;
				randomInTangent.xy = randomSample;
				randomInTangent.z = sqrt(1.0 - saturate(dot(randomSample.xy, randomSample.xy)));

				float3 hairNormal = randomInTangent.x * tangent + randomInTangent.y * bitangent + randomInTangent.z * normalFace;

				float3 viewDir = ObjSpaceViewDir(averageFace);

				float3 tangentHair = normalize(cross(viewDir, hairNormal)); //horizontal direction of the hair triangle
				//extruded triangle

					o.pos = UnityObjectToClipPos(averageFace + _Factor / 10.0 * tangentHair);
					o.uv = averageUV;
					o.col = fixed4(nDotL * 0.5, nDotL * 0.5, nDotL * 0.5, 1.);
					tristream.Append(o);

					o.pos = UnityObjectToClipPos(averageFace - _Factor / 10.0 * tangentHair);
					o.uv = averageUV;
					o.col = fixed4(nDotL * 0.5, nDotL * 0.5, nDotL * 0.5, 1.);
					tristream.Append(o);

					o.pos = UnityObjectToClipPos(averageFace + hairNormal);
					o.uv = averageUV;
					o.col = fixed4(nDotL, nDotL, nDotL, 1.);
					tristream.Append(o);
				
				tristream.RestartStrip();
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * i.col;
				return col;
			}
			ENDCG
		}
	} Fallback "VertexLit"
}