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
    
    @State private var gameLogic = GameLogic()
    
    // MARK: - UI Layout
    /// Defines the visual structure of the game interface using SwiftUI’s declarative syntax.
    var body: some View {
        
        VStack(spacing: 20) {
            ///``View_GameTitle``
            View_GameTitle
            
            ///``View_AIMove``
            View_AIMove
            
            ///``View_Result``
            View_Result
            
            ///``Button_RockPaperScissor``
            Button_RockPaperScissor
            
            ///``Button_reset``
            Button_reset
            
        }
        .padding()  // Outer padding around the entire view
    }
    
    
    
    /// It Shows the Title of the Game
    private var View_GameTitle: some View {
        Text("Rock Paper Scissors")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
    
    
    /// It shows the AI move
    private var View_AIMove: some View {
        Text("AI Move: \(gameLogic.aiMove)")
            .font(.title2)
    }
    
    /// it shows the result of the Match
    private var View_Result: some View {
        VStack(spacing: 20) {
            Text(gameLogic.result)
                .font(.title3)
                .foregroundColor({
                    switch gameLogic.result {
                    case "Player Wins":
                        return .green
                    case "AI Wins":
                        return .red
                    case "Tie":
                        return .gray
                    default:
                        return .gray // For "Ready to play!" or any other state
                    }
                }())
            Text("Score - You: \(gameLogic.playerWins) | AI: \(gameLogic.aiWins)")
                .font(.headline)
        }
    }
    
    /// Button of Rock Paper scissors
    private var Button_RockPaperScissor: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { move in
                @State var isPressed = false
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    gameLogic.playMove(move)
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
    
    /// Reset button for reset the match and clear previous result
    private var Button_reset: some View {
        Button("Reset Game") {
            gameLogic.resetGame()
        }
        .padding()
        .background(Color.red.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    
    
}



#Preview {
    GamePage()
}
