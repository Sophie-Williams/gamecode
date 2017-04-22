package main

import "fmt"
import "math"
//import "os"

type object struct {
    id int
    item string
    x float64
    y float64
    vx float64
    vy float64
    state float64
}

func getdistance(x1 float64, x2 float64, y1 float64, y2 float64) float64 {
    var distance float64 = ((((x1 - x2) * (x1 - x2))) + (((y1 - y2) * (y1 - y2))))
    distance = math.Sqrt(distance)
    return distance
}

func main() {
    // myTeamId: if 0 you need to score on the right of the map, if 1 you need to score on the left
    var myTeamId int
    fmt.Scan(&myTeamId)
    
    var entity = make(map[string]object)
    
    for {
        var myScore, myMagic int
        fmt.Scan(&myScore, &myMagic)
        
        var opponentScore, opponentMagic int
        fmt.Scan(&opponentScore, &opponentMagic)
        
        var entities int
        fmt.Scan(&entities)
        
        for i := 0; i < entities; i++ {
            // entityType: "WIZARD", "OPPONENT_WIZARD" or "SNAFFLE" (or "BLUDGER" after first league)
            var entityId int
            var entityType string
            var x, y, vx, vy, state float64
            var id object
            fmt.Scan(&entityId, &entityType, &x, &y, &vx, &vy, &state)
            
            id.id = entityId
            id.item = entityType
            id.x = x
            id.y = y
            id.vx = vx
            id.vx = vy
            id.state = state
            
            entity["id"] = id
        }

        for entityid := range entity {
            fmt.Println("MOVE", entity[entityid].x, entity[entityid].y, "100\n")
        }
            
    }
}