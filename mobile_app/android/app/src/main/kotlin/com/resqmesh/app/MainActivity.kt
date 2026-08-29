package com.resqmesh.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var nearbyMeshPlugin: NearbyMeshPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Google Nearby Connections plugin
        val meshChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.resqmesh.app/nearby_mesh")
        nearbyMeshPlugin = NearbyMeshPlugin(applicationContext)
        nearbyMeshPlugin?.setMethodChannel(meshChannel)
    }
}
