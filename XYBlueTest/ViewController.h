//
//  ViewController.h
//  XYBlueTest
//
//  Created by xiyang on 16/9/21.
//  Copyright © 2016年 xiyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate>


@property (strong, nonatomic) CBCentralManager* myCentralManager;
@property (strong, nonatomic) NSMutableArray* myPeripherals;
@property (strong, nonatomic) CBPeripheral* myPeripheral;
@property (strong, nonatomic) NSMutableArray* nServices;
@property (strong, nonatomic) NSMutableArray* nDevices;
@property (strong, nonatomic) NSMutableArray* nCharacteristics;
@property (strong, nonatomic) CBCharacteristic* writeCharacteristic;
@property (strong, nonatomic) CBCharacteristic* readCharacteristic;

@property (strong, nonatomic) IBOutlet UITextView *valueTextView;
@property (strong, nonatomic) IBOutlet UITextField *writeText1;
@property (strong, nonatomic) IBOutlet UITextField *writeText2;
@property (strong, nonatomic) IBOutlet UITextField *writeText3;
@property (strong, nonatomic) IBOutlet UITextField *writeText4;
@property (strong, nonatomic) IBOutlet UITextField *writeText5;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *peripheralState;
@property (strong, nonatomic) IBOutlet UILabel *peripheralRssi;
@property (strong, nonatomic) IBOutlet UILabel *attention;

- (void)scanClick;
- (void)connectClick;
- (void)hideKeyboard;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)clearTextView:(id)sender;
- (IBAction)connDevice:(id)sender;

- (IBAction)writeBn1:(id)sender;
- (IBAction)writeBn2:(id)sender;
- (IBAction)writeBn3:(id)sender;
- (IBAction)writeBn4:(id)sender;
- (IBAction)writeBn5:(id)sender;
@end

