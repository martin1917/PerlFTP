const BASE_URL = "/perl_ftp";

$(document).ready(function() {
    let currentPath = $(".pwd > div").html();
    let prev_view_file;

    if (currentPath == "/") {
        currentPath = "";
    }

    // Обработчик для двойного нажатия на папку
    const divsFolders = document.querySelectorAll(".it_folder");
    for (const div of divsFolders) {
        div.addEventListener("dblclick", (e) => {
            let folderName = div.innerHTML;
            let path = `${currentPath}/${folderName}`;
            update(path);
        })
    }

    const files = document.querySelectorAll(".file > div:not(.it_folder)")
    for (let i = 0; i < files.length; i += 2) {
        const fileDiv = files[i];
        const sizeDiv = files[i+1];

        const myRe = /bytes: (\d+)/g;
        const myArray = myRe.exec(sizeDiv.innerHTML);
        const size = myArray[1] - '';

        fileDiv.addEventListener("dblclick", (e) => {
            let path = `${currentPath}/${fileDiv.innerHTML}`;
            if (path != prev_view_file) {
                prev_view_file = path;
                if (size < 10000) {
                    $.ajax({
                        url: "get_content.pl",
                        method: "POST",
                        headers: { "Content-Type": "text/plain" },
                        data: JSON.stringify({path: path}),
                        success: (res) => {
                            $(".view_file_name").html(`Файл: ${fileDiv.innerHTML}`);
                            $(".view_file_content").html(res);
                        }
                    });
                } else {
                    $(".view_file_name").html(`Файл: ${fileDiv.innerHTML}`);
                    const message = `<h2>Слишком большой файл ${sizeDiv.innerHTML}<br>Макс. кол-во байтов = 10000<h2>`;
                    $(".view_file_content").html(message);
                }
            }
        })
    }

    // Обработчик для поднятия наверх в файловой системе
    $("#btn_back").click(function() {
        let i = currentPath.lastIndexOf("/");
        const backPath = currentPath.substring(0, i);
        update(backPath);
    });

    $("#btn_root").click(function() {
        update("");
    });
    
    // Обработчик для скачивания файлов
    $("#btn_download").click(function() {
        const { files, folders } = getSelectedItems();
        
        if (files.length == 0 && folders.length == 0) {
            alert(`Вы не выбрали файлы для скачивания!`);
            return;
        }
        
        const localPath = prompt("Путь на локальной машине");
        if (localPath == undefined || localPath == null || localPath.trim() == "") {
            return;
        }

        if (files.length != 0 || folders.length != 0) {
            const postData = {
                path: currentPath,
                localPath: localPath,
                files: files,
                folders: folders
            };    
            $.ajax({
                url: "get.pl",
                method: "POST",
                headers: { "Content-Type": "text/plain" },
                data: JSON.stringify(postData),
                error: function() {
                    alert("Указанный путь не существует");
                },
                success: () => {
                    document.querySelectorAll(`input[type='checkbox']:checked`)
                        .forEach(cb => cb.checked = false);
                    alert("Файлы скачаны");
                }
            });
        }
    });

    // Обработчик для удаления файлов
    $("#btn_delete").click(function() {
        const { files, folders } = getSelectedItems();
        if (files.length != 0 || folders.length != 0) {
            const postData = {
                path: currentPath,
                files: files,
                folders: folders
            };    
            $.ajax({
                url: "delete.pl",
                method: "POST",
                headers: { "Content-Type": "text/plain" },
                data: JSON.stringify(postData),
                success: () => update(currentPath)
            });
        }
    })

    // Обработчики для загрузки файла
    $("#btn_upload").click(() => $("#uploadForm_input_file").click());
    $("#uploadForm_input_file").change(() => $("#uploadForm").submit());
    $("#uploadForm").submit(e => {
        e.preventDefault();
        let formData = new FormData();
        formData.append("path", currentPath);
        formData.append("file", $("#uploadForm_input_file")[0].files[0]);
        $.ajax({
            url: "put.pl",
            method: "POST",
            processData: false,
            contentType: false,
            data: formData,
            success: () => update(currentPath)
        });
    }); 

    // Обработчики для создания папки
    $("#btn_mkdir").click(function() {
        let folderName = prompt("Название папки");
        if (folderName == null || folderName == undefined) {
            return;
        }

        folderName = folderName.trim();
        if (folderName == "" || folderName.startsWith(".")) {
            alert("Некорректное имя для папки");
            return;
        }

        let fullPath = `${currentPath}/${folderName}`;

        $.ajax({
            url: "mkdir.pl",
            method: "POST",
            headers: { "Content-Type": "text/plain; charset=utf-8" },
            data: JSON.stringify({ path: fullPath }),
            error: (e) => {
                alert(`Директория '${folderName}' уже существует!`);
            },
            success: () => update(currentPath)
        })
    })

    // Обработчики для отключения от ftp
	$("#btn_disconnect").click(function() {
		deleteAllCookies();
		document.location.href = BASE_URL;
	})
})

function update(path) {
    $("#updateForm_input_path").val(path);
    $("#updateForm").submit();
}

function getSelectedItems() {
    const files = [];
    const folders = [];
    const checkboxes = document.querySelectorAll(`input[type='checkbox']:checked`);
    for (const checkbox of checkboxes) {
        const divFile = checkbox.parentNode;
        const nameFile = divFile.querySelector("div").innerHTML;
        if (checkbox.className == "cb_file") {
            files.push(nameFile);
        } else if (checkbox.className == "cb_folder") {
            folders.push(nameFile);
        }
    }

    return { files: files, folders: folders };
}

function deleteAllCookies() {
    let cookies = document.cookie.split("; ");
	for (let c = 0; c < cookies.length; c++) {
		let d = window.location.hostname.split(".");
		while (d.length > 0) {
			let cookieBase = 
                encodeURIComponent(cookies[c].split(";")[0].split("=")[0])
                + '=; expires=Thu, 01-Jan-1970 00:00:01 GMT; domain='
                + d.join('.') + ' ;path=';

			let p = location.pathname.split('/');
			document.cookie = cookieBase + '/';
			while (p.length > 0) {
				document.cookie = cookieBase + p.join('/');
				p.pop();
			};
			d.shift();
		}
	}
}