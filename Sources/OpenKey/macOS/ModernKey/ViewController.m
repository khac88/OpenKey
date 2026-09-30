//
//  ViewController.m
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "ViewController.h"
#import "OpenKeyManager.h"
#import "AppDelegate.h"
#import "MyTextField.h"
#import <ApplicationServices/ApplicationServices.h>

extern AppDelegate* appDelegate;
extern void OnSpellCheckingChanged(void);

ViewController* viewController;
extern int vFreeMark;
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vSwitchKeyStatus;
extern int vQuickTelex;
extern int vRestoreIfWrongSpelling;
extern int vFixRecommendBrowser;
extern int vUseMacro;
extern int vUseMacroInEnglishMode;
extern int vSendKeyStepByStep;
extern int vUseSmartSwitchKey;
extern int vUpperCaseFirstChar;
extern int vTempOffSpelling;
extern int vAllowConsonantZFWJ;
extern int vQuickStartConsonant;
extern int vQuickEndConsonant;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vTempOffOpenKey;
extern int vAutoRestoreEnglish;
extern int vIgnoreStandaloneW;
extern int vShowIconOnDock;
extern int vAutoCapsMacro;
extern int vFixChromiumBrowser;
extern int vPerformLayoutCompat;

static const CGFloat kPanelWidth = 780;
static const CGFloat kPanelHeight = 640;
static const CGFloat kSidebarWidth = 200;
static const CGFloat kFooterHeight = 60;
static const CGFloat kSidebarInset = 8;
static const CGFloat kSidebarCornerRadius = 20;

// Flipped container so that a page starts at the top of its scroll view.
@interface OKFlippedView : NSView
@end

@implementation OKFlippedView
- (BOOL)isFlipped {
    return YES;
}
@end

@implementation ViewController {
    __weak NSButton *CustomSwitchCommand;
    __weak NSButton *CustomSwitchOption;
    __weak NSButton *CustomSwitchControl;
    __weak NSButton *CustomSwitchShift;
    __weak MyTextField *CustomSwitchKey;
    __weak NSSwitch *CustomBeepSound;
    NSArray<NSView*>* pages;
    NSArray<NSView*>* navItems;
    NSArray<NSButton*>* navButtons;
    NSScrollView* pageScrollView;
    NSView* footerView;
    NSView* statusDot;
    NSTextField* statusLabel;
}

#pragma mark - Building the panel

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kPanelWidth, kPanelHeight)];
    [self buildFooter];
    [self buildSidebar];
    [self buildPages];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    viewController = self;
    
    NSArray* inputTypeData = @[@"Telex", @"VNI", @"Simple Telex 1", @"Simple Telex 2"];
    [self.popupInputType removeAllItems];
    [self.popupInputType addItemsWithTitles:inputTypeData];
    
    [self.popupCode removeAllItems];
    [self.popupCode addItemsWithTitles:[OpenKeyManager getTableCodes]];
    
    [self showPage:0];
    [self initKey];
    [self fillData];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    NSWindow* window = self.view.window;
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = YES;
    window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    [self initKey];
    [self updateStatus];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    NSString* str = @"OpenKey %@ - Bộ gõ Tiếng Việt";
    self.view.window.title = [NSString stringWithFormat:str, [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
}

-(void)initKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        [OpenKeyManager initEventTap];
    });
}

-(void)updateStatus {
    BOOL trusted = AXIsProcessTrusted();
    statusDot.layer.backgroundColor = (trusted ? [NSColor systemGreenColor] : [NSColor systemOrangeColor]).CGColor;
    statusLabel.stringValue = trusted ? @"Đang hoạt động" : @"Chưa được cấp quyền Trợ năng";
}

