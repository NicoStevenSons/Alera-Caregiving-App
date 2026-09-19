from datetime import datetime, timedelta, timezone
from uuid import uuid4

import requests


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"

START_AHEAD_MINUTES = 5

NORMAL_VALUE = 75
WARNING_VALUE = 150

RESET_OFFSETS = [0, 15, 30, 45, 60, 75, 90]
WARNING_OFFSETS = [105, 120, 135, 150, 165, 180, 225]
RECOVERY_OFFSETS = [240, 255, 270, 285, 300, 315, 330]


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


def send_heart_rate(value, recorded_at, label):
    payload = {
        "patient_id": PATIENT_ID,
        "external_event_id": (
            f"fast-warning-recovery-"
            f"{recorded_at.strftime('%Y%m%dT%H%M%S%fZ')}-"
            f"{uuid4()}"
        ),
        "metric_type": "HEART_RATE",
        "numeric_value": value,
        "text_value": None,
        "boolean_value": None,
        "metric_unit": "bpm",
        "recorded_at": recorded_at.isoformat(),
        "validation_status": "VALID_REALTIME",
        "validation_reason": None,
        "raw_payload": {
            "source": "hr_warning_recovery_forced_test",
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
            f"[{label}] "
            f"{recorded_at.strftime('%H:%M:%S')} "
            f"HR {value} bpm -> HTTP {response.status_code}"
        )

        try:
            print("Response:", response.json())
        except Exception:
            print("Response:", response.text)

        if not response.ok:
            raise RuntimeError(
                f"{label} failed with HTTP {response.status_code}"
            )

    except requests.RequestException as error:
        raise RuntimeError(f"{label} request failed: {error}") from error


def send_phase(label, value, offsets, base_time):
    print(f"\n{label}")
    for index, offset in enumerate(offsets, start=1):
        send_heart_rate(
            value,
            base_time + timedelta(seconds=offset),
            f"{label} {index}/{len(offsets)}",
        )


def run_test():
    base_time = datetime.now(timezone.utc) + timedelta(
        minutes=START_AHEAD_MINUTES
    )

    print("\nFAST FORCED HR WARNING -> RECOVERY TEST")
    print("---------------------------------------")
    print(f"Patient: {PATIENT_ID}")
    print(f"Synthetic start: {base_time.isoformat()}")

    print(
        "\n[SETUP] Resetting any existing HR_HIGH tracker occurrence..."
        "\nThis is test setup only; it is not the alert being tested."
    )
    send_phase(
        "RESET",
        NORMAL_VALUE,
        RESET_OFFSETS,
        base_time,
    )

    print(
        "\n[1/2] Creating a fresh WARNING occurrence..."
        "\nThe requests are sent immediately, while recorded_at spans "
        "the backend's required 2-minute warning window."
    )
    send_phase(
        "WARNING",
        WARNING_VALUE,
        WARNING_OFFSETS,
        base_time,
    )

    print(
        "\n>>> WARNING SHOULD NOW EXIST <<<"
        "\nCheck the caregiver app / alerts endpoint / alerts table."
    )

    print("\n[2/2] Recovering the physiological HR condition...")
    send_phase(
        "RECOVERY",
        NORMAL_VALUE,
        RECOVERY_OFFSETS,
        base_time,
    )

    print("\nTEST COMPLETE")
    print("Expected backend behavior:")
    print("  1. Existing HR tracker occurrence normalized/reset")
    print("  2. Fresh HR_HIGH WARNING alert created")
    print("  3. HR_HIGH condition tracker becomes inactive after recovery")
    print()
    print(
        "Recovery does not automatically mark the caregiver Alert row "
        "RESOLVED; that remains a caregiver action."
    )
    print()
    print(
        "This test uses future synthetic timestamps. Real watch readings "
        "for this same patient can be treated as stale until the synthetic "
        "timeline has passed."
    )


def main():
    print("Starting forced Heart Rate Warning/Recovery test...")

    if not check_backend():
        print("Backend is not responding.")
        return

    run_test()


if __name__ == "__main__":
    main()
