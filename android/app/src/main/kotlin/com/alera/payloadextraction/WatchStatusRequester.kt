package com.alera.payloadextraction

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.Wearable

class WatchStatusRequester(
    context: Context
) {
    companion object {
        private const val TAG =
            "AleraWatchRequest"

        private const val STATUS_REQUEST_PATH =
            "/alera/device-status/request"
    }

    private val nodeClient =
        Wearable.getNodeClient(context)

    private val messageClient =
        Wearable.getMessageClient(context)

    fun requestStatus() {
        nodeClient.connectedNodes
            .addOnSuccessListener { nodes ->

                if (nodes.isEmpty()) {
                    Log.w(
                        TAG,
                        "No connected watch found"
                    )

                    return@addOnSuccessListener
                }

                nodes.forEach { node ->

                    Log.d(
                        TAG,
                        "Requesting status from: " +
                            "${node.displayName} (${node.id})"
                    )

                    messageClient.sendMessage(
                        node.id,
                        STATUS_REQUEST_PATH,
                        ByteArray(0)
                    )
                        .addOnSuccessListener {
                            Log.d(
                                TAG,
                                "Status request sent to " +
                                    node.displayName
                            )
                        }
                        .addOnFailureListener { exception ->
                            Log.e(
                                TAG,
                                "Failed to send status request",
                                exception
                            )
                        }
                }
            }
            .addOnFailureListener { exception ->
                Log.e(
                    TAG,
                    "Failed to find connected watch",
                    exception
                )
            }
    }
}