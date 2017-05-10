// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/LightWrapping" 
{
    Properties 
    {
        _ColorMul ("Main Color", Color) = (1,1,1,1)
    }
    SubShader 
    {
    
        Tags {"RenderType" = "Transparent" "Queue"="AlphaTest"} //In Alphatest Queue becuase it is rendered after Opaque objects and isn't the Transparent or Overlay queue. (Shadows with those tags are disabled as per https://forum.unity3d.com/threads/no-shadows-visible-on-transparency-shaders.9909/)
        // (You can change the queue to be the same as transparent by fiddling with settings on the Renderer, which will override the shader settings here)
        ZWrite Off
        ZTest On
        Pass 
        {
            Tags {"LightMode" = "ForwardBase"}                      // This Pass tag is important or Unity may not give it the correct light information.

            Blend One OneMinusSrcAlpha

           		CGPROGRAM
                #pragma multi_compile_fwdbase
 
                #pragma vertex vert
 
                #pragma fragment frag
 
                #pragma fragmentoption ARB_precision_hint_fastest
 
                #include "UnityCG.cginc"
 
                #include "AutoLight.cginc"
 
 
 
                struct Input
 
                {
 
                    float4 pos : SV_POSITION;
 
                    float3 lightDir : TEXCOORD1;
 
                    float3 vNormal : TEXCOORD2;
 
                    LIGHTING_COORDS(3,4)
 
                };
 
 
 
                Input vert(appdata_full v)
 
                {
 
                    Input o;
 
                    o.pos = UnityObjectToClipPos(v.vertex);
 
                   
 
                    // Calc normal and light dir.
 
                    o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
 
                    o.vNormal = normalize(v.normal).xyz;
 
                   
 
                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
 
                    float3 worldNormal = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
 
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
 
                    return o;
 
                }
 
 
 
                float4 _LightColor0; // Contains the light color for this pass.
 
                half4 _ColorMul;

                half4 frag(Input IN) : COLOR
 
                {
 
                    IN.lightDir = normalize ( IN.lightDir );
 
                    IN.vNormal = normalize ( IN.vNormal );
 
                   
 
                    float atten = LIGHT_ATTENUATION(IN);
 
                    float3 color;
 
                    float NdotL = saturate( dot (IN.vNormal, IN.lightDir ));
 
                    color = UNITY_LIGHTMODEL_AMBIENT.rgb;
 
                    color += _LightColor0.rgb * NdotL * ( atten * 2);
 
                    return half4(color * _ColorMul.rgb * _ColorMul.a, _ColorMul.a);
 
                }
 
               
 
            ENDCG
        }
        Pass {
            Tags {"LightMode" = "ForwardAdd"}                       // Again, this pass tag is important otherwise Unity may not give the correct light information.
            
            Blend One One                                           // Additively blend this pass with the previous one(s). This pass gets run once per pixel light.
            ZWrite Off
            ZTest On
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdadd_fullshadows                        // This line tells Unity to compile this pass for forward add, giving attenuation information for the light.
                
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                //#include "Lighting.cginc"
                
                struct v2f
                {
                    float4  pos         : SV_POSITION;
                    float2  uv          : TEXCOORD0;
                    float3  lightDir    : TEXCOORD2;
                    float3 normal		: TEXCOORD1;
                    LIGHTING_COORDS(3,4)                            // Macro to send shadow & attenuation to the vertex shader.
                };
 
                v2f vert (appdata_tan v)
                {
                    v2f o;
                    
                    o.pos = UnityObjectToClipPos( v.vertex);
                    o.uv = v.texcoord.xy;
                   	
					o.lightDir = ObjSpaceLightDir(v.vertex);
					
					o.normal =  v.normal;
                    TRANSFER_VERTEX_TO_FRAGMENT(o);                 // Macro to send shadow & attenuation to the fragment shader.
                    return o;
                }
                fixed4 _ColorMul;
 
                fixed4 _LightColor0; // Colour of the light used in this pass.
 
                fixed4 frag(v2f i) : COLOR
                {
                    i.lightDir = normalize(i.lightDir);
                    
                    fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.
                   
					fixed3 normal = i.normal;                    
                    fixed diff = saturate(dot(normal, i.lightDir));
                    
                    
                    fixed4 c;
                    c.rgb = (_LightColor0.rgb * diff) * (atten * 2)  * _ColorMul.rgb * _ColorMul.a; // Diffuse
                    c.a = _ColorMul.a;

                    return c;
                }
            ENDCG
        }
        
    }
    FallBack "VertexLit"    // Use VertexLit's shadow caster/receiver passes.
}