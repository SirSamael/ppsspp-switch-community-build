#include "ppsspp_config.h"
#include "Core/Config.h"
#include "Core/ConfigValues.h"
#include "Common/System/System.h"
#include "Common/System/NativeApp.h"
#include "Common/System/Display.h"
#include "Common/GPU/thin3d.h"
#include "Common/GPU/thin3d_create.h"
#include "Common/GPU/Vulkan/VulkanRenderManager.h"
#include "Common/Data/Text/Parsers.h"
#include "GPU/Vulkan/VulkanUtil.h"

#include "Core/System.h"
#if PPSSPP_PLATFORM(MAC)
#include "SDL2/SDL_vulkan.h"
#else
#include "SDL_vulkan.h"
#endif
#include "SDLVulkanGraphicsContext.h"
#if PPSSPP_PLATFORM(SWITCH) && defined(SWITCH_USE_NXVK)
#include <switch.h>
#endif

#if defined(VK_USE_PLATFORM_METAL_EXT)
#include "SDLCocoaMetalLayer.h"
#endif

#ifdef _DEBUG
static const bool g_Validate = true;
#else
static const bool g_Validate = false;
#endif

bool SDLVulkanGraphicsContext::Init(SDL_Window *&window, int x, int y, int w, int h, int mode, std::string *error_message) {
#if PPSSPP_PLATFORM(SWITCH) && defined(SWITCH_USE_NXVK)
	window = SDL_CreateWindow("PPSSPP", x, y, w, h, mode & ~SDL_WINDOW_VULKAN);
	if (!window) {
		*error_message = std::string("Error creating SDL window: ") + SDL_GetError();
		return false;
	}
#else
	window = SDL_CreateWindow("Initializing Vulkan...", x, y, w, h, mode);
	if (!window) {
		fprintf(stderr, "Error creating SDL window: %s\n", SDL_GetError());
		exit(1);
	}
#endif

	init_glslang();
	glslangInitialized_ = true;

	g_LogOptions.breakOnError = true;
	g_LogOptions.breakOnWarning = true;
	g_LogOptions.msgBoxOnError = false;

	Version gitVer(PPSSPP_GIT_VERSION);

	std::string errorStr;
	if (!VulkanLoad(&errorStr)) {
		*error_message = "Failed to load Vulkan driver library: ";
		(*error_message) += errorStr;
		DestroyVulkan();
		return false;
	}

	vulkan_ = new VulkanContext();

	VulkanContext::CreateInfo info{};
	InitVulkanCreateInfoFromConfig(&info);
	if (VK_SUCCESS != vulkan_->CreateInstance(info)) {
		*error_message = vulkan_->InitError();
		DestroyVulkan();
		return false;
	}

	int deviceNum = vulkan_->GetPhysicalDeviceByName(g_Config.sVulkanDevice);
	if (deviceNum < 0) {
		deviceNum = vulkan_->GetBestPhysicalDevice();
		if (!g_Config.sVulkanDevice.empty())
			g_Config.sVulkanDevice = vulkan_->GetPhysicalDeviceProperties(deviceNum).properties.deviceName;
	}

	if (vulkan_->CreateDevice(deviceNum) != VK_SUCCESS) {
		*error_message = vulkan_->InitError();
		DestroyVulkan();
		return false;
	}

	#if PPSSPP_PLATFORM(SWITCH) && defined(SWITCH_USE_NXVK)
	NWindow *nativeWindow = nwindowGetDefault();
	vulkan_->SetCbGetDrawSize([nativeWindow]() {
		u32 width = 1, height = 1;
		nwindowGetDimensions(nativeWindow, &width, &height);
		return VkExtent2D{ width, height };
	});
	if (vulkan_->InitSurface(WINDOWSYSTEM_NN_VI, nativeWindow, nullptr) != VK_SUCCESS) {
		*error_message = "Unable to create the NXVK VI presentation surface.";
		DestroyVulkan();
		return false;
	}
	#else
	vulkan_->SetCbGetDrawSize([window]() {
		int w=1,h=1;
		SDL_Vulkan_GetDrawableSize(window, &w, &h);
		return VkExtent2D {(uint32_t)w, (uint32_t)h};
	});

	SDL_SysWMinfo sys_info{};
	SDL_VERSION(&sys_info.version); //Set SDL version
	if (!SDL_GetWindowWMInfo(window, &sys_info)) {
		fprintf(stderr, "Error getting SDL window wm info: %s\n", SDL_GetError());
		exit(1);
	}
	switch (sys_info.subsystem) {
	case SDL_SYSWM_X11:
#if defined(VK_USE_PLATFORM_XLIB_KHR)
		vulkan_->InitSurface(WINDOWSYSTEM_XLIB, (void*)sys_info.info.x11.display,
				(void *)(intptr_t)sys_info.info.x11.window);
#elif defined(VK_USE_PLATFORM_XCB_KHR)
		vulkan_->InitSurface(WINDOWSYSTEM_XCB, (void*)XGetXCBConnection(sys_info.info.x11.display),
				(void *)(intptr_t)sys_info.info.x11.window);
#endif
		break;
#if defined(VK_USE_PLATFORM_WAYLAND_KHR)
	case SDL_SYSWM_WAYLAND:
		vulkan_->InitSurface(WINDOWSYSTEM_WAYLAND, (void*)sys_info.info.wl.display, (void *)sys_info.info.wl.surface);
		break;
#endif
#if defined(VK_USE_PLATFORM_METAL_EXT)
#if PPSSPP_PLATFORM(MAC)
	case SDL_SYSWM_COCOA:
		vulkan_->InitSurface(WINDOWSYSTEM_METAL_EXT, makeWindowMetalCompatible(sys_info.info.cocoa.window), nullptr);
		break;
#else
	case SDL_SYSWM_UIKIT:
		vulkan_->InitSurface(WINDOWSYSTEM_METAL_EXT, makeWindowMetalCompatible(sys_info.info.uikit.window), nullptr);
		break;
#endif
#endif
#if defined(VK_USE_PLATFORM_DISPLAY_KHR)
	case SDL_SYSWM_KMSDRM:
		/*
		There is no problem passing null for the next two arguments, and reinit will be called later
		huangzihan china
		*/
		vulkan_->InitSurface(WINDOWSYSTEM_DISPLAY, nullptr, nullptr);
		break;
#endif
	default:
		fprintf(stderr, "Vulkan subsystem %d not supported\n", sys_info.subsystem);
		exit(1);
		break;
	}
	#endif

	bool useMultiThreading = g_Config.bRenderMultiThreading;
	if (g_Config.iInflightFrames == 1) {
		useMultiThreading = false;
	}
	draw_ = Draw::T3DCreateVulkanContext(vulkan_, useMultiThreading);
	if (!draw_) {
		*error_message = "Unable to create the Vulkan drawing context.";
		DestroyVulkan();
		return false;
	}

	VkPresentModeKHR presentMode = ConfigPresentModeToVulkan(draw_);
	if (!vulkan_->InitSwapchain(presentMode)) {
		*error_message = vulkan_->InitError();
		if (error_message->empty())
			*error_message = "Unable to create the Vulkan swapchain.";
		DestroyVulkan();
		return false;
	}

	SetGPUBackend(GPUBackend::VULKAN);
	bool success = draw_->CreatePresets();
	if (!success) {
		*error_message = "Unable to create Vulkan rendering presets.";
		DestroyVulkan();
		return false;
	}
	draw_->HandleEvent(Draw::Event::GOT_BACKBUFFER, vulkan_->GetBackbufferWidth(), vulkan_->GetBackbufferHeight());

	renderManager_ = (VulkanRenderManager *)draw_->GetNativeObject(Draw::NativeObject::RENDER_MANAGER);
	if (!renderManager_) {
		*error_message = "Unable to create the Vulkan render manager.";
		DestroyVulkan();
		return false;
	}
	renderManager_->SetInflightFrames(g_Config.iInflightFrames);
	return true;
}

