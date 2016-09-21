//
//  ViewController.m
//  XYBlueTest
//
//  Created by xiyang on 16/9/21.
//  Copyright © 2016年 xiyang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
- (NSString*)hexadecimalString:(NSData*)data;
- (NSData*)dataWithHexstring:(NSString*)hexstring;
- (void)writeToPeripheral:(NSString*)data;

@property (strong, nonatomic) NSMutableString* values;
@property (strong, nonatomic) NSMutableString* valuesTest;
@property (nonatomic) NSUInteger intTest;
@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.myCentralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    //    self.scanClick;
    self.values = [NSMutableString stringWithString:@""];
    _myPeripherals = [NSMutableArray array];
    _tableView.dataSource = self;
    _tableView.delegate = self;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//扫描
- (void)scanClick{
    NSLog(@"正在扫描外设...");
    //    [self.myCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    
    [self.myCentralManager scanForPeripheralsWithServices:nil options:nil];
    if(_myPeripheral != nil){
        [_myCentralManager cancelPeripheralConnection:_myPeripheral];
    }
    
    double delayInSeconds = 20.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds* NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.myCentralManager stopScan];
        NSLog(@"扫描超时,停止扫描!");
    });
}

//连接
- (void)connectClick{
    [self.myCentralManager connectPeripheral:self.myPeripheral options:nil];
}

//开始查看服务, 蓝牙开启
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"蓝牙已打开, 请扫描外设!");
            break;
            
        default:
            break;
    }
}

//查到外设后的方法,peripherals
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    //    NSLog(@"已发现 peripheral: %@ rssi: %@, uuid: %@ advertisementData: %@", peripheral, RSSI, peripheral.UUID, advertisementData);
    
    [_myPeripherals addObject:peripheral];
    NSInteger count = [_myPeripherals count];
    NSLog(@"my periphearls count : %ld\n", (long)count);
    [_tableView reloadData];

}

//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //    NSLog(@"成功连接 peripheral: %@ with UUID: %@",peripheral, peripheral.UUID);
    [self.myPeripheral setDelegate:self];
    [self.myPeripheral discoverServices:nil];
    NSLog(@"扫描服务...");
    [_attention setText:@""];
}

//掉线时调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"periheral has disconnect");
    [_peripheralState setText:@"disconnected"];
    [_peripheralState setTextColor:[UIColor redColor]];
    [_peripheralRssi setText:@"00"];
    [_attention setText:@"connect failure, please try again!"];
}

//连接外设失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", error);
    [_peripheralState setText:@"disconnected"];
    [_peripheralState setTextColor:[UIColor redColor]];
    [_peripheralRssi setText:@"00"];
    [_attention setText:@"connect failure, please try again!"];
}

//已发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"发现服务!");
    int i = 0;
    for(CBService* s in peripheral.services){
        [self.nServices addObject:s];
    }
    for(CBService* s in peripheral.services){
        NSLog(@"%d :服务 UUID: %@(%@)", i, s.UUID.data, s.UUID);
        i++;
        [peripheral discoverCharacteristics:nil forService:s];
        NSLog(@"扫描Characteristics...");
    }
}

//已发现characteristcs
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for(CBCharacteristic* c in service.characteristics){
        NSLog(@"特征 UUID: %@ (%@)", c.UUID.data, c.UUID);
        if([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]){
            self.writeCharacteristic = c;
        
            NSLog(@"找到WRITE : %@", c);
        }else if([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]]){
            self.readCharacteristic = c;

            [self.myPeripheral setNotifyValue:YES forCharacteristic:c];
            [self.myPeripheral readValueForCharacteristic:c];
            NSLog(@"找到READ : %@", c);
            [_peripheralState setText:@"connected"];
            [_peripheralState setTextColor:[UIColor greenColor]];
        }
    }
}

//获取外设发来的数据,不论是read和notify,获取数据都从这个方法中读取
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    [peripheral readRSSI];
    NSNumber* rssi = [peripheral RSSI];
    [_peripheralRssi setText:[NSString stringWithFormat:@"%@", rssi]];
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]]){
        
        NSData* data = characteristic.value;
        

        NSString* value = [self hexadecimalString:data];
        NSLog(@"characteristic : %@, data : %@, value : %@", characteristic, data, value);

        [self.values appendString:[NSString stringWithFormat:@"%@\n",value]];
        //        NSLog(@"\n%@\n vlaue: %@",self.values, value);
        [_valueTextView setText:_values];
        NSRange range;
        range.location = _valueTextView.text.length;
        range.length = 0;
        [_valueTextView scrollRangeToVisible:range];
        [_valueTextView setScrollEnabled:NO];
        [_valueTextView setScrollEnabled:YES];
    }
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error){
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    //Notification has started
    if(characteristic.isNotifying){
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        NSLog(@"Notification stopped on %@. Disconnting", characteristic);
        [self.myCentralManager cancelPeripheralConnection:self.myPeripheral];
    }
}