-(NSTextField*)labelWithString:(NSString*)string size:(CGFloat)size weight:(NSFontWeight)weight secondary:(BOOL)secondary {
    NSTextField* label = [NSTextField labelWithString:string];
    label.font = [NSFont systemFontOfSize:size weight:weight];
    if (secondary)
        label.textColor = [NSColor secondaryLabelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

-(NSBox*)separator {
    NSBox* line = [[NSBox alloc] init];
    line.boxType = NSBoxSeparator;
    line.translatesAutoresizingMaskIntoConstraints = NO;
    return line;
}

-(void)buildFooter {
    NSView* root = self.view;
    NSView* footer = [[NSView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:footer];
    footerView = footer;
    
    NSBox* line = [self separator];
    [footer addSubview:line];
    
    NSTextField* credit = [self labelWithString:@"OpenKey – dựa trên mã nguồn của Mai Vũ Tuyên © 2019" size:11 weight:NSFontWeightRegular secondary:YES];
    
    NSFont* footerFont = [NSFont systemFontOfSize:11];
    NSMutableAttributedString* license = [[NSMutableAttributedString alloc] initWithString:@"Phát hành theo giấy phép GPL-3.0 · Mã nguồn: "
                                                                                attributes:@{NSFontAttributeName: footerFont,
                                                                                             NSForegroundColorAttributeName: [NSColor secondaryLabelColor]}];
    [license appendAttributedString:[[NSAttributedString alloc] initWithString:@"github.com/khac88/openkey"
                                                                    attributes:@{NSFontAttributeName: footerFont,
                                                                                 NSLinkAttributeName: [NSURL URLWithString:@"https://github.com/khac88/openkey"]}]];
    NSTextField* licenseLabel = [NSTextField labelWithAttributedString:license];
    licenseLabel.selectable = YES;
    licenseLabel.allowsEditingTextAttributes = YES;
    
    NSStackView* texts = [NSStackView stackViewWithViews:@[credit, licenseLabel]];
    texts.orientation = NSUserInterfaceLayoutOrientationVertical;
    texts.alignment = NSLayoutAttributeLeading;
    texts.spacing = 3;
    texts.translatesAutoresizingMaskIntoConstraints = NO;
    [footer addSubview:texts];
    
    NSButton* defaultButton = [NSButton buttonWithTitle:@"Khôi phục mặc định" target:self action:@selector(onDefaultConfig:)];
    NSButton* quitButton = [NSButton buttonWithTitle:@"Thoát OpenKey" target:self action:@selector(onTerminateApp:)];
    NSStackView* buttons = [NSStackView stackViewWithViews:@[defaultButton, quitButton]];
    buttons.spacing = 8;
    buttons.translatesAutoresizingMaskIntoConstraints = NO;
    [footer addSubview:buttons];
    
    [NSLayoutConstraint activateConstraints:@[
        [footer.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [footer.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [footer.heightAnchor constraintEqualToConstant:kFooterHeight],
        [line.topAnchor constraintEqualToAnchor:footer.topAnchor],
        [line.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor],
        [texts.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:20],
        [texts.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [buttons.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-20],
        [buttons.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [buttons.leadingAnchor constraintGreaterThanOrEqualToAnchor:texts.trailingAnchor constant:16],
    ]];
}

-(void)buildSidebar {
    NSView* root = self.view;
    //floating Liquid Glass sidebar, its items live in the glass content view
    NSGlassEffectView* glass = [[NSGlassEffectView alloc] init];
    glass.cornerRadius = kSidebarCornerRadius;
    glass.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:glass];
    NSView* sidebar = [[NSView alloc] init];
    glass.contentView = sidebar;
    
    //app title
    NSImageView* icon = [NSImageView imageViewWithImage:[NSApp applicationIconImage]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    NSTextField* name = [self labelWithString:@"OpenKey" size:15 weight:NSFontWeightSemibold secondary:NO];
    NSTextField* subtitle = [self labelWithString:@"Bộ gõ Tiếng Việt" size:11 weight:NSFontWeightRegular secondary:YES];
    NSStackView* titleTexts = [NSStackView stackViewWithViews:@[name, subtitle]];
    titleTexts.orientation = NSUserInterfaceLayoutOrientationVertical;
    titleTexts.alignment = NSLayoutAttributeLeading;
    titleTexts.spacing = 1;
    NSStackView* header = [NSStackView stackViewWithViews:@[icon, titleTexts]];
    header.spacing = 10;
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [sidebar addSubview:header];
    
    //navigation
    NSArray* navData = @[@[@"Bộ gõ", @"keyboard"], @[@"Gõ tắt", @"bolt"], @[@"Hệ thống", @"gearshape"]];
    NSMutableArray* items = [NSMutableArray array];
    NSMutableArray* buttons = [NSMutableArray array];
    NSStackView* nav = [[NSStackView alloc] init];
    nav.orientation = NSUserInterfaceLayoutOrientationVertical;
    nav.alignment = NSLayoutAttributeLeading;
    nav.spacing = 2;
    nav.translatesAutoresizingMaskIntoConstraints = NO;
    [sidebar addSubview:nav];
    for (NSInteger i = 0; i < navData.count; i++) {
        NSImage* image = [NSImage imageWithSystemSymbolName:navData[i][1] accessibilityDescription:nil];
        NSButton* button = [NSButton buttonWithTitle:navData[i][0] image:image target:self action:@selector(onNavButton:)];
        button.bordered = NO;
        button.imagePosition = NSImageLeading;
        button.imageHugsTitle = YES;
        button.alignment = NSTextAlignmentLeft;
        button.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
        button.tag = i;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSView* item = [[NSView alloc] init];
        item.wantsLayer = YES;
        item.layer.cornerRadius = 16;
        item.translatesAutoresizingMaskIntoConstraints = NO;
        [item addSubview:button];
        [nav addArrangedSubview:item];
        [NSLayoutConstraint activateConstraints:@[
            [item.widthAnchor constraintEqualToAnchor:nav.widthAnchor],
            [item.heightAnchor constraintEqualToConstant:32],
            [button.leadingAnchor constraintEqualToAnchor:item.leadingAnchor constant:10],
            [button.trailingAnchor constraintEqualToAnchor:item.trailingAnchor],
            [button.topAnchor constraintEqualToAnchor:item.topAnchor],
            [button.bottomAnchor constraintEqualToAnchor:item.bottomAnchor],
        ]];
        [items addObject:item];
        [buttons addObject:button];
    }
    navItems = items;
    navButtons = buttons;
    
    //accessibility permission status
    NSView* dot = [[NSView alloc] init];
    dot.wantsLayer = YES;
    dot.layer.cornerRadius = 4;
    dot.translatesAutoresizingMaskIntoConstraints = NO;
    statusDot = dot;
    statusLabel = [self labelWithString:@"" size:12 weight:NSFontWeightRegular secondary:NO];
    NSStackView* status = [NSStackView stackViewWithViews:@[dot, statusLabel]];
    status.spacing = 8;
    status.translatesAutoresizingMaskIntoConstraints = NO;
    [sidebar addSubview:status];
    
    [NSLayoutConstraint activateConstraints:@[
        [glass.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:kSidebarInset],
        [glass.topAnchor constraintEqualToAnchor:root.topAnchor constant:kSidebarInset],
        [glass.bottomAnchor constraintEqualToAnchor:footerView.topAnchor constant:-kSidebarInset],
        [glass.widthAnchor constraintEqualToConstant:kSidebarWidth - kSidebarInset],
        [icon.widthAnchor constraintEqualToConstant:36],
        [icon.heightAnchor constraintEqualToConstant:36],
        [header.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:40],
        [header.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:16],
        [header.trailingAnchor constraintLessThanOrEqualToAnchor:sidebar.trailingAnchor constant:-12],
        [nav.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:22],
        [nav.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:10],
        [nav.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-10],
        [dot.widthAnchor constraintEqualToConstant:8],
        [dot.heightAnchor constraintEqualToConstant:8],
        [status.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:18],
        [status.trailingAnchor constraintLessThanOrEqualToAnchor:sidebar.trailingAnchor constant:-12],
        [status.bottomAnchor constraintEqualToAnchor:sidebar.bottomAnchor constant:-16],
    ]];
}

-(void)buildPages {
    NSView* root = self.view;
    NSScrollView* scroll = [[NSScrollView alloc] init];
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.drawsBackground = NO;
    scroll.borderType = NSNoBorder;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:scroll];
    pageScrollView = scroll;
    
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:kSidebarWidth],
        [scroll.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:root.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:footerView.topAnchor],
    ]];
    
    pages = @[[self buildInputPage], [self buildMacroPage], [self buildSystemPage]];
}

-(void)showPage:(NSInteger)index {
    NSView* page = pages[index];
    NSClipView* clip = pageScrollView.contentView;
    pageScrollView.documentView = page;
    [NSLayoutConstraint activateConstraints:@[
        [page.leadingAnchor constraintEqualToAnchor:clip.leadingAnchor],
        [page.trailingAnchor constraintEqualToAnchor:clip.trailingAnchor],
        [page.topAnchor constraintEqualToAnchor:clip.topAnchor],
    ]];
    [clip scrollToPoint:NSZeroPoint];
    [pageScrollView reflectScrolledClipView:clip];
    
    for (NSInteger i = 0; i < navItems.count; i++) {
        BOOL selected = (i == index);
        navItems[i].layer.backgroundColor = selected ? [NSColor controlAccentColor].CGColor : [NSColor clearColor].CGColor;
        navButtons[i].contentTintColor = selected ? [NSColor whiteColor] : [NSColor labelColor];
    }
}

- (IBAction)onNavButton:(NSButton *)sender {
    [self showPage:sender.tag];
}

-(NSView*)pageWithTitle:(NSString*)title subtitle:(NSString*)subtitle sections:(NSArray<NSView*>*)sections {
    OKFlippedView* page = [[OKFlippedView alloc] init];
    page.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSTextField* heading = [self labelWithString:title size:20 weight:NSFontWeightSemibold secondary:NO];
    NSTextField* sub = [self labelWithString:subtitle size:13 weight:NSFontWeightRegular secondary:YES];
    NSStackView* stack = [NSStackView stackViewWithViews:@[heading, sub]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 20;
    [stack setCustomSpacing:4 afterView:heading];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [page addSubview:stack];
    for (NSView* section in sections) {
        [stack addArrangedSubview:section];
        [section.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:page.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:page.trailingAnchor constant:-28],
        [stack.topAnchor constraintEqualToAnchor:page.topAnchor constant:40],
        [stack.bottomAnchor constraintEqualToAnchor:page.bottomAnchor constant:-28],
    ]];
    return page;
}

-(NSView*)sectionWithTitle:(NSString*)title rows:(NSArray<NSView*>*)rows {
    NSStackView* section = [[NSStackView alloc] init];
    section.orientation = NSUserInterfaceLayoutOrientationVertical;
    section.alignment = NSLayoutAttributeLeading;
    section.spacing = 8;
    section.translatesAutoresizingMaskIntoConstraints = NO;
    if (title) {
        NSTextField* label = [self labelWithString:title size:12 weight:NSFontWeightSemibold secondary:YES];
        [section addArrangedSubview:label];
        [section setCustomSpacing:6 afterView:label];
    }
    
    NSBox* card = [[NSBox alloc] init];
    card.boxType = NSBoxCustom;
    card.titlePosition = NSNoTitle;
    card.cornerRadius = 14;
    card.borderWidth = 1;
    card.borderColor = [NSColor separatorColor];
    card.fillColor = [NSColor controlBackgroundColor];
    card.contentViewMargins = NSZeroSize;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSStackView* list = [[NSStackView alloc] init];
    list.orientation = NSUserInterfaceLayoutOrientationVertical;
    list.alignment = NSLayoutAttributeLeading;
    list.spacing = 0;
    list.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSInteger i = 0; i < rows.count; i++) {
        if (i > 0) {
            NSBox* line = [self separator];
            [list addArrangedSubview:line];
            [line.widthAnchor constraintEqualToAnchor:list.widthAnchor constant:-28].active = YES;
        }
        [list addArrangedSubview:rows[i]];
        [rows[i].widthAnchor constraintEqualToAnchor:list.widthAnchor].active = YES;
    }
    list.alignment = NSLayoutAttributeCenterX;
    [card.contentView addSubview:list];
    [section addArrangedSubview:card];
    
    [NSLayoutConstraint activateConstraints:@[
        [list.leadingAnchor constraintEqualToAnchor:card.contentView.leadingAnchor],
        [list.trailingAnchor constraintEqualToAnchor:card.contentView.trailingAnchor],
        [list.topAnchor constraintEqualToAnchor:card.contentView.topAnchor],
        [list.bottomAnchor constraintEqualToAnchor:card.contentView.bottomAnchor],
        [card.widthAnchor constraintEqualToAnchor:section.widthAnchor],
    ]];
    return section;
}

-(NSView*)rowWithTitle:(NSString*)title hint:(NSString*)hint control:(NSView*)control {
    NSView* row = [[NSView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSTextField* titleLabel = [self labelWithString:title size:13 weight:NSFontWeightRegular secondary:NO];
    NSStackView* texts = [NSStackView stackViewWithViews:@[titleLabel]];
    texts.orientation = NSUserInterfaceLayoutOrientationVertical;
    texts.alignment = NSLayoutAttributeLeading;
    texts.spacing = 2;
    texts.translatesAutoresizingMaskIntoConstraints = NO;
    if (hint) {
        NSTextField* hintLabel = [NSTextField wrappingLabelWithString:hint];
        hintLabel.font = [NSFont systemFontOfSize:11];
        hintLabel.textColor = [NSColor secondaryLabelColor];
        hintLabel.preferredMaxLayoutWidth = 340;
        [texts addArrangedSubview:hintLabel];
    }
    [row addSubview:texts];
    
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [control setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [row addSubview:control];
    
    NSLayoutConstraint* compact = [row.heightAnchor constraintEqualToConstant:44];
    compact.priority = NSLayoutPriorityDefaultLow;
    [NSLayoutConstraint activateConstraints:@[
        compact,
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:44],
        [row.heightAnchor constraintGreaterThanOrEqualToAnchor:texts.heightAnchor constant:20],
        [row.heightAnchor constraintGreaterThanOrEqualToAnchor:control.heightAnchor constant:16],
        [texts.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:14],
        [texts.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [control.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],
        [control.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [control.leadingAnchor constraintGreaterThanOrEqualToAnchor:texts.trailingAnchor constant:16],
    ]];
    return row;
}

-(NSSwitch*)switchWithAction:(SEL)action {
    NSSwitch* control = [[NSSwitch alloc] init];
    control.target = self;
    control.action = action;
    return control;
}

-(NSPopUpButton*)popupWithAction:(SEL)action {
    NSPopUpButton* popup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    popup.target = self;
    popup.action = action;
    [popup.widthAnchor constraintEqualToConstant:190].active = YES;
    return popup;
}

-(NSButton*)modifierKeyButton:(NSString*)symbol toolTip:(NSString*)toolTip action:(SEL)action {
    NSButton* button = [NSButton buttonWithTitle:symbol target:self action:action];
    [button setButtonType:NSButtonTypePushOnPushOff];
    button.bezelStyle = NSBezelStyleRounded;
    button.toolTip = toolTip;
    button.font = [NSFont systemFontOfSize:14];
    [button.widthAnchor constraintEqualToConstant:40].active = YES;
    return button;
}

-(NSView*)buildInputPage {
    NSSegmentedControl* method = [NSSegmentedControl segmentedControlWithLabels:@[@"Tiếng Việt", @"English"]
                                                                   trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                         target:self
                                                                         action:@selector(onLanguageChanged:)];
    self.inputMethodControl = method;
    NSPopUpButton* inputType = [self popupWithAction:@selector(onInputTypeChanged:)];
    self.popupInputType = inputType;
    NSPopUpButton* code = [self popupWithAction:@selector(onCodeTableChanged:)];
    self.popupCode = code;
    
    NSButton* control = [self modifierKeyButton:@"⌃" toolTip:@"Phím Control" action:@selector(onControlSwitchKey:)];
    NSButton* option = [self modifierKeyButton:@"⌥" toolTip:@"Phím Option" action:@selector(onOptionSwitchKey:)];
    NSButton* command = [self modifierKeyButton:@"⌘" toolTip:@"Phím Command" action:@selector(onCommandSwitchKey:)];
    NSButton* shift = [self modifierKeyButton:@"⇧" toolTip:@"Phím Shift" action:@selector(onShiftSwitchKey:)];
    CustomSwitchControl = control;
    CustomSwitchOption = option;
    CustomSwitchCommand = command;
    CustomSwitchShift = shift;
    NSTextField* plus = [self labelWithString:@"+" size:13 weight:NSFontWeightRegular secondary:YES];
    MyTextField* key = [[MyTextField alloc] init];
    key.alignment = NSTextAlignmentCenter;
    key.usesSingleLineMode = YES;
    key.toolTip = @"Nhập ký tự vào đây";
    key.Parent = self;
    [key.widthAnchor constraintEqualToConstant:56].active = YES;
    CustomSwitchKey = key;
    NSStackView* switchKey = [NSStackView stackViewWithViews:@[control, option, command, shift, plus, key]];
    switchKey.spacing = 6;
    
    NSSwitch* beep = [self switchWithAction:@selector(onBeepSound:)];
    CustomBeepSound = beep;
    
    NSView* general = [self sectionWithTitle:nil rows:@[
        [self rowWithTitle:@"Chế độ gõ" hint:nil control:method],
        [self rowWithTitle:@"Kiểu gõ" hint:nil control:inputType],
        [self rowWithTitle:@"Bảng mã" hint:nil control:code],
        [self rowWithTitle:@"Phím chuyển Việt / Anh" hint:@"Bấm để chọn tổ hợp phím" control:switchKey],
        [self rowWithTitle:@"Kêu beep khi chuyển chế độ" hint:@"Không áp dụng khi chuyển chế độ thông minh" control:beep],
    ]];
    
    NSSwitch* s;
    NSMutableArray* spelling = [NSMutableArray array];
    s = [self switchWithAction:@selector(onModernOrthography:)]; self.UseModernOrthography = s;
    [spelling addObject:[self rowWithTitle:@"Đặt dấu kiểu mới" hint:@"oà, uý thay vì òa, úy" control:s]];
    s = [self switchWithAction:@selector(onCheckSpelling:)]; self.CheckSpellingButton = s;
    [spelling addObject:[self rowWithTitle:@"Kiểm tra chính tả" hint:nil control:s]];
    s = [self switchWithAction:@selector(onRestoreIfInvalidWord:)]; self.RestoreIfInvalidWord = s;
    [spelling addObject:[self rowWithTitle:@"Tự khôi phục phím khi gõ sai từ" hint:nil control:s]];
    s = [self switchWithAction:@selector(onAllowZFWJ:)]; self.AllowZWJF = s;
    [spelling addObject:[self rowWithTitle:@"Cho phép “z w j f” làm phụ âm" hint:nil control:s]];
    s = [self switchWithAction:@selector(omTempOffSpellChecking:)]; self.TempOffSpellChecking = s;
    [spelling addObject:[self rowWithTitle:@"Tạm tắt chính tả bằng phím ⌃" hint:nil control:s]];
    s = [self switchWithAction:@selector(onIgnoreStandaloneW:)]; self.IgnoreStandaloneW = s;
    [spelling addObject:[self rowWithTitle:@"Bỏ qua W đầu từ" hint:@"Không tự thành Ư" control:s]];
    
    NSMutableArray* smart = [NSMutableArray array];
    s = [self switchWithAction:@selector(onAutoRememberSwitchKey:)]; self.AutoRememberSwitchKey = s;
    [smart addObject:[self rowWithTitle:@"Chuyển chế độ thông minh" hint:@"Nhớ Việt / Anh cho từng ứng dụng" control:s]];
    s = [self switchWithAction:@selector(onRememberTableCode:)]; self.RememberTableCode = s;
    [smart addObject:[self rowWithTitle:@"Tự ghi nhớ bảng mã theo ứng dụng" hint:nil control:s]];
    s = [self switchWithAction:@selector(onAutoRestoreEnglish:)]; self.AutoRestoreEnglish = s;
    [smart addObject:[self rowWithTitle:@"Tự khôi phục từ tiếng Anh bị lỗi Telex" hint:nil control:s]];
    s = [self switchWithAction:@selector(onUpperCaseFirstChar:)]; self.UpperCaseFirstChar = s;
    [smart addObject:[self rowWithTitle:@"Viết hoa chữ cái đầu câu" hint:nil control:s]];
    s = [self switchWithAction:@selector(onFixRecommendBrowser:)]; self.FixRecommendBrowser = s;
    [smart addObject:[self rowWithTitle:@"Sửa lỗi gợi ý" hint:@"Trình duyệt, Excel…" control:s]];
    s = [self switchWithAction:@selector(onTempOffOpenKeyByHotKey:)]; self.TempOffOpenKey = s;
    [smart addObject:[self rowWithTitle:@"Tạm tắt OpenKey bằng phím ⌘" hint:nil control:s]];
    s = [self switchWithAction:@selector(onOtherLanguage:)]; self.OtherLanguage = s;
    [smart addObject:[self rowWithTitle:@"Tắt tiếng Việt khi bộ gõ hệ thống không phải tiếng Anh" hint:nil control:s]];
    
    return [self pageWithTitle:@"Bộ gõ" subtitle:@"Kiểu gõ, bảng mã và cách bỏ dấu." sections:@[
        general,
        [self sectionWithTitle:@"DẤU VÀ CHÍNH TẢ" rows:spelling],
        [self sectionWithTitle:@"THÔNG MINH" rows:smart],
    ]];
}

-(NSView*)buildMacroPage {
    NSSwitch* s;
    NSMutableArray* macro = [NSMutableArray array];
    s = [self switchWithAction:@selector(onMacroChanged:)]; self.UseMacro = s;
    [macro addObject:[self rowWithTitle:@"Cho phép gõ tắt" hint:nil control:s]];
    s = [self switchWithAction:@selector(onUseMacroInEnglishModeChanged:)]; self.UseMacroInEnglishMode = s;
    [macro addObject:[self rowWithTitle:@"Gõ tắt cả khi đang tắt tiếng Việt" hint:nil control:s]];
    s = [self switchWithAction:@selector(onAutoCapsMacro:)]; self.AutoCapsMacro = s;
    [macro addObject:[self rowWithTitle:@"Tự động viết hoa theo từ gõ tắt" hint:nil control:s]];
    NSButton* table = [NSButton buttonWithTitle:@"Mở bảng gõ tắt..." target:self action:@selector(onMacroButton:)];
    [macro addObject:[self rowWithTitle:@"Bảng gõ tắt" hint:@"Thêm, sửa, nạp hoặc xuất danh sách từ gõ tắt" control:table]];
    
    NSMutableArray* quick = [NSMutableArray array];
    s = [self switchWithAction:@selector(onQuickTelex:)]; self.QuickTelex = s;
    [quick addObject:[self rowWithTitle:@"Gõ nhanh phụ âm kép" hint:@"cc→ch, gg→gi, kk→kh, nn→ng, qq→qu, pp→ph, tt→th" control:s]];
    s = [self switchWithAction:@selector(onQuickStartConsonant:)]; self.QuickStartConsonant = s;
    [quick addObject:[self rowWithTitle:@"Gõ tắt phụ âm đầu" hint:@"f→ph, j→gi, w→qu" control:s]];
    s = [self switchWithAction:@selector(onQuickEndConsonant:)]; self.QuickEndConsonant = s;
    [quick addObject:[self rowWithTitle:@"Gõ tắt phụ âm cuối" hint:@"g→ng, h→nh, k→ch" control:s]];
    
    return [self pageWithTitle:@"Gõ tắt" subtitle:@"Gõ nhanh cụm từ và phụ âm." sections:@[
        [self sectionWithTitle:@"GÕ TẮT" rows:macro],
        [self sectionWithTitle:@"GÕ NHANH" rows:quick],
    ]];
}

-(NSView*)buildSystemPage {
    NSSwitch* s;
    NSMutableArray* startup = [NSMutableArray array];
    s = [self switchWithAction:@selector(onRunOnStartup:)]; self.RunOnStartupButton = s;
    [startup addObject:[self rowWithTitle:@"Khởi động cùng macOS" hint:nil control:s]];
    s = [self switchWithAction:@selector(onShowUIOnStartup:)]; self.ShowUIButton = s;
    [startup addObject:[self rowWithTitle:@"Mở bảng này khi khởi động" hint:nil control:s]];
    s = [self switchWithAction:@selector(onGrayIcon:)]; self.UseGrayIcon = s;
    [startup addObject:[self rowWithTitle:@"Biểu tượng hiện đại trên thanh menu" hint:nil control:s]];
    s = [self switchWithAction:@selector(onShowIconOnDock:)]; self.ShowIconOnDock = s;
    [startup addObject:[self rowWithTitle:@"Hiện biểu tượng trên thanh Dock" hint:nil control:s]];
    
    NSMutableArray* compat = [NSMutableArray array];
    s = [self switchWithAction:@selector(onSendKeyStepByStep:)]; self.SendKeyStepByStep = s;
    [compat addObject:[self rowWithTitle:@"Gửi từng phím" hint:@"Chỉ bật khi gặp lỗi gõ" control:s]];
    s = [self switchWithAction:@selector(onFixChromiumBrowser:)]; self.FixChromiumBrowser = s;
    [compat addObject:[self rowWithTitle:@"Sửa lỗi trên Chromium (beta)" hint:@"Cần bật “Sửa lỗi gợi ý”" control:s]];
    s = [self switchWithAction:@selector(onPerformLayoutCompat:)]; self.PerformLayoutCompat = s;
    [compat addObject:[self rowWithTitle:@"Tương thích Telex trên bàn phím khác" hint:nil control:s]];
    s = [self switchWithAction:@selector(onForceEnglishSpotlight:)]; self.ForceEnglishSpotlight = s;
    [compat addObject:[self rowWithTitle:@"Chuyển sang tiếng Anh khi mở Spotlight" hint:nil control:s]];
    
    NSMutableArray* update = [NSMutableArray array];
    s = [self switchWithAction:@selector(onCheckNewVersionOnStartup:)]; self.CheckNewVersionOnStartup = s;
    [update addObject:[self rowWithTitle:@"Kiểm tra bản mới lúc khởi động" hint:nil control:s]];
    NSButton* check = [NSButton buttonWithTitle:@"Kiểm tra bản mới..." target:self action:@selector(onCheckNewVersionButton:)];
    self.CheckNewVersionButton = check;
    NSString* version = [NSString stringWithFormat:@"Phiên bản %@ (build %@)",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];
    NSString* buildDate = [NSString stringWithFormat:@"Ngày cập nhật %@", [OpenKeyManager getBuildDate]];
    [update addObject:[self rowWithTitle:version hint:buildDate control:check]];
    
    return [self pageWithTitle:@"Hệ thống" subtitle:@"Khởi động, biểu tượng và tương thích." sections:@[
        [self sectionWithTitle:@"KHỞI ĐỘNG VÀ HIỂN THỊ" rows:startup],
        [self sectionWithTitle:@"TƯƠNG THÍCH" rows:compat],
        [self sectionWithTitle:@"CẬP NHẬT" rows:update],
    ]];
}

#pragma mark - Actions

- (IBAction)onInputTypeChanged:(NSPopUpButton *)sender {
    [appDelegate onInputTypeSelectedIndex:(int)[self.popupInputType indexOfSelectedItem]];
}

- (IBAction)onCodeTableChanged:(NSPopUpButton *)sender {
    [appDelegate onCodeTableChanged:(int)[self.popupCode indexOfSelectedItem]];
}

- (IBAction)onLanguageChanged:(id)sender {
    NSInteger wanted = self.inputMethodControl.selectedSegment == 0 ? 1 : 0;
    if (wanted != [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"]) {
        [appDelegate onInputMethodSelected];
    }
}

- (IBAction)onFreeMark:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"FreeMark"];
    vFreeMark = (int)val;
}

- (IBAction)onModernOrthography:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"ModernOrthography"];
    vUseModernOrthography = (int)val;
}

- (IBAction)onCheckSpelling:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"Spelling"];
    vCheckSpelling = (int)val;
    [self.RestoreIfInvalidWord setEnabled:val];
    [self.AllowZWJF setEnabled:val];
    [self.TempOffSpellChecking setEnabled:val];
    OnSpellCheckingChanged();
}

- (IBAction)onShowUIOnStartup:(NSButton *)sender {
    [self setCustomValue:sender keyToSet:@"ShowUIOnStartup"];
}

- (IBAction)onRunOnStartup:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"RunOnStartup"];
    [appDelegate setRunOnStartup:val];
}

