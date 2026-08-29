#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <substrate.h>

#include "imgui.h"

namespace CheatState {
    bool isMenuVisible = true;
    bool espBox = false;
    bool aimbot = false;
    float boxColor[4] = { 1.0f, 0.0f, 0.0f, 1.0f };
}

static bool g_Initialized = false;

void DrawMenu() {
    if (!CheatState::isMenuVisible) return;

    ImGui::Begin("VietAnh Mod Menu", &CheatState::isMenuVisible, ImGuiWindowFlags_NoCollapse);
    ImGui::Checkbox("ESP Box", &CheatState::espBox);
    ImGui::Checkbox("Aimbot", &CheatState::aimbot);
    ImGui::ColorEdit4("Box Color", CheatState::boxColor);
    ImGui::End();
}

static void (*orig_mtkView_draw)(id self, SEL _cmd);
static void hk_mtkView_draw(id self, SEL _cmd) {
    orig_mtkView_draw(self, _cmd);

    MTKView *view = (__bridge MTKView *)self;
    if (!view) return;

    if (!g_Initialized) {
        id<MTLDevice> device = view.device;
        if (device) {
            IMGUI_CHECKVERSION();
            ImGui::CreateContext();
            ImGuiIO& io = ImGui::GetIO(); (void)io;
            ImGui::StyleColorsDark();
            g_Initialized = true;
        }
    }

    if (g_Initialized) {
        MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        id<MTLDrawable> drawable = view.currentDrawable;

        if (renderPassDescriptor && drawable) {
            ImGuiIO& io = ImGui::GetIO();
            io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);

            ImGui::NewFrame();
            DrawMenu();
            ImGui::Render();
        }
    }
}

__attribute__((constructor)) static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class mtkViewClass = objc_getClass("MTKView");
        if (mtkViewClass) {
            Method mtkDrawMethod = class_getInstanceMethod(mtkViewClass, @selector(draw));
            if (mtkDrawMethod) {
                method_exchangeImplementations(mtkDrawMethod, (Method)hk_mtkView_draw);
            }
        }
    });
}
