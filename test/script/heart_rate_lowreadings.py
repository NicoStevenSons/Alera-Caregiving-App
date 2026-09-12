import time
import requests

from datetime import datetime, timezone


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


NORMAL_VALUES = [72, 75, 78]
LOW_WARNING_VALUES = [52, 49, 47]
LOW_CRITICAL_VALUES = [38, 35, 33]

STATE_INTERVAL_SECONDS = 90
READING_INTERVAL_SECONDS = 15

def send_state_readings(label, values):
    print(f"\n{label}")

    for i, value in enumerate(values, start=1):
        print(f"Reading {i}/{len(values)}: {value} bpm")
        send_heart_rate(value)

        if i < len(values):
            time.sleep(READING_INTERVAL_SECONDS)

def check_backend():
    try:
        response = requests.get(
            f"{BACKEND_URL}/health",
            timeout=90,
        )

        print(f"Backend health: HTTP {response.status_code}")
        print(response.text)

        return response.ok

    except requests.RequestException as error:
        print("Backend unavailable:", error)
        return False


def send_heart_rate(value):
    now = datetime.now(timezone.utc)

    payload = {
        "patient_id": PATIENT_ID,
        "external_event_id": (
            f"lifecycle-slow-hr-{now.strftime('%Y%m%dT%H%M%S%fZ')}"
        ),
        "metric_type": "HEART_RATE",
        "numeric_value": value,
        "text_value": None,
        "boolean_value": None,
        "metric_unit": "bpm",
        "recorded_at": now.isoformat(),
        "validation_status": "VALID_REALTIME",
        "validation_reason": None,
        "raw_payload": {
            "source": "slow_hr_lifecycle_simulator",
            "device": "Simulator",
            "test": True,
        },
    }

    try:
        response = requests.post(
            f"{BACKEND_URL}/api/v1/health-events",
            json=payload,
            timeout=90,
        )

        print(
            f"[{now.strftime('%H:%M:%S')}] "
            f"HR {value} bpm → HTTP {response.status_code}"
        )

        try:
            print("Response:", response.json())
        except Exception:
            print("Response:", response.text)

        return response.ok

    except requests.RequestException as error:
        print("Request failed:", error)
        return False


def wait_for_next_state():
    print(
        f"\nWaiting {STATE_INTERVAL_SECONDS} seconds "
        "before next state..."
    )
    time.sleep(STATE_INTERVAL_SECONDS)


def run_lifecycle():
    print("\n=== SLOW HEART RATE LIFECYCLE ===")
    print("NORMAL → LOW WARNING → LOW CRITICAL → NORMAL\n")

    # 1. NORMAL
    print("[1/4]")
    send_state_readings(
        "NORMAL",
        NORMAL_VALUES,
    )

    wait_for_next_state()

    # 2. LOW / WARNING
    print("\n[2/4]")
    send_state_readings(
        "LOW / WARNING",
        LOW_WARNING_VALUES,
    )

    wait_for_next_state()

    # 3. CRITICAL LOW
    print("\n[3/4]")
    print("Leaving previous warning unresolved.")

    send_state_readings(
        "CRITICAL LOW",
        LOW_CRITICAL_VALUES,
    )

    wait_for_next_state()

    # 4. RECOVERY
    print("\n[4/4]")
    send_state_readings(
        "NORMAL / RECOVERY",
        [70, 73, 76],
    )

    print("\n=== LIFECYCLE COMPLETE ===")


def main():
    print("=== ALERA SLOW HR LIFECYCLE SIMULATOR ===")

    print("\nChecking backend...")

    if not check_backend():
        print("Backend is not responding.")
        return

    print("\nBackend ready.")
    input("\nPress Enter to start slow HR lifecycle...")

    run_lifecycle()


if __name__ == "__main__":
    main()