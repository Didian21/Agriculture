package com.example.agriculture

import android.graphics.Color
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.osmdroid.config.Configuration
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Polygon
import org.osmdroid.views.overlay.Polyline
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : AppCompatActivity() {

    private lateinit var map: MapView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // I-configure ang OSMDroid configuration
        Configuration.getInstance().load(applicationContext, getPreferences(MODE_PRIVATE))

        // Gumawa ng MapView at i-center sa Pagsanjan, Laguna
        map = MapView(this).apply {
            setMultiTouchControls(true)
            controller.setZoom(14.0)
            controller.setCenter(GeoPoint(14.2790, 121.4173))
        }

        setContentView(map)

        // 1. I-load ang Landuse (Polygon na may semi-transparent green fill)
        loadGeoJsonPolygon("pagsanan_landuse.geojson", fillColor = Color.parseColor("442E7D32"), strokeColor = Color.parseColor("#1B5E20"))

        // 2. I-load ang Waterways (Polyline na kulay Asul)
        loadGeoJsonLine("pagsanjan_waterway.geojson", strokeColor = Color.BLUE, strokeWidth = 3.0f)

        // 3. I-load ang Roadways (Polyline na kulay Dark Gray)
        loadGeoJsonLine("pagsanjanroadway.geojson", strokeColor = Color.DKGRAY, strokeWidth = 3.5f)
    }

    // Function para mag-load ng Polygons (Landuse)
    private fun loadGeoJsonPolygon(fileName: String, fillColor: Int, strokeColor: Int) {
        try {
            val jsonString = assets.open(fileName).bufferedReader().use { it.readText() }
            val jsonObject = JSONObject(jsonString)
            val features = jsonObject.getJSONArray("features")

            for (i in 0 until features.length()) {
                val feature = features.getJSONObject(i)
                val geometry = feature.getJSONObject("geometry")
                val type = geometry.getString("type")
                val coordinates = geometry.getJSONArray("coordinates")

                if (type == "Polygon") {
                    val ring = coordinates.getJSONArray(0)
                    val points = parseRing(ring)
                    val polygon = Polygon(map).apply {
                        this.points = points
                        this.fillColor = fillColor
                        this.strokeColor = strokeColor
                        this.strokeWidth = 2.0f
                    }
                    map.overlays.add(polygon)
                } else if (type == "MultiPolygon") {
                    for (p in 0 until coordinates.length()) {
                        val polygonCoords = coordinates.getJSONArray(p)
                        val ring = polygonCoords.getJSONArray(0)
                        val points = parseRing(ring)
                        val polygon = Polygon(map).apply {
                            this.points = points
                            this.fillColor = fillColor
                            this.strokeColor = strokeColor
                            this.strokeWidth = 2.0f
                        }
                        map.overlays.add(polygon)
                    }
                }
            }
            map.invalidate()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Function para mag-load ng Lines/Polylines (Waterways at Roadways)
    private fun loadGeoJsonLine(fileName: String, strokeColor: Int, strokeWidth: Float) {
        try {
            val jsonString = assets.open(fileName).bufferedReader().use { it.readText() }
            val jsonObject = JSONObject(jsonString)
            val features = jsonObject.getJSONArray("features")

            for (i in 0 until features.length()) {
                val feature = features.getJSONObject(i)
                val geometry = feature.getJSONObject("geometry")
                val type = geometry.getString("type")
                val coordinates = geometry.getJSONArray("coordinates")

                if (type == "LineString") {
                    val points = parseRing(coordinates)
                    val polyline = Polyline(map).apply {
                        setPoints(points)
                        this.color = strokeColor
                        this.width = strokeWidth
                    }
                    map.overlays.add(polyline)
                } else if (type == "MultiLineString") {
                    for (l in 0 until coordinates.length()) {
                        val lineCoords = coordinates.getJSONArray(l)
                        val points = parseRing(lineCoords)
                        val polyline = Polyline(map).apply {
                            setPoints(points)
                            this.color = strokeColor
                            this.width = strokeWidth
                        }
                        map.overlays.add(polyline)
                    }
                }
            }
            map.invalidate()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Helper para i-convert ang GeoJSON coordinate arrays sa OSMDroid GeoPoints (Lat, Lon)
    private fun parseRing(ring: JSONArray): ArrayList<GeoPoint> {
        val points = ArrayList<GeoPoint>()
        for (j in 0 until ring.length()) {
            val coord = ring.getJSONArray(j)
            val lon = coord.getDouble(0)
            val lat = coord.getDouble(1)
            points.add(GeoPoint(lat, lon)) // OSMDroid gumagamit ng (Latitude, Longitude)
        }
        return points
    }

    override fun onResume() {
        super.onResume()
        map.onResume()
    }

    override fun onPause() {
        super.onPause()
        map.onPause()
    }
}
