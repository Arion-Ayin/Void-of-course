package com.example.lioluna

import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import android.content.Context
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.ImageView
import android.widget.Button

class NativeAdFactory(val context: Context) : NativeAdFactory {

    override fun createNativeAd(ad: NativeAd, customOptions: Map<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.native_ad_factory, null) as NativeAdView

        // Associate the NativeAdView with the NativeAd object.
        adView.setNativeAd(ad)

        // Find the views.
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)

        // Set the media view.
        // val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        // adView.mediaView = mediaView

        // Set other ad assets.
        headlineView.text = ad.headline
        bodyView.text = ad.body
        (callToActionView as Button).text = ad.callToAction

        if (ad.icon != null) {
            iconView.setImageDrawable(ad.icon?.drawable)
            adView.iconView = iconView
        } else {
            iconView.visibility = ImageView.GONE
        }

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = callToActionView

        return adView
    }
}
