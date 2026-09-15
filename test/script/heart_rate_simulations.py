import time
import requests

from datetime import datetime, timezone


BACKEND_URL = "https://alera-backend-i1ui.onrender.com"
PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"


# Multiple readings per state
HR_NORMAL_READINGS = [72, 75, 78]

HR_WARNING_READINGS = [
    138,
    140,
    142,
    139,
    141,
    140,
]

HR_CRITICAL_READINGS = [
    160,
    164,
    158,
]

HR_RECOVERY_READINGS = [
    76,
    74,
    73,
]


# Timing
NORMAL_INTERVAL_SECONDS = 15

# Keep warning readings <= 90 seconds apart
# so persistence continuity is maintained.
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


def send_heart_rate(value):
    now = datetime.now(timezone.utc)

    payload = {
        "patient_id": PATIENT_ID,
        "external_event_id": (
            f"lifecycle-hr-{now.strftime('%Y%m%dT%H%M%S%fZ')}"
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

    for i, value in enumerate(readings):
        print(
            f"\n{label} reading "
            f"{i + 1}/{len(readings)}"
        )

        send_heart_rate(value)

        if i < len(readings) - 1:
            print(
                f"Waiting {interval} seconds "
                "for next reading..."
            )

            time.sleep(interval)


def run_lifecycle():
    print("\nHeart Rate Simulations....")

    print("\n[1/4]")

    send_readings(
        "Normal",
        HR_NORMAL_READINGS,
        NORMAL_INTERVAL_SECONDS,
    )

    time.sleep(3)
    
    print("\n[2/4]")

    print(
        "\nWarning readings will be sent every "
        f"{WARNING_INTERVAL_SECONDS} seconds."
    )

    send_readings(
        "Warning",
        HR_WARNING_READINGS,
        WARNING_INTERVAL_SECONDS,
    )

    print("\nWarning persistence completed.")

    time.sleep(3)

    print("\n[3/4]")

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

    print("\n[4/4]")

    send_readings(
        "Recovery",
        HR_RECOVERY_READINGS,
        RECOVERY_INTERVAL_SECONDS,
    )

    print("\nLIFECYCLE COMPLETE....")


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