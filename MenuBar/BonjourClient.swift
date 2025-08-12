//
//  BonjourService.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//

import Foundation
import Network

class BonjourService: NSObject, NetServiceDelegate {
    private var service: NetService?
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    func start() {
        let fixedPort: NWEndpoint.Port = 50505

        do {
            // CRÍTICO: Configurar parámetros TCP para aceptar conexiones remotas
            let parameters = NWParameters.tcp
            parameters.acceptLocalOnly = false  // ← Esta es la línea clave que faltaba
            
            // Crear listener con parámetros corregidos
            listener = try NWListener(using: parameters, on: fixedPort)
            
            listener?.newConnectionHandler = { [weak self] connection in
                print("📱 Nueva conexión desde: \(connection.endpoint)")
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("✅ Servidor TCP listo en puerto 50505 (todas las interfaces)")
                case .failed(let error):
                    print("❌ Error del servidor TCP: \(error)")
                case .cancelled:
                    print("🚫 Servidor TCP cancelado")
                default:
                    print("📡 Estado del servidor: \(state)")
                }
            }
            
            listener?.start(queue: .main)

            // Publicar servicio Bonjour
            service = NetService(domain: "local.", type: "_yourservice._tcp", name: "MacController", port: Int32(fixedPort.rawValue))
            service?.delegate = self
            service?.publish()
            print("🔊 Servicio Bonjour publicado en el puerto fijo \(fixedPort)")
            
        } catch {
            print("❌ Error al iniciar el listener en puerto fijo: \(error)")
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        // Agregar a conexiones activas
        connections.append(connection)
        
        // Configurar manejo de estado
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ Conexión establecida con \(connection.endpoint)")
                self?.setupReceive(for: connection)
                
                // Enviar mensaje de bienvenida
                self?.sendResponse("Conectado a Mac - Comandos: ping, shutdown, restart", to: connection)
                
            case .failed(let error):
                print("❌ Conexión falló: \(error)")
                self?.removeConnection(connection)
                
            case .cancelled:
                print("🚫 Conexión cancelada con \(connection.endpoint)")
                self?.removeConnection(connection)
                
            default:
                break
            }
        }
        
        // Iniciar conexión
        connection.start(queue: .main)
    }

    private func setupReceive(for connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, context, isComplete, error in
            
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "mensaje ilegible"
                print("📨 Mensaje recibido de \(connection.endpoint): '\(message)'")
                
                // Procesar el comando
                self?.processCommand(message.trimmingCharacters(in: .whitespacesAndNewlines), from: connection)
            }
            
            if let error = error {
                print("❌ Error recibiendo datos: \(error)")
                self?.removeConnection(connection)
                return
            }
            
            // Continuar recibiendo si la conexión está activa
            if !isComplete && connection.state == .ready {
                self?.setupReceive(for: connection)
            }
        }
    }
    
    private func processCommand(_ command: String, from connection: NWConnection) {
        let cmd = command.lowercased()
        
        switch cmd {
        case "ping":
            sendResponse("pong - Mac funcionando correctamente", to: connection)
            
        case "shutdown":
            sendResponse("⚡ Iniciando apagado del sistema...", to: connection)
            executeShutdown()
            
        case "restart":
            sendResponse("🔄 Iniciando reinicio del sistema...", to: connection)
            executeRestart()
            
        case "status":
            let status = "Mac activa - \(connections.count) conexiones activas"
            sendResponse(status, to: connection)
            
        default:
            sendResponse("❓ Comando no reconocido: '\(command)'. Comandos disponibles: ping, shutdown, restart, status", to: connection)
        }
    }
    
    private func sendResponse(_ message: String, to connection: NWConnection) {
        guard let data = message.data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Error enviando respuesta: \(error)")
            } else {
                print("✅ Respuesta enviada: '\(message)'")
            }
        })
    }
    
    private func executeShutdown() {
        print("💻 Ejecutando apagado del sistema en 3 segundos...")
        
        // Dar tiempo para que se envíe la respuesta antes de apagar
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/sbin/shutdown")
            process.arguments = ["-h", "now"]
            
            do {
                try process.run()
            } catch {
                print("❌ Error ejecutando shutdown: \(error)")
            }
        }
    }
    
    private func executeRestart() {
        print("🔄 Ejecutando reinicio del sistema en 3 segundos...")
        
        // Dar tiempo para que se envíe la respuesta antes de reiniciar
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/sbin/shutdown")
            process.arguments = ["-r", "now"]
            
            do {
                try process.run()
            } catch {
                print("❌ Error ejecutando restart: \(error)")
            }
        }
    }
    
    private func removeConnection(_ connection: NWConnection) {
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }
    
    func stop() {
        // Cerrar todas las conexiones
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        // Detener servicio Bonjour
        service?.stop()
        service = nil
        
        // Detener listener TCP
        listener?.cancel()
        listener = nil
        
        print("🛑 Servicio Bonjour y servidor TCP detenidos")
    }
    
    // MARK: - NetServiceDelegate
    func netServiceDidPublish(_ sender: NetService) {
        print("✅ Servicio Bonjour publicado exitosamente: \(sender.name).\(sender.type)\(sender.domain)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("❌ Error publicando servicio Bonjour: \(errorDict)")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("🚫 Servicio Bonjour detenido")
    }
    
    deinit {
        stop()
    }
}
