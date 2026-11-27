package com.digitallab.predigeo

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal. Además de alojar Flutter, expone el barómetro del
 * dispositivo (sensor TYPE_PRESSURE) mediante canales de plataforma propios,
 * sin paquetes externos:
 *  - MethodChannel "predigeo/barometer/method": isAvailable -> Boolean
 *  - EventChannel  "predigeo/barometer/events": presión en hPa (Double)
 */
class MainActivity : FlutterActivity() {
    private var pressureListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val pressureSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "predigeo/barometer/method").setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(pressureSensor != null)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "predigeo/barometer/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    if (pressureSensor == null) {
                        events.error("UNAVAILABLE", "El dispositivo no tiene barómetro", null)
                        return
                    }
                    val listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            events.success(event.values[0].toDouble())
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    pressureListener = listener
                    sensorManager.registerListener(
                        listener,
                        pressureSensor,
                        SensorManager.SENSOR_DELAY_UI,
                    )
                }

                override fun onCancel(arguments: Any?) {
                    pressureListener?.let { sensorManager.unregisterListener(it) }
                    pressureListener = null
                }
            },
        )
    }

    override fun onDestroy() {
        pressureListener?.let {
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(it)
        }
        pressureListener = null
        super.onDestroy()
    }
}
