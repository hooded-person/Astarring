#import "@preview/cetz:0.3.2"
#import "/tools/vector.typ": add as addV, sub as subV, multiply as multiplyV, divide as divideV, pow as powV, root as rootV

#let straightPath(current, target) = {
  let disX = calc.abs(target.at(0)) - calc.abs(current.at(0))
  let disY = calc.abs(target.at(1)) - calc.abs(current.at(1))
  let disXabs = calc.abs(disX)
  let disYabs = calc.abs(disY)
  let disDiag = 0
  while disXabs > 0 and disYabs > 0 {
    let disToDiag = 0
    if disXabs < disYabs {
      disToDiag = disXabs
    } else {
      disToDiag = disYabs
    }
    disXabs = disXabs - disToDiag
    disYabs = disYabs - disToDiag
    disDiag = disDiag + disToDiag
  }
  let path = (current,)
  let pathShifts = (
    (disXabs * disX.signum(), 0), 
    (0                      , disYabs * disY.signum()), 
    (disDiag * disX.signum(), disDiag * disY.signum())
  )
  for pathShift in pathShifts {
    let prev = path.last()
    let new = addV(prev, pathShift)
    if prev != new {
      path.push(new)
    }
  }
  return path// disXabs + disYabs + 1.4 * disDiag
}

#let path = straightPath((1,-1),(2,1))
#path

#cetz.canvas({
  import cetz.draw: *
  let shifted = path.slice(1)
  for (start, end) in path.zip(shifted) {
    line(start, end)
  }
})