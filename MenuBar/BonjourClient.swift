//
//  BonjourClient.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//

import Foundation
import Network

class BonjourService: NSObject, NetServiceDelegate {
    private var service: NetService?
    private var listener: NWListener?

    func start() {
        let fixedPort: NWEndpoint.Port = 50505

        do {
            listener = try NWListener(using: .tcp, on: fixedPort)
            listener?.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .main)
                self?.receive(on: connection)
            }
            listener?.start(queue: .main)

            service = NetService(domain: "local.", type: "_ipodsync._tcp.", name: "MacController", port: Int32(fixedPort.rawValue))
            service?.delegate = self
            service?.publish()
            print("Servicio Bonjour publicado en el puerto fijo \(fixedPort)")
        } catch {
            print("Error al iniciar el listener en puerto fijo: \(error)")
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("Mensaje recibido: \(message)")
                if message == "shutdown" {
                   // NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
