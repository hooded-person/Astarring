#import "@preview/cetz:0.3.2"
#import "tools/vector.typ": add as addV, sub as subV, multiply as multiplyV, divide as divideV, pow as powV, root as rootV

#let gen1DArray(width, height, fill: (), start: (0,0)) = {
  if type(fill) != "function" {
    fill = (x,y) => return fill
  }
  let array1D = ()
  for y in range(height) {
    for x in range(width) {
      array1D.push(fill(
        x + start.at(0),
        y + start.at(1),
      )) 
    }
  }
  return array1D
}

// TYPES
#let Node(pos, connection: none, walkable: true) = {
  let node = (
    pos: pos,
    connection: connection,
    getName : (self) => {
      return str(self.pos.at(0)) + "_" + str(self.pos.at(1))
    },
    walkable: walkable,
  )
  return node
}

/// Grid object that holds the nodes and provides utility functions to interact with them.
/// Auto expands using getDefNode when a node is looked up that is not in the grid.
/// -> dict
#let Grid(
  /// The width of the starting grid that will be generated -> integer
  sWidth, 
  /// The height of the starting grid that will be generated -> integer
  sHeight, 
  /// Starting offset of the grid -> array
  start: (0,0), 
  /// Wether diagonal movement is allowed -> boolean
  allowDiag: true, 
  /// Costs of certain movement directions -> dict
  costs: (
    straight: 1,
    diagonal: 1.4,
  ),
  /// Used to generate the nodes for the grid on creation -> function
  startFill: (x,y) => return Node((x,y)),
  /// called when a undefined node is looked up on the grid, should return a node. When call modifies a node this node is used as base -> function
  getDefNode: (pos) => Node(pos) 
) = {
  let grid = (
    rangeX: (start.at(0), sWidth + start.at(0)),
    rangeY: (start.at(1), sHeight + start.at(1)),
    getSize: (self) => {
      return (
        self.rangeX.at(1) - self.rangeX.at(0),
        self.rangeY.at(1) - self.rangeY.at(0),
      )
    },
    getCorners: (self) => {
      return (
        (self.rangeX.at(0), self.rangeY.at(0)),
        (self.rangeX.at(1), self.rangeY.at(1))
      )
    },
    getNeighbors: (self, node) => {
      let posNeighbors = (
        (-1, 1),(0, 1),(1, 1),
        (-1, 0),       (1, 0),
        (-1,-1),(0,-1),(1,-1) 
      ).map(posNeighbor => return addV(node.pos, posNeighbor))
        .map(posNeighbor => self.at("getNodeAt")(self, posNeighbor) )
      return posNeighbors
    },
    getNodeAt: (self, pos) => {
      let node = self.at("nodes").find(node => node.pos == pos)
      if node == none {
        node = getDefNode(pos)
      }
      return node
    },
    pushNode: (self, node) => {
      let i = self.at("nodes").position(sNode => sNode.pos == node.pos)
      if i != none {
        self.at("nodes").at(i) = node
      } else {
        self = self.at("newNode")(self, node)
      }
      return self
    },
    newNode: (self, node) => {
      let (posX, posY) = node.pos
      if posX < self.rangeX.at(0) { // lower bound
        self.rangeX.at(0) = posX
      } else if posX > self.rangeX.at(1)  { // higher boud
        self.rangeX.at(1) = posX
      }
      if posY < self.rangeY.at(0) { // lower bound
        self.rangeY.at(0) = posY
      } else if posY > self.rangeY.at(1)  { // higher boud
        self.rangeY.at(1) = posY
      }
      self.at("nodes").push(node)
      return self
    },
  )
  // constructor kinda
  let (Sx,Sy) = start
  let array1D = gen1DArray(sWidth, sHeight,
    start: start,
    fill: startFill,
  )
  grid.insert("nodes", array1D)
  
  return grid
}
// DISPLAY CODE
#let drawGrid(..args, style: (type: "square", centerOnCross: false)) = {
  let posArgs = args.pos()
  let itemGrid = posArgs.at(0)
  let path = posArgs.at(1, default: none)
  // non-pos args
  let style = (
    type: args
      .at("style",default:(:))
      .at("type", default: "square"),
    centerOnCross: args
      .at("style",default:(:))
      .at("centerOnCross", default: false),
  )

  cetz.canvas({
    import cetz.draw: *
    let corners = itemGrid.at("getCorners")(itemGrid)
    let typesCenterCross = (
      "square":(0, 0.5),
      "circle":(0, 0.5),
    )
    grid(
      ..corners.map(corner => return corner.map(c => c - typesCenterCross.at(style.type).at(int(style.centerOnCross)))),
    )
    for node in itemGrid.nodes {
      let nodeColor = if not node.walkable {gray
      } else if path == none {white
      } else if node.pos == path.first().pos {green
      } else if node.pos == path.last().pos {blue
      } else {white}
      if style.type == "circle" {
        circle(node.pos, 
          radius: .4, 
          fill: nodeColor, 
          name: "node",
        )
      } else {
        rect(
          node.pos, addV(node.pos, (1,1)), 
          fill: nodeColor, 
          name: "node",
        )
      }
      let G = node.at("G", default: calc.inf)
      let H = node.at("H", default: calc.inf)
      let F = calc.round(G + H, digits: 2)
      (G, H) = (calc.round(G, digits: 2), calc.round(H, digits: 2))
      content( ("node.north-west", 0%, "node.north-east"),
        box(fill: black, inset: 1pt,
          text(7.5pt ,white, stroke: 0.1pt + black)[#G]
        ),
        anchor: "north-west",
      )
      content( ("node.north-east", 0%, "node.north-west"), 
        box(fill: black, inset: 1pt,
          text(7.5pt, white, stroke: 0.1pt + black)[#H]
        ),
        anchor: "north-east",
      )
      content("node.center", 
        text()[#F],
      )
      content( ("node.south-west", 0%, "node.south-east"), 
        box(fill: black, inset: 1pt,
          text(7.5pt, white, stroke: 0.1pt + black)[#node.pos.at(0).#node.pos.at(1)]
        ),
        anchor: "south-west",
      )
      if path == none and node.at("connection") != none and node.pos != node.at("connection") {
        let nodeName = node.at("getName")(node)
        on-layer(1, 
          line(addV(node.at("pos"), 0.5), addV(node.at("connection"), 0.5), 
            stroke: red,
            mark: (end: (symbol: ">")),
          )
        )
      } else if path != none and path.find(pathNode => pathNode.pos == node.pos) != none {
        let pathPosition = path.position(pathNode => pathNode.pos == node.pos)
        if pathPosition + 1 < path.len() {
          on-layer(1, 
            line(addV(node.pos, 0.5), addV(path.at(pathPosition + 1).pos, 0.5), 
              stroke: red,
              mark: (end: (symbol: ">")),
            )
          )
        }
      }
    }
  })
}

// Calling display code
#let (width, height) = (6,6)
#let start = (0,-1)
#let itemGrid = Grid(width, height, 
  start: start, 
  startFill: (x,y) => {
      let node = Node((x, y), walkable: calc.rem(y,2) == 0)
      node.G = x
      node.H = y
      return node
    }
)
#(itemGrid = itemGrid.at("pushNode")(itemGrid, Node((1,1), walkable: false)))

#drawGrid(itemGrid)

#let (positions, duplicates) = ((:), (:))
#for node in itemGrid.nodes {
  let nodeName = node.at("getName")(node)
  if positions.at(nodeName, default: false) {
    duplicates.insert(nodeName, true)
  }
  positions.insert(nodeName, true)
}

#let dupeData = itemGrid.nodes

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