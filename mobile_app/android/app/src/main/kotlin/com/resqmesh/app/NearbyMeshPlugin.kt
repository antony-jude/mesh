package com.resqmesh.app

import android.content.Context
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets

/**
 * Native Android Plugin for Google Nearby Connections API (com.google.android.gms.nearby.connection)
 * Implements P2P_CLUSTER strategy for multi-hop store-and-forward disaster mesh relay.
 */
class NearbyMeshPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "ResQNearbyMesh"
        private const val SERVICE_ID = "com.resqmesh.app.mesh"
        private const val CHANNEL_NAME = "com.resqmesh.app/nearby_mesh"
    }

    private var methodChannel: MethodChannel? = null
    private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(context)

    private var localDeviceId: String = "UNKNOWN"
    private var localRole: String = "VICTIM"
    private val connectedEndpoints = mutableSetOf<String>()

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startMesh" -> {
                localDeviceId = call.argument<String>("deviceId") ?: "NODE_DEF"
                localRole = call.argument<String>("role") ?: "VICTIM"
                startMeshNetwork()
                result.success(true)
            }
            "stopMesh" -> {
                stopMeshNetwork()
                result.success(true)
            }
            "sendPayload" -> {
                val payloadString = call.argument<String>("payload") ?: ""
                val excludeEndpoint = call.argument<String>("excludeEndpoint")
                broadcastPayload(payloadString, excludeEndpoint)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startMeshNetwork() {
        Log.i(TAG, "Starting Nearby Connections P2P_CLUSTER mesh for $localDeviceId as $localRole")

        // 1. Start Advertising
        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startAdvertising(
            localDeviceId,
            SERVICE_ID,
            connectionLifecycleCallback,
            advertisingOptions
        ).addOnSuccessListener {
            Log.i(TAG, "Nearby Advertising active.")
        }.addOnFailureListener { e ->
            Log.e(TAG, "Nearby Advertising failed: ${e.message}")
        }

        // 2. Start Discovery
        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startDiscovery(
            SERVICE_ID,
            endpointDiscoveryCallback,
            discoveryOptions
        ).addOnSuccessListener {
            Log.i(TAG, "Nearby Discovery active.")
        }.addOnFailureListener { e ->
            Log.e(TAG, "Nearby Discovery failed: ${e.message}")
        }
    }

    private fun stopMeshNetwork() {
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
        connectionsClient.stopAllEndpoints()
        connectedEndpoints.clear()
        Log.i(TAG, "Nearby Connections mesh stopped.")
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            Log.i(TAG, "Discovered endpoint: ${info.endpointName} ($endpointId)")
            
            // Notify Flutter layer
            methodChannel?.invokeMethod("onEndpointDiscovered", mapOf(
                "endpointId" to endpointId,
                "endpointName" to info.endpointName
            ))

            // Auto-request connection to form decentralized mesh cluster
            connectionsClient.requestConnection(
                localDeviceId,
                endpointId,
                connectionLifecycleCallback
            )
        }

        override fun onEndpointLost(endpointId: String) {
            Log.w(TAG, "Lost endpoint: $endpointId")
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            Log.i(TAG, "Connection initiated from ${connectionInfo.endpointName} ($endpointId). Auto-accepting...")
            // Accept connection automatically in emergency mesh
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            when (result.status.statusCode) {
                ConnectionsStatusCodes.STATUS_OK -> {
                    Log.i(TAG, "Connected successfully to: $endpointId")
                    connectedEndpoints.add(endpointId)
                    methodChannel?.invokeMethod("onEndpointConnected", mapOf("endpointId" to endpointId))
                }
                else -> {
                    Log.w(TAG, "Connection rejected/failed with status: ${result.status.statusCode}")
                }
            }
        }

        override fun onDisconnected(endpointId: String) {
            Log.w(TAG, "Endpoint disconnected: $endpointId")
            connectedEndpoints.remove(endpointId)
            methodChannel?.invokeMethod("onEndpointDisconnected", mapOf("endpointId" to endpointId))
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val bytes = payload.asBytes() ?: return
                val payloadString = String(bytes, StandardCharsets.UTF_8)
                Log.i(TAG, "Received payload (${bytes.size} bytes) from $endpointId")

                // Forward to Flutter store-and-forward layer
                methodChannel?.invokeMethod("onPayloadReceived", mapOf(
                    "payload" to payloadString,
                    "senderEndpointId" to endpointId
                ))
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // Transfer status tracking if required
        }
    }

    private fun broadcastPayload(payloadString: String, excludeEndpoint: String?) {
        if (connectedEndpoints.isEmpty()) {
            Log.d(TAG, "No connected peers to broadcast payload.")
            return
        }

        val bytes = payloadString.toByteArray(StandardCharsets.UTF_8)
        val payload = Payload.fromBytes(bytes)

        val targetEndpoints = connectedEndpoints.filter { it != excludeEndpoint }
        if (targetEndpoints.isNotEmpty()) {
            connectionsClient.sendPayload(targetEndpoints, payload)
                .addOnSuccessListener {
                    Log.i(TAG, "Payload successfully transmitted to ${targetEndpoints.size} peers.")
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Payload transmission failed: ${e.message}")
                }
        }
    }
}
