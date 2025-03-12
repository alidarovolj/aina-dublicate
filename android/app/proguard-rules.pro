# Keep OkHttp and Conscrypt
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn org.bouncycastle.**
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# Keep OkHttp platform used only on JVM and when Conscrypt and OpenJSSE are available
-keep class okhttp3.internal.platform.ConscryptPlatform { *; }
-keep class okhttp3.internal.platform.OpenJSSEPlatform { *; }

# Keep any classes referenced in your code
-keep class org.conscrypt.** { *; }
-keep class org.openjsse.** { *; } 