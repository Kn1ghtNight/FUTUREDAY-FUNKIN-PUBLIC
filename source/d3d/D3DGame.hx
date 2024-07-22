#if D3D
package d3d;

import flixel.FlxG;
import haxe.io.Bytes;
#if windows
import d3d11.interfaces.D3d11Resource;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.structures.D3d11SubResourceData;
import d3d11.enumerations.D3d11CpuAccessFlag;
import d3d11.structures.D3d11BufferDescription;
import d3d11.enumerations.D3d11Usage;
import d3d11.structures.D3d11DepthStencilViewDescription;
import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11Texture2D.NativeID3D11Texture2D;
import d3d11.structures.D3d11Texture2DDescription;
import dxgi.structures.DxgiSwapChainFullscreenDescription;
import dxgi.structures.DxgiSampleDescription;
import d3d11.enumerations.D3dDriverType;
import d3dcommon.enumerations.D3dFeatureLevel;
import dxgi.constants.DxgiError;
import d3d11.structures.D3d11Viewport;
import d3d11.enumerations.D3d11ClearFlag;
import d3d.DirectXTK.ThrowIfFailed;
import d3d11.D3d11;
import d3d11.interfaces.D3d11Device.D3d11Device1;
import d3dcommon.enumerations.D3dDriverType;
import d3d11.interfaces.D3d11Device;
import dxgi.enumerations.DxgiSwapEffect;
import dxgi.interfaces.DxgiDevice;
import dxgi.enumerations.DxgiScaling;
import dxgi.structures.DxgiRational;
import dxgi.structures.DxgiModeDescription;
import dxgi.structures.DxgiSwapChainDescription;
import dxgi.interfaces.DxgiFactory;
import dxgi.interfaces.DxgiAdapter;
import dxgi.enumerations.DxgiFormat;
import d3d.WindowManager;
import d3d11.interfaces.D3d11DepthStencilView;
import d3d11.enumerations.D3d11BindFlag;
import dxgi.constants.DxgiError;
import dxgi.interfaces.DxgiSwapChain;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11DeviceContext;
import d3d11.interfaces.D3d11Device;
import d3d11.enumerations.D3d11CreateDeviceFlags;
import d3d11.interfaces.D3d11Buffer;
#end
#if cpp
import cpp.Star;
import d3d.CPPTypes;
import cpp.UInt8;
import cpp.Pointer;

using cpp.Native;
#end

@:include('d3d11.h')
class D3DGame
{
	// going to be a ton of c++ code
	private var resources:DeviceResources;

	// window properties
	public var width:Int;
	public var height:Int;
	public var isActive(default, set):Bool = false;

	private var isDeviceCreated:Bool = false;
	private var areResourcesAllocated:Bool = false;

