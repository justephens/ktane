module ui;

import std.string;
import std.functional : toDelegate;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import std.math;

import qui.qui;
import qui.widgets;


 
/// Root element for QUI library elements
private QTerminal term;
private EditLineWidget prompt;

/// Triggers the UI module to run
static void run()
{
    // Register a function to respond to interrupt signals
    import core.stdc.signal : signal, SIGINT;
    extern(C) void stopRun(int a) nothrow @nogc @system
    {
        term.terminate();
    }
    signal(SIGINT, &stopRun);

    // Baseline widget
    term = new QTerminal(QLayout.Type.Vertical);
    prompt = new EditLineWidget();
    term.addWidget(prompt);

    prompt.onKeyboardEvent = toDelegate(&selectionCallback);

    // Enter UI loop
    term.run();
}

/// The callback used when selecting modules
bool selectionCallback(QWidget caller, KeyboardEvent event)
{
    if (event.key == 10)
    {
        term.terminate();
        const dstring input = prompt.text.strip;
        prompt.text = "";

        switch(input)
        {
        case "maze":
            runMaze();
            break;
        case "morse":
            morseWidgets();
            break;
        default:
            prompt.text = null;
        }

        term.run();
    }
    return false;
}

static void runMaze()
{
}

/// Generates widgets to run morse code
static void morseWidgets()
{
    import morse;
    import std.stdio : stdout;

    // Initialize widgets to have enough space to list every result
    auto lineCount = morse.codewordFreqDict.length;

    // Layout containers
    QLayout vsplit = new QLayout(QLayout.Type.Horizontal);
    QLayout labelLayout = new QLayout(QLayout.Type.Vertical);
    QLayout scoreBarLayout = new QLayout(QLayout.Type.Vertical);
    QLayout resultsLayout = new QLayout(QLayout.Type.Vertical);
    LogWidget log = new LogWidget();

    // Display widgets
    TextLabelWidget[] labels = new TextLabelWidget[](lineCount);
    ProgressbarWidget[] scorebars = new ProgressbarWidget[](lineCount);
    TextLabelWidget[] results = new TextLabelWidget[](lineCount);
    foreach(i; 0..lineCount)
    {
        labels[i] = new TextLabelWidget();
        labels[i].textColor = Color.white;
        labels[i].backgroundColor = Color.DEFAULT;
        labelLayout.addWidget(labels[i]);

        scorebars[i] = new ProgressbarWidget();
        scorebars[i].max = 100;
        scorebars[i].size.maxHeight = 1;
        scorebars[i].backgroundColor = Color.black;
        scoreBarLayout.addWidget(scorebars[i]);

        results[i] = new TextLabelWidget();
        results[i].backgroundColor = Color.DEFAULT;
        resultsLayout.addWidget(results[i]);
    }

    vsplit.addWidget([labelLayout, scoreBarLayout, resultsLayout]);
    term.addWidget(vsplit);

    // Set up callback to process input live and output score
    bool KeyBoardUpdate(QWidget caller, KeyboardEvent event)
    {
        if (prompt.text.strip.empty) return false;

        auto matches = morse.runModule(prompt.text.to!string);
        auto maxLen = matches.map!(m => m.morse.length).maxElement;
        auto maxScore = max(matches.map!(m => m.score).maxElement, 1);

        auto getConfidence(T)(T match) {
            return
                (((cast(float)prompt.text.strip.length / match.length)  // ratio of input length to dictionary
                * (cast(float)(maxScore - match.score) / maxScore))     // ratio of current score out of max
                * 100)
                .clamp(0, 100);
        }
        
        labelLayout.size.minWidth = maxLen + 9;
        resultsLayout.size.minWidth = 10;

        int i = 0;
        foreach(match; matches)
        {
            if (i > lineCount) throw new Exception("Uhhhh");
            labels[i].caption = to!dstring(match.morse.padRight(' ', maxLen + 2).to!string ~ match.word);

            auto score = getConfidence(match);
            scorebars[i].progress = cast(int)score;
            scorebars[i].barColor = score.predSwitch!"a<b"(
                    40, Color.red,
                    70, Color.yellow,
                    Color.green);
            
            results[i].caption = to!dstring("  "
                    .chain(match.score.to!string.padRight(' ', 4))
                    .chain(match.freq.to!string));
            i++;
        }
        return false;
    }

    prompt.onKeyboardEvent = &KeyBoardUpdate;
}
