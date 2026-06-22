import asyncio
from bleak import BleakScanner

# Endereço MAC que você encontrou
TARGET_MAC = "2A:C0:19:11:27:1D"

def callback(device, advertising_data):
    if device.address.upper() == TARGET_MAC:
        m_data = advertising_data.manufacturer_data
        
        if m_data:
            # Converte os dados do fabricante para uma lista de bytes
            raw_bytes = list(m_data.values())[0]
            
            # Garante que o pacote veio completo (mínimo de 13 bytes após o cabeçalho)
            if len(raw_bytes) >= 12:
                # O peso bruto está localizado exatamente nos bytes de índice 10 e 11
                byte_alto = raw_bytes[10]
                byte_baixo = raw_bytes[11]
                
                # Monta o número de 16 bits (Big Endian)
                valor_conversao = (byte_alto << 8) + byte_baixo
                
                # DIVISOR DE CALIBRAÇÃO: 
                # Se marcar o dobro do esperado, mude para 20.0 (escala de 50g)
                # Se marcar exatamente o esperado, mantenha 10.0 (escala de 100g)
                peso_final = valor_conversao / 100.0
                
                print(f"Bytes do Peso: [{byte_alto:02X} {byte_baixo:02X}] -> Valor: {valor_conversao} -> Peso: {peso_final:.2f} kg")

async def main():
    # Inicializa o scanner focando apenas no callback
    scanner = BleakScanner(detection_callback=callback)
    
    print(f"Buscando apenas a balança {TARGET_MAC}...")
    print("Coloque um peso ou force a balança para ver os bytes mudarem.")
    
    await scanner.start()
    await asyncio.sleep(1000000.0)  # Escaneia por 10 segundos
    await scanner.stop()
    print("Escaneamento finalizado.")

if __name__ == "__main__":
    asyncio.run(main())