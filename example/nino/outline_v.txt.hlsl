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
	TEXCOORD6;
}
out.SV_Position.xyzw = in.POSITION.xyzw;
out.TEXCOORD1.xy = in.TEXCOORD1.xy;
out.TEXCOORD1.zw = float2(0.005, 0.1);
r0.yz = float2(0.001852, 0.001042) * $Globals.windowParamForEdge.wz;
r0.xw = float2(0, 0);
out.TEXCOORD2.xy = r0.zw + in.TEXCOORD1.xy;
r0.z = -0.001042 * $Globals.windowParamForEdge.z;
r0.w = 0;
out.TEXCOORD2.zw = r0.zw + in.TEXCOORD1.xy;
r0.z = 0;
r0.w = -0.001852 * $Globals.windowParamForEdge.w;
out.TEXCOORD3.xyzw = r0.xyzw + in.TEXCOORD1.xyxy;
out.TEXCOORD4.xy = $Globals.windowParamForEdge.zw*float2(0.000521, 0.000926) + in.TEXCOORD1.xy;
out.TEXCOORD4.zw = $Globals.windowParamForEdge.zw*float2(-0.000521, 0.000926) + in.TEXCOORD1.xy;
out.TEXCOORD5.xy = $Globals.windowParamForEdge.zw*float2(0.000521, -0.000926) + in.TEXCOORD1.xy;
out.TEXCOORD5.zw = -$Globals.windowParamForEdge.zw*float2(0.000521, 0.000926) + in.TEXCOORD1.xy;
return;