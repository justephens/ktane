import std.algorithm;
import std.array;
import std.container.dlist;
import std.conv;
import std.range;
import std.string;
import std.stdio;

/**
 * Runs the maze solver.
 * param: input - a range of lines, each line holding a comma-separated
 *      coordinate pair
 * param: output - an output range which text is written to
 */
void runModule(T)(string[] input, T output)
{
    // Generate Maze objects from the ASCII TextMaps
    Maze[] mazes;
    builtInMaps.each!( tm => mazes ~= new Maze(tm) );

    // Read sets of coordinate pairs from input
    int[][] coordinates = input
        .map!(line => line
            .split(',')
            .take(2)
            .map!( a => a.strip )
            .map!( a => a.parse!int )
            //.map!( n => n++ )     // Uncomment to use start-from-one indexing
            //.retro                // Uncomment to use "x,y" instead of "y,x"
            .array
        )
        .array;

    auto markerPos = coordinates[0].to!(int[2]);
    auto startPos = coordinates[1].to!(int[2]);
    auto targetPos = coordinates[2].to!(int[2]);

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
    output.writeln(maze.textMap[].joiner("\n"));

    // Solve maze and write instructions
    output.writeln(maze.solveToSteps(startPos, targetPos));
}

/++
 + A KTANE Maze.
 +/
class Maze
{
    alias Coord = int[2];
    alias TextMap = string[13];

    /++
     + Represents a Node in the map
     +/
    class Node
    {
        /// int[2] containing the [y,x] position of this Node
        Coord position;
        /// List of references to neighboring Nodes
        Node[] neighbors;
        /// Used in pathfinding. References the preceding node in the path.
        Node pathParent = null;

        /// Creates a Node with the given position
        this(T)(T[2] pos)
        {
            position = pos.to!Coord;
            neighbors.reserve(4);
        }

        override string toString() const
        {
            return "{" ~ position.to!string ~ " -> " ~ neighbors.map!(n => n.position.to!string).join(", ") ~ "}";
        }

        /// Returns a range of the nodes in the path tracing from this node to
        /// the path's origin node.
        auto path()
        {
            struct MazeNodePathRange
            {
                Node current;
                bool empty() { return (current is null); }
                auto front() { return current; }
                void popFront() { current = current.pathParent; }
                auto save() { return this; }
            }

            return MazeNodePathRange(this);
        }
    }

    /// Grid contains the 6x6 array of tiles in the map
    Node[6][6] grid;
    /// Markers are nodes on the map used to identify the map
    Node[] markers;
    /// A reference to the original text map used to generate this maze, if an
    TextMap textMap;

    /// Initialize an empty map of 6x6 nodes
    this()
    {
        foreach(y, ref row; grid)
            foreach(x, ref node; row)
                node = new Node([y,x]);
    }
    /// Initializes a Maze from the text map given
    this(TextMap map)
    {
        this();
        foreach(y, ref row; grid)
        {
            foreach(x, ref node; row)
            {
                if (map[y*2][x*2+1] != '-')     node.neighbors ~= grid[y-1][x];
                if (map[y*2+1][x*2+2] != '|')   node.neighbors ~= grid[y][x+1];
                if (map[y*2+2][x*2+1] != '-')   node.neighbors ~= grid[y+1][x];
                if (map[y*2+1][x*2] != '|')     node.neighbors ~= grid[y][x-1];

                if (map[y*2+1][x*2+1] == '0')   markers ~= node;
            }
        }
        textMap = map;
    }

    /// Finds a path from (start) to (target) and returns the target Node, with
    /// path being traced backward to the starting point via Node.pathParent
    Node solve(Coord start, Coord target)
    {
        DList!Node openList = [grid[start[0]][start[1]]];
        DList!Node closedList;

        while (true)
        {
            foreach (node; openList)
            {
                // Return this node if the target is found
                if (node.position == target) return node;

                // Add all neighbors of this node to the open list, if those
                // neighbors are not on the closed list
                foreach (neighbor; node.neighbors)
                {
                    if (closedList[].canFind(neighbor)) continue;
                    neighbor.pathParent = node;
                    openList.insertBack(neighbor);
                }
                
                // Move this node from the open to closed list
                openList.removeFront(1);
                closedList.insertBack(node);
            }
        }
    }

