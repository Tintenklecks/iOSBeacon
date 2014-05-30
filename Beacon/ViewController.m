//
//  ViewController.m
//  Beacon
//
//  Created by Christopher Ching on 2013-11-28.
//  Copyright (c) 2013 AppCoda. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "PulsingHaloLayer.h"

#define SETTINGSUUID          @"uuid"
#define SETTINGSMAYOR         @"mayor"
#define SETTINGSMINOR         @"minor"
#define SETTINGSPOWER         @"power"


@interface ViewController () <CBPeripheralManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) PulsingHaloLayer *halo;

@property (strong, nonatomic) IBOutlet UIButton *advertisingButton;

@property (strong, nonatomic) UITextField *currentStepperTextField;

@end

@implementation ViewController

- (void)setBeaconValues {
	// Create a NSUUID object
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_uuidField.text];
    
	// Initialize the Beacon Region
	self.myBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
	                                                              major:[_majorField.text integerValue]
	                                                              minor:[_minorField.text integerValue]
	                                                         identifier:[[NSBundle mainBundle] bundleIdentifier]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    
    
	_halo = [PulsingHaloLayer layer];
	_halo.position = self.advertisingButton.center;
	_halo.radius = 0;
	_halo.pulseInterval = 0.0;
	_halo.animationDuration = 1.0;
	[self.view.layer insertSublayer:_halo below:_advertisingButton.layer];
    
	_majorField.keyboardType = UIKeyboardTypeNumberPad;
	_minorField.keyboardType = UIKeyboardTypeNumberPad;
    
	AppDelegate *app = (AppDelegate *)([UIApplication sharedApplication]).delegate;
	app.viewController = self;
    
	[self loadSettings];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self saveSettings];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (IBAction)buttonClicked:(UIButton *)sender {
	if (sender.tag == 0) { // activate
		[self setBeaconValues];
        
		_halo.radius = _advertisingButton.bounds.size.width * 3 / 2; // MIN(self.view.bounds.size.width, self.view.bounds.size.height) / 2;
		_halo.position = self.advertisingButton.center;
		[sender setImage:[UIImage imageNamed:@"BroadcastButtonActive"] forState:UIControlStateNormal];
		// Get the beacon data to advertise
		self.myBeaconData = [self.myBeaconRegion peripheralDataWithMeasuredPower:nil];
        
		// Start the peripheral manager
		self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
		                                                                 queue:nil
		                                                               options:nil];
		sender.tag = 1;
	}
	else {
		[self.peripheralManager stopAdvertising];
		[sender setImage:[UIImage imageNamed:@"BroadcastButtonInactive"] forState:UIControlStateNormal];
		sender.tag = 0;
		_halo.radius = 0;
	}
    
	_uuidField.enabled = (sender.tag == 0);
	_minorField.enabled = _uuidField.enabled;
	_majorField.enabled = _uuidField.enabled;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	_halo.position = self.advertisingButton.center;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
	if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
		// Bluetooth is on
        
		// Update our status label
		self.statusLabel.text = [NSString stringWithFormat:@"Broadcasting ...\n%@ ", _myBeaconData];
		NSLog(@"%@", _statusLabel.text);
		// Start broadcasting
		[self.peripheralManager startAdvertising:self.myBeaconData];
	}
	else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
		// Update our status label
		self.statusLabel.text = @"Stopped";
        
		// Bluetooth isn't on. Stop broadcasting
		[self.peripheralManager stopAdvertising];
	}
	else if (peripheral.state == CBPeripheralManagerStateUnsupported) {
		self.statusLabel.text = @"BLE is unsupported";
        
		UIAlertView *alertView;
		alertView = [[UIAlertView alloc] initWithTitle:@"INFO" message:@"Bluetooth Low Energy (BLE) is not supported on that device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
        
        
		[self performSelector:@selector(buttonClicked:) withObject:_advertisingButton afterDelay:0.5];
		//	[self buttonClicked:_advertisingButton];
	}
	NSLog(@"... %@", self.statusLabel.text);
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
	NSLog(@"...2, (%@)", error.description);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
	NSLog(@"...3");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
	NSLog(@"...4");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
	NSLog(@"...5");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
	NSLog(@"...6");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
	NSLog(@"...7");
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
	NSLog(@"...8");
}

#pragma mark - Textfield Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	BOOL shouldReplace;
	if ([textField isEqual:_uuidField]) {
		string = [string uppercaseString];
		NSCharacterSet *nonHexSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef-"]  invertedSet];
		shouldReplace = ([string stringByTrimmingCharactersInSet:nonHexSet].length > 0) || [string isEqualToString:@""];
	}
	else {
		NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		shouldReplace = ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0) || [string isEqualToString:@""];
        
		NSString *text = textField.text;
		if (shouldReplace) {
			text = [text stringByReplacingCharactersInRange:range withString:string];
			_stepper.value = text.integerValue;
		}
	}
    
    
	return shouldReplace;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	NSLog(@"begin ");
	CGPoint stepperCenter = _stepper.center;
	if ([textField isEqual:_majorField]) {
		stepperCenter.x = textField.center.x;
		_stepper.hidden = NO;
		_stepper.value = textField.text.integerValue;
		_currentStepperTextField = textField;
	}
	else if ([textField isEqual:_minorField]) {
		stepperCenter.x = textField.center.x;
		_stepper.hidden = NO;
		_stepper.value = textField.text.integerValue;
		_currentStepperTextField = textField;
	}
	else { // UUID
		_stepper.hidden = YES;
	}
	_stepper.center = stepperCenter;
	_advertisingButton.enabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if ([textField isEqual:_minorField] || [textField isEqual:_majorField]) {
		_stepper.value = _currentStepperTextField.text.integerValue;
	}
    
	_stepper.hidden = YES;
	_advertisingButton.enabled = YES;
}

- (IBAction)stepperControl:(id)sender {
	if ([_currentStepperTextField isEqual:_minorField]) {
		NSLog(@"MINOR");
	}
	else {
		NSLog(@"major");
	}
	_currentStepperTextField.text = [NSString stringWithFormat:@"%0.0f", _stepper.value];
}

- (IBAction)tapView:(id)sender {
	[self.view endEditing:YES];
}

- (void)loadSettings {
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 @{
       SETTINGSUUID     : @"F9A7F5BA-15F9-476C-952C-0E3A3FDEBD5B"
       , SETTINGSMAYOR    : @1
       , SETTINGSMINOR    : @1
       }
     ];
    
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
	_uuidField.text = [settings objectForKey:SETTINGSUUID];
	_minorField.text = [[settings objectForKey:SETTINGSMINOR] stringValue];
	_majorField.text = [[settings objectForKey:SETTINGSMAYOR] stringValue];
}

- (void)saveSettings {
	NSLog(@"SAVE");
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[settings setObject:_uuidField.text forKey:SETTINGSUUID];
    
	[settings setInteger:[_minorField.text integerValue] forKey:SETTINGSMINOR];
	[settings setInteger:[_majorField.text integerValue] forKey:SETTINGSMAYOR];
    
	[settings synchronize];
}

@end
