<h1 align="center">🐍 vendpy</h1>

<p align="center">
  <b>Lightweight vendoring for Python — install packages into a hidden local directory and auto-enable them via <code>__venddeps__.py</code>.</b>
</p>

<p align="center">
  <a href="https://github.com/<YOUR_USER>/vendpy/blob/main/install_vendor.sh"><img src="https://img.shields.io/badge/script-install_vendor.sh-blue?style=flat-square"></a>
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3.7%2B-blue?style=flat-square&logo=python"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square"></a>
</p>

---

## ⚙️ Overview

`vendpy` is a **tiny Bash utility** that lets you vendor Python dependencies locally — into `.third_party/python` by default — and automatically creates a helper `__venddeps__.py` file so you can import those packages anywhere in your project.

✅ No virtualenv
✅ No system-wide installs
✅ No extra dependencies

---

## 🧠 Why vendpy?

* Self-contained dependencies (ideal for deployments and CI).
* No need for `venv` or system installs.
* Clean, reproducible environments inside your repo.

---

## 🏷️ Repo Info

| Field         | Value                                          |
| ------------- | ---------------------------------------------- |
| **Repo name** | `vendpy`                                       |
| **License**   | MIT                                            |
| **Language**  | Bash / Python                                  |
| **Tags**      | `python`, `pip`, `vendor`, `bash`, `packaging` |

---

## 🤝 Contributing

Pull requests and issues are welcome!
Change the default vendor directory using `--vendor` or tweak the constant inside the script.

---

<p align="center">
  <i>Built for Python developers who want simple, self-contained vendoring — without virtualenvs.</i>
</p>

