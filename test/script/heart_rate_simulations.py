import time
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import requests


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


# Multiple readings per state
HR_NORMAL_READINGS = [72, 75, 78, 74, 76, 73, 75]

HR_WARNING_READINGS = [
    138,
    140,
    142,
    139,
    141,
    140,
    138,
    142,
    140,
]

HR_CRITICAL_READINGS = [160, 164]

HR_RECOVERY_READINGS = [
    76,
    74,
    73,
    75,
    77,
    72,
    74,
]


# Timing
NORMAL_INTERVAL_SECONDS = 15

WARNING_INTERVAL_SECONDS = 15

CRITICAL_INTERVAL_SECONDS = 15
RECOVERY_INTERVAL_SECONDS = 15


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
            f"lifecycle-hr-{now.strftime('%Y%m%dT%H%M%S%fZ')}-{uuid4()}"
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
            "source": "hr_lifecycle_simulator",
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


def send_readings(label, readings, interval):
    print(f"\n{label} Starting...")
    started_at = datetime.now(timezone.utc)
    started_monotonic = time.monotonic()

    for i, value in enumerate(readings):
        target_elapsed = i * interval
        remaining = target_elapsed - (time.monotonic() - started_monotonic)
        if remaining > 0:
            print(f"Waiting {remaining:.1f} seconds for scheduled reading...")
            time.sleep(remaining)

        print(
            f"\n{label} reading "
            f"{i + 1}/{len(readings)}"
        )

        if not send_heart_rate(
            value,
            started_at + timedelta(seconds=target_elapsed),
        ):
            raise RuntimeError(f"{label} reading {i + 1} failed")


def run_lifecycle():
    print("\nHeart Rate Simulations....")

    print("\n[1/6]")

    send_readings(
        "Normal",
        HR_NORMAL_READINGS,
        NORMAL_INTERVAL_SECONDS,
    )

    time.sleep(3)

    print("\n[2/6]")

    print(
        "\nWarning readings will be sent every "
        f"{WARNING_INTERVAL_SECONDS} seconds."
    )

    send_readings(
        "Warning",
        HR_WARNING_READINGS,
        WARNING_INTERVAL_SECONDS,
    )

    print("\nTwo-minute Warning qualification completed.")

    time.sleep(3)

    print("\n[3/6]")

    print(
        "\nLeaving the existing warning unresolved "
        "and sending critical readings."
    )

    send_readings(
        "Critical",
        HR_CRITICAL_READINGS,
        CRITICAL_INTERVAL_SECONDS,
    )

    time.sleep(3)

    print("\n[4/6]")

    send_readings(
        "Recovery",
        HR_RECOVERY_READINGS,
        RECOVERY_INTERVAL_SECONDS,
    )

    time.sleep(3)

    print("\n[5/6]")
    print(
        "\nSending a new Critical occurrence while the earlier caregiver "
        "case may still be unresolved. This must create a new alert."
    )
    send_readings(
        "Recurrent Critical",
        [158, 162],
        CRITICAL_INTERVAL_SECONDS,
    )

    time.sleep(3)

    print("\n[6/6]")
    send_readings(
        "Final Recovery",
        HR_RECOVERY_READINGS,
        RECOVERY_INTERVAL_SECONDS,
    )

    print("\nLIFECYCLE COMPLETE")
    print("Expected pushes: Warning, Critical escalation, recurrent Critical.")


def main():
    print("Starting Heart Rate Simulations...")

    print("\nChecking backend...")

    if not check_backend():
        print("Backend is not responding...")
        return

    print("\nBackend ready.")

    input("\nPress Enter to start HR lifecycle...")

    run_lifecycle()


if __name__ == "__main__":
    main()