    /// similar to `solve`, but returns string range containing a list of steps
    /// to take in order to navigate from `start` to `target`
    auto solveToSteps(Coord start, Coord target)
    {
        import std.range : slide, retro;
        import std.algorithm : map, joiner;

        Node node = solve(start, target);

        // Step through nodes in pairs and calculate the deltas between their
        // coordinates
        int[2][] deltas; 
        foreach(pair; node.path.slide(2))
        {
            auto a = pair.front();
            pair.popFront();
            auto b = pair.front();

            int[2] delta = a.position[] - b.position[];
            deltas ~= delta;
        }

        // Convert deltas into english text, merge into a continuous string
        return deltas
            .retro
            .map!(
                a => a.predSwitch!"a==b"(
                    [0,1],  "Right",
                    [0,-1], "Left",
                    [-1,0], "Up",
                    [1,0],  "Down"
                )
            )
            .joiner(" ");
    }
}

/// An array of text maps for all built-in KTANE maze layouts
immutable Maze.TextMap[9] builtInMaps = [
	[
		"-------------",
		"|     |     |",
		"| |-| | |-|-|",
		"|0|   |     |",
		"| | |-|-|-| |",
		"| |   |    0|",
		"| |-| | |-| |",
		"| |     |   |",
		"| |-|-|-|-| |",
		"|     |   | |",
		"| |-| | |-| |",
		"|   |   |   |",
		"-------------",
	],
	[
		"-------------",
		"|     |     |",
		"|-| |-| | |-|",
		"|   |   |0  |",
		"| |-| |-|-| |",
		"| |   |     |",
		"| | |-| |-| |",
		"|  0|   | | |",
		"| |-| |-| | |",
		"| | | |   | |",
		"| | | | |-| |",
		"| |   |     |",
		"-------------",
	],
	[
		"-------------",
		"|     | |   |",
		"| |-| | | | |",
		"| | | |   | |",
		"|-| | |-|-| |",
		"|   | |   | |",
		"| | | | | | |",
		"| | | |0| |0|",
		"| | | | | | |",
		"| |   | | | |",
		"| |-|-| | | |",
		"|       |   |",
		"-------------",
	],
	[
		"-------------",
		"|0  |       |",
		"| | |-|-|-| |",
		"| | |       |",
		"| | | |-|-| |",
		"| |   |   | |",
		"| |-|-| |-| |",
		"|0|         |",
		"| |-|-|-|-| |",
		"|         | |",
		"| |-|-|-| | |",
		"|     |   | |",
		"-------------",
	],
	[
		"-------------",
		"|           |",
		"|-|-|-|-| | |",
		"|         | |",
		"| |-|-| |-|-|",
		"|   |   |0  |",
		"| | |-|-| | |",
		"| |     | | |",
		"| |-|-| |-| |",
		"| |       | |",
		"| | |-|-|-| |",
		"| |    0    |",
		"-------------",
	],
	[
		"-------------",
		"| |   |  0  |",
		"| | | |-| | |",
		"| | | |   | |",
		"| | | | |-| |",
		"|   | | |   |",
		"| |-|-| | |-|",
		"|   |   | | |",
		"|-| | | | | |",
		"|   |0| |   |",
		"| |-|-| |-| |",
		"|       |   |",
		"-------------",
	],
	[
		"-------------",
		"|  0    |   |",
		"| |-|-| | | |",
		"| |   |   | |",
		"| | |-|-|-| |",
		"|   |   |   |",
		"|-|-| |-| |-|",
		"|   |     | |",
		"| | | |-|-| |",
		"| | |     | |",
		"| |-|-|-| | |",
		"|  0        |",
		"-------------",
	],
	[
		"-------------",
		"| |    0|   |",
		"| | |-| | | |",
		"|     |   | |",
		"| |-|-|-|-| |",
		"| |       | |",
		"| | |-|-| | |",
		"| |  0|     |",
		"| |-| |-|-|-|",
		"| | |       |",
		"| | |-|-|-|-|",
		"|           |",
		"-------------",
	],
	[
		"-------------",
		"| |         |",
		"| | |-|-| | |",
		"| | |0  | | |",
		"| | | |-| | |",
		"|     |   | |",
		"| |-|-| |-| |",
		"| | |   |   |",
		"| | | |-|-| |",
		"|0| | |   | |",
		"| | | | | |-|",
		"|   |   |   |",
		"-------------",
	],
];