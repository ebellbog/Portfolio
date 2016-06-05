//
//  AppDelegate.m
//  Pholder Assistant
//
//  Created by Elana Bogdan on 11/30/14.
//  Copyright (c) 2014 Elana Bogdan. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
   [self openDirectory:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
   // Insert code here to tear down your application
}

- (IBAction)openDirectory:(id)sender {
   NSOpenPanel* openDlg = [NSOpenPanel openPanel];
   openDlg.canChooseFiles = NO;
   openDlg.canChooseDirectories = YES;
   openDlg.allowsMultipleSelection = NO;
   openDlg.title = @"Select your Pholder directory...";
   
   if ( [openDlg runModal] == NSModalResponseOK ) {
      
      NSError *error;
      NSURL* directoryURL = [openDlg URL];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      
      NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:[directoryURL path] error:&error];
      if (error) {
         NSLog(@"Error acccessing directory contents: %@", [error description]);
         return;
      }
      
      NSMutableArray *photoURLs = [[NSMutableArray alloc] init];
      for (NSString *filePath in filePaths) {
         if ([self isPhotoFile:filePath]) {
            [photoURLs addObject:[directoryURL URLByAppendingPathComponent:filePath]];
         }
      }
      
      NSMutableSet *newDirectories = [[NSMutableSet alloc] init];
      NSCountedSet *movedFiles = [[NSCountedSet alloc] init];
      int movedCount = 0;
      int favoritedCount = 0;
      
      for (NSURL *photoURL in photoURLs) {
         CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)photoURL, NULL);
         NSDictionary *metadata = (__bridge_transfer NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
         NSDictionary *IPTCdictionary = metadata[@"{IPTC}"];
         if (IPTCdictionary) {
            NSArray *keywords = IPTCdictionary[@"Keywords"];
            if (keywords) {
               NSString *newPath, *currentPath = [photoURL path];
               
               for (NSString *keyword in keywords) { //TODO: full support for multiple album membership -> file needs to get copied, not just moved
                  
                  //Create directories as needed
                  BOOL isDirectory;
                  NSString *subDirectoryPath = [[directoryURL path] stringByAppendingPathComponent:keyword];
                  if (!([fileManager fileExistsAtPath:subDirectoryPath isDirectory:&isDirectory] && isDirectory)) { //"If it is NOT the case that we have a directory at this path..."
                     [fileManager createDirectoryAtPath:subDirectoryPath withIntermediateDirectories:NO attributes:nil error:&error];
                     if (error) {
                        NSLog(@"Error creating new directory: %@", [error description]);
                     } else {
                        [newDirectories addObject:keyword];
                        NSLog(@"Created new directory: %@", keyword);
                     }
                  }
                  
                  newPath = [subDirectoryPath stringByAppendingPathComponent:[photoURL lastPathComponent]];
                  
                  //Move files into directories and makes aliases for Favorites
                  if ([keyword isEqualToString:@"Favorites"]) {
                     [fileManager createSymbolicLinkAtPath:newPath withDestinationPath:currentPath error:&error];
                     if (error) {
                        NSLog(@"Error making alias: %@", [error description]);
                     } else {
                        favoritedCount++;
                     }
                  } else {
                     [fileManager moveItemAtPath:[photoURL path] toPath:newPath error:&error];
                     if (error) {
                        NSLog(@"Error moving file: %@", [error description]);
                     } else {
                        currentPath = newPath;
                        [movedFiles addObject:keyword];
                        movedCount++;
                     }
                  }
               }
               
            } else {
               NSLog(@"No keywords");
            }
         } else {
            NSLog(@"No IPTC metadata for %@", photoURL);
         }
         
      }
      
      NSAlert *alert = [[NSAlert alloc] init];
      [alert addButtonWithTitle:@"Done"];

      if (movedCount > 0) {
         NSString *alertMessage = @"";
         if (newDirectories.count > 0) {
            alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"Created %i new albums:\n", (int)newDirectories.count]];
            for (NSString *newDirectory in newDirectories) {
               alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"-%@\n", newDirectory]];
            }
         }
         
         alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"\nMoved %i photo(s) into the following albums:\n", movedCount]];
         for (NSString *albumName in [movedFiles allObjects]) {
            alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"-%@ (%i)\n", albumName, (int)[movedFiles countForObject:albumName]]];
         }
         
         if (favoritedCount > 0) {
            alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"\nMade shortcuts for %i photo(s) in the Favorites album", favoritedCount]];
         }

         [alert setMessageText:@"Your photos have been organized!"];
         [alert setInformativeText:alertMessage];
         [alert setAlertStyle:NSInformationalAlertStyle];
      } else {
         [alert setMessageText:@"Pholder Assistant did not detect any photos to organize"];
         [alert setInformativeText:@"Please make sure you have selected a directory containing new photos captured with the Pholder app, then try again."];
         [alert setAlertStyle:NSWarningAlertStyle];
      }
      [alert runModal];
   } else {
      [[NSApplication sharedApplication] terminate:nil];
   }
   
}

- (BOOL)isPhotoFile:(NSString *)file {
   NSString *fileType = [[file pathExtension] lowercaseString];
   NSArray *photoFiles = @[@"png",@"jpg",@"jpeg",@"tiff"];
   
   return [photoFiles containsObject:fileType];
}

@end
