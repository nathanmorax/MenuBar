//
//  BonjourClient.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//

import SwiftUI
import Network

class BonjourService: ObservableObject {
    private var netService: NetService?
    private var listener: NWListener?

    func start() {
        do {
            listener = try NWListener(using: .tcp, on: 0)
            
            listener?.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    if let port = self.listener?.port {
                        print("Listener listo en puerto: \(port.rawValue)")
                        // Aquí publicas el servicio Bonjour con el puerto real
                        self.netService = NetService(domain: "local.", type: "_myremote._tcp.", name: "Mi Mac", port: Int32(port.rawValue))
                        self.netService?.publish()
                        print("Servicio Bonjour publicado en puerto \(port.rawValue)")
                    }
                case .failed(let error):
                    print("Listener fallo con error: \(error)")
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { connection in
                connection.start(queue: .main)
                print("Nueva conexión recibida")
            }
            
            listener?.start(queue: .main)

        } catch {
            print("Error creando listener: \(error)")
        }
    }


    func stop() {
        netService?.stop()
        listener?.cancel()
    }
}
