
import SwiftUI

struct ContentView: View {
    
    @ObservedObject var bonjour = BonjourService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack(spacing: 8) {
                Image(systemName: "iphone.gen1")
                    .font(.title)
                Text("iPod Sync")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            let buttonHeight: CGFloat = 40
            
            HStack(spacing: 10) {
                
                Text(bonjour.isConnected ? "iPhone Encendido" : "iPhone Desconetado")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .background(bonjour.isConnected ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button(action: {
                    if bonjour.listener == nil {
                        bonjour.start()
                    } else {
                        bonjour.stop()
                        bonjour.isConnected = false
                    }
                }) {
                    HStack {
                        Image(systemName: bonjour.listener == nil ? "power.circle.fill" : "power")
                        Text(bonjour.listener == nil ? "Encender" : "Apagar")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                .buttonStyle(.plain)
                .background(Color(NSColor.controlBackgroundColor))
                .foregroundColor(Color(NSColor.controlTextColor))
                .cornerRadius(8)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 290, height: 110)
    }
}

