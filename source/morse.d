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
 * Runs the module
 */
void runModule(T)(string input, T output)
{
    // If the input is full-length or longer, we repeat the pattern 3 times, so
    // that a staggered input scores closer on the levenshtein comparison.
    // If input is not full-length, don't repeat
    const size_t input_letters = input.split(' ').count;
    const size_t repeat_n = (input_letters >= 5) ? 3 : 1;

    const auto repeatedInput = input.repeat(repeat_n).joiner(" ").to!string;
    const auto repeatedMorseWords = morseCodewordDict.keys
            .map!( word => word.repeat(repeat_n).joiner(" ").to!string ).array;

    // Here, we compare the morse representation of each code word with the morse
    // provided by the user, and sort by similarity
    const auto sortedMorseWords = repeatedMorseWords
            .map!( morseWord =>
                tuple(
                    levenshteinDistance(morseWord, repeatedInput),
                    morseWord
                )
            )
            .map!( n => tuple(n[0], n[1][0..$/repeat_n]) )
            .array.sort.array;


    // Output results
    output.writeln("\n");
    output.writeln("Input:                  ", input, "\n");

    output.writeln("SCORE  WORD     FREQ    MORSE");
    foreach (morseTup; sortedMorseWords)
    {
        auto score = morseTup[0];
        auto morse = morseTup[1];
        auto codeword = morseCodewordDict[morse];
        auto freq = codewordFreqDict[codeword];

        output.writefln(" %-5d %-8s %-7s %s", score, codeword, freq, morse);
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