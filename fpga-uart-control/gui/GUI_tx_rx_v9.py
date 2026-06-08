import tkinter as tk
import serial
import time

# ---------------- UART Setup ----------------
try:
    ser = serial.Serial(
        port='COM5', 
        baudrate=115200, 
        timeout=0, 
        rtscts=False      
    )
except Exception as e:
    print(f"Serial Error: {e}")
    ser = None

def auto_update():
    """ Automatically updates the frequency value if data is present """
    if ser and ser.in_waiting > 0:
        try:
            raw_data = ser.read(ser.in_waiting)
            lines = raw_data.decode('ascii', errors='ignore').strip().split('\n')
            last_valid_line = lines[-1].strip()
            
            if last_valid_line:
                entry_a.delete(0, tk.END)
                entry_a.insert(0, f"{last_valid_line} Hz")
        except Exception:
            pass 
    
    window.after(1, auto_update)

def transmit_to_fpga():
    """ Reads integer from entry_transmit and sends via UART """
    if ser and ser.is_open:
        val = entry_transmit.get()
        if val.isdigit():
            try:
                # Send character by character with a micro-delay for stability
                for char in f"{val}\n":
                    ser.write(char.encode('ascii'))
                    time.sleep(0.001) # 1ms delay between characters
                print(f"Sent Pulse Width: {val} ms")
            except Exception as e:
                print(f"Transmission Error: {e}")
        # entry_transmit.delete(0, tk.END)  <-- REMOVED: Value now stays in box

# ---------------- GUI ----------------
window = tk.Tk()
window.title("FPGA parameter control")
window.configure(bg="#E0FFFF")

# Top Frame
frame_a = tk.Frame(master=window, relief=tk.GROOVE, borderwidth=3, bg="#E0FFFF")
frame_a.pack(side=tk.TOP, fill=tk.BOTH)

label_a = tk.Label(master=frame_a, text="CCEL GUI - FPGA CONTROL", bg="#E0FFFF", 
                   width=100, height=3, font=("Times New Roman", 15, "bold"))
label_a.pack(fill=tk.X)

label_b = tk.Label(master=frame_a, text="Enter the Pulse width duration below and click Enter", 
                   bg="#E0FFFF", width=122, height=2, font=("Times New Roman", 12))
label_b.pack(fill=tk.X)

# Left Frame (Frequency Display)
frame_b = tk.Frame(master=window, relief=tk.GROOVE, borderwidth=3, bg="#E0FFFF")
frame_b.pack(side=tk.LEFT, expand=True, fill=tk.BOTH)

label_c = tk.Label(master=frame_b, text="The current frequency:", 
                   bg="#E0FFFF", font=("Times New Roman", 13))
label_c.pack(pady=10)

entry_a = tk.Entry(master=frame_b, font=("Times New Roman", 15), justify='center')
entry_a.pack(pady=10, padx=20)

# Right Frame (Input and Transmit)
frame_c = tk.Frame(master=window, relief=tk.GROOVE, borderwidth=3, bg="#E0FFFF")
frame_c.pack(side=tk.RIGHT, expand=True, fill=tk.BOTH)

# New Label for Pulse Width
label_pulse_width = tk.Label(master=frame_c, text="Pulse width high (ms)", 
                             bg="#E0FFFF", font=("Times New Roman", 13))
label_pulse_width.pack(pady=(40, 0)) # Padding only on top to sit above the box

# Container for Button + Entry to sit side-by-side
input_subframe = tk.Frame(frame_c, bg="#E0FFFF")
input_subframe.pack(pady=20, padx=20)

button_a = tk.Button(master=input_subframe, text="Enter", width=10, height=1,
                     bg="#FFA500", fg="white", font=("Times New Roman", 13, "bold"),
                     command=transmit_to_fpga)
button_a.pack(side=tk.LEFT, padx=5)

entry_transmit = tk.Entry(master=input_subframe, font=("Times New Roman", 15), width=10)
entry_transmit.pack(side=tk.LEFT, padx=5)
entry_transmit.bind('<Return>', lambda event: transmit_to_fpga())

# Start the automatic refresh loop
window.after(100, auto_update)

window.mainloop()

if ser and ser.is_open:
    ser.close()

