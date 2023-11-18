"""Turn off TV when CEC goes berserk"""

import subprocess
import time
from threading import Thread

last_state_time = time.time()
current_state = 0

weird_state_machine = [
    "Event: State Change: PA: f.f.f.f, LA mask: 0x0000, Conn Info: yes",
    "Transmitted by Recording Device 1 to TV (1 to 0): IMAGE_VIEW_ON (0x04)",
    "Received from TV to Recording Device 1 (0 to 1): REPORT_POWER_STATUS (0x90):",
    "pwr-state: on (0x00)"
]

def kill_tv():
    """Turns TV off"""
    time.sleep(8)
    subprocess.run(['cec-ctl', '--to', '0', '--standby'], check=False)

    with open("cec_fix.log", "a", encoding="utf-8") as file:
        file.write(f"[{time.time()}] TV was told to sleep")
        file.write("\n")

def process_output(line):
    """Where the magic happens"""
    global last_state_time, current_state

    pretty_line = line.strip()

    now = time.time()
    diff = now - last_state_time

    if diff >= 10:
        current_state = 0

    if pretty_line == weird_state_machine[current_state]:
        last_state_time = now
        current_state += 1

    if current_state == 4:
        current_state = 0
        t = Thread(target=kill_tv)
        t.start()

def main():
    """Where the magic does not happen"""
    process = subprocess.Popen(['cec-ctl', '-m'],
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True)

    try:
        while True:
            line = process.stdout.readline()
            if line:
                process_output(line)
            else:
                time.sleep(0.1)

    except KeyboardInterrupt:
        print("Stopping program")

    finally:
        process.terminate()

if __name__ == "__main__":
    main()
