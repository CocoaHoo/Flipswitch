#import <UIKit/UIKit.h>
#import <notify.h>

#import "FSSwitchPanel.h"
#import "NSBundle+Flipswitch.h"

@interface PSSpecifier : NSObject {
@public
	id target;
	SEL getter;
	SEL setter;
	SEL action;
	SEL cancel;
	Class detailControllerClass;
	int cellType;
	Class editPaneClass;
	int keyboardType;
	int autoCapsType;
	int autoCorrectionType;
	unsigned textFieldType;
	NSString *_name;
	NSArray *_values;
	NSDictionary *_titleDict;
	NSDictionary *_shortTitleDict;
	id _userInfo;
	NSMutableDictionary *_properties;
@private
	SEL _confirmationAction;
	SEL _confirmationCancelAction;
	SEL _buttonAction;
	SEL _controllerLoadAction;
	BOOL _showContentString;
}

+ (int)keyboardTypeForString:(NSString *)string;
+ (int)autoCapsTypeForString:(NSString *)string;
+ (int)autoCorrectionTypeForNumber:(NSNumber *)number;
+ (PSSpecifier *)emptyGroupSpecifier;
+ (PSSpecifier *)groupSpecifierWithName:(NSString *)name;
+ (PSSpecifier *)preferenceSpecifierNamed:(NSString *)name target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(int)cell edit:(Class)edit;
+ (PSSpecifier *)deleteButtonSpecifierWithName:(NSString *)name target:(id)target action:(SEL)action;

@property (assign, nonatomic) BOOL showContentString;
@property (assign, nonatomic) SEL controllerLoadAction;
@property (assign, nonatomic) SEL buttonAction;
@property (assign, nonatomic) SEL confirmationCancelAction;
@property (assign, nonatomic) SEL confirmationAction;
@property (assign, nonatomic) Class editPaneClass;
@property (assign, nonatomic) int cellType;
@property (assign, nonatomic) Class detailControllerClass;
@property (assign, nonatomic) id target;
@property (retain, nonatomic) NSString *identifier;
@property (retain, nonatomic) NSDictionary *shortTitleDictionary;
@property (retain, nonatomic) NSDictionary *titleDictionary;
@property (retain, nonatomic) id userInfo;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSArray *values;

- (NSComparisonResult)titleCompare:(PSSpecifier *)otherSpecifier;
- (void)setKeyboardType:(int)type autoCaps:(int)caps autoCorrection:(int)correction;
- (void)setupIconImageWithPath:(NSString *)path;
- (void)setupIconImageWithBundle:(NSBundle *)bundle;
- (void)setValues:(NSArray *)values titles:(NSArray *)titles shortTitles:(NSArray *)shortTitles usingLocalizedTitleSorting:(BOOL)usingLocalizedTitleSorting;
- (void)setValues:(NSArray *)values titles:(NSArray *)titles shortTitles:(NSArray *)shortTitles;
- (void)setValues:(NSArray *)values titles:(NSArray *)titles;
- (void)loadValuesAndTitlesFromDataSource;
- (NSDictionary *)properties;
- (void)setProperties:(NSDictionary *)properties;
- (void)removePropertyForKey:(NSString *)key;
- (void)setProperty:(id)property forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

@end

@interface PSViewController : UIViewController
@property (nonatomic, retain) PSSpecifier *specifier;
@end

@interface FSSettingsController : PSViewController <UITableViewDataSource, UITableViewDelegate> {
@private
	NSString *settingsFile;
	NSString *enabledKey;
	NSMutableArray *enabledIdentifiers;
	NSString *disabledKey;
	NSMutableArray *disabledIdentifiers;
	NSString *notificationName;
	NSBundle *templateBundle;
	CGFloat rowHeight;
}
@end

@implementation FSSettingsController

- (void)dealloc
{
	[enabledIdentifiers release];
	[disabledIdentifiers release];
	[enabledKey release];
	[disabledKey release];
	[notificationName release];
	[settingsFile release];
	[templateBundle release];
	[super dealloc];
}

- (void)loadView
{
	UITableView *tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f) style:UITableViewStyleGrouped] autorelease];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.rowHeight = rowHeight;
	[tableView setEditing:YES animated:NO];
	self.view = tableView;
	[tableView release];
}

