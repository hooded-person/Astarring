#import "grid.typ": Grid, Node, drawGrid
#import "tools/vector.typ": add as addV, sub as subV, multiply as multiplyV, divide as divideV, pow as powV, root as rootV

#set page(height: auto)

/// Calculate the heuristic distance from `current` to `target`.
/// -> integer | float
#let getDistance(
  /// The node from which to calculate the distance. -> dict
  current, 
  /// The node too which to calculate the distance. -> dict
  target
) = {
  let disX = calc.abs(target.pos.at(0) - current.pos.at(0))
  let disY = calc.abs(target.pos.at(1) - current.pos.at(1))
  let disDiag = 0
  while disX > 0 and disY > 0 {
    let disToDiag = 0
    if disX < disY {
      disToDiag = disX
    } else {
      disToDiag = disY
    }
    disX = disX - disToDiag
    disY = disY - disToDiag
    disDiag = disDiag + disToDiag
  }
  let totalDistance = disX + disY + 1.4 * disDiag
  return totalDistance
}
/// Gets the value of key for a node.
/// -> any
#let getV(
  node, 
  key
) = {
  return node.at(key, default: calc.inf)
}
/// sets the G value of a node.
/// -> dict
#let setG(
  /// The node for which to set the G value. -> dict
  node, 
  /// New G value. -> integer | float
  G,
) = {
  node.insert("G", G)
  node.insert("F",  getV(node, "G") +  getV(node, "H") )
  return node
}
/// sets the H value of a node.
/// -> dict
#let setH(
  /// The node for which to set the H value. -> dict
  node, 
  /// New H value. -> integer | float
  H,
) = {
  node.insert("H", H)
  node.insert("F",  getV(node, "G") +  getV(node, "H") )
  return node
}
/// Gets the F value of a node by adding the G value and H value together.
/// -> integer | float
#let getF(
  /// The node for which to get the F value. -> dict
  node
) = {
  return node.G + node.H
}

/// Calculates the best path from `startNode` to `targetNode` across `grid` using the A* search algorithm. Returns the grid with connections as first arg and the path as second arg.
/// -> grid, array
#let findPath(
  /// The grid across which to find the path. -> dict
  grid, 
  /// The starting node. -> dict
  startNode, 
  /// The target node. -> dict
  targetNode
) = {
  startNode = setG(startNode, 0)
  startNode = setH(startNode, getDistance(startNode, targetNode))
  grid = grid.at("pushNode")(grid, startNode)
  let toSearch = (startNode,)
  let processed = ()

  while (toSearch.len() > 0) {
    let current = toSearch.at(0)
    for node in toSearch {
      if getF(node) < getF(current) or getF(node) == getF(current) and node.H < current.H {
        current = node
      }
    }
    let curI = toSearch.position(node => node == current)
    toSearch.remove(curI)

    if current.at("pos") == targetNode.at("pos") {
      let currentPathTile = current
      let path = ()
      while (currentPathTile.at("pos") != startNode.at("pos")) {
        path.push(currentPathTile)
        currentPathTile = grid.at("getNodeAt")(grid, currentPathTile.connection)
      }
      path.push(currentPathTile)
      return (grid, path.rev())
    }

    for neighbor in grid.at("getNeighbors")(grid, current).filter(node => node.walkable and processed.find(processedNode => node.pos == processedNode.pos) == none ) {
      let inSearch = toSearch.contains( node => node.pos == neighbor.pos)
      let costToNeighbor = current.G + getDistance(current, neighbor)
      
      if (not inSearch or costToNeighbor <  getV(neigbor, "G")) {
        neighbor = setG(neighbor, costToNeighbor)
        neighbor.at("connection") = current.at("pos")
        
        if not inSearch {
          neighbor = setH(neighbor, getDistance(neighbor, targetNode))
          toSearch.push(neighbor)
        }
        grid = grid.at("pushNode")(grid, neighbor)
      }
    }
    
    processed.push(current)
  }
  return (grid, none)
}
// DEMO AND TESTING
#let grid = Grid(10,10, 
  startFill: (x,y)=> Node((x,y), walkable: y != 4)
) // Setting up the grid
#let (grid, foundPath) = findPath(grid, Node((0,0)),Node((2,5))) // Finding the path

// Drawing the grid and path
#drawGrid(grid, foundPath)

// Check for duplicate nodes for bug fixing purposes
#let (positions, duplicates) = ((:), (:))
#for node in grid.nodes {
  let nodeName = node.at("getName")(node)
  if positions.at(nodeName, default: false) {
    duplicates.insert(nodeName, true)
  }
  positions.insert(nodeName, true)
}

#let dupeData = grid.nodes

#(dupeData = dupeData.filter(node => duplicates.at(node.at("getName")(node), default: false)))
#(dupeData = dupeData.map(node => {
  return (
    [pos: #node.pos\ ],
    [connection: #node.connection\ ],
    table.cell(fill: if not node.walkable {gray} else {white})[walk: #node.walkable\ ],
    table.cell(fill: if duplicates.at(node.at("getName")(node), default: false) {red} else {white})[name: #node.at("getName")(node)\ ],
    [#node.at("G", default: calc.inf)],
    [#node.at("H", default: calc.inf)],
    [#calc.round(digits: 2,
      node.at("F", default: calc.inf)
      )]
  )
}))
#show table.cell.where(y: 0): strong
#table(columns: (auto,auto,auto,auto,30pt,30pt,30pt), table.header(
    [pos], [connection], [walkable], [name],[G],[H],[F]
  ),
  ..dupeData.flatten(),
)