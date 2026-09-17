import time
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import requests


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


NORMAL_VALUES = [72, 75, 78, 74, 76, 73, 75]
LOW_WARNING_VALUES = [52, 49, 47, 51, 48, 53, 50, 46, 49]
LOW_CRITICAL_VALUES = [38, 35]

READING_INTERVAL_SECONDS = 15


def send_state_readings(label, values):
    print(f"\n{label}")
    started_at = datetime.now(timezone.utc)
    started_monotonic = time.monotonic()

    for i, value in enumerate(values, start=1):
        target_elapsed = (i - 1) * READING_INTERVAL_SECONDS
        remaining = target_elapsed - (time.monotonic() - started_monotonic)
        if remaining > 0:
            print(f"Waiting {remaining:.1f} seconds for scheduled reading...")
            time.sleep(remaining)

        print(f"Reading {i}/{len(values)}: {value} bpm")
        if not send_heart_rate(
            value,
            started_at + timedelta(seconds=target_elapsed),
        ):
            raise RuntimeError(f"{label} reading {i} failed")


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


def send_heart_rate(value, recorded_at=None):
    now = recorded_at or datetime.now(timezone.utc)

    payload = {
        "patient_id": PATIENT_ID,
        "external_event_id": (
            f"lifecycle-low-hr-{now.strftime('%Y%m%dT%H%M%S%fZ')}-{uuid4()}"
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
            "source": "low_hr_lifecycle_simulator",
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


def run_lifecycle():
    print("\n=== LOW HEART RATE LIFECYCLE ===")
    print("NORMAL → LOW WARNING → LOW CRITICAL → NORMAL\n")

    # 1. NORMAL
    print("[1/4]")
    send_state_readings(
        "NORMAL",
        NORMAL_VALUES,
    )

    time.sleep(3)

    # 2. LOW / WARNING
    print("\n[2/4]")
    send_state_readings(
        "LOW / WARNING",
        LOW_WARNING_VALUES,
    )

    print("\nTwo-minute low-HR Warning qualification completed.")
    time.sleep(3)

    # 3. CRITICAL LOW
    print("\n[3/4]")
    print("Leaving previous warning unresolved.")

    send_state_readings(
        "CRITICAL LOW",
        LOW_CRITICAL_VALUES,
    )

    time.sleep(3)

    # 4. RECOVERY
    print("\n[4/4]")
    send_state_readings(
        "NORMAL / RECOVERY",
        NORMAL_VALUES,
    )

    print("\n=== LIFECYCLE COMPLETE ===")
    print("Expected pushes: low-HR Warning, then Critical escalation.")


def main():
    print("=== ALERA LOW HR LIFECYCLE SIMULATOR ===")

    print("\nChecking backend...")

    if not check_backend():
        print("Backend is not responding.")
        return

    print("\nBackend ready.")
    input("\nPress Enter to start low-HR lifecycle...")

    run_lifecycle()


if __name__ == "__main__":
    main()
