package main

import "fmt"
import "os"

/**
 * Grab Snaffles and try to throw them through the opponent's goal!
 * Move towards a Snaffle and use your team id to determine where you need to throw it.
 **/

func main() {
    // myTeamId: if 0 you need to score on the right of the map, if 1 you need to score on the left
    var myTeamId int
    fmt.Scan(&myTeamId)
    
    for {
        var myScore, myMagic int
        fmt.Scan(&myScore, &myMagic)
        
        var opponentScore, opponentMagic int
        fmt.Scan(&opponentScore, &opponentMagic)
        
        // entities: number of entities still in game
        var entities int
        fmt.Scan(&entities)
        
        for i := 0; i < entities; i++ {
            // entityId: entity identifier
            // entityType: "WIZARD", "OPPONENT_WIZARD" or "SNAFFLE" (or "BLUDGER" after first league)
            // x: position
            // y: position
            // vx: velocity
            // vy: velocity
            // state: 1 if the wizard is holding a Snaffle, 0 otherwise
            var entityId int
            var entityType string
            var x, y, vx, vy, state int
            fmt.Scan(&entityId, &entityType, &x, &y, &vx, &vy, &state)
        }
        for i := 0; i < 2; i++ {
            
            // fmt.Fprintln(os.Stderr, "Debug messages...")
            
            // Edit this line to indicate the action for each wizard (0 ≤ thrust ≤ 150, 0 ≤ power ≤ 500)
            // i.e.: "MOVE x y thrust" or "THROW x y power"
            fmt.Printf("MOVE 8000 3750 100\n")
        }
    }
}