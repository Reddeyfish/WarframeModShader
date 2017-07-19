//Reddeyfish 6/14/2017
Shader "Custom/TesselateFur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Factor ("Factor", Range(0., 2.)) = 0.02
		_Density ("Fur Density", Float) = 6.0
		_Occlusion ("Occlusion", Range(0, 1)) = 0.4
		_HairColor ("Hair Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }

		//base skin pass
		Pass
		{
			Name "SKIN"
            Tags {"LightMode" = "ForwardBase"}
			Cull Back
        	ZWrite On
        	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 3.0 //tesselation shaders

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest

			struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 vNormal : TEXCOORD3;

                LIGHTING_COORDS(4,5)
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Calc normal and light dir.
                o.lightDir = UnityWorldSpaceLightDir(o.worldPos);
                o.vNormal = UnityObjectToWorldNormal(v.normal.xyz); 
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
			
			float _Occlusion;
			float4 _LightColor0; // Contains the light color for this pass.

			fixed4 frag (v2f IN) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, IN.uv);
				col.rgb *= _Occlusion;
				IN.lightDir = normalize (IN.lightDir);
                IN.vNormal = normalize (IN.vNormal);

                UNITY_LIGHT_ATTENUATION(atten, IN, IN.worldPos);
                //fixed atten = LIGHT_ATTENUATION(IN);
                float nDotL = dot (IN.vNormal, IN.lightDir);
                nDotL = max(0, nDotL);

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * col.rgb;
                float3 diffuse = col.rgb * nDotL;
                //float3 lighting = diffuse + specular.xxx; //no specular
                float3 lighting = diffuse;


                lighting *= _LightColor0 * atten;
                float3 color = lighting  + ambient;
                return float4(color, col.a);
				return col;
			}
			ENDCG
		}

		Pass
		{
			Name "FUR"
            Tags {"LightMode" = "ForwardBase"}
			Cull Off
        	ZWrite On //normally would be off, but we need to write it to avoid blurring from sky haze
        	
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
            #pragma multi_compile_fwdbase
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
    
			float _Density;

    		h2dTesselation hullConstant( InputPatch<v2h, 3> Input )
    		{
        		h2dTesselation output;

				float3 edgeA = Input[1].vertex - Input[0].vertex;
				float3 edgeB = Input[2].vertex - Input[0].vertex;
				float3 area = length(cross(edgeA, edgeB));

				float tesselation = sqrt(area);

        		output.TessFactor[0] = output.TessFactor[1] = output.TessFactor[2] = min(32.0, max(1.0, tesselation * _Density));
        		output.InsideTessFactor = min(32.0, max(1.0, tesselation * _Density));    
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
			float _Occlusion;
			float4 _LightColor0; // Contains the light color for this pass.
			float3 _HairColor;

			[maxvertexcount(3)]
			void geom(triangle d2g IN[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;

				float3 normalFace = normalize(IN[0].normal + IN[1].normal + IN[2].normal);
				float4 averageFace = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
				float3 lightDir = normalize(IN[0].lightDir + IN[1].lightDir + IN[2].lightDir);
				float2 averageUV = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

				float nDotL = dot(normalFace, lightDir);
				nDotL = max(0, nDotL);

				fixed4 col;
				#if !defined(SHADER_API_OPENGL) && !defined(SHADER_API_D3D11_9X)
					col = tex2Dlod(_MainTex, float4(averageUV, 0, 0));
				#else
					col = fixed4(1, 1, 1, 1);
				#endif
				col.rgb *= _HairColor;


				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * col.rgb;
                float3 diffuse = col.rgb * nDotL;
                //float3 lighting = diffuse + specular.xxx; //no specular
                float3 lighting = diffuse;


                //lighting *= _LightColor0 * atten; //ignore lighting attenuation
                lighting *= _LightColor0;
                float4 color = float4(lighting  + ambient, col.a);

				/*
				float3 edgeA = IN[1].vertex - IN[0].vertex;
				float3 edgeB = IN[2].vertex - IN[0].vertex;
				float3 normalFace = normalize(cross(edgeA, edgeB));
				*/

				float3 tangent = IN[0].tangent + IN[1].tangent + IN[2].tangent;

				float3 bitangent = normalize(cross(tangent, normalFace));
				tangent = normalize(cross(bitangent, normalFace));

				float normalVariationStr = 1.0;

				float2 randomSample = normalVariationStr * float2(rand(averageUV.xy), rand(averageUV.yx));

				float3 randomInTangent;
				randomInTangent.xy = randomSample;
				randomInTangent.z = sqrt(1.0 - saturate(dot(randomSample.xy, randomSample.xy)));

				float3 hairNormal = randomInTangent.x * tangent + randomInTangent.y * bitangent + randomInTangent.z * normalFace;

				float3 viewDir = ObjSpaceViewDir(averageFace);

				float3 tangentHair = normalize(cross(viewDir, hairNormal)); //horizontal direction of the hair triangle

				o.pos = UnityObjectToClipPos(averageFace + _Factor * tangentHair);
				//o.uv = averageUV;
				o.col = color;
				o.col.rgb *= _Occlusion;
				tristream.Append(o);

				o.pos = UnityObjectToClipPos(averageFace - _Factor * tangentHair);
				//o.uv = averageUV;
				o.col = color;
				o.col.rgb *= _Occlusion;
				tristream.Append(o);

				o.pos = UnityObjectToClipPos(averageFace + hairNormal);
				//o.uv = averageUV;
				o.col = color;
				tristream.Append(o);
				
				tristream.RestartStrip();
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				return i.col;
			}
			ENDCG
		}
	} Fallback "VertexLit"
}