#let check(input, pos: "", source: "", num: true) = {
  let typeI = type(input)
  let valid = (typeI == "array") or (num and (typeI == "integer" or typeI == "float"))
  assert(valid,
    message: "Input" + str(pos) + " is not an array and can not be used as a vector"
  )
}
#let convertNumber(v1, v2) = {
  let len1 = if type(v1) == "array" {v1.len()} else {1}
  let len2 = if type(v2) == "array" {v2.len()} else {1}
  if type(v1) != "array" {
    v1 = (v1,) * len2
  }
  if type(v2) != "array" {
    v2 = (v2,) * len1
  }
  return (v1, v2)
}
#let loop(v1, v2, callback) = {
  let resultsV = ()
  for (base, operand) in v1.zip(v2) {
    let result = callback(base, operand)
    resultsV.push(result)
  }
  return resultsV
}
#let add(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)
  
  return loop(v1, v2, (a,b) => a+b)
}
#let sub(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)

  return loop(v1, v2, (a,b) => a - b)
}

#let multiply(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)
  
  return loop(v1, v2, (a,b) => a*b)
}
#let divide(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)
  
  return loop(v1, v2, (a,b) => a/b)
}

#let pow(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)
  
  return loop(v1, v2, (a,b) => calc.pow(a,b) )
}
#let root(v1, v2) = {
  check(v1)
  check(v2)
  let (v1, v2) = convertNumber(v1, v2)
  
  return loop(v1, v2, (a,b) => calc.root(a,b) )
}

#add( (1, 2), 5 ) \
#sub( (1, 2), 5 ) \

#multiply( (1, 2), 5) \
#divide( (1, 2), 5) \

#pow( (1, 2), 5) \
#root( (1, 4), 2) \

// #import "/tools/vector.typ": add, sub, multiply, divide, pow, root 