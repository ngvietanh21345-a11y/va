#include <mach/mach.h>
#include <dlfcn.h>
#include <pthread.h>
#include <CoreGraphics/CoreGraphics.h>
#include <UIKit/UIKit.h>
#include <string>
#include <vector>

#define EXPORT __attribute__((visibility("default")))

struct CheatConfig {
    bool aimbotEnabled = false;
    bool aimFovCircle = true;
    bool espBox = false;
    bool espLine = false;
    bool espDistance = false;
    bool banResetBypass = false;
    float aimFovSize = 100.0f;
    float aimSmooth = 5.0f;
    int targetBone = 1;
};

static CheatConfig g_config;
static UIWindow *g_menuWindow = nil;
static UIView *g_overlayView = nil;

namespace AntiCheatBypass {
    void initHooks() {
        void *libSystem = dlopen("/usr/lib/libSystem.B.dylib", RTLD_NOW);
        if (libSystem) {
            dlclose(libSystem);
        }
    }
}

namespace AccountManager {
    void resetGuestAndBanData() {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSArray *keychainClasses = @[
            (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecClassInternetPassword,
            (__bridge id)kSecClassCertificate,
            (__bridge id)kSecClassKey,
            (__bridge id)kSecClassIdentity
        ];
        
        for (id kcClass in keychainClasses) {
            NSDictionary *spec = @{ (__bridge id)kSecClass: kcClass };
            SecItemDelete((__bridge CFDictionaryRef)spec);
        }
        
        NSString *tmpDir = NSTemporaryDirectory();
        NSError *error = nil;
        NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:tmpDir error:&error];
        for (NSString *file in tmpFiles) {
            [fileManager removeItemAtPath:[tmpDir stringByAppendingPathComponent:file] error:nil];
        }
    }
}

@interface ESPOverlayView : UIView
@end

@implementation ESPOverlayView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    if (g_config.aimbotEnabled && g_config.aimFovCircle) {
        CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
        CGContextSetRGBStrokeColor(context, 1.0f, 0.0f, 0.0f, 0.8f);
        CGContextSetLineWidth(context, 1.5f);
        CGRect fovRect = CGRectMake(center.x - g_config.aimFovSize, center.y - g_config.aimFovSize, g_config.aimFovSize * 2, g_config.aimFovSize * 2);
        CGContextStrokeEllipseInRect(context, fovRect);
    }
}
@end

@interface CheatMenuController : UIViewController
@property (nonatomic, strong) UIView *mainPanel;
@end

@implementation CheatMenuController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.mainPanel = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 320, 420)];
    self.mainPanel.backgroundColor = [UIColor colorWithWhite:0.1f alpha:0.85f];
    self.mainPanel.layer.cornerRadius = 12.0f;
    self.mainPanel.layer.borderWidth = 1.0f;
    self.mainPanel.layer.borderColor = [UIColor cyanColor].CGColor;
    [self.view addSubview:self.mainPanel];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 30)];
    titleLabel.text = @"ONYX v67 — EXCLUSIVE MOD MENU";
    titleLabel.textColor = [UIColor cyanColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.mainPanel addSubview:titleLabel];
    
    CGFloat yOffset = 50;
    
    UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, yOffset, 0, 0)];
    [aimSwitch setOn:g_config.aimbotEnabled];
    [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
    [self.mainPanel addSubview:aimSwitch];
    
    UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, yOffset, 220, 30)];
    aimLabel.text = @"Aimbot Integration";
    aimLabel.textColor = [UIColor whiteColor];
    aimLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.mainPanel addSubview:aimLabel];
    yOffset += 45;
    
    UISwitch *fovSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, yOffset, 0, 0)];
    [fovSwitch setOn:g_config.aimFovCircle];
    [fovSwitch addTarget:self action:@selector(toggleFov:) forControlEvents:UIControlEventValueChanged];
    [self.mainPanel addSubview:fovSwitch];
    
    UILabel *fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, yOffset, 220, 30)];
    fovLabel.text = @"ESP FOV Circle";
    fovLabel.textColor = [UIColor whiteColor];
    fovLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.mainPanel addSubview:fovLabel];
    yOffset += 45;
    
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(20, yOffset, 280, 35);
    [resetBtn setTitle:@"RESET GUEST / BAN DATA" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    resetBtn.layer.cornerRadius = 6.0f;
    [resetBtn addTarget:self action:@selector(handleResetAccount:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainPanel addSubview:resetBtn];
}

- (void)toggleAimbot:(UISwitch *)sender {
    g_config.aimbotEnabled = sender.isOn;
}

- (void)toggleFov:(UISwitch *)sender {
    g_config.aimFovCircle = sender.isOn;
    [g_overlayView setNeedsDisplay];
}

- (void)handleResetAccount:(UIButton *)sender {
    AccountManager::resetGuestAndBanData();
    exit(0);
}
@end

@interface CheatWindow : UIWindow
@end

@implementation CheatWindow
- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    NSSet *touches = [event allTouches];
    if (touches.count >= 3) {
        for (UITouch *touch in touches) {
            if (touch.phase == UITouchPhaseBegan) {
                if (g_menuWindow) {
                    g_menuWindow.hidden = !g_menuWindow.isHidden;
                }
                break;
            }
        }
    }
}
@end

__attribute__((constructor)) void initializeCheat() {
    AntiCheatBypass::initHooks();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [[UIApplication sharedApplication] windows].firstObject;
        }
        
        g_overlayView = [[ESPOverlayView alloc] initWithFrame:keyWindow.bounds];
        [keyWindow addSubview:g_overlayView];
        
        CheatWindow *menuWin = [[CheatWindow alloc] initWithFrame:keyWindow.bounds];
        menuWin.windowLevel = UIWindowLevelAlert + 1;
        menuWin.rootViewController = [[CheatMenuController alloc] init];
        menuWin.hidden = YES;
        g_menuWindow = menuWin;
    });
}