- (IBAction)onGrayIcon:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"GrayIcon"];
    [appDelegate setGrayIcon:val];
}

- (IBAction)onQuickTelex:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"QuickTelex"];
    vQuickTelex = (int)val;
}

- (IBAction)onRestoreIfInvalidWord:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"RestoreIfInvalidWord"];
    vRestoreIfWrongSpelling = (int)val;
}

- (IBAction)omTempOffSpellChecking:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vTempOffSpelling"];
    vTempOffSpelling = (int)val;
}

- (IBAction)onAllowZFWJ:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vAllowConsonantZFWJ"];
    vAllowConsonantZFWJ = (int)val;
}

- (IBAction)onFixRecommendBrowser:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"FixRecommendBrowser"];
    vFixRecommendBrowser = (int)val;
    [self.FixChromiumBrowser setEnabled:val];
}

- (IBAction)onControlSwitchKey:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x100);
    vSwitchKeyStatus |= val << 8;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onOptionSwitchKey:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x200);
    vSwitchKeyStatus |= val << 9;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onCommandSwitchKey:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x400);
    vSwitchKeyStatus |= val << 10;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onShiftSwitchKey:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x800);
    vSwitchKeyStatus |= val << 11;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

-(void)onMyTextFieldKeyChange:(unsigned short)keyCode character:(unsigned short)character {
    vSwitchKeyStatus &= 0xFFFFFF00;
    vSwitchKeyStatus |= keyCode;
    vSwitchKeyStatus &= 0x00FFFFFF;
    vSwitchKeyStatus |= ((unsigned int)character<<24);
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onBeepSound:(NSButton *)sender {
    unsigned int val = (unsigned int)[self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x8000);
    vSwitchKeyStatus |= val << 15;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onSendKeyStepByStep:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"SendKeyStepByStep"];
    vSendKeyStepByStep = (int)val;
}

