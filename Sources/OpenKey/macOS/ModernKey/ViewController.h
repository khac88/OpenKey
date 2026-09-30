//
//  ViewController.h
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyTextField.h"

// The control panel is built in code (see ViewController.m), not in the storyboard.
@interface ViewController : NSViewController<MyTextFieldDelegate>

@property (weak) NSPopUpButton *popupInputType;
@property (weak) NSPopUpButton *popupCode;
@property (weak) NSSegmentedControl *inputMethodControl;

@property (weak) NSSwitch *FreeMarkButton;
@property (weak) NSSwitch *UseModernOrthography;

@property (weak) NSSwitch *CheckSpellingButton;

@property (weak) NSSwitch *RunOnStartupButton;
@property (weak) NSSwitch *ShowUIButton;

@property (weak) NSSwitch *UseGrayIcon;
@property (weak) NSSwitch *QuickTelex;

@property (weak) NSSwitch *RestoreIfInvalidWord;
@property (weak) NSSwitch *FixRecommendBrowser;
@property (weak) NSSwitch *AllowZWJF;
@property (weak) NSSwitch *TempOffSpellChecking;

@property (weak) NSSwitch *UseMacro;
@property (weak) NSSwitch *UseMacroInEnglishMode;

@property (weak) NSSwitch *SendKeyStepByStep;
@property (weak) NSSwitch *AutoRememberSwitchKey;
@property (weak) NSSwitch *UpperCaseFirstChar;
@property (weak) NSSwitch *QuickStartConsonant;
@property (weak) NSSwitch *QuickEndConsonant;

@property (weak) NSSwitch *RememberTableCode;
@property (weak) NSSwitch *OtherLanguage;

@property (weak) NSSwitch *TempOffOpenKey;
@property (weak) NSSwitch *AutoCapsMacro;
@property (weak) NSSwitch *ShowIconOnDock;
@property (weak) NSSwitch *CheckNewVersionOnStartup;
@property (weak) NSSwitch *FixChromiumBrowser;
@property (weak) NSSwitch *PerformLayoutCompat;
@property (weak) NSSwitch *ForceEnglishSpotlight;
@property (weak) NSSwitch *AutoRestoreEnglish;
@property (weak) NSSwitch *IgnoreStandaloneW;

@property (weak) NSButton *CheckNewVersionButton;

-(void)fillData;
@end

