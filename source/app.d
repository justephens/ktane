import std.stdio;
import std.range;
import std.algorithm;
import std.array;
import std.string;
import std.conv;
import maze;

/// Read a coordinate pair from stdin
Maze.Coord readCoords()
{
    int[2] arr = readln()
        .split(',')
        .take(2)
        .map!( a => a.strip )
        .map!( a => a.parse!int )
        //.map!( n => n++ )     // Uncomment to use start-from-one indexing
        //.retro                // Uncomment to use "x,y" instead of "y,x"
        .array;
    return arr;
}

void main()
{
    // Generate Maze objects from the ASCII TextMaps
    Maze[] mazes;
    builtInMaps.each!( tm => mazes ~= new Maze(tm) );

    writeln("Welcom to the KTANE Maze solver...");
    writeln("Use \"row,col\", 0-indexed...");
    writeln();


    // Get location of any marker (all built-in KTANE mazes have unique markers)
    writeln("Location of marker:");
    int[2] markerPos = readCoords();


    // Find any mazes containing marker nodes matching the provided coordinates
    auto matchingMazes = mazes.filter!(
            maze => maze.markers.any!(
                mark => mark.position == markerPos
            )
        );
    if (matchingMazes.count != 1)
        throw new Exception("Found more or less than 1 matching maze");
    

    // Select matching maze, output it's text map
    Maze maze = matchingMazes.front;
    maze.textMap[]
        .joiner("\n")
        .to!string
        .writeln();


    // Ask for start and end coords
    writeln("Current Position: ");
    int[2] startPos = readCoords();
    writeln("Target Position: ");
    int[2] targetPos = readCoords();


    // Solve maze and write instructions
    maze.solveToSteps(startPos, targetPos).writeln();
}
