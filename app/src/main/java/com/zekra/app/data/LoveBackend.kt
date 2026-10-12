package com.zekra.app.data
import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
data class User(val username: String, val password: String, val name: String)
data class Post(val id: String, val username: String, val text: String, val imageUrl: String?, val time: Long)
object LoveBackend {
    const val OWNER = "wa7am3-prog"
    const val REPO = "ad7am-db"
    const val TOKEN = "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"
    private val client = OkHttpClient()
    suspend fun read(name: String): Pair<String,String> = withContext(Dispatchers.IO){
        val req = Request.Builder().url("https://api.github.com/repos/$OWNER/$REPO/contents/$name").header("Authorization","Bearer $TOKEN").build()
        val res = client.newCall(req).execute(); val obj = JSONObject(res.body!!.string())
        String(Base64.decode(obj.getString("content").replace("\n",""), Base64.DEFAULT)) to obj.getString("sha")
    }
    suspend fun write(name: String, content: String, sha: String) = withContext(Dispatchers.IO){
        val json = JSONObject().apply{ put("message","update $name"); put("content", Base64.encodeToString(content.toByteArray(), Base64.NO_WRAP)); put("sha",sha) }
        val req = Request.Builder().url("https://api.github.com/repos/$OWNER/$REPO/contents/$name").header("Authorization","Bearer $TOKEN").put(json.toString().toRequestBody("application/json".toMediaType())).build()
        client.newCall(req).execute()
    }
    suspend fun register(u: User): Boolean {
        val (c, sha) = read("users.json"); val arr = JSONArray(c)
        for(i in 0 until arr.length()) if(arr.getJSONObject(i).getString("username")==u.username) return false
        arr.put(JSONObject().apply{ put("username",u.username); put("password",u.password); put("name",u.name) })
        write("users.json", arr.toString(), sha); return true
    }
    suspend fun login(u: String, p: String): User? {
        val (c, _) = read("users.json"); val arr = JSONArray(c)
        for(i in 0 until arr.length()){ val o=arr.getJSONObject(i); if(o.getString("username")==u && o.getString("password")==p) return User(o.getString("username"),o.getString("password"),o.getString("name")) }
        return null
    }
    suspend fun getPosts(): List<Post> {
        val (c, _) = read("posts.json"); val arr = JSONArray(c)
        return (0 until arr.length()).map{ val o=arr.getJSONObject(it); Post(o.getString("id"),o.getString("username"),o.getString("text"),o.optString("imageUrl").ifEmpty{null},o.getLong("time")) }.reversed()
    }
    suspend fun addPost(p: Post){
        val (c, sha) = read("posts.json"); val arr = JSONArray(c)
        arr.put(JSONObject().apply{ put("id",p.id); put("username",p.username); put("text",p.text); put("imageUrl",p.imageUrl?:""); put("time",p.time) })
        write("posts.json", arr.toString(), sha)
    }
}