- (void)setSpecifier:(PSSpecifier *)specifier
{
	[super setSpecifier:specifier];
	self.navigationItem.title = [specifier name];
	[settingsFile release];
	settingsFile = [[specifier propertyForKey:@"flipswitchSettingsFile"] copy];
	[notificationName release];
	notificationName = [[specifier propertyForKey:@"flipswitchPostNotification"] copy];
	[enabledKey release];
	enabledKey = [[specifier propertyForKey:@"flipswitchEnabledKey"] copy];
	[disabledKey release];
	disabledKey = [[specifier propertyForKey:@"flipswitchDisabledKey"] copy];
	// Reading Settings file
	NSDictionary *settings = settingsFile ? [NSDictionary dictionaryWithContentsOfFile:settingsFile] : nil;
	NSArray *originalEnabled = [settings objectForKey:enabledKey] ?: [specifier propertyForKey:@"flipswitchDefaultEnabled"] ?: [NSArray array];
	[enabledIdentifiers release];
	enabledIdentifiers = [originalEnabled mutableCopy];
	NSArray *originalDisabled = [settings objectForKey:disabledKey] ?: [specifier propertyForKey:@"flipswitchDefaultDisabled"] ?: [NSArray array];
	[disabledIdentifiers release];
	disabledIdentifiers = [originalDisabled mutableCopy];
	NSMutableArray *allIdentifiers = [[[FSSwitchPanel sharedPanel].switchIdentifiers mutableCopy] autorelease];
	for (NSString *identifier in originalEnabled) {
		if ([allIdentifiers containsObject:identifier]) {
			[allIdentifiers removeObject:identifier];
			[disabledIdentifiers removeObject:identifier];
		} else {
			[enabledIdentifiers removeObject:identifier];
		}
	}
	for (NSString *identifier in originalDisabled) {
		if ([allIdentifiers containsObject:identifier]) {
			[allIdentifiers removeObject:identifier];
		} else {
			[disabledIdentifiers removeObject:identifier];
		}
	}
	NSMutableArray *arrayToAddNewIdentifiers = [[specifier propertyForKey:@"flipswitchNewAreDisabled"] boolValue] ? disabledIdentifiers : enabledIdentifiers;
	for (NSString *identifier in allIdentifiers) {
		[arrayToAddNewIdentifiers addObject:identifier];
	}
	// Theming
	NSString *bundlePath = [specifier propertyForKey:@"flipswitchTemplateBundle"];
	if (bundlePath) {
		[templateBundle release];
		templateBundle = [[NSBundle alloc] initWithPath:bundlePath];
	}
	rowHeight = [[templateBundle.flipswitchThemedInfoDictionary objectForKey:@"height"] floatValue] + 2.0f;
	if (rowHeight < 44.0f) {
		rowHeight = 44.0f;
	}
	if ([self isViewLoaded]) {
		[(UITableView *)self.view setRowHeight:rowHeight];
		[(UITableView *)self.view reloadData];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	return 2;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	return section ? @"Disabled" : @"Enabled";
}

- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section
{
	return @" ";
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	return section ? [disabledIdentifiers count] : [enabledIdentifiers count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
	FSSwitchPanel *panel = [FSSwitchPanel sharedPanel];
	NSString *switchIdentifier = [indexPath.section ? disabledIdentifiers : enabledIdentifiers objectAtIndex:indexPath.row];
	cell.textLabel.text = [panel titleForSwitchIdentifier:switchIdentifier];
	cell.imageView.image = [panel imageOfSwitchState:FSSwitchStateIndeterminate controlState:UIControlStateNormal forSwitchIdentifier:switchIdentifier usingTemplate:templateBundle];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	NSMutableArray *fromArray = fromIndexPath.section ? disabledIdentifiers : enabledIdentifiers;
	NSMutableArray *toArray = toIndexPath.section ? disabledIdentifiers : enabledIdentifiers;
	NSString *identifier = [[fromArray objectAtIndex:fromIndexPath.row] retain];
	[fromArray removeObjectAtIndex:fromIndexPath.row];
	[toArray insertObject:identifier atIndex:toIndexPath.row];
	[identifier release];
	if (settingsFile) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:settingsFile] ?: [NSMutableDictionary dictionary];
		if (enabledKey) {
			[dict setObject:enabledIdentifiers forKey:enabledKey];
		}
		if (disabledKey) {
			[dict setObject:disabledIdentifiers forKey:disabledKey];
		}
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
		[data writeToFile:settingsFile atomically:YES];
	}
	if (notificationName) {
		notify_post([notificationName UTF8String]);
	}
}

@end
