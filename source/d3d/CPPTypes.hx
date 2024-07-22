#if D3D
package d3d;

#if cpp
import cpp.Pointer;
import cpp.UInt32;
import cpp.ConstCharStar;
#end
#if windows
import d3d11.interfaces.D3d11Device;
import d3d11.interfaces.D3d11DeviceContext;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11DepthStencilView;
import dxgi.interfaces.DxgiSwapChain;
#end

// define a bunch of uhhh C++ Types here as typedefs
typedef LONG = Null<Int>;
typedef UINT = UInt32;
typedef LPSTR = String;
typedef HRESULT = LONG;
typedef PUINT = Pointer<UINT>;
typedef BOOL = Int;
typedef ULONG = UINT;
typedef LPCSTR = ConstCharStar;

typedef DeviceResources =
{
	var device:D3d11Device;
	var context:D3d11DeviceContext;
	var swapChain:DxgiSwapChain;
	var renderTarget:D3d11RenderTargetView;
	var depthStencil:D3d11DepthStencilView;
};
#end
