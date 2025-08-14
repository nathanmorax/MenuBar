//
//  BonjourService.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//

import Foundation
import Network
import Cocoa

class BonjourService: NSObject, NetServiceDelegate, ObservableObject {
    private var service: NetService?
    var listener: NWListener?
    private var connections: [NWConnection] = []
    @Published var isConnected: Bool = false


    func start() {
        let fixedPort: NWEndpoint.Port = 50505

        do {
            // ✅ Usar parámetros TCP estándar
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.acceptLocalOnly = false
            parameters.includePeerToPeer = true

            // ✅ Crear listener
            listener = try NWListener(using: parameters, on: fixedPort)

            listener?.newConnectionHandler = { [weak self] connection in
                print("📱 Nueva conexión desde: \(connection.endpoint)")
                self?.handleNewConnection(connection)
            }

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("✅ Servidor TCP listo en puerto 50505 (IPv4 + IPv6 si el sistema lo permite)")
                case .failed(let error):
                    print("❌ Error del servidor TCP: \(error)")
                case .cancelled:
                    print("🚫 Servidor TCP cancelado")
                default:
                    print("📡 Estado del servidor: \(state)")
                }
            }

            listener?.start(queue: .main)

            // ✅ Publicar servicio Bonjour
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
                self?.isConnected = true
                self?.sendResponse("Conectado a Mac ", to: connection)
                
            case .failed(let error):
                print("❌ Conexión falló: \(error)")
                self?.isConnected = false
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
        
        if cmd.hasPrefix("say ") {
            let mensaje = String(command.dropFirst(4)) // conserva mayúsculas y acentos
            sendResponse("🗣️ Diciendo: '\(mensaje)'", to: connection)
            executeSay(mensaje)
            return
        }
        
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
            
        case "exit":
            sendResponse("🛑 Cerrando app en la Mac...", to: connection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        case "open music":
            sendResponse("🎶 Abriendo Apple Music...", to: connection)
            openAppDirect(path: "/System/Applications/Music.app")

            
        case "close music":
            sendResponse("🛑 Cerrando Apple Music...", to: connection)

        case "play music":
            sendResponse("▶️ Reproduciendo música...", to: connection)
            playAppleMusic()
            
        case "key code 125": // flecha abajo
            sendResponse("⬇️ Scroll hacia abajo...", to: connection)
            simulateKeyPress(code: 125)

        case "key code 126": // flecha arriba
            sendResponse("⬆️ Scroll hacia arriba...", to: connection)
            simulateKeyPress(code: 126)

        case "key code 123": // flecha izquierda
            sendResponse("⬅️ Navegación izquierda...", to: connection)
            simulateKeyPress(code: 123)

        case "key code 124": // flecha derecha
            sendResponse("➡️ Navegación derecha...", to: connection)
            simulateKeyPress(code: 124)

        case "key code 36": // enter
            sendResponse("⏎ Enter enviado...", to: connection)
            simulateKeyPress(code: 36)

        case "mouse click":
            sendResponse("🖱️ Clic izquierdo ejecutado", to: connection)
            simulateMouseClick()
            
        case "back 15":
            sendResponse("⏪ Retrocedido 15 segundos", to: connection)
            
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
    
    private func executeSay(_ mensaje: String) {
        let proceso = Process()
        proceso.launchPath = "/usr/bin/say"
        proceso.arguments = [mensaje]
        proceso.launch()
    }
    
    func openAppDirect(path: String) {
        let proceso = Process()
        proceso.launchPath = "/usr/bin/open"
        proceso.arguments = [path]
        proceso.launch()
    }
    
    func playAppleMusic() {
        let script = """
        
        tell application "Music"
            activate
            delay 1
            if (exists current track) then
                play
            else
                return "❌ No hay música en la cola."
            end if
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("🎵 Resultado: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }
    
    func simulateKeyPress(code: CGKeyCode) {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: false)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func simulateMouseClick() {
        let loc = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedY = screenHeight - loc.y // Convertir a coordenadas de Quartz

        let point = CGPoint(x: loc.x, y: flippedY)
        let src = CGEventSource(stateID: .hidSystemState)

        let mouseDown = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let mouseUp = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)

        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
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