//向peripheral中写入数据
- (void)writeToPeripheral:(NSString *)data{
    if(!_writeCharacteristic){
        NSLog(@"writeCharacteristic is nil!");
        return;
    }
    NSData* value = [self dataWithHexstring:data];

    [_myPeripheral writeValue:value forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
    
}

//向peripheral中写入数据后的回调函数
- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"write value success : %@", characteristic);
}

//将传入的NSData类型转换成NSString并返回
- (NSString*)hexadecimalString:(NSData *)data{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}

//将传入的NSString类型转换成NSData并返回
- (NSData*)dataWithHexstring:(NSString *)hexstring{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for(idx = 0; idx + 2 <= hexstring.length; idx += 2){
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexstring substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

//连接设备[connect]
- (IBAction)connDevice:(id)sender{
    [self.myCentralManager stopScan];
    if(_myPeripherals != nil){
        _myPeripherals = nil;
        _myPeripherals = [NSMutableArray array];
        [_tableView reloadData];
    }
    _tableView.hidden = NO;
    self.scanClick;
    
}

//tableview的方法,返回section个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//tableview的方法,返回rows(行数)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _myPeripherals.count;
}

//tableview的方法,返回cell的view
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //为表格定义一个静态字符串作为标识符
    static NSString* cellId = @"cellId";
    //从IndexPath中取当前行的行号
    NSUInteger rowNo = indexPath.row;
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    UILabel* labelName = (UILabel*)[cell viewWithTag:1];
    UILabel* labelUUID = (UILabel*)[cell viewWithTag:2];
    labelName.text = [[_myPeripherals objectAtIndex:rowNo] name];
    NSString* uuid = [NSString stringWithFormat:@"%@", [[_myPeripherals objectAtIndex:rowNo] identifier]];
    uuid = [uuid substringFromIndex:[uuid length] - 13];
    NSLog(@"%@", uuid);
    labelUUID.text = uuid;
    
    return cell;
}

//tableview的方法,点击行时触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger rowNo = indexPath.row;
    //    NSLog(@"%lu", (unsigned long)rowNo);
    _tableView.hidden = YES;
    _myPeripheral = [_myPeripherals objectAtIndex:rowNo];
    [self connectClick];
}


//隐藏键盘
- (IBAction)hideKeyboard:(id)sender{
    [self hideKeyboard];
}

- (void)hideKeyboard{
    [_writeText1 resignFirstResponder];
    [_writeText2 resignFirstResponder];
    [_writeText3 resignFirstResponder];
    [_writeText4 resignFirstResponder];
    [_writeText5 resignFirstResponder];
}

- (IBAction)clearTextView:(id)sender {
    _values = nil;
    _values = [NSMutableString stringWithString:@""];
    [_valueTextView setText:_values];
}
//连接
- (IBAction)writeBn1:(id)sender {
    
    NSString* value = [_writeText1 text];
    if(!value || [value isEqualToString:@""]){
        return;
    }
    [self writeToPeripheral:value];
    [self hideKeyboard];
    NSLog(@"write to peripheral value : %@", value);
}
//启动测量
- (IBAction)writeBn2:(id)sender {
    
    NSString* value = [_writeText2 text];
    if(!value || [value isEqualToString:@""]){
        return;
    }
    [self writeToPeripheral:value];
    [self hideKeyboard];
    NSLog(@"write to peripheral value : %@", value);
}
//停止测量
- (IBAction)writeBn3:(id)sender {
    
    NSString* value = [_writeText3 text];
    if(!value || [value isEqualToString:@""]){
        return;
    }
    [self writeToPeripheral:value];
    [self hideKeyboard];
    NSLog(@"write to peripheral value : %@", value);
}
//关机
- (IBAction)writeBn4:(id)sender {
    
    NSString* value = [_writeText4 text];
    if(!value || [value isEqualToString:@""]){
        return;
    }
    [self writeToPeripheral:value];
    [self hideKeyboard];
    NSLog(@"write to peripheral value : %@", value);
}

- (IBAction)writeBn5:(id)sender {
    NSString* value = [_writeText5 text];
    if(!value || [value isEqualToString:@""]){
        return;
    }
    [self writeToPeripheral:value];
    [self hideKeyboard];
    NSLog(@"write to peripheral value : %@", value);
}


@end
