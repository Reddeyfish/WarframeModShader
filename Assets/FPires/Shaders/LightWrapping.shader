// Upgrade NOTE: replaced 'defined defined' with 'defined (defined)'
// Upgrade NOTE: replaced 'defined return' with 'defined (return)'

Shader "Custom/LightWrapping" {
    Properties 
    {
        _DiffColor ("Main Color", Color) = (1,1,1,1)
		_SpecExpo ("Specular Exponent", Float) = 50
        _LightWrapping ("Light Wrapping", Range(0, 1)) = 0.25
        _Gradient("Gradient", 2D) = "white" {}
        _OpacityExponent("Opacity Distance Exponent", Float) = 100
        _ScatterOffset ("Scattering Interpolation. 0 for frontscatter, 1 for backscatter", Range(0, 1)) = 0.5
    }

    CGINCLUDE
        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "UnityShadowLibrary.cginc"
        #include "HLSLSupport.cginc"

        struct BasePassV2FInput
        {
            float4 pos : SV_POSITION;
            float3 worldPos : TEXCOORD0;
            float3 lightDir : TEXCOORD1;
            float3 vNormal : TEXCOORD2;
            float3 viewDir : TEXCOORD3;

            LIGHTING_COORDS(4,5)
        };

    	//UNITY_SAMPLE_SHADOW / UNITY_SAMPLE_SHADOW_PROJ declarations
    	//from HLSLSupport.cginc
    	#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X) || defined(UNITY_COMPILER_HLSLCC)
		    // DX11 & hlslcc platforms: built-in PCF
		    //#if defined(SHADER_API_D3D11_9X)
		        // FL9.x has some bug where the runtime really wants resource & sampler to be bound to the same slot,
		        // otherwise it is skipping draw calls that use shadowmap sampling. Let's bind to #15
		        // and hope all works out.
		        //#define UNITY_DECLARE_SHADOWMAP(tex) Texture2D tex : register(t15); SamplerComparisonState sampler##tex : register(s15)
		    //#else
		        //#define UNITY_DECLARE_SHADOWMAP(tex) Texture2D tex; SamplerComparisonState sampler##tex
		    //#endif
		    //#define UNITY_SAMPLE_SHADOW(tex,coord) tex.SampleCmpLevelZero (sampler##tex,(coord).xy,(coord).z)
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex.SampleCmpLevelZero (sampler##tex,(coord).xy/(coord).w,(coord).z/(coord).w)
		    

		#elif defined(UNITY_COMPILER_HLSL2GLSL) && defined(SHADOWS_NATIVE)
		    // OpenGL-like hlsl2glsl platforms: most of them always have built-in PCF
		    //#define UNITY_DECLARE_SHADOWMAP(tex) sampler2DShadow tex
		    //#define UNITY_SAMPLE_SHADOW(tex,coord) shadow2D (tex,(coord).xyz)
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) shadow2Dproj (tex,coord)
		#elif defined(SHADER_API_D3D9)
		    // D3D9: Native shadow maps FOURCC "driver hack", looks just like a regular
		    // texture sample. Have to always do a projected sample
		    // so that HLSL compiler doesn't try to be too smart and mess up swizzles
		    // (thinking that Z is unused).
		    //#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
		    //#define UNITY_SAMPLE_SHADOW(tex,coord) tex2Dproj (tex,float4((coord).xyz,1)).r
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex2Dproj (tex,coord).r
		#elif defined(SHADER_API_PSSL)
		    // PS4: built-in PCF
		    //#define UNITY_DECLARE_SHADOWMAP(tex)        Texture2D tex; SamplerComparisonState sampler##tex
		    //#define UNITY_SAMPLE_SHADOW(tex,coord)      tex.SampleCmpLOD0(sampler##tex,(coord).xy,(coord).z)
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex.SampleCmpLOD0(sampler##tex,(coord).xy/(coord).w,(coord).z/(coord).w)
		#elif defined(SHADER_API_PSP2)
		    // Vita
		    //#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
		    // tex2d shadow comparison on Vita returns 0 instead of 1 when shadowCoord.z >= 1 causing artefacts in some tests.
		    // Clamping Z to the range 0.0 <= Z < 1.0 solves this.
		    //#define UNITY_SAMPLE_SHADOW(tex,coord) tex2D<float>(tex, float3((coord).xy, clamp((coord).z, 0.0, 0.999999)))
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex2DprojShadow(tex, coord)
		#else
		    // Fallback / No built-in shadowmap comparison sampling: regular texture sample and do manual depth comparison
		    //#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D_float tex
		    //#define UNITY_SAMPLE_SHADOW(tex,coord) ((SAMPLE_DEPTH_TEXTURE(tex,(coord).xy) < (coord).z) ? 0.0 : 1.0)
		    //#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) ((SAMPLE_DEPTH_TEXTURE_PROJ(tex,UNITY_PROJ_COORD(coord)) < ((coord).z/(coord).w)) ? 0.0 : 1.0)
		    #define CUSTOM_SAMPLE_SHADOW_DEPTH_PROJ(tex,coord) ((SAMPLE_DEPTH_TEXTURE_PROJ(tex,UNITY_PROJ_COORD(coord)))
		#endif

		//UnitySampleShadowmap definitions
		//from UnityShadowLibrary.cginc
		#if defined (SHADOWS_DEPTH) && defined (SPOT)
			/*
			inline fixed UnitySampleShadowmap (float4 shadowCoord)
			{
			    // DX11 feature level 9.x shader compiler (d3dcompiler_47 at least)
			    // has a bug where trying to do more than one shadowmap sample fails compilation
			    // with "inconsistent sampler usage". Until that is fixed, just never compile
			    // multi-tap shadow variant on d3d11_9x.

			        // 1-tap shadows

			    #if defined (SHADOWS_NATIVE)
			    half shadow = UNITY_SAMPLE_SHADOW_PROJ(_ShadowMapTexture, shadowCoord);
			    shadow = _LightShadowData.r + shadow * (1-_LightShadowData.r);
			    #else
			    half shadow = SAMPLE_DEPTH_TEXTURE_PROJ(_ShadowMapTexture, UNITY_PROJ_COORD(shadowCoord)) < (shadowCoord.z / shadowCoord.w) ? _LightShadowData.r : 1.0;

			    #endif

			    return shadow;
			}
			*/
		#endif // #if defined (SHADOWS_DEPTH) && defined (SPOT)

		#if defined (SHADOWS_CUBE)
			/*
			samplerCUBE_float _ShadowMapTexture;
			inline float SampleCubeDistance (float3 vec)
			{
			    #ifdef UNITY_FAST_COHERENT_DYNAMIC_BRANCHING
			        return UnityDecodeCubeShadowDepth(texCUBElod(_ShadowMapTexture, float4(vec, 0)));
			    #else
			        return UnityDecodeCubeShadowDepth(texCUBE(_ShadowMapTexture, vec));
			    #endif
			}
			inline half UnitySampleShadowmap (float3 vec)
			{
			    float mydist = length(vec) * _LightPositionRange.w;
			    mydist *= 0.97; // bias

			    #if defined (SHADOWS_SOFT)
			        float z = 1.0/128.0;
			        float4 shadowVals;
			        shadowVals.x = SampleCubeDistance (vec+float3( z, z, z));
			        shadowVals.y = SampleCubeDistance (vec+float3(-z,-z, z));
			        shadowVals.z = SampleCubeDistance (vec+float3(-z, z,-z));
			        shadowVals.w = SampleCubeDistance (vec+float3( z,-z,-z));
			        half4 shadows = (shadowVals < mydist.xxxx) ? _LightShadowData.rrrr : 1.0f;
			        return dot(shadows,0.25);
			    #else
			        float dist = SampleCubeDistance (vec);
			        return dist < mydist ? _LightShadowData.r : 1.0;
			    #endif
			}
			*/
			inline float CustomSampleShadowDepth(float3 vec) {
				float result = saturate(length(vec) * _LightPositionRange.w * 0.95);
				return result;
			}

		#endif // #if defined (SHADOWS_CUBE)
/*
    	//SHADOW_ATTENUATION definitions
    	//copied and modifed from AutoLight.cginc. 
    	#if defined (SHADOWS_DEPTH) && defined (SPOT)
			//#define SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
			//#define TRANSFER_SHADOW(a) a._ShadowCoord = mul (unity_WorldToShadow[0], mul(unity_ObjectToWorld,v.vertex));
			#define SHADOW_ATTENUATION(a) UnitySampleShadowmap(a._ShadowCoord)
		#endif

		// ---- Point light shadows
		#if defined (SHADOWS_CUBE)
			//#define SHADOW_COORDS(idx1) unityShadowCoord3 _ShadowCoord : TEXCOORD##idx1;
			//#define TRANSFER_SHADOW(a) a._ShadowCoord = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
			#define SHADOW_ATTENUATION(a) UnitySampleShadowmap(a._ShadowCoord)
		#endif

		// ---- Shadows off
		#if !defined (SHADOWS_SCREEN) && !defined (SHADOWS_DEPTH) && !defined (SHADOWS_CUBE)
			//#define SHADOW_COORDS(idx1)
			//#define TRANSFER_SHADOW(a)
			#define SHADOW_ATTENUATION(a) 1.0
		#endif

    	#if defined (SHADOWS_SCREEN)
			#define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord)
		#endif

		//UNITY_SHADOW_ATTENUATION definitions
    	//copied and modifed from AutoLight.cginc. 
    	#if defined(HANDLE_SHADOWS_BLENDING_IN_GI) // handles shadows in the depths of the GI function for performance reasons
		//#   define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
		//#   define UNITY_TRANSFER_SHADOW(a, coord) TRANSFER_SHADOW(a)
		#   define UNITY_SHADOW_ATTENUATION(a, worldPos) SHADOW_ATTENUATION(a)
		#elif defined(SHADOWS_SCREEN) && !defined(LIGHTMAP_ON) && !defined(UNITY_NO_SCREENSPACE_SHADOWS) // no lightmap uv thus store screenPos instead
		//#   define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
		//#   define UNITY_TRANSFER_SHADOW(a, coord) TRANSFER_SHADOW(a)
		#   define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, a._ShadowCoord)
		#else
		//#   define UNITY_SHADOW_COORDS(idx1) unityShadowCoord2 _ShadowCoord : TEXCOORD##idx1;
		#   if defined(SHADOWS_SHADOWMASK)
		//#       define UNITY_TRANSFER_SHADOW(a, coord) a._ShadowCoord = coord * unity_LightmapST.xy + unity_LightmapST.zw;
		#       if (defined(SHADOWS_DEPTH) || defined(SHADOWS_SCREEN) || defined(SHADOWS_CUBE) || UNITY_LIGHT_PROBE_PROXY_VOLUME)
		#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(a._ShadowCoord, worldPos, 0)
		#       else
		#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(a._ShadowCoord, 0, 0)
		#       endif
		#   else
		//#       define UNITY_TRANSFER_SHADOW(a, coord)
		#       if (defined(SHADOWS_DEPTH) || defined(SHADOWS_SCREEN) || defined(SHADOWS_CUBE))
		#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, 0)
		#       else
		            #if UNITY_LIGHT_PROBE_PROXY_VOLUME
		#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, 0)
		            #else
		#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, 0, 0)
		            #endif
		#       endif
		#   endif
		#endif
*/
		//UNITY_LIGHT_ATTENUATION definitions
        //copied and modified from AutoLight.cginc. Remove shadow component from UNITY_LIGHT_ATTENUATION and rename to CUSTOM_LIGHT_ATTENUATION
        #ifdef POINT
			float CUSTOM_LIGHT_ATTENUATION(BasePassV2FInput input, float3 worldPos) 
			{
			    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; 
			    //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); 
			    return tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;// * shadow;
			}
		#endif

		#ifdef SPOT
			float CUSTOM_LIGHT_ATTENUATION(BasePassV2FInput input, float3 worldPos)
			{
			    unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)); 
			    //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); 
			    return (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);// * shadow;
			}
		#endif

		#ifdef DIRECTIONAL
		    float CUSTOM_LIGHT_ATTENUATION(BasePassV2FInput input, float3 worldPos) { return 1; }//return UNITY_SHADOW_ATTENUATION(input, worldPos);
		#endif

		#ifdef POINT_COOKIE
			float CUSTOM_LIGHT_ATTENUATION(BasePassV2FInput input, float3 worldPos)
			{
			    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz;
			    //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos);
			    return tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w;// * shadow;
			}
		#endif

		#ifdef DIRECTIONAL_COOKIE
			float CUSTOM_LIGHT_ATTENUATION(BasePassV2FInput input, float3 worldPos){
			    unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy;
			    //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
			    return tex2D(_LightTexture0, lightCoord).w;// * shadow;
			}
		#endif
    ENDCG

    SubShader 
    {
        
        Tags {"RenderType" = "Opaque" "Queue"="Geometry" "IgnoreProjector" = "true"} 
        ZWrite On
        ZTest On
        
        Pass 
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Back 
            Blend One Zero  
            CGPROGRAM
                #pragma multi_compile_fwdbase
                #pragma vertex vert
                #pragma fragment basePassFragment
                #pragma fragmentoption ARB_precision_hint_fastest
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
        		#include "UnityShadowLibrary.cginc"
                //common functions

                float4 _LightColor0; // Contains the light color for this pass.
                half4 _DiffColor; //diffuse color.
                float _SpecExpo; //specular exponent in Phong shading model
                float _LightWrapping;
                sampler2D _Gradient;
                float _OpacityExponent;
                float _ScatterOffset;

                BasePassV2FInput vert(appdata_full v)
                {
                    BasePassV2FInput o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    // Calc normal and light dir.
                    o.lightDir = UnityWorldSpaceLightDir(o.worldPos);
                    o.vNormal = UnityObjectToWorldNormal(v.normal.xyz); 
                    o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                float4 basePassFragment(BasePassV2FInput IN) : COLOR
                {
                    IN.lightDir = normalize (IN.lightDir);
                    IN.vNormal = normalize (IN.vNormal);
                    IN.viewDir = normalize(IN.viewDir);
 

                    float atten = CUSTOM_LIGHT_ATTENUATION(IN, IN.worldPos);
                    float nDotL = lerp(dot (IN.vNormal, IN.lightDir), 1, _LightWrapping);
                    nDotL = max(0, nDotL);
                    float3 reflection = reflect(-IN.viewDir, IN.vNormal); //if you want to use a cubemap for reflections, use this vector to sample from it.
                    float rDotL = dot(reflection, IN.lightDir);
                    rDotL = saturate(rDotL);
 
                    float specular = max(0, pow(rDotL, _SpecExpo)); //computation different from, but gives identical results to, the Phong shading model
                    float ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _DiffColor.rgb;
                    float3 diffuse = _DiffColor.rgb * nDotL;
                    float3 lighting = (diffuse * (1 - _ScatterOffset)) + specular.xxx;

                    lighting *= _LightColor0 * atten;
                    float3 color = lighting + ambient;
                    
                    return float4(color, _DiffColor.a);
                }
            ENDCG
        }
       
        Pass {
            Tags {"LightMode" = "ForwardAdd"}                       
            Cull Back 
            Blend One One //ForwardAdd is intended to be additively lit
            CGPROGRAM
                #pragma multi_compile_fwdadd_fullshadows
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_fastest
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"

                float4 _LightColor0; // Contains the light color for this pass.
                half4 _DiffColor; //diffuse color.
                float _SpecExpo; //specular exponent in Phong shading model
                float _LightWrapping;
                sampler2D _Gradient;
                float _OpacityExponent;
                float _ScatterOffset;

                BasePassV2FInput vert(appdata_full v) 
                {
                    BasePassV2FInput o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    // Calc normal and light dir.
                    o.lightDir = UnityWorldSpaceLightDir(o.worldPos);
                    o.vNormal = UnityObjectToWorldNormal(v.normal.xyz); 
                    o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                float4 frag(BasePassV2FInput IN) : COLOR
                {
                    //same as basePassFragment, but with ambient and _AlphaOffset removed 
                    IN.lightDir = normalize (IN.lightDir);
                    IN.vNormal = normalize (IN.vNormal);
                    IN.viewDir = normalize(IN.viewDir);
 
 					
                    float atten = CUSTOM_LIGHT_ATTENUATION(IN, IN.worldPos);
                    float nDotL = lerp(dot (IN.vNormal, IN.lightDir), 1, _LightWrapping);
                    nDotL = max(0, nDotL);
                    float3 reflection = reflect(-IN.viewDir, IN.vNormal);
                    float rDotL = dot(reflection, IN.lightDir);
                    rDotL = saturate(rDotL);
                    float specular = max(0, pow(rDotL, _SpecExpo));
                    float3 diffuse = _DiffColor.rgb * nDotL; 
                    float3 lighting = (diffuse * (1 - _ScatterOffset)) + specular.xxx;
                    lighting *= _LightColor0 * atten;
                    //no ambient
                    float3 color = lighting;
                    #if defined (SHADOWS_CUBE)

                    	float entryDist = SampleCubeDistance (IN._ShadowCoord);
                    	float exitDist = length(IN._ShadowCoord) * _LightPositionRange.w;
			    		//exitDist *= 0.97; // bias

			    		float depthExp = saturate(exp((entryDist - exitDist) * _OpacityExponent));
			    		color += tex2D(_Gradient, float2(depthExp - 0.01, 0.5)) * _ScatterOffset;

                    #endif
                    return float4(color, 1);
                }
            ENDCG
        }
    }
    FallBack "VertexLit" 
}