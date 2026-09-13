import os
import time
from datetime import datetime, timezone

import requests


BASE_URL = os.getenv(
    "ALERA_BASE_URL",
    "https://alera-backend-i1ui.onrender.com",
)

PATIENT_ID = "a076ecdb-ae38-4f84-b490-e714977027ee"
TOKEN = os.environ["ALERA_PATIENT_TOKEN"]

INTERVAL_SECONDS = 5


def send_status(
    device_type: str,
    *,
    battery: int,
    status: str,
    label: str,
) -> None:
    payload = {
        "patient_id": PATIENT_ID,
        "device_type": device_type,
        "device_name": "Phone" if device_type == "PHONE" else "Watch",
        "device_model": "Lifecycle Simulator",
        "battery_percent": battery,
        "connection_status": status,
        "reported_at": datetime.now(timezone.utc).isoformat(),
    }

    print()
    print(f"=== {label} ===")
    print(
        f"{device_type} | battery={battery}% | status={status}"
    )

    response = requests.post(
        f"{BASE_URL}/api/v1/device-status",
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=90,
    )

    print(f"HTTP {response.status_code}")

    if response.ok:
        data = response.json()

        print(
            f"Stored: "
            f"{data['device_type']} | "
            f"{data['battery_percent']}% | "
            f"{data['connection_status']} | "
            f"applied={data['applied']}"
        )
    else:
        print(response.text)

    response.raise_for_status()

    time.sleep(INTERVAL_SECONDS)


def main() -> None:
    print()
    print("====================================")
    print("   ALERA DEVICE LIFECYCLE TEST")
    print("====================================")
    print(f"Patient: {PATIENT_ID}")
    print()

    # -------------------------------------------------
    # 1. Initial healthy state
    # -------------------------------------------------

    send_status(
        "PHONE",
        battery=80,
        status="CONNECTED",
        label="PHONE NORMAL",
    )

    send_status(
        "WATCH",
        battery=75,
        status="CONNECTED",
        label="WATCH NORMAL",
    )

    # -------------------------------------------------
    # 2. Watch disconnect while phone is healthy
    # -------------------------------------------------

    send_status(
        "WATCH",
        battery=74,
        status="DISCONNECTED",
        label="WATCH DISCONNECTED - should create alert",
    )

    send_status(
        "WATCH",
        battery=73,
        status="CONNECTED",
        label="WATCH RECONNECTED - should resolve alert",
    )

    # -------------------------------------------------
    # 3. Phone low battery lifecycle
    # -------------------------------------------------

    send_status(
        "PHONE",
        battery=20,
        status="CONNECTED",
        label="PHONE 20% - boundary, should still be normal",
    )

    send_status(
        "PHONE",
        battery=19,
        status="CONNECTED",
        label="PHONE LOW BATTERY - should create alert",
    )

    send_status(
        "PHONE",
        battery=10,
        status="CONNECTED",
        label="PHONE STILL LOW - should NOT duplicate alert",
    )

    send_status(
        "PHONE",
        battery=20,
        status="CONNECTED",
        label="PHONE BATTERY RECOVERED - should resolve alert",
    )

    # -------------------------------------------------
    # 4. Watch low battery lifecycle
    # -------------------------------------------------

    send_status(
        "WATCH",
        battery=19,
        status="CONNECTED",
        label="WATCH LOW BATTERY - should create alert",
    )

    send_status(
        "WATCH",
        battery=12,
        status="CONNECTED",
        label="WATCH STILL LOW - should NOT duplicate alert",
    )

    send_status(
        "WATCH",
        battery=21,
        status="CONNECTED",
        label="WATCH BATTERY RECOVERED - should resolve alert",
    )

    # -------------------------------------------------
    # 5. Phone disconnect
    #
    # Important:
    # Backend should automatically mark WATCH as UNKNOWN.
    # -------------------------------------------------

    send_status(
        "PHONE",
        battery=60,
        status="DISCONNECTED",
        label=(
            "PHONE DISCONNECTED - should create phone alert "
            "and force WATCH UNKNOWN"
        ),
    )

    # -------------------------------------------------
    # 6. Phone reconnects
    #
    # Phone alert should resolve.
    # Watch should remain UNKNOWN until its own heartbeat arrives.
    # -------------------------------------------------

    send_status(
        "PHONE",
        battery=59,
        status="CONNECTED",
        label=(
            "PHONE RECONNECTED - phone alert should resolve; "
            "watch still UNKNOWN"
        ),
    )

    # -------------------------------------------------
    # 7. Watch heartbeat returns
    # -------------------------------------------------

    send_status(
        "WATCH",
        battery=55,
        status="CONNECTED",
        label="WATCH RECONNECTED AFTER PHONE RECOVERY",
    )

    # -------------------------------------------------
    # Final healthy state
    # -------------------------------------------------

    send_status(
        "PHONE",
        battery=58,
        status="CONNECTED",
        label="FINAL PHONE HEALTHY",
    )

    send_status(
        "WATCH",
        battery=54,
        status="CONNECTED",
        label="FINAL WATCH HEALTHY",
    )

    print()
    print("====================================")
    print("   DEVICE LIFECYCLE COMPLETE")
    print("====================================")


if __name__ == "__main__":
    main()