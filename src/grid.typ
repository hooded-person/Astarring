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

#let Grid(sWidth, sHeight, 
  start: (0,0), 
  allowDiag: true, 
  costs: (
    straight: 1,
    diagonal: 1.4,
  ),
  getDefNode: (pos) => Node(pos) // called when a undefined node is looked up on the grid, should return a node. When call modifies a node this node is used as base
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
        self.at("nodes").insert(i, node)
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
    fill: (x,y) => return Node((x, y), walkable: calc.rem(y,2) == 0),
  )
  grid.insert("nodes", array1D)
  
  return grid
}
// DISPLAY CODE
#let itemGrid = Grid(width, height, start: start)

#let drawGrid(..args) = {
  let posArgs = args.pos()
  let itemGrid = posArgs.at(0)
  let path = posArgs.at(1, default: none)

  cetz.canvas({
    import cetz.draw: *
    grid(
      ..itemGrid.at("getCorners")(itemGrid)
    )
    for node in itemGrid.nodes {
      let nodeColor = if not node.walkable {gray
      } else if path == none {white
      } else if node.pos == path.first().pos {green
      } else if node.pos == path.last().pos {blue
      } else {white}
      circle(node.pos, radius: .4, fill: nodeColor, name: "node")
      let G = node.at("G", default: calc.inf)
      let H = node.at("H", default: calc.inf)
      let F = calc.round(G + H, digits: 2)
      (G, H) = (calc.round(G, digits: 2), calc.round(H, digits: 2))
      content("node.north-west", 
        box(fill: black, inset: 1pt,
          text(7.5pt ,white, stroke: 0.1pt + black)[#G]
        ),
        align: "left",
      )
      content("node.north-east", 
        box(fill: black, inset: 1pt,
          text(7.5pt, white, stroke: 0.1pt + black)[#H]
        ),
        align: "right",
      )
      content("node.center", 
        text()[#F],
      )
      if path == none and node.at("connection") != none and node.pos != node.at("connection") {
        let nodeName = node.at("getName")(node)
        on-layer(1, line(node.pos, node.at("connection"), 
          stroke: red,
          mark: (end: (symbol: ">")),
        ))
      } else if path != none and path.find(pathNode => pathNode.pos == node.pos) != none {
        let pathPosition = path.position(pathNode => pathNode.pos == node.pos)
        if pathPosition + 1 < path.len() {
          on-layer(1, line(node.pos, path.at(pathPosition + 1).pos, 
            stroke: red,
            mark: (end: (symbol: ">")),
          ))
        }
      }
    }
  })
}

// Calling display code
#let (width, height) = (9,5)
#let start = (0,-1)
#let itemGrid = Grid(width, height, start: start)

#drawGrid(itemGrid)
#itemGrid.at("getNeighbors")(itemGrid, 
  itemGrid.at("getNodeAt")(itemGrid, (1,1))
)