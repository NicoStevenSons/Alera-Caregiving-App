import time
from datetime import datetime, timezone
from uuid import uuid4

import requests


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


SPO2_NORMAL = 97
SPO2_WARNING = 92
SPO2_CRITICAL = 85

WARNING_INTERVAL_SECONDS = 10
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
            f"lifecycle-spo2-{now.strftime('%Y%m%dT%H%M%S%fZ')}-{uuid4()}"
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
    print("\nSp02 Simulations.....")
    print("NORMAL → WARNING → CRITICAL → NORMAL\n")

    # 1. NORMAL
    print("[1/4]Normal.....")
    send_spo2(SPO2_NORMAL)

    time.sleep(3)

    # 2. WARNING
    print("\n[2/4]warninng...")
    print(
        f"Sending two consecutive {SPO2_WARNING}% readings..."
    )

    send_spo2(SPO2_WARNING)

    print(
        f"\nWaiting {WARNING_INTERVAL_SECONDS} seconds..."
    )

    time.sleep(WARNING_INTERVAL_SECONDS)

    send_spo2(SPO2_WARNING)

    print("\nWarning qualification completed...")

    time.sleep(3)

    # 3. CRITICAL
    print("\n[3/4] Critical....")
    print(
        "Leaving the existing warning unresolved "
        "and sending critical."
    )

    send_spo2(SPO2_CRITICAL)
    print(
        f"Waiting {CRITICAL_CONFIRMATION_SECONDS} seconds for the "
        "Critical confirmation sample..."
    )
    time.sleep(CRITICAL_CONFIRMATION_SECONDS)
    send_spo2(84)

    # 4. NORMAL / RECOVERY
    print("\n[4/4]Recovery....")
    time.sleep(3)
    send_spo2(SPO2_NORMAL)

    print("\nComplete....")
    print("Expected pushes: SpO2 Warning, then Critical escalation.")


def main():
    print("Spo2 Simulations...")

    print("\nChecking backend...")

    if not check_backend():
        print("Backend is not responding.")
        return

    print("\nBackend ready.")
    input("\nPress Enter to start SpO2 lifecycle...")

    run_lifecycle()


if __name__ == "__main__":
    main()
