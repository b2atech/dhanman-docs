# Clean code principle - c#

## 1. Use Default import to import React
Don't 
```js
import * as React from "react";
```

Do 
```js
import React, {useContext, useState} from "react";
```

Note: Use this option by adding in configure the tsconfig.json file as seen below:
```js
{
    "compilerOptions":
    {
        "esModuleInterop": true
    }
}
```

## 2. Don’t use constructor for class components
```js
// Don't do
type State = {count: number}
type Props = {}
 
 
class Counter extends Component<Props, State> {
    constructor(props:Props){
    super(props);
    this.state = {count: 0}
    }
}
 
 
// Do
type State = {count: number}
type Props = {}
 
 
class Counter extends Component<Props, State> {
    state = {count: 0}
}
```

## 3. Don’t use public accessor within classes

Don't
```js
import { Component } from "react"
 
class Friends extends Component {
    public fetchFriends () {}
    public render () {
        return // jsx blob
    }
}
```
Do
```js
import { Component } from "react"
 
class Friends extends Component {
    fetchFriends () {}
    render () {
    return // jsx blob
    }
}
```

## 4. Don’t use private accessor within Component class
Don't
```js
import {Component} from "react"
 
class Friends extends Component {
  private fetchProfileByID () {}
   
  render () {
    return // jsx blob
  }
}
```

Do
```js
import {Component} from "react"class Friends extends Component {
  _fetchProfileByID () {}
   
  render () {
    return // jsx blob
  }
}
```

5. Don’t use enum
```js
// Don't do this
enum Response {
  Successful,
  Failed,
  Pending
}

function fetchData (status: Response): void => {
    // some code.
}

// Do this
type Response = Sucessful | Failed | Pending
 
function fetchData (status: Response): void => {
    // some code.
}
``` 

## 6. Don’t use method declaration within interface/type alias

```js
// Don't do
interface Counter {
  start(count:number) : string
  reset(): void
}
   
// Do
interface Counter {
  start: (count:number) => string
  reset: () => string
}
```

## 7. Move unrelated code into a separate component

## 8. Create separate files for each component

## 9. Format your code
