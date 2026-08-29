#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <substrate.h>
#include <iostream>
#include <vector>
#include <string>
#include <thread>
#include <chrono>

// ImGui headers inclusion
#include "imgui.h"
#include "imgui_impl_metal.h"

// ==========================================
// GLOBAL STATE & CONFIGURATIONS
// ==========================================
namespace CheatState {
    bool isMenuVisible = true;

    // Visuals (ESP)
    bool espBox = false;
    bool espLine = false;
    bool espDistance = false;
    bool espHealth = false;
    float espBoxColor[4] = { 1.0f, 0.0f, 0.0f, 1.0f };

    // Combat (Aimbot)
    bool aimbot = false;
    bool aimbotFovCircle = true;
    float aimbotFovSize = 120.0f;
    float aimbotSmoothness = 4.0f;
    int aimbotTargetBone = 0; // 0: Head, 1: Chest

    // Anti-Cheat & Security Bypasses
    bool antiCheatBypass = true;
    bool memoryProtectionBypass = true;
    bool speedHackCheckBypass = true;

    // Misc & Account Manager
    bool rainbowMenu = false;
}

// Hooking declarations or variables can go here
static bool g_Initialized = false;

// Draw ImGui Menu UI
void DrawMenu() {
    if (!CheatState::isMenuVisible) return;

    ImGui::Begin("VietAnh Mod Menu v1.0", &CheatState::isMenuVisible, ImGuiWindowFlags_NoCollapse);
    
    if (ImGui::CollapsingHeader("Visuals (ESP)")) {
        ImGui::Checkbox("ESP Box", &CheatState::espBox);
        ImGui::Checkbox("ESP Line", &CheatState::espLine);
        ImGui::Checkbox("ESP Distance", &CheatState::espDistance);
        ImGui::Checkbox("ESP Health", &CheatState::espHealth);
        ImGui::ColorEdit4("Box Color", CheatState::espBoxColor);
    }

    if (ImGui::CollapsingHeader("Combat (Aimbot)")) {
        ImGui::Checkbox("Enable Aimbot", &CheatState::aimbot);
        ImGui::Checkbox("Draw FOV Circle", &CheatState::aimbotFovCircle);
        ImGui::SliderFloat("FOV Size", &CheatState::aimbotFovSize, 10.0f, 300.0f);
        ImGui::SliderFloat("Smoothness", &CheatState::aimbotSmoothness, 1.0f, 20.0f);
        ImGui::Combo("Target Bone", &CheatState::aimbotTargetBone, "Head\0Chest\0");
    }

    if (ImGui::CollapsingHeader("Bypasses & Misc")) {
        ImGui::Checkbox("Anti-Cheat Bypass", &CheatState::antiCheatBypass);
        ImGui::Checkbox("Memory Protection", &CheatState::memoryProtectionBypass);
        ImGui::Checkbox("SpeedHack Check Bypass", &CheatState::speedHackCheckBypass);
        ImGui::Checkbox("Rainbow Menu Theme", &CheatState::rainbowMenu);
    }

    ImGui::End();
}

// Hooking into MTKView draw method to render ImGui
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
            ImGui_ImplMetal_Init(device);
            g_Initialized = true;
        }
    }

    if (g_Initialized) {
        MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        id<MTLDrawable> drawable = view.currentDrawable;

        if (renderPassDescriptor && drawable) {
            id<MTLCommandQueue> commandQueue = [view.device newCommandQueue];
            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();

            DrawMenu();

            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderPassDescriptor);

            [commandBuffer presentDrawable:drawable];
            [commandBuffer commit];
        }
    }
}

// Constructor initializer to hook MTKView
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