	private function set_isActive(n:Bool):Bool
	{
		trace('[[IMPORTANT]]: Current 3D activation state: ${n ? "ACTIVE" : "INACTIVE. Shouldn't update models or sprites in this case"}');
		if (n == isActive)
		{
			trace("Not setting isActive if trying to set it to it's current value: " + isActive + " You tried setting it to: " + n);
			return n;
		}

		if (!isDeviceCreated || !areResourcesAllocated)
		{
			trace("[[IMPORTANT]]: Tried activating the renderer while the device is missing/uncreated or the resources are missing/uncreated.\nPlease wait until they've been initialized to use them.");
			return isActive = false;
		}

		return isActive = n;
	}

	public function new(width:Int, height:Int)
	{
		this.width = width;
		this.height = height;
		this.isActive = false;
		resources = {
			depthStencil: null,
			renderTarget: null,
			swapChain: null,
			device: new D3d11Device(),
			context: new D3d11DeviceContext()
		};

		CreateDevice();
		CreateResources();

		this.isActive = true;
	}

	public function Tick(elapsed:Float):Void
	{
		Update(elapsed);

		Render();
	}

	public function onActivated():Void
	{
		isActive = true;
	}

	public function onDeactivated():Void
	{
		isActive = false;
	}

	public function onSuspended():Void
	{
		isActive = false;
	}

	public function onResume():Void
	{
		isActive = true;
	}

	public function onWindowSizeChanged(width:Int, height:Int):Void
	{
		this.width = width;
		this.height = height;

		final viewport:D3d11Viewport = new D3d11Viewport();
		viewport.topLeftX = 0;
		viewport.topLeftY = 0;
		viewport.width = this.width;
		viewport.height = this.height;
		viewport.minDepth = 0;
		viewport.maxDepth = 1;

		resources.context.rsSetViewports([viewport]);

		CreateResources();
	}

	private function CreateDevice():Void
	{
		// finally
		ThrowIfFailed(D3d11.createDevice(null, D3dDriverType.Hardware, null, 0, null, D3d11.SdkVersion, resources.device, null, resources.context));

		trace("Device created successfully.");
		isDeviceCreated = true;
	}

	private function CreateResources():Void
	{
		if (resources.context == null || resources.device == null)
			throw 'Tried to create resources while main device objects haven\'t been created yet. Please call CreateDevice() first and then call this.';

		resources.context.omSetRenderTargets([], null);
		if (resources.renderTarget != null && resources.renderTarget.ptr != null)
			resources.renderTarget.ptr.release();

		resources.renderTarget = null;
		if (resources.depthStencil != null && resources.depthStencil.ptr != null)
			resources.depthStencil.ptr.release();
		resources.depthStencil = null;

		resources.context.flush();

		final backbufferFormat:DxgiFormat = B8G8R8A8UNorm;
		final depthbufferFormat:DxgiFormat = DxgiFormat.D24UNormS8UInt;
		final backbufferCount:UINT = 1;

		if (resources.swapChain != null && areResourcesAllocated)
		{
			final hr:HRESULT = resources.swapChain.resizeBuffers(backbufferCount, width, height, backbufferFormat, 0);

			if (hr == DxgiError.DeviceRemoved || hr == DxgiError.DeviceReset)
			{
				onDeviceLost();
				return;
			}
			else
				ThrowIfFailed(hr);
		}
		else
		{
			this.resources.swapChain = new DxgiSwapChain();
			var factory:DxgiFactory = new DxgiFactory();

			ThrowIfFailed(dxgi.Dxgi.createFactory(factory));

			var swapChainDescription = new DxgiSwapChainDescription();
			swapChainDescription.bufferDesc.width = this.width;
			swapChainDescription.bufferDesc.height = this.height;
			swapChainDescription.bufferDesc.format = backbufferFormat;
			swapChainDescription.sampleDesc.count = 1;
			swapChainDescription.bufferCount = 1;
			swapChainDescription.bufferUsage = RenderTargetOutput;
			swapChainDescription.swapEffect = DxgiSwapEffect.Discard;
			swapChainDescription.windowed = true;
			swapChainDescription.outputWindow = WindowManager.GetHWND();

			ThrowIfFailed(factory.createSwapChain(this.resources.device, swapChainDescription, this.resources.swapChain));

			trace("Created SwapChain successfully.");
		}

		var backBuffer:D3d11Texture2D = new D3d11Texture2D();

		ThrowIfFailed(resources.swapChain.getBuffer(0, NativeID3D11Texture2D.uuid(), backBuffer));

		if (resources.renderTarget == null)
			resources.renderTarget = new D3d11RenderTargetView();

		ThrowIfFailed(resources.device.createRenderTargetView(backBuffer, null, resources.renderTarget));

		var depthTextureDescription = new D3d11Texture2DDescription();
		depthTextureDescription.width = this.width;
		depthTextureDescription.height = this.height;
		depthTextureDescription.mipLevels = 1;
		depthTextureDescription.arraySize = 1;
		depthTextureDescription.format = depthbufferFormat;
		depthTextureDescription.sampleDesc.count = 1;
		depthTextureDescription.sampleDesc.quality = 0;
		depthTextureDescription.usage = D3d11Usage.Default;
		depthTextureDescription.bindFlags = D3d11BindFlag.DepthStencil;
		depthTextureDescription.cpuAccessFlags = 0;
		depthTextureDescription.miscFlags = 0;

		var dummyStencil:D3d11Texture2D = new D3d11Texture2D();
		ThrowIfFailed(resources.device.createTexture2D(depthTextureDescription, null, dummyStencil));

		if (resources.depthStencil == null)
			resources.depthStencil = new D3d11DepthStencilView();

		var depthStencilViewDescription = new D3d11DepthStencilViewDescription();
		depthStencilViewDescription.format = depthbufferFormat;
		depthStencilViewDescription.viewDimension = Texture2D;
		depthStencilViewDescription.texture2D.mipSlice = 0;

		ThrowIfFailed(resources.device.createDepthStencilView(dummyStencil, depthStencilViewDescription, resources.depthStencil));

		// viewport
		final viewport:D3d11Viewport = new D3d11Viewport();
		viewport.topLeftX = 0;
		viewport.topLeftY = 0;
		viewport.width = this.width;
		viewport.height = this.height;
		// viewport.minDepth = 0;
		// viewport.maxDepth = 1;

		var bufferDesc = new D3d11BufferDescription();
		bufferDesc.byteWidth = 128;
		bufferDesc.usage = Dynamic;
		bufferDesc.bindFlags = D3d11BindFlag.VertexBuffer;
		bufferDesc.cpuAccessFlags = D3d11CpuAccessFlag.Write;

		var initialBytes = new D3d11SubResourceData();
		initialBytes.systemMemory = Bytes.alloc(128).getData();
		initialBytes.systemMemoryPitch = 32;

		var buffer:D3d11Buffer = new D3d11Buffer();

		ThrowIfFailed(resources.device.createBuffer(bufferDesc, initialBytes, buffer));

		var mappedBuffer = new D3d11MappedSubResource();
		ThrowIfFailed(resources.context.map(buffer, 0, WriteDiscard, 0, mappedBuffer));
		(mappedBuffer.data.reinterpret() : Pointer<Int>)[0] = 7;
		resources.context.unmap(buffer, 0);

		resources.context.iaSetVertexBuffers(0, [buffer], [0], [0]);

		resources.context.rsSetViewports([viewport]);

		trace("Created resources correctly.");
		areResourcesAllocated = true;
	}

	private function onDeviceLost(?posInfos:haxe.PosInfos):Void
	{
		isActive = false;
		isDeviceCreated = false;
		areResourcesAllocated = false;

		trace('Device has been lost report from class: ${posInfos.className}\n Function this was called from: ${posInfos.methodName}\nLine number: ${posInfos.lineNumber}. Gonna try recreating the device and context.');

		resources.depthStencil.ptr.release();
		resources.depthStencil = null;
		resources.context.ptr.release();
		resources.context = null;
		resources.device.ptr.release();
		resources.device = null;
		resources.renderTarget.ptr.release();
		resources.renderTarget = null;
		resources.swapChain.ptr.release();
		resources.swapChain = null;
		trace("Successfully removed dirty/old device, context and etc.");

		resources = null;
		resources = {
			depthStencil: null,
			renderTarget: null,
			swapChain: null,
			device: new D3d11Device1(),
			context: new D3d11DeviceContext1()
		};

		CreateDevice();

		CreateResources();
		trace('Successfully restored device.');
		isActive = true;
		isDeviceCreated = true;
		areResourcesAllocated = true;
	}

	private function Present():Void
	{
		(!isActive || !isDeviceCreated || !areResourcesAllocated) ?return:null;
		final hr:HRESULT = resources.swapChain.present(DxgiSwapEffect.Discard, 0);
		(hr == DxgiError.DeviceRemoved || hr == DxgiError.DeviceReset) ? onDeviceLost() : ThrowIfFailed(hr);
	}

	private function Clear():Void
	{
		(!isActive || !isDeviceCreated || !areResourcesAllocated) ?return:null;
		resources.context.clearRenderTargetView(resources.renderTarget, [0.7, 0.2, 0.6, 1.0]);
		resources.context.clearDepthStencilView(resources.depthStencil, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1.0, 0);
		resources.context.omSetRenderTargets([resources.renderTarget], resources.depthStencil);
	}

	private function Render():Void
	{
		(!isActive || !isDeviceCreated || !areResourcesAllocated) ?return:null;
			// i hope this doesnt render anything before the first update, it shouldn't because of how flixel is programmed i'd have to assume
		Clear();
		// add rendering code here
		Present();
	}

	private function Update(elapsed:Float)
	{
		(!isActive || !isDeviceCreated || !areResourcesAllocated) ?return:null;
	}

	public function Reset()
	{
		// to remove any dirty images from the screen wink wink
		this.Clear();

		// to pause
		this.isActive = false;
		this.areResourcesAllocated = false;
		this.isDeviceCreated = false;
		this.width = 0;
		this.height = 0;

		if (resources.depthStencil != null)
			resources.depthStencil.ptr.release();

		resources.depthStencil = null;
		resources.context.ptr.release();
		resources.context = null;
		resources.device.ptr.release();
		resources.device = null;
		if (resources.renderTarget != null)
			resources.renderTarget.ptr.release();

		resources.renderTarget = null;

		if (resources.swapChain != null)
			resources.swapChain.ptr.release();

		resources.swapChain = null;

		this.resources = null;

		// set finalizer
		cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalize));
	}

	private static function finalize(obj:D3DGame)
	{
		cpp.Pointer.addressOf(obj).destroy();
	}
}
#end
