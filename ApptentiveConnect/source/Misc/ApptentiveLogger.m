//
//  ApptentiveLogger.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogger.h"

#import "ApptentiveUtilities.h"


@interface ApptentiveLogger ()
- (NSString *)logDirectoryPath;
- (NSString *)logFilePath;
- (NSString *)backupLogFilePath;
- (BOOL)rotateLog;
- (BOOL)startNewLog;
- (void)queueLogWithLevel:(NSString *)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)message;
@end


@implementation ApptentiveLogger {
	// Tracks whether or not we can actually log to the log file.
	BOOL creatingLogPathFailed;

	NSFileHandle *logHandle;
}

static dispatch_queue_t loggingQueue;

+ (void)load {
	ApptentiveLogger *logger = [ApptentiveLogger sharedLogger];
	[logger startNewLog];
}

+ (ApptentiveLogger *)sharedLogger {
	static ApptentiveLogger *sharedLogger;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		loggingQueue = dispatch_queue_create("com.apptentive.logging-queue", NULL);
		sharedLogger = [[self alloc] init];
	});
	return sharedLogger;
}

- (void)dealloc {
	if (logHandle != nil) {
		[logHandle synchronizeFile];
		[logHandle closeFile];
	}
}

+ (void)logWithLevel:(NSString *)level file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format, ... {
	va_list args;
	if (format != nil) {
		va_start(args, format);

		NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
		[[ApptentiveLogger sharedLogger] queueLogWithLevel:level file:file function:function line:line message:message];
		message = nil;
		va_end(args);
	}
}

+ (void)logWithLevel:(NSString *)level file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format args:(va_list)args {
	if (format != nil) {
		NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
		[[ApptentiveLogger sharedLogger] queueLogWithLevel:level file:file function:function line:line message:message];
		message = nil;
	}
}


- (NSString *)currentLogText {
	NSError *error = nil;
	NSString *text = [NSString stringWithContentsOfFile:[self logFilePath] encoding:NSUTF8StringEncoding error:&error];
	if (text == nil) {
		NSLog(@"Unable to read contents of file: %@", error);
	}
	return text;
}

#pragma mark - Private Methods
- (NSString *)logDirectoryPath {
	NSFileManager *fm = [NSFileManager defaultManager];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

	if (path == nil) {
		creatingLogPathFailed = YES;
		return nil;
	}

	NSString *newPath = [path stringByAppendingPathComponent:@"com.apptentive.logs"];
	NSError *error = nil;
	BOOL isDir = NO;

	BOOL pathExists = [fm fileExistsAtPath:newPath isDirectory:&isDir];
	if (pathExists == NO && isDir) {
		NSLog(@"ATLog path exists but is a directory: %@", newPath);
		creatingLogPathFailed = YES;
		return nil;
	} else if (pathExists) {
		return newPath;
	}

	BOOL pathCreated = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (pathCreated == NO) {
		NSLog(@"Failed to create log directory: %@", newPath);
		NSLog(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)logFilePath {
	NSString *logDir = [self logDirectoryPath];
	if (logDir == nil) {
		return nil;
	}
	return [logDir stringByAppendingPathComponent:@"apptentive.log"];
}

- (NSString *)backupLogFilePath {
	NSString *logDir = [self logDirectoryPath];
	if (logDir == nil) {
		return nil;
	}
	return [logDir stringByAppendingPathComponent:@"apptentive.previous.log"];
}

- (BOOL)rotateLog {
	__block BOOL result = YES;

	dispatch_sync(loggingQueue, ^{
		if (logHandle) {
			[logHandle synchronizeFile];
			[logHandle closeFile];
		}
		
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir = NO;
		if ([fm fileExistsAtPath:[self logFilePath] isDirectory:&isDir] && isDir == NO) {
			[fm removeItemAtPath:[self backupLogFilePath] error:nil];
			NSError *error = nil;
			if ([fm moveItemAtPath:[self logFilePath] toPath:[self backupLogFilePath] error:&error] == NO) {
				NSLog(@"Unable to rotate logs: %@", error);
				result = NO;
			}
		}
	});
	return result;
}

- (BOOL)startNewLog {
	[self rotateLog];
	if (logHandle != nil) {
		NSLog(@"logHandle should be nil here.");
		return NO;
	}
	NSString *logPath = [self logFilePath];
	if (!logPath) {
		NSLog(@"Unable to get log path.");
		return NO;
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm createFileAtPath:logPath contents:nil attributes:nil] == NO) {
		NSLog(@"Unable to create new log file.");
		creatingLogPathFailed = YES;
		return NO;
	}
	if (creatingLogPathFailed) {
		NSLog(@"Creating log path failed. Not starting new log.");
		return NO;
	}
	logHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
	if (logHandle == nil) {
		NSLog(@"Unable to create log handle.");
		return NO;
	}
	return YES;
}

- (void)queueLogWithLevel:(NSString *)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)message {
	NSDate *date = [NSDate date];

	dispatch_async(loggingQueue, ^{
		@autoreleasepool {
			NSString *fullFilename = [NSString stringWithUTF8String:file];
			NSString *filename = [fullFilename lastPathComponent];
			NSString *fullMessage = [[NSString alloc] initWithFormat:@"%@ %s:%d [%@] %@", filename, function, line, level, message];
			
			NSLog(@"[%@] %@", level, message);
			if (creatingLogPathFailed == NO && logHandle != nil) {
				NSString *dateString = [ApptentiveUtilities stringRepresentationOfDate:date];
				NSMutableString *fileLogMessage = [NSMutableString stringWithFormat:@"%@  %@", dateString, fullMessage];
				if ([fileLogMessage hasSuffix:@"\n"] == NO) {
					[fileLogMessage appendString:@"\n"];
				}
				@try {
					[logHandle writeData:[fileLogMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				@catch (NSException *exception) {
					// Probably out of space on the device.
				}
			}
		}
	});
}
@end
