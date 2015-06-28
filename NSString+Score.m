//
//  NSString+Score.m
//
//  Created by Nicholas Bruning on 5/12/11.
//  Copyright (c) 2011 Involved Pty Ltd. All rights reserved.
//

//String Score reference: http://jsfiddle.net/JrLVD/

#import "NSString+Score.h"

@implementation NSString (Score)

- (CGFloat) scoreAgainst:(NSString *)otherString{
    return [self scoreAgainst:otherString fuzziness:nil];
}

- (CGFloat) scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness{
    return [self scoreAgainst:otherString fuzziness:fuzziness options:NSStringScoreOptionNone];
}

- (NSMutableCharacterSet*)invalidCharacterSet {
    static NSMutableCharacterSet *invalidCharacterSet = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^{
        invalidCharacterSet = NSMutableCharacterSet.controlCharacterSet;
        [invalidCharacterSet formUnionWithCharacterSet:NSCharacterSet.illegalCharacterSet];
        [invalidCharacterSet formUnionWithCharacterSet:NSCharacterSet.symbolCharacterSet];
    });
    
    return invalidCharacterSet;
}

unichar getCharacter(NSString *a, NSUInteger i) {
    unichar buffer[1];
    [a getCharacters:buffer range:NSMakeRange(i, 1)];
    return buffer[0];
}

- (CGFloat)scoreWithOriginalAlgorithmAgainst:(NSString *)anotherString fuzziness:(NSNumber *)fuzziness options:(NSStringScoreOptions)options{
    if(!anotherString) return (CGFloat) 0.0f;
    
    NSString *string = [[self.decomposedStringWithCanonicalMapping componentsSeparatedByCharactersInSet:self.invalidCharacterSet] componentsJoinedByString:@""];
    NSString *otherString = [[anotherString.decomposedStringWithCanonicalMapping componentsSeparatedByCharactersInSet:self.invalidCharacterSet] componentsJoinedByString:@""];
    
    // If the string is equal to the abbreviation, perfect match.
    if ([string isEqualToString:otherString]) return (CGFloat) 1.0f;
    
    //if it's not a perfect match and is empty return 0
    if (otherString.length == 0) return (CGFloat) 0.0f;
    
    CGFloat runningScore = 0.0f;
    CGFloat characterScore = 0.0f;
    CGFloat totalScore = 0.0f;
    CGFloat fuzzyFactor = 0.0f;
    NSUInteger fuzzies = 1;
    
    const unichar space = [@" " characterAtIndex:0];
    
    NSString *lowerStr = string.lowercaseString;
    NSString *lowerOtherStr = otherString.lowercaseString;
    
    unsigned long otherLen = otherString.length;
    unichar buffer[otherLen+1];
    [otherString getCharacters:buffer range:NSMakeRange(0, otherLen)];
    
    if (fuzziness) fuzzyFactor = 1 - fuzziness.floatValue;
    
    for (int i = 0; i < otherLen; i++) {
        NSRange r = [lowerStr rangeOfString:[lowerOtherStr substringFromIndex:i] options:NSCaseInsensitiveSearch];
        
        if (r.location == NSNotFound) {
            
            if (fuzziness) {
                fuzzies += fuzzyFactor;
            } else {
                return 0;
            }
        } else {
            if (i == r.location) {
                // Consecutive letter & start-of-string Bonus
                characterScore = 0.7;
                
            } else {
                characterScore = 0.1;
                
                // Acronym Bonus
                // Weighing Logic: Typing the first character of an acronym is as if you
                // preceded it with two perfect character matches.
                if (getCharacter(string, r.location-1) == space) characterScore += 0.8;
            }
        }
        
        // Same case bonus.
        if (r.location != NSNotFound && getCharacter(string, r.location) == buffer[i]) characterScore += 0.1;
        
        // Update scores and startAt position for next round
        runningScore += characterScore;
    }
    
    // Reduce penalty for longer strings.
    if (NSStringScoreOptionReducedLongStringPenalty == (options & NSStringScoreOptionReducedLongStringPenalty)) {
        totalScore = ((runningScore/string.length) + (runningScore/otherLen)) / fuzzies;
    }
    
    if ((getCharacter(lowerOtherStr,0) == getCharacter(lowerStr,0)) && (totalScore < 0.85)) totalScore += 0.15;
    
    return totalScore;
}

