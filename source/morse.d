/**
 * This module implements a morse code solver. 
 *
 * Given a string of characters mapping to the morse code message, the module
 * will search for exact matches, and if none can be found, will resort to
 * guessing the word based off of likely transcription errors or 
 */
module morse;

import std.algorithm;
import std.array;
import std.conv;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;



/**
 * Runs the module, returning a range of sorted matches in the form:
 *     tuple(score, morse, word, freq)
 */
auto runModule(string rawInput)
{
    /// Process the raw input so we
    auto inputLetters = rawInput.splitter(' ')
        .filter!(a => !a.empty)
        .map!(a => a.strip)
        .array;
    string input = inputLetters.joiner(" ").to!string;
    
    // Calculates the minimal levenshtein distance between `b` and any substring
    // of `a`.
    // If `wrap` is true, considers the case where `b` might span from the end of
    // `a` to the start of `a`.
    auto minimalDistance(T,U)(T a, U b, bool wrap=true)
    {
        return a
            .repeat( wrap ? 2 : 1 )
            .joiner
            .take(a.length + b.length - 1)
            .slide(b.length)
            .map!(str => str.to!string.levenshteinDistance(b))
            .minElement;
    }

    // Here, we compare the morse representation of each code word with the morse
    // provided by the user, and sort by similarity
    auto sortedMorseWords = morseCodewordDict.keys
            .map!(delegate(morse) {
                auto english = morseCodewordDict[morse];
                return tuple!("score","morse","word","freq")(
                    minimalDistance(morse, input),
                    morse,
                    english,
                    codewordFreqDict[english]
                );
            })
            .array
            .sort;

    return sortedMorseWords;
}

/// Runs the module, printing a summary to `output`
void runModule(T)(string rawInput, T output)
{
    auto matches = runModule(rawInput);

    // Output results
    output.writeln("SCORE  WORD     FREQ    MORSE");
    foreach (match; matches)
    {
        output.writefln(" %-5d %-8s %-7s %s",
            match.score,
            match.word,
            match.freq,
            match.morse);
    }
}

/// Maps english letters to their Morse representation
enum string[char] letterMorseDict = [
    'A': ".-",      'B': "-...",
    'C': "-.-.",    'D': "-..",
    'E': ".",       'F': "--.",
    'G': "--.",     'H': "....",
    'I': "..",      'J': ".---",
    'K': "-.-",     'L': ".-..",
    'M': "--",      'N': "-.",
    'O': "---",     'P': ".--.",
    'Q': "--.-",    'R': ".-.",
    'S': "...",     'T': "-",
    'U': "..-",     'V': "...-",
    'W': ".--",     'X': "-..-",
    'Y': "-.--",    'Z': "--..",
    '0': "-----",   '1': ".----",
    '2': "..---",   '3': "...--",
    '4': "....-",   '5': ".....",
    '6': "-....",   '7': "--...",
    '8': "---..",   '9': "----.",
    ' ': " "
];

/// Maps word to frequency. Table from the KTANE manual
enum string[string] codewordFreqDict = [
    "shell":    "3.505",
    "halls":    "3.515",
    "slick":    "3.522",
    "trick":    "3.532",
    "boxes":    "3.535",
    "leaks":    "3.542",
    "strobe":   "3.545",
    "bistro":   "3.552",
    "flick":    "3.555",
    "bombs":    "3.565",
    "break":    "3.572",
    "brick":    "3.575",
    "steak":    "3.582",
    "sting":    "3.592",
    "vector":   "3.595",
    "beats":    "3.600"
];

/// Maps morse representation to codeword. Generated from codewordFreqDict
enum string[string] morseCodewordDict = codewordFreqDict.keys
    .map!( key => tuple(
        key.textToMorse(true),
        key)
    ).assocArray;

/// Given the text in english, return a string of text in morse code
/// If `addSpace` is true, a space will be inserted between each letter
string textToMorse(string text, bool addSpace=false)
{
    string joinChar = addSpace ? " " : "";
    return text.map!( c => letterMorseDict[c.toUpper.to!char] ).joiner(joinChar).to!string;
}