- (IBAction)onPerformLayoutCompat:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vPerformLayoutCompat"];
    vPerformLayoutCompat = (int)val;
}

- (IBAction)onForceEnglishSpotlight:(id)sender {
    [self setCustomValue:sender keyToSet:@"vForceEnglishSpotlight"];
}

- (NSInteger)setCustomValue:(id)sender keyToSet:(NSString*) key {
    NSInteger val = 0;
    if ([sender state] == NSControlStateValueOn) {
        val = 1;
    } else {
        val = 0;
    }
    if (key != nil)
        [[NSUserDefaults standardUserDefaults] setInteger:val forKey:key];
    return val;
}

- (IBAction)onMacroButton:(id)sender {
    [appDelegate onMacroSelected];
}

- (IBAction)onMacroChanged:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseMacro"];
    vUseMacro = (int)val;
}

- (IBAction)onUseMacroInEnglishModeChanged:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseMacroInEnglishMode"];
    vUseMacroInEnglishMode = (int)val;
}

- (IBAction)onAutoRememberSwitchKey:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseSmartSwitchKey"];
    vUseSmartSwitchKey = (int)val;
}

- (IBAction)onUpperCaseFirstChar:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UpperCaseFirstChar"];
    vUpperCaseFirstChar = (int)val;
}
- (IBAction)onQuickStartConsonant:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vQuickStartConsonant"];
    vQuickStartConsonant = (int)val;
}

