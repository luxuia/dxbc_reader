class $Globals{
	float4	windowParamForEdge;
}
class INPUT {
	POSITION;
	TEXCOORD1;
}
class OUT {
	SV_Position;
	TEXCOORD1;
	TEXCOORD2;
	TEXCOORD3;
	TEXCOORD4;
	TEXCOORD5;
}
out.SV_Position.xyzw = in.POSITION.xyzw;
out.TEXCOORD1.xy = in.TEXCOORD1.xy;
r0.z = -0.000521 * $Globals.windowParamForEdge.z;
r0.w = 0;
out.TEXCOORD2.zw = r0.zw + in.TEXCOORD1.xy;
r0.xw = float2(0.000521, 0.000521) * $Globals.windowParamForEdge.zw;
r0.yz = float2(0, 0);
out.TEXCOORD2.xy = r0.xy + in.TEXCOORD1.xy;
out.TEXCOORD3.xy = r0.zw + in.TEXCOORD1.xy;
r0.z = 0;
r0.w = -0.000521 * $Globals.windowParamForEdge.w;
out.TEXCOORD3.zw = r0.zw + in.TEXCOORD1.xy;
r0.z = -0.001042 * $Globals.windowParamForEdge.z;
r0.w = 0;
out.TEXCOORD4.zw = r0.zw + in.TEXCOORD1.xy;
r0.xw = float2(0.001042, 0.001042) * $Globals.windowParamForEdge.zw;
r0.yz = float2(0, 0);
out.TEXCOORD4.xy = r0.xy + in.TEXCOORD1.xy;
out.TEXCOORD5.xy = r0.zw + in.TEXCOORD1.xy;
r0.z = 0;
r0.w = -0.001042 * $Globals.windowParamForEdge.w;
out.TEXCOORD5.zw = r0.zw + in.TEXCOORD1.xy;
return;