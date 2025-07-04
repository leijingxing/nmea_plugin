package com.hyzh.nmea_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NmeaPlugin : FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  // 定义通道名称，必须与 Flutter 端一致
  private val CHANNEL = "com.hyzh.location_test/nmea" // 保持和旧项目一致

  private lateinit var channel: MethodChannel
  private lateinit var locationManager: LocationManager
  private var nmeaListener: OnNmeaMessageListener? = null

  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
  private var activity: Activity? = null

  // --- FlutterPlugin 生命周期 ---

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = binding
    // 1. 初始化 MethodChannel
    channel = MethodChannel(binding.binaryMessenger, CHANNEL)
    // 2. 获取 Context 和 LocationManager
    val context = binding.applicationContext
    locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = null
  }

  // --- ActivityAware 生命周期 ---

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
    // 当 Activity 可用时，检查权限并开始监听
    checkPermissionAndStartListener()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    // Activity 销毁时，停止监听以防内存泄漏
    stopNmeaListener()
    this.activity = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  // --- 权限处理 ---

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
      if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        // 权限获取成功后，开始监听
        startNmeaListener()
      } else {
        // 可以选择通过 channel 告诉 Flutter 权限被拒绝
        channel.invokeMethod("onPermissionDenied", null)
      }
      return true // 表示我们处理了这个请求
    }
    return false
  }

  // --- 核心逻辑 ---

  private fun checkPermissionAndStartListener() {
    if (checkLocationPermission()) {
      startNmeaListener()
    } else {
      activity?.let {
        ActivityCompat.requestPermissions(
          it,
          arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
          LOCATION_PERMISSION_REQUEST_CODE
        )
      }
    }
  }

  private fun checkLocationPermission(): Boolean {
    val context = flutterPluginBinding?.applicationContext ?: return false
    return ActivityCompat.checkSelfPermission(
      context,
      Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun startNmeaListener() {
    // 再次检查权限和 activity 是否为空
    if (!checkLocationPermission() || activity == null) return

    // 如果监听器已存在，则先移除旧的
    stopNmeaListener()

    // 创建 NMEA 监听器
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      nmeaListener = OnNmeaMessageListener { message, _ ->
        // 通过 runOnUiThread 将数据发送到 Flutter
        activity?.runOnUiThread {
          channel.invokeMethod("onNmeaMessage", message)
        }
      }

      // 注册监听器
      activity?.runOnUiThread {
        locationManager.addNmeaListener(nmeaListener!!, null)
      }
    }
  }

  private fun stopNmeaListener() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      nmeaListener?.let {
        locationManager.removeNmeaListener(it)
      }
      nmeaListener = null
    }
  }

  companion object {
    private const val LOCATION_PERMISSION_REQUEST_CODE = 12345 // 使用一个插件专用的请求码
  }
}