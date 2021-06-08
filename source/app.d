import std.stdio;
import maze;
import morse;

void main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Please specify a module to run");
        return;
    }

    switch (args[1])
    {
    case "maze":
        if (args.length >= 5)
        {
            maze.runModule(args[2..5], stdout);
            return;
        }
        string[] input;
        writeln("Location of marker:");
        input ~= readln();
        writeln("Current Position: ");
        input ~= readln();
        writeln("Target Position: ");
        input ~= readln();
        maze.runModule(input, stdout);
        return;

    case "morse":
        if (args.length >= 3)
        {
            import std.algorithm : joiner;
            import std.conv : to;
            morse.runModule(args[2..$].joiner(" ").to!string, stdout);
            return;
        }
        writeln("Morse transcription: ");
        string input = readln();
        morse.runModule(input, stdout);
        return;

    default:
        writeln("Unrecognized module \"" ~ args[0] ~ "\"");
    }
}
