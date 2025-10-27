<div align="center">

  <picture>
    <!-- Dark mode logo if available -->
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png" type="image/png" />
    <!-- Default (light) logo -->
    <img src="https://raw.githubusercontent.com/okhtaymp/vendpy/main/assets/logo.png" alt="vendpy — lightweight vendoring for Python" width="140" height="140" loading="lazy" decoding="async" style="max-width:100%;height:auto;" />
  </picture>

  <h1 style="margin:12px 0 6px;">vendpy</h1>

  <p style="margin:0 0 12px;">
    <strong>
      Lightweight vendoring for Python — install packages into a hidden local directory
      and auto‑enable them via <code>__venddeps__.py</code>.
    </strong>
  </p>

  <p>
    <a href="https://github.com/okhtaymp/vendpy/blob/main/vendor.sh">
      <img src="https://img.shields.io/badge/script-vendor.sh-blue?style=flat-square" alt="vendor.sh" />
    </a>
    <a href="https://github.com/okhtaymp/vendpy/blob/main/dwl.sh">
      <img src="https://img.shields.io/badge/downloader-dwl.sh-9cf?style=flat-square" alt="dwl.sh" />
    </a>
    <a href="https://www.python.org/">
      <img src="https://img.shields.io/badge/python-3.7%2B-blue?style=flat-square&logo=python" alt="Python 3.7+" />
    </a>
    <a href="https://opensource.org/license/python-2-0">
      <img src="https://img.shields.io/badge/license-PSF-green?style=flat-square" alt="PSF License" />
    </a>
  </p>

</div>

---

## ⚙️ Overview

`vendpy` is a **tiny Bash utility** that vendors Python dependencies locally — by default into `.third_party/python` — and auto‑creates `__venddeps__.py` so those packages are importable anywhere in your project.

* ✅ No virtualenv
* ✅ No system‑wide installs
* ✅ No extra deps

---

## 🚀 Quick Start

```bash
curl -L "https://raw.githubusercontent.com/okhtaymp/vendpy/main/dwl.sh" | bash
```

> `dwl.sh` downloads `vendor.sh` into the current directory with a clean summary (size + SHA256). It does not execute it.

---

## 📦 Usage (installer: <code>vendor.sh</code>)

**Run without saving (one‑liner):**

```bash
curl -L "https://raw.githubusercontent.com/okhtaymp/vendpy/main/vendor.sh" | bash
```

**Run the downloaded installer:**

```bash
bash ./vendor.sh
```

**Examples:**

```bash
# From requirements.txt in project root
bash ./vendor.sh

# Specific packages
bash ./vendor.sh click==8.3.0 requests

# Clear vendor dir before install
bash ./vendor.sh --clear

# Custom vendor path / Python interpreter
bash ./vendor.sh --vendor .hidden/deps --python /usr/bin/python3
```

------------------------------- | ------------------------------------------------------------- |
| Install from `requirements.txt` | `./vendor.sh`                                                 |
| Install specific packages       | `./vendor.sh click==8.3.0 requests`                           |
| Clear vendor dir before install | `./vendor.sh --clear`                                         |
| Custom vendor path / Python bin | `./vendor.sh --vendor .hidden/deps --python /usr/bin/python3` |

---

## 🧩 In Your Python Code

At the top of your main file:

```python
import __venddeps__  # adds .third_party/python to sys.path
import requests
```

That’s it — your vendored deps are available automatically.

---

## 📁 Typical Layout

```
myproject/
├── vendor.sh             # installer (runs pip --target into .third_party/python)
├── requirements.txt
├── __venddeps__.py       ← auto-generated on first run
├── .third_party/
│   └── python/
│       ├── click/
│       ├── requests/
│       └── ...
└── main.py
```

---

## 🔒 Security Tips

* Always review remote scripts before running them.
* Avoid `curl | bash` unless you **trust the source**.
* Verify integrity:

```bash
# dwl.sh prints SHA256 automatically for vendor.sh
# or compute manually if you fetched vendor.sh directly
sha256sum vendor.sh
```

---

## 🧠 Why vendpy?

* Self‑contained dependencies (ideal for deployments and CI).
* No need for `venv` or system installs.
* Clean, reproducible environments inside your repo.

---

## 🏷️ Repo Info

| Field         | Value                                          |
| ------------- | ---------------------------------------------- |
| **Repo name** | `vendpy`                                       |
| **License**   | PSF-2.0                                            |
| **Language**  | Bash / Python                                  |
| **Tags**      | `python`, `pip`, `vendor`, `bash`, `packaging` |

---

## 🤝 Contributing

Pull requests and issues are welcome!
Change the default vendor directory using `--vendor` or tweak the constant inside the script.

---

<p align="center">
  <i>Built for Python developers who want simple, self‑contained vendoring — without virtualenvs.</i>
</p>