void SDLVulkanGraphicsContext::Shutdown() {
	DestroyVulkan();
}

void SDLVulkanGraphicsContext::DestroyVulkan() {
	if (draw_ && vulkan_ && vulkan_->GetDevice())
		draw_->HandleEvent(Draw::Event::LOST_BACKBUFFER, vulkan_->GetBackbufferWidth(), vulkan_->GetBackbufferHeight());
	delete draw_;
	draw_ = nullptr;
	renderManager_ = nullptr;

	if (vulkan_) {
		if (vulkan_->GetDevice()) {
			vulkan_->WaitUntilQueueIdle();
			vulkan_->DestroySwapchain();
			vulkan_->DestroySurface();
			vulkan_->DestroyDevice();
		} else {
			vulkan_->DestroySurface();
		}
		if (vulkan_->GetInstance())
			vulkan_->DestroyInstance();
		delete vulkan_;
		vulkan_ = nullptr;
	}
	if (glslangInitialized_) {
		finalize_glslang();
		glslangInitialized_ = false;
	}
}

void SDLVulkanGraphicsContext::Resize() {
	draw_->HandleEvent(Draw::Event::LOST_BACKBUFFER, vulkan_->GetBackbufferWidth(), vulkan_->GetBackbufferHeight());
	// NOTE: Removing DestroySwapchain here causes a double re-create on MacOS with MoltenVK, for some reason.
	// It's like passing on oldSwapchain doesn't really work as expected.
	vulkan_->DestroySwapchain();
	VkPresentModeKHR presentMode = ConfigPresentModeToVulkan(draw_);
	if (!vulkan_->InitSwapchain(presentMode)) {
		ERROR_LOG(Log::G3D, "Unable to recreate Vulkan swapchain: %s", vulkan_->InitError().c_str());
		return;
	}
	draw_->HandleEvent(Draw::Event::GOT_BACKBUFFER, vulkan_->GetBackbufferWidth(), vulkan_->GetBackbufferHeight());
}

void SDLVulkanGraphicsContext::Poll() {
	// Check for existing swapchain to avoid issues during shutdown.
	if (vulkan_->GetSwapchain() && renderManager_->NeedsSwapchainRecreate()) {
		Resize();
	}
}