- (IBAction)onQuickEndConsonant:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vQuickEndConsonant"];
    vQuickEndConsonant = (int)val;
}

- (IBAction)onTempOffOpenKeyByHotKey:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vTempOffOpenKey"];
    vTempOffOpenKey = (int)val;
}

- (IBAction)onAutoRestoreEnglish:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vAutoRestoreEnglish"];
    vAutoRestoreEnglish = (int)val;
}

- (IBAction)onIgnoreStandaloneW:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vIgnoreStandaloneW"];
    vIgnoreStandaloneW = (int)val;
}

- (IBAction)onRememberTableCode:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vRememberCode"];
    vRememberCode = (int)val;
}
- (IBAction)onOtherLanguage:(id)sender {
    
    NSInteger val = [self setCustomValue:sender keyToSet:@"vOtherLanguage"];
    vOtherLanguage = (int)val;
}


- (IBAction)onAutoCapsMacro:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vAutoCapsMacro"];
    vAutoCapsMacro = (int)val;
}

- (IBAction)onShowIconOnDock:(id)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vShowIconOnDock"];
    vShowIconOnDock = (int)val;
    if (!vShowIconOnDock) {
        [self.view.window close];
    }
    [appDelegate showIconOnDock:vShowIconOnDock];
}

- (IBAction)onCheckNewVersionOnStartup:(NSButton *)sender {
    NSInteger val = sender.state == NSControlStateValueOn ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"DontCheckUpdate"];
}

