package com.zekra.app
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.zekra.app.data.LoveBackend
import com.zekra.app.data.Post
import com.zekra.app.data.User
import kotlinx.coroutines.launch
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            var user by remember { mutableStateOf<User?>(null) }
            if (user == null) LoginScreen { user = it } else HomeScreen(user!!)
        }
    }
}

@Composable
fun LoginScreen(onLogin: (User) -> Unit) {
    var u by remember { mutableStateOf("") }; var p by remember { mutableStateOf("") }; var name by remember { mutableStateOf("") }; var isReg by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    Column(Modifier.padding(24.dp).fillMaxSize(), verticalArrangement = Arrangement.Center) {
        Text(if(isReg) "انشاء حساب" else "تسجيل دخول", style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(16.dp))
        if(isReg) OutlinedTextField(value=name, onValueChange={name=it}, label={Text("اسمك")}, modifier=Modifier.fillMaxWidth())
        OutlinedTextField(value=u, onValueChange={u=it}, label={Text("اسم المستخدم")}, modifier=Modifier.fillMaxWidth())
        OutlinedTextField(value=p, onValueChange={p=it}, label={Text("الباسورد")}, modifier=Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        Button(onClick={
            scope.launch {
                if(isReg){ if(LoveBackend.register(User(u,p,name))) onLogin(User(u,p,name)) }
                else { LoveBackend.login(u,p)?.let{ onLogin(it) } }
            }
        }, modifier=Modifier.fillMaxWidth()){ Text(if(isReg)"سجل" else "دخول") }
        TextButton(onClick={isReg=!isReg}){ Text(if(isReg)"عندي حساب" else "انشاء حساب جديد") }
    }
}

@Composable
fun HomeScreen(user: User) {
    var text by remember { mutableStateOf("") }; var posts by remember { mutableStateOf(listOf<Post>()) }
    val scope = rememberCoroutineScope()
    LaunchedEffect(Unit){ posts = LoveBackend.getPosts() }
    Column(Modifier.padding(16.dp).fillMaxSize()){
        Text("أهلاً ${user.name} ❤️")
        Row{ OutlinedTextField(value=text, onValueChange={text=it}, modifier=Modifier.weight(1f), placeholder={Text("اكتب ذكرى...")})
            Button(onClick={ scope.launch{ LoveBackend.addPost(Post(UUID.randomUUID().toString(), user.username, text, null, System.currentTimeMillis())); text=""; posts=LoveBackend.getPosts() } }){ Text("نشر") }
        }
        LazyColumn{ items(posts){ post -> Card(Modifier.fillMaxWidth().padding(vertical=4.dp)){ Column(Modifier.padding(12.dp)){ Text(post.username, style=MaterialTheme.typography.labelLarge); Text(post.text) } } } }
    }
}
