sebuah applikasi yang berfungsi untuk remote server melalu SSH namun berbasis GUI, dengan alur 
1. ketika applikasi di buka akan membutuhkan kode secara default adalah 123456, 
2. ada fitur untuk input alamat ip / domain serta port, username, password serta apakah menggunakan public key atau tidak ,

3. jika berhasil konek maka akan masuk ke halaman yang menyediakan input untuk masuk ke direktory tertentu, kemudian ada beberapa tombol-tombol, seprti deploy, install & deploy, jadi sebenarnya akan berprilaku seperti terminal ssh hanya saja penulisan perintah terminalnya di wakili dengan tombol-tombol berbasis GUI, 

4. intinya applikasi ini untuk memudahkan dalam melakukan perintah pada server berbasis linux melalui ssh dengan mengganti perintah berbasis teks dengan tombol berbasis GUI,

5. targetny applikasi ini bisa dijalankan di windows dan macos, gunakan flutter versi terbaru. 