- (CGFloat) scoreAgainst:(NSString *)anotherString fuzziness:(NSNumber *)fuzziness options:(NSStringScoreOptions)options{
    if(!anotherString) return (CGFloat) 0.0f;
    
    NSString *string = [[self.decomposedStringWithCanonicalMapping componentsSeparatedByCharactersInSet:self.invalidCharacterSet] componentsJoinedByString:@""];
    NSString *otherString = [[anotherString.decomposedStringWithCanonicalMapping componentsSeparatedByCharactersInSet:self.invalidCharacterSet] componentsJoinedByString:@""];
    
    // If the string is equal to the abbreviation, perfect match.
    if([string isEqualToString:otherString]) return (CGFloat) 1.0f;
    
    //if it's not a perfect match and is empty return 0
    if(otherString.length == 0) return (CGFloat) 0.0f;
    
    CGFloat totalCharacterScore = 0;
    NSUInteger otherStringLength = otherString.length;
    NSUInteger stringLength = string.length;
    BOOL startOfStringBonus = NO;
    CGFloat otherStringScore;
    CGFloat fuzzies = 1;
    CGFloat finalScore;
    
    NSString *otherUpper = otherString.uppercaseString;
    NSString *otherLower = otherString.lowercaseString;
    
    CGFloat fuzzinessFloat = fuzziness? fuzziness.floatValue : 0.0f;
    
    const unichar space = [@" " characterAtIndex:0];
    
    // Walk through abbreviation and add up scores.
    for(uint index = 0; index < otherStringLength; index++){
        CGFloat characterScore = 0.1;
        NSInteger indexInString = NSNotFound;
        NSRange rangeChrLowercase;
        NSRange rangeChrUppercase;
        
        unichar chr = [otherString characterAtIndex:index];
        
        NSRange r = NSMakeRange(index, 1);
        NSString *lowerChr = [otherLower substringWithRange:r];
        NSString *upperChr = [otherUpper substringWithRange:r];
        
        //make these next few lines leverage NSNotFound, methinks.
        rangeChrLowercase = [string rangeOfString:lowerChr];
        rangeChrUppercase = [string rangeOfString:upperChr];
        
        if(rangeChrLowercase.location == NSNotFound && rangeChrUppercase.location == NSNotFound){
            if(fuzziness){
                fuzzies += 1 - fuzzinessFloat;
            } else {
                return (CGFloat) 0.0f; // this is an error!
            }
            
        } else if (rangeChrLowercase.location != NSNotFound && rangeChrUppercase.location != NSNotFound){
            indexInString = MIN(rangeChrLowercase.location, rangeChrUppercase.location);
            
        } else if(rangeChrLowercase.location != NSNotFound || rangeChrUppercase.location != NSNotFound){
            indexInString = rangeChrLowercase.location != NSNotFound ? rangeChrLowercase.location : rangeChrUppercase.location;
            
        } else {
            indexInString = MIN(rangeChrLowercase.location, rangeChrUppercase.location);
            
        }
        
        // Set base score for matching chr
        
        if (indexInString != NSNotFound) {
            if (getCharacter(string,indexInString) == chr) characterScore += 0.1;
            
            // Consecutive letter & start-of-string bonus
            if(indexInString == 0){
                // Increase the score when matching first character of the remainder of the string
                characterScore += 0.6;
                if(index == 0){
                    // If match is the first character of the string
                    // & the first character of abbreviation, add a
                    // start-of-string match bonus.
                    startOfStringBonus = YES;
                }
            } else {
                // Acronym Bonus
                // Weighing Logic: Typing the first character of an acronym is as if you
                // preceded it with two perfect character matches.
                if(getCharacter(string,indexInString-1) == space) characterScore += 0.8;
            }
            
            // Left trim the already matched part of the string
            // (forces sequential matching).
            string = [string substringFromIndex:indexInString + 1];
        }
        
        totalCharacterScore += characterScore;
    }
    
    if(NSStringScoreOptionFavorSmallerWords == (options & NSStringScoreOptionFavorSmallerWords)){
        // Weigh smaller words higher
        return totalCharacterScore / stringLength;
    }
    
    otherStringScore = totalCharacterScore / otherStringLength;
    
    if(NSStringScoreOptionReducedLongStringPenalty == (options & NSStringScoreOptionReducedLongStringPenalty)){
        // Reduce the penalty for longer words
        CGFloat percentageOfMatchedString = otherStringLength / stringLength;
        CGFloat wordScore = otherStringScore * percentageOfMatchedString;
        finalScore = (wordScore + otherStringScore) / 2;
        
    } else {
        finalScore = ((otherStringScore * ((CGFloat)(otherStringLength) / (CGFloat)(stringLength))) + otherStringScore) / 2;
    }
    
    finalScore = finalScore / fuzzies;
    
    if (startOfStringBonus && finalScore + 0.15 < 1) finalScore += 0.15;
    
    return finalScore;
}

- (float)levenshteinDistanceToString:(NSString *)comparisonString {
    // Normalize strings
    NSString *originalString = self;
    [originalString stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
    [comparisonString stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
    
    originalString = originalString.lowercaseString;
    comparisonString = comparisonString.lowercaseString;
    
    // Step 1
    NSInteger k, i, j, cost, * d, distance;
    
    NSInteger n = originalString.length;
    NSInteger m = comparisonString.length;
    
    if (n == 0) {
        //edit distance is the entire length of the new string
        return m;
    }
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(NSInteger) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
                                            andOf: d[ j * n + i - 1 ] +  1
                                            andOf: d[ (j - 1) * n + i - 1 ] + cost ];
                
                // This conditional adds Damerau transposition to Levenshtein distance
                if( i>1 && j>1 && [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-2] &&
                   [originalString characterAtIndex: i-2] ==
                   [comparisonString characterAtIndex: j-1] )
                {
                    d[ j * n + i] = MIN(d[ j * n + i ], d[ (j - 2) * n + i - 2 ] + cost);
                }
            }
        
        distance = d[ n * m - 1 ];
        
        free(d);
        
        return distance;
    }
    return 0.0;
}

// Return the minimum of a, b and c - used by compareString:withString:
- (NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b andOf:(NSInteger)c {
    return MIN(a, MIN(b, c));
}

@end
