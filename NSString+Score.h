//
//  NSString+Score.h
//
//  Created by Nicholas Bruning on 5/12/11.
//  Copyright (c) 2011 Involved Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_OPTIONS(NSUInteger, NSStringScoreOptions) {
    NSStringScoreOptionNone                         = 1 << 0,
    NSStringScoreOptionFavorSmallerWords            = 1 << 1,
    NSStringScoreOptionReducedLongStringPenalty     = 1 << 2
};

@interface NSString (Score)

- (CGFloat) scoreAgainst:(nonnull NSString *)otherString;
- (CGFloat) scoreAgainst:(nonnull NSString *)otherString fuzziness:(nullable NSNumber *)fuzziness;
- (CGFloat) scoreAgainst:(nonnull NSString *)otherString fuzziness:(nullable NSNumber *)fuzziness options:(NSStringScoreOptions)options;
- (CGFloat) scoreWithOriginalAlgorithmAgainst:(nonnull NSString *)otherString fuzziness:(nullable NSNumber *)fuzziness options:(NSStringScoreOptions)options;

- (float)levenshteinDistanceToString:(nonnull NSString *)comparisonString;

@end
