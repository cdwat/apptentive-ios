//
//  Apptentive+Debugging.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive+Debugging.h"
#import "ATWebClient.h"
#import "ATBackend.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"
#import "ATDeviceInfo.h"


@implementation Apptentive (Debugging)

- (ApptentiveDebuggingOptions)debuggingOptions {
	return 0;
}

- (NSString *)SDKVersion {
	return kApptentiveVersionString;
}

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL storagePath:(nonnull NSString *)storagePath {
	if (![baseURL isEqual:self.baseURL]) {
		ATLogInfo(@"Base URL of %@ will not be used due to SDK version. Using %@ instead.", baseURL, self.baseURL);
	}

	if (![storagePath isEqualToString:self.storagePath]) {
		ATLogInfo(@"Storage path of %@ will not be used due to SDK version. Using %@ instead.", storagePath, self.storagePath);
	}

	self.apiKey = APIKey;
}

- (NSString *)storagePath {
	return [self class].supportDirectoryPath;
}

- (NSURL *)baseURL {
	return self.webClient.baseURL;
}

- (NSString *)APIKey {
	return self.apiKey;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSData *rawJSONData = self.engagementBackend.engagementManifestJSON;

	if (rawJSONData != nil) {
		NSData *outputJSONData = nil;

		// try to pretty-print by round-tripping through NSJSONSerialization
		id JSONObject = [NSJSONSerialization JSONObjectWithData:rawJSONData options:0 error:NULL];
		if (JSONObject) {
			outputJSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:NULL];
		}

		// fall back to ugly JSON
		if (!outputJSONData) {
			outputJSONData = rawJSONData;
		}

		return [[NSString alloc] initWithData:outputJSONData encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

- (NSDictionary *)deviceInfo {
	return [[[[ATDeviceInfo alloc] init] dictionaryRepresentation] objectForKey:@"device"];
}

- (NSArray *)engagementInteractions {
	return [self.engagementBackend allEngagementInteractions];
}

- (NSInteger)numberOfEngagementInteractions {
	return [[self engagementInteractions] count];
}

- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return [interaction.configuration objectForKey:@"name"] ?: [interaction.configuration objectForKey:@"title"] ?: @"Untitled Interaction";
}

- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return interaction.type;
}

- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController {
	[self.engagementBackend presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

@end