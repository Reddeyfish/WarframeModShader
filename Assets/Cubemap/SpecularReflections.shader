//Derek Edrich, 5/14/2017

Shader "Custom/SpecularReflections" {
    Properties 
    {
        _DiffColor ("Main Color", Color) = (1,1,1,1)
		_SpecExpo ("Specular Exponent", Float) = 50
        _Cubemap ("Cubemap", Cube) = "" {}
        _ReflectionTint ("Reflection Tint", Color) = (0.5, 0.5, 0.5, 0.5)
    }


    SubShader 
    {
        
        Tags {"RenderType" = "Opaque" "Queue"="Geometry" } 
        ZWrite On
        ZTest On
        
        Pass 
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Back 
            Blend One Zero  
            CGPROGRAM
                #pragma multi_compile_fwdbase_fullshadows

                #pragma vertex vert
                #pragma fragment basePassFragment
                #pragma fragmentoption ARB_precision_hint_fastest
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                //common functions

                #include "UnityCG.cginc"
                #include "AutoLight.cginc"

                struct BasePassV2FInput
                {
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 lightDir : TEXCOORD1;
                    float3 vNormal : TEXCOORD2;
                    float3 viewDir : TEXCOORD3;

                    LIGHTING_COORDS(4,5)
                };

                float4 _LightColor0; // Contains the light color for this pass.
                half4 _DiffColor; //diffuse color.
                float _SpecExpo; //specular exponent in Phong shading model
                samplerCUBE _Cubemap;
                half3 _ReflectionTint;

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
 
                    UNITY_LIGHT_ATTENUATION(atten, IN, IN.worldPos);
                    //fixed atten = LIGHT_ATTENUATION(IN);
                    float nDotL = dot (IN.vNormal, IN.lightDir);
                    nDotL = max(0, nDotL);
                    float3 reflection = reflect(-IN.viewDir, IN.vNormal); //if you want to use a cubemap for reflections, use this vector to sample from it.
                    float rDotL = saturate(dot(reflection, IN.lightDir));
 
                    float specular = max(0, pow(rDotL, _SpecExpo)); //computation different from, but gives identical results to, the Phong shading model
                    float ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _DiffColor.rgb;
                    float3 diffuse = _DiffColor.rgb * nDotL;
                    float3 reflected = texCUBE(_Cubemap, reflection).rgb * _ReflectionTint;


                    float3 lighting = diffuse + specular.xxx;


                    lighting *= _LightColor0 * atten;
                    float3 color = lighting  + ambient + reflected;
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

                struct AddPassV2FInput
                {
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 lightDir : TEXCOORD1;
                    float3 vNormal : TEXCOORD2;
                    float3 viewDir : TEXCOORD3;

                    LIGHTING_COORDS(4,5)
                };

                float4 _LightColor0; // Contains the light color for this pass.
                half4 _DiffColor; //diffuse color.
                float _SpecExpo; //specular exponent in Phong shading model
 
                AddPassV2FInput vert(appdata_full v) 
                {
                    AddPassV2FInput o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    // Calc normal and light dir.
                    o.lightDir = UnityWorldSpaceLightDir(o.worldPos);
                    o.vNormal = UnityObjectToWorldNormal(v.normal.xyz); 
                    o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                float4 frag(AddPassV2FInput IN) : COLOR
                {
                    //same as basePassFragment, but with ambient and _AlphaOffset removed 
                    IN.lightDir = normalize (IN.lightDir);
                    IN.vNormal = normalize (IN.vNormal);
                    IN.viewDir = normalize(IN.viewDir);

                    UNITY_LIGHT_ATTENUATION(atten, IN, IN.worldPos);
                    //fixed atten = LIGHT_ATTENUATION(IN);
                    float nDotL = dot (IN.vNormal, IN.lightDir);
                    nDotL = max(0, nDotL);
                    float3 reflection = reflect(-IN.viewDir, IN.vNormal);
                    float rDotL = saturate(dot(reflection, IN.lightDir));

                    float specular = max(0, pow(rDotL, _SpecExpo));
                    float3 diffuse = _DiffColor.rgb * nDotL; 
                    float3 lighting = diffuse + specular.xxx;
                    lighting *= _LightColor0 * atten;
                    //no ambient
                    float3 color = lighting;
                    return float4(color, 1);
                }
            ENDCG
        }
    }
    FallBack "VertexLit" 
}