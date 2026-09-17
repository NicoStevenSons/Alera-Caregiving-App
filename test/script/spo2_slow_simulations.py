import time
from datetime import datetime, timezone
from uuid import uuid4

import requests


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


SPO2_NORMAL = 97
SPO2_WARNING = 92
SPO2_CRITICAL = 85

# Real smartwatch cadence:
# one SpO2 reading every 3 minutes.
SPO2_READING_INTERVAL_SECONDS = 180

CRITICAL_CONFIRMATION_SECONDS = 15


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


def send_spo2(value):
    now = datetime.now(timezone.utc)

    payload = {
        "patient_id": PATIENT_ID,
        "external_event_id": (
            f"lifecycle-spo2-slow-{now.strftime('%Y%m%dT%H%M%S%fZ')}-{uuid4()}"
        ),
        "metric_type": "SPO2",
        "numeric_value": value,
        "text_value": None,
        "boolean_value": None,
        "metric_unit": "percent",
        "recorded_at": now.isoformat(),
        "validation_status": "VALID_REALTIME",
        "validation_reason": None,
        "raw_payload": {
            "source": "spo2_lifecycle_simulator",
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
            f"SpO2 {value}% → HTTP {response.status_code}"
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
    print("\n=== SPO2 LIFECYCLE ===")
    print("NORMAL → WARNING → CRITICAL → NORMAL\n")

    # 1. NORMAL
    print("[1/4] NORMAL")
    send_spo2(SPO2_NORMAL)

    print(
        f"\nWaiting {SPO2_READING_INTERVAL_SECONDS // 60} minutes "
        "for the next smartwatch reading..."
    )

    time.sleep(SPO2_READING_INTERVAL_SECONDS)

    # 2. WARNING
    print("\n[2/4] WARNING")

    print(
        f"First warning reading: {SPO2_WARNING}%"
    )

    send_spo2(SPO2_WARNING)

    print(
        f"\nWaiting {SPO2_READING_INTERVAL_SECONDS // 60} minutes "
        "for the next smartwatch reading..."
    )

    time.sleep(SPO2_READING_INTERVAL_SECONDS)

    print(
        f"\nSecond consecutive warning reading: "
        f"{SPO2_WARNING}%"
    )

    send_spo2(SPO2_WARNING)

    print("\nWarning qualification completed.")

    # 3. CRITICAL
    print("\n[3/4] CRITICAL")
    print(
        "Leaving the warning unresolved and sending "
        "two Critical confirmation readings."
    )

    send_spo2(SPO2_CRITICAL)
    print(
        f"Waiting {CRITICAL_CONFIRMATION_SECONDS} seconds for the explicit "
        "Critical confirmation sample..."
    )
    time.sleep(CRITICAL_CONFIRMATION_SECONDS)
    send_spo2(84)

    # 4. NORMAL / RECOVERY
    print("\n[4/4] NORMAL / RECOVERY")
    time.sleep(3)
    send_spo2(SPO2_NORMAL)

    print("\n=== LIFECYCLE COMPLETE ===")
    print("Expected pushes: SpO2 Warning, then Critical escalation.")


def main():
    print("=== ALERA SPO2 LIFECYCLE SIMULATOR ===")

    print("\nChecking backend...")

    if not check_backend():
        print("Backend is not responding.")
        return

    print("\nBackend ready.")
    input("\nPress Enter to start SpO2 lifecycle...")

    run_lifecycle()


if __name__ == "__main__":
    main()
