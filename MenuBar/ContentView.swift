
import SwiftUI

struct ContentView: View {
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
                Button(action: {
                    print("Botón de estado presionado.")
                }) {
                    HStack {
                        Text("iPhone conectado")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                .buttonStyle(.plain)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: {
                    print("Botón de apagar presionado.")
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Apagar")
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

