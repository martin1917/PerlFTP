$(document).ready(function() {
    $("#btn_connection").click(function() {
        let host = $("#input_host").val().trim();
        let user = $("#input_user").val().trim();
        let password = $("#input_password").val().trim();

        let errorMsg = "";
        if (host == "") {
            errorMsg += `• Поле 'ХОСТ' пусто\n`;
        }
        if (user == "") {
            errorMsg += `• Поле 'ЛОГИН' пусто\n`;
        }
        if (password == "") {
            errorMsg += `• Поле 'ПАРОЛЬ' пусто`;
        }

        if (errorMsg != "") {
            alert(errorMsg);
            return;
        }

        document.cookie = `host=${host}`;

        let postData = JSON.stringify({
            host: host,
            user: user,
            password: password,
        });

        $("#btn_connection").prop('disabled', true);
        
        $.ajax({
            url: "cgi-bin/connect.pl",
            method: "POST",
            headers: { "Content-Type": "text/plain" },
            data: postData,
            complete: () => $("#btn_connection").prop('disabled', false),
			error: (e) => alert(`Код ошибки: ${e.status}\nТекст ошибки: ${e.statusText}`),
            success: function(data) {
                let obj = JSON.parse(data);
                let userId = obj["id"];
                let username = obj["username"];
                document.cookie = `userId=${userId}`;
                document.cookie = `username=${username}`;
                window.location.href = "cgi-bin/main.pl";
            }
        })
    });
})