- (IBAction)onFixChromiumBrowser:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vFixChromiumBrowser"];
    vFixChromiumBrowser = (int)val;
}

- (IBAction)onTerminateApp:(id)sender {
    [NSApp terminate:0];
}

-(void)fillData {
    NSInteger value;
    
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    self.inputMethodControl.selectedSegment = (intInputMethod == 1) ? 0 : 1;
    
    NSInteger intInputType = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputType"];
    [self.popupInputType selectItemAtIndex:intInputType];
    
    NSInteger intCodeTable = [[NSUserDefaults standardUserDefaults] integerForKey:@"CodeTable"];
    [self.popupCode selectItemAtIndex:intCodeTable];
    
    //option
    NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
    self.ShowUIButton.state = showui ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger freeMark = [[NSUserDefaults standardUserDefaults] integerForKey:@"FreeMark"];
    self.FreeMarkButton.state = freeMark ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger useModernOrthography = [[NSUserDefaults standardUserDefaults] integerForKey:@"ModernOrthography"];
    self.UseModernOrthography.state = useModernOrthography ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger spelling = [[NSUserDefaults standardUserDefaults] integerForKey:@"Spelling"];
    self.CheckSpellingButton.state = spelling ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger runOnStartup = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    self.RunOnStartupButton.state = runOnStartup ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger useGrayIcon = [[NSUserDefaults standardUserDefaults] integerForKey:@"GrayIcon"];
    self.UseGrayIcon.state = useGrayIcon ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger quicTelex = [[NSUserDefaults standardUserDefaults] integerForKey:@"QuickTelex"];
    self.QuickTelex.state = quicTelex ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger restoreIfInvalidWord = [[NSUserDefaults standardUserDefaults] integerForKey:@"RestoreIfInvalidWord"];
    self.RestoreIfInvalidWord.state = restoreIfInvalidWord ? NSControlStateValueOn : NSControlStateValueOff;
    [self.RestoreIfInvalidWord setEnabled:spelling];
    
    NSInteger tempOffSpelling = [[NSUserDefaults standardUserDefaults] integerForKey:@"vTempOffSpelling"];
    self.TempOffSpellChecking.state = tempOffSpelling ? NSControlStateValueOn : NSControlStateValueOff;
    [self.TempOffSpellChecking setEnabled:spelling];
    
    NSInteger allowZFWJ = [[NSUserDefaults standardUserDefaults] integerForKey:@"vAllowConsonantZFWJ"];
    self.AllowZWJF.state = allowZFWJ ? NSControlStateValueOn : NSControlStateValueOff;
    [self.AllowZWJF setEnabled:spelling];
    
    NSInteger fixRecommendBrowser = [[NSUserDefaults standardUserDefaults] integerForKey:@"FixRecommendBrowser"];
    self.FixRecommendBrowser.state = fixRecommendBrowser ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger useMacro = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMacro"];
    self.UseMacro.state = useMacro ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger useMacroInEnglish = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMacroInEnglishMode"];
    self.UseMacroInEnglishMode.state = useMacroInEnglish ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger sendKeySbS = [[NSUserDefaults standardUserDefaults] integerForKey:@"SendKeyStepByStep"];
    self.SendKeyStepByStep.state = sendKeySbS ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger useSmartSwitchKey = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseSmartSwitchKey"];
    self.AutoRememberSwitchKey.state = useSmartSwitchKey ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger upperCaseFirstChar = [[NSUserDefaults standardUserDefaults] integerForKey:@"UpperCaseFirstChar"];
    self.UpperCaseFirstChar.state = upperCaseFirstChar ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger quickStartConsonant = [[NSUserDefaults standardUserDefaults] integerForKey:@"vQuickStartConsonant"];
    self.QuickStartConsonant.state = quickStartConsonant ? NSControlStateValueOn : NSControlStateValueOff;
    
    NSInteger quickEndConsonant = [[NSUserDefaults standardUserDefaults] integerForKey:@"vQuickEndConsonant"];
    self.QuickEndConsonant.state = quickEndConsonant ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vRememberCode"];
    self.RememberTableCode.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vOtherLanguage"];
    self.OtherLanguage.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vTempOffOpenKey"];
    self.TempOffOpenKey.state = value ? NSControlStateValueOn : NSControlStateValueOff;

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vAutoRestoreEnglish"];
    self.AutoRestoreEnglish.state = value ? NSControlStateValueOn : NSControlStateValueOff;

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vIgnoreStandaloneW"];
    self.IgnoreStandaloneW.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vAutoCapsMacro"];
    self.AutoCapsMacro.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vShowIconOnDock"];
    self.ShowIconOnDock.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    self.CheckNewVersionOnStartup.state = value ? NSControlStateValueOff :NSControlStateValueOn;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vFixChromiumBrowser"];
    self.FixChromiumBrowser.state = value ? NSControlStateValueOn : NSControlStateValueOff;
    self.FixChromiumBrowser.enabled = fixRecommendBrowser ? YES : NO;
    
    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vPerformLayoutCompat"];
    self.PerformLayoutCompat.state = value ? NSControlStateValueOn : NSControlStateValueOff;

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vForceEnglishSpotlight"];
    if (value == 0 && ![[NSUserDefaults standardUserDefaults] objectForKey:@"vForceEnglishSpotlight"]) {
        value = 1; // default ON
    }
    self.ForceEnglishSpotlight.state = value ? NSControlStateValueOn : NSControlStateValueOff;

    CustomSwitchControl.state = (vSwitchKeyStatus & 0x100) ? NSControlStateValueOn : NSControlStateValueOff;
    CustomSwitchOption.state = (vSwitchKeyStatus & 0x200) ? NSControlStateValueOn : NSControlStateValueOff;
    CustomSwitchCommand.state = (vSwitchKeyStatus & 0x400) ? NSControlStateValueOn : NSControlStateValueOff;
    CustomSwitchShift.state = (vSwitchKeyStatus & 0x800) ? NSControlStateValueOn : NSControlStateValueOff;
    CustomBeepSound.state = (vSwitchKeyStatus & 0x8000) ? NSControlStateValueOn : NSControlStateValueOff;
    [CustomSwitchKey setTextByChar:((vSwitchKeyStatus>>24) & 0xFF)];
    
}

- (IBAction)onOK:(id)sender {
    [self.view.window close];
}

- (IBAction)onDefaultConfig:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?"];
    [alert addButtonWithTitle:@"Có"];
    [alert addButtonWithTitle:@"Không"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == 1000) {
            [appDelegate loadDefaultConfig];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"ShowUIOnStartup"];
            self.ShowUIButton.state = NSControlStateValueOff;
            
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"RunOnStartup"];
            self.RunOnStartupButton.state = NSControlStateValueOn;
        }
    }];
}

- (IBAction)onHomePageLink:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://open-key.org"]];
}

- (IBAction)onFanpageLink:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.facebook.com/OpenKeyVN"]];
}

- (IBAction)onEmailLink:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:maivutuyen.91@gmail.com"]];
}

- (IBAction)onSourceCode:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/khac88/openkey"]];
}

- (IBAction)onCheckNewVersionButton:(id)sender {
    self.CheckNewVersionButton.title = @"Đang kiểm tra...";
    self.CheckNewVersionButton.enabled = false;
    
    [OpenKeyManager checkNewVersion:self.view.window callbackFunc:^{
        self.CheckNewVersionButton.enabled = true;
        self.CheckNewVersionButton.title = @"Kiểm tra bản mới...";
    }];
}

@end
