//
//  GamePage.swift
//  __RockPaperScissors_AI__
//
//  Created by  Sadi on 01/03/2025.
//
import SwiftUI
import CoreML


// MARK: - Global Constants
/// Dictionary to map move names to indices for Core ML predictions.
let MOVE_TO_NUM = ["rock": 0, "paper": 1, "scissors": 2]

/// Dictionary to map indices to move names for display.
let NUM_TO_MOVE = [0: "rock", 1: "paper", 2: "scissors"]

/// The main view of the rock-paper-scissors game, built using SwiftUI.
/// This struct defines the UI and game logic for playing against an AI.
struct GamePage: View {
    // MARK: - State Variables
    /// Stores the player's move history as an array of integers (0=rock, 1=paper, 2=scissors).
    /// @State makes it reactive, so the UI updates when this changes.
    @State private var moveHistory: [Int] = []
    
    /// Tracks the number of times the player has won.
    @State private var playerWins = 0
    
    /// Tracks the number of times the AI has won.
    @State private var aiWins = 0
    
    /// Displays the AI's current move as a string (e.g., "rock", "paper", "scissors", or "?" before a move).
    @State private var aiMove = "?"
    
    /// Shows the result of the current round (e.g., "Ready to play!", "Player Wins", "Tie").
    @State private var result = "Ready to play!"
    
    /// Counts the total number of rounds played in the current game session.
    @State private var gameCount = 0
    
    // MARK: - Constants
    /// The number of previous moves used to look for patterns (set to 5).
    let sequenceLength = 5
    
    /// The untrained Core ML model, loaded from RPSPredictor.mlmodel.
    /// Used as a last-resort fallback if the trained model fails.
    let untrainedModel = try! RPSPredictor(configuration: MLModelConfiguration())
    
    /// The trained Core ML model, loaded from RPSPredictorTrained.mlmodel.
    /// Used when no pattern is found after 6 rounds to predict the player's next move.
    let trainedModel = try! RPSPredictor_trained(configuration: MLModelConfiguration())
    
    // MARK: - UI Layout
    /// Defines the visual structure of the game interface using SwiftUI’s declarative syntax.
    var body: some View {
        
        VStack(spacing: 20) {
            
            View_GameTitle
            
            
            View_AIMove
            
            View_Result
            
            Button_RockPaperScissor
            
            Button_reset
            
        }
        .padding()  // Outer padding around the entire view
    }
    
