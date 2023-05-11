//
//  SleepTips.swift
//  SAIOS
//
//  Created by Sebastian Sigurdarson on 20.3.2023.
//

import SwiftUI

struct SleepTips: View {
    var sleepTips: [String] = [
            "Establish a consistent sleep schedule by going to bed and waking up at the same time every day, including weekends.",
            "Create a relaxing bedtime routine to signal your body that it's time to wind down.",
            "Avoid consuming caffeine and nicotine within four hours of bedtime.",
            "Exercise regularly, but not too close to bedtime.",
            "Keep your sleep environment cool, dark, and quiet.",
            "Limit exposure to screens and blue light at least one hour before bedtime.",
            "Invest in a comfortable mattress and pillows to ensure proper support and alignment.",
            "Avoid large meals and alcohol close to bedtime.",
            "If you can't fall asleep within 20 minutes, get up and do something relaxing until you feel sleepy.",
            "Consider practicing relaxation techniques, such as deep breathing, meditation, or progressive muscle relaxation before bed.",
            "Avoid daytime naps, especially in the afternoon.",
            "Expose yourself to natural light during the day, especially in the morning.",
            "Avoid stimulating activities before bedtime.",
            "Set aside time for worry and problem-solving earlier in the day.",
            "Try listening to calming music or white noise to help you fall asleep."
        ]
    
    @State private var currentTip: String = "Tap the button below to get a sleep tip."
    @State private var bgColor = Color.gray

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                .frame(height: 10)
                Text("Sleep Tip")
                    .font(.largeTitle)
                    .bold()
                
                Text(currentTip)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    currentTip = sleepTips.randomElement() ?? "No tips available."
                    withAnimation(Animation.linear(duration: 0.5)) {
                        bgColor = randomPastelColor()
                    }
                }) {
                    Text("I'm feeling lucky")
                        .padding()
                        .background(bgColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
                .frame(height: 10)
            }
            .frame(maxWidth: .infinity) // set the width to the maximum available width
            
            .background(bgColor.edgesIgnoringSafeArea(.bottom).opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            
            
            
        }
    }
    
    
    func randomPastelColor() -> Color {
        let hue = CGFloat.random(in: 0...1)
        let saturation = CGFloat.random(in: 0.3...0.7)
        let brightness = CGFloat.random(in: 0.8...1)
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

struct SleepTips_Previews: PreviewProvider {
    static var previews: some View {
        SleepTips()
    }
}


