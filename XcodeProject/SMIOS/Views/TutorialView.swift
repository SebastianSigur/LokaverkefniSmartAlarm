//
//  TutorialView.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 27.4.2023.
//

import SwiftUI

struct TutorialView: View {
    @Binding var showTutorial: Bool
    @State private var selectedTab = 0
    @State private var backgroundColor = LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
    @State var next = ""
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack{
                        Button("Skip") {
                            showTutorial = false
                        }
                        .padding()
                        Spacer()
                       
                        Button("\(next)") {
                            showTutorial = false
                        }
                        .padding()
                    }

                    PageTabView(selection: $selectedTab, backgroundColor: $backgroundColor, next: $next)
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.6)
                        .cornerRadius(10)
                        .padding()

                }
                .background(backgroundColor).edgesIgnoringSafeArea(.all)
                .cornerRadius(10)
                .shadow(radius: 10)
                .animation(.easeInOut(duration: 1.0)) // animate the background color change
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
        }
    }
}


struct PageTabView: View {
    @Binding var selection: Int
    @Binding var backgroundColor: LinearGradient
    @Binding var next: String
    let LASTPAGE = 5
    @State var colors =
            [LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing),
             LinearGradient(gradient: Gradient(colors: [.red, .green]), startPoint: .topLeading, endPoint: .bottomTrailing),
             LinearGradient(gradient: Gradient(colors: [.red, .black]), startPoint: .topLeading, endPoint: .bottomTrailing),
             LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing),
             LinearGradient(gradient: Gradient(colors: [.red, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
             LinearGradient(gradient: Gradient(colors: [.red, .gray]), startPoint: .topLeading, endPoint: .bottomTrailing),
            ]
    
        var body: some View {
        TabView(selection: $selection) {
            VStack{
                Text("Welcome to SmartAlarm")
                    .font(.title)
                    .foregroundColor(Color.black)
                Text("Let's get You started")
                    .foregroundColor(Color.black)
                    .font(.title3)
                
            }
            .tag(0)
            
            VStack {
                Text("Tabs Overview")
                    .foregroundColor(Color.black)
                    .font(.title)
                Text("The three tabs represent different areas of the app.")
                    .foregroundColor(Color.black)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Image("Tabs")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .background(Color.white.opacity(0.8).blendMode(.multiply))
            }
            .tag(1)
            VStack {
                Text("Alarm Page")
                    .foregroundColor(Color.black)
                    .font(.title)
                Text("Here you can see and manage all of your alarms")
                    .foregroundColor(Color.black)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                HStack {
                    
                    Image("AlarmsMini")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                        .frame(width: 100, height: 100)
                        .background(Color.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    Spacer()
                    Image("Alarms")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                       
                }
                Spacer()
            }
            .padding(.bottom)
            .tag(2)
            VStack {
                Text("Creating Smart Alarms")
                    .foregroundColor(Color.black)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                   
                    .padding(.top, 40)
                
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("When creating a smart alarm, you can set:")
                            .foregroundColor(Color.black)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading) {
                            Text("Give Front")
                                .foregroundColor(Color.black)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("Set how much earlier the app is allowed to wake you up before the regular alarm.")
                                .foregroundColor(Color.black)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading) {
                          
                            Text("Give Back")
                                .foregroundColor(Color.black)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("Set how much later the app is allowed to wake you up after the regular alarm.")
                                .foregroundColor(Color.black)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    Image("addAlarm")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
             
                        .frame(width: 100, height: 200)
                    
                }
              
                
                Spacer()
            }
            .padding()
            .tag(3)


           
            VStack {
                HStack {
                    Image(systemName: "person.crop.square")
                    
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white.opacity(0.8).blendMode(.multiply))
                        .frame(width: 50)
                    VStack{
                        Text("Set up your information in the profile page.")
                            .foregroundColor(Color.black)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            
                        Text("This step is optional, but helps improve the accuracy of our sleep stage predictions")
                            .foregroundColor(Color.black)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }
                    
                }
               

                Divider()
                    .padding(.vertical)

                HStack {
                    Image(systemName: "heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white.opacity(0.8).blendMode(.multiply))
                        .frame(width: 50)


                        Text("Access and review your past sleep history in the statistics page")
                            .foregroundColor(Color.black)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .fixedSize(horizontal: false, vertical: true)

                }
                Divider()
                    .padding(.vertical)
                HStack {
                    Image(systemName: "cloud")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white.opacity(0.8).blendMode(.multiply))
                        .frame(width: 50)
                    VStack {
                        Text("Make sure that both iOS and WatchOS are connected to iCloud.")
                            .foregroundColor(Color.black)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Bug reporting is very helpful and can be found in the profile page.")
                            .foregroundColor(Color.black)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }
                }
                Spacer()
            }
            .tag(4)


            VStack {
                Text("When going to sleep, start a sleep process on your apple watch to begin measure your heart rate.")
                    .foregroundColor(Color.black)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer() // Add Spacer to center content

                    Image("gnstart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                        .frame(width: 150, height: 150)
                        .background(Color.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    Image("gnstop")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                        .frame(width: 150, height: 150)
                        .background(Color.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    Spacer() // Add Spacer to center content
                }
                .padding(.vertical, 10)

                Text("We predict your sleep stage to prevent you from waking up during deep sleep.")
                    .foregroundColor(Color.black)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            .tag(5)



        }
        .tabViewStyle(PageTabViewStyle())
        .onChange(of: selection) { newValue in
            if newValue == LASTPAGE{
                next = "Continue"
            }
            else{
                next = ""
            }
            withAnimation {
                backgroundColor = colors[newValue]
            }
        }
    }
}
struct TutorialView_Previews: PreviewProvider {

    static var previews: some View {
        TutorialView(showTutorial: Binding.constant(true))
    }
}