    private var View_GameTitle: some View {
        Text("Rock Paper Scissors")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
    
    private var View_AIMove: some View {
        Text("AI Move: \(aiMove)")
            .font(.title2)
    }
    
    private var View_Result: some View {
        VStack(spacing: 20) {
            Text(result)
                .font(.title3)
                .foregroundColor(result.contains("Wins") ? .green : .gray)
            Text("Score - You: \(playerWins) | AI: \(aiWins)")
                .font(.headline)
        }
    }
    
    private var Button_RockPaperScissor: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { move in
                @State var isPressed = false
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    playMove(move)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = false
                        }
                    }
                }) {
                    Text(NUM_TO_MOVE[move]!.capitalized)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 110, height: 60)
                        .foregroundColor(Color.black.opacity(0.8))
                        .background(
                            Color(.systemGray6)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 5, y: 5)
                                .shadow(color: .white.opacity(0.8), radius: 5, x: -5, y: -5)
                        )
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var Button_reset: some View {
        Button("Reset Game") {
            resetGame()
        }
        .padding()
        .background(Color.red.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    
    
    // MARK: - Game Logic Functions
    /// Handles a single round of the game when the player makes a move.
    /// - Parameter playerMove: The player's chosen move (0=rock, 1=paper, 2=scissors).
    func playMove(_ playerMove: Int) {
        gameCount += 1
        moveHistory.append(playerMove)
        
        let aiMoveInt: Int          // Variable to store the AI's move
        if gameCount <= 6 {
            aiMoveInt = Int.random(in: 0...2)
        } else {
            aiMoveInt = predictAIMove() // return an index
        }
        
        aiMove = NUM_TO_MOVE[aiMoveInt]!  // Convert AI move index to string (e.g., "rock")
        let gameResult = determineWinner(playerMove: playerMove, aiMove: aiMoveInt)
        result = gameResult
        updateScore(result: gameResult)
    }
    
    /// Predicts the AI’s move based on the player’s move history.
    /// - Returns: An integer (0=rock, 1=paper, 2=scissors) representing the AI’s move to counter the player.
    func predictAIMove() -> Int {
        // Get the last 6 moves (5 for pattern + 1 to compare)
        let recentMoves = Array(moveHistory.suffix(sequenceLength + 1))
        
        if recentMoves.count < sequenceLength + 1 {
            return Int.random(in: 0...2)
        }
        
        let pattern = Array(recentMoves.prefix(sequenceLength))  // Last 5 moves as the pattern
        let lastMove = recentMoves.last!  // The most recent move to match against
        
        // Look for the same pattern in earlier history
        if moveHistory.count > sequenceLength + 1 {
            // Loop through history to find matching patterns
            for i in 0...(moveHistory.count - sequenceLength - 2) {
                let candidatePattern = Array(moveHistory[i...(i + sequenceLength - 1)])  // Extract 5-move chunk
                if candidatePattern == pattern {  // If this matches the recent pattern
                    let nextMove = moveHistory[i + sequenceLength]  // Move that followed the pattern
                    if nextMove == lastMove {  // If it matches the current last move
                        let predictedMove = lastMove  // Predict the player will repeat this move
                        return (predictedMove + 1) % 3  // Return move that beats it (e.g., rock -> paper)
                    }
                }
            }
        }
        
        // If no pattern is found, use the trained Core ML model
        let inputArray = pattern.map { Double($0) }  // Convert pattern to doubles for model input
        do {
            // Create an MLMultiArray with shape [1, 5, 1] for the trained model
            let mlArray = try MLMultiArray(shape: [1, NSNumber(value: sequenceLength), 1], dataType: .double)
            for (i, value) in inputArray.enumerated() {
                mlArray[i] = NSNumber(value: value)  // Fill array with move values
            }
            let prediction = try trainedModel.prediction(input: mlArray)  // Predict with trained model
            let predictedMove = MOVE_TO_NUM[prediction.classLabel]!  // Get predicted move index
            return (predictedMove + 1) % 3  // Return move that counters it
        } catch {
            print("Trained model prediction error: \(error)")  // Log error if prediction fails
            
            // Fallback to untrained model
            do {
                let mlArray = try MLMultiArray(shape: [1, NSNumber(value: sequenceLength), 1], dataType: .double)
                for (i, value) in inputArray.enumerated() {
                    mlArray[i] = NSNumber(value: value)
                }
                let prediction = try untrainedModel.prediction(input: mlArray)  // Predict with untrained model
                let predictedMove = MOVE_TO_NUM[prediction.classLabel]!
                return (predictedMove + 1) % 3
            } catch {
                print("Untrained model prediction error: \(error)")  // Log error if untrained model fails
                return Int.random(in: 0...2)  // Final fallback to random move
            }
        }
    }
    
    /// Determines the winner of a round based on the moves.
    /// - Parameters:
    ///   - playerMove: Player's move (0=rock, 1=paper, 2=scissors).
    ///   - aiMove: AI's move (0=rock, 1=paper, 2=scissors).
    /// - Returns: A string indicating the result ("Tie", "AI Wins", or "Player Wins").
    func determineWinner(playerMove: Int, aiMove: Int) -> String {
        if playerMove == aiMove {
            return "Tie"  // Same move results in a tie
        }
        if (playerMove + 1) % 3 == aiMove {
            return "AI Wins"  // AI’s move beats player’s (e.g., rock -> paper)
        }
        return "Player Wins"  // Player’s move beats AI’s (e.g., rock -> scissors)
    }
    
    /// Updates the score based on the round’s result.
    /// - Parameter result: The result string ("Player Wins", "AI Wins", or "Tie").
    func updateScore(result: String) {
        if result == "Player Wins" {
            playerWins += 1
        } else if result == "AI Wins" {
            aiWins += 1
        }
    }
    
    /// Resets all game state to start a new game.
    func resetGame() {
        moveHistory = []
        playerWins = 0
        aiWins = 0
        aiMove = "?"
        result = "Ready to play!"
        gameCount = 0
    }
}



#Preview {
    GamePage()
}
