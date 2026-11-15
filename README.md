# Seminarski rad: Dockerizacija WordPress aplikacije

**Fakultet organizacionih nauka (FON) | Predmet: Cloud Computing**

---

## 📖 Opis projekta

Ovaj repozitorijum sadrži kompletno rešenje za višekontejnersku (multi-container) dockerizaciju postojećeg WordPress veb sajta i e-trgovine. Sistem se sastoji od tri međusobno povezana servisa koji komuniciraju preko izolovane Docker mreže:

1. **WordPress** (PHP 8.2 + Apache) – prilagođena Docker slika sa predefinisanim Apache modulima (`rewrite`, `expires`, `headers`), optimizovanom PHP konfiguracijom i healthcheck proverom.
2. **MariaDB** (11.4) – relaciona baza podataka sa perzistentnim skladištenjem podataka i automatskom inicijalizacijom dump-a (`epos.sql`).
3. **phpMyAdmin** (5.2) – veb grafički interfejs za administraciju baze podataka.

### 🌐 Pristup servisima

| Servis | Kontejner | Interni port | Eksterni port (Host) | URL adresa |
| :--- | :--- | :--- | :--- | :--- |
| **WordPress Web Sajt** | `wp` | `80` | `8080` | [http://localhost:8080](http://localhost:8080) |
| **phpMyAdmin** | `pma` | `80` | `8081` | [http://localhost:8081](http://localhost:8081) |
| **MariaDB Baza** | `db` | `3306` | `3306` | `localhost:3306` |

---

## 📁 Struktura repozitorijuma

```text
CLOUDSeminarski/
├── .env                       # Konfiguracija environment varijabli (kredencijali, nazivi)
├── compose.yaml               # Docker Compose specifikacija za celokupan stack
├── run.ps1                    # Automatizovana PowerShell skripta za Windows okruženje
├── run.sh                     # Automatizovana Bash skripta za Linux / macOS okruženje
├── README.md                  # Dokumentacija projekta
├── epos.sql                   # SQL dump baze podataka (WordPress export)
├── backup_epos.sql            # Dodatna rezervna kopija baze
├── site/
│   └── wp-content/            # Bind-mount direktorijum (teme, pluginovi, uploads, prevodi)
└── docker/
    ├── wordpress/
    │   ├── Dockerfile         # Prilagođena definicija WordPress slike
    │   ├── .dockerignore      # Ignorisanje nepotrebnih fajlova pri build-u
    │   └── php.ini            # Custom PHP direktive (upload_max_filesize, memory_limit...)
    ├── db/
    │   ├── Dockerfile         # Prilagođena definicija MariaDB slike sa healthcheck-om
    │   └── init/
    │       ├── 01-fix-urls.sql# Skripta za usklađivanje URL-ova na http://localhost:8080
    │       └── 02-epos.sql    # Inicijalni podaci baze
    └── phpmyadmin/
        └── Dockerfile         # Dockerfile za phpMyAdmin servis
```

---

## ⚙️ Preduslovi

Pre pokretanja potrebno je imati instalirano:
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / macOS) ili Docker Engine + Docker Compose (Linux).
- Na Windows-u preporučeno korišćenje WSL2 backend-a.

---

## 🚀 Načini pokretanja

Aplikaciju je moguće pokrenuti na tri načina:
1. **Docker Compose** *(najjednostavniji i preporučeni način)*
2. **Skripte za automatizaciju** (`run.ps1` ili `run.sh`)
3. **Pojedinačne Docker CLI komande** *(za potrebe demonstracije i izveštaja)*

---

### Opcija 1: Pokretanje preko Docker Compose (Preporučeno)

Pokretanje svih servisa u pozadini:
```bash
docker compose up -d --build
```

Provera statusa servisa:
```bash
docker compose ps
```

Uvid u logove:
```bash
docker compose logs -f
```

Zaustavljanje servisa:
```bash
docker compose down
```
*(Ukoliko želite i brisanje volumena baze podataka, dodajte zastavicu `-v`: `docker compose down -v`)*

---

### Opcija 2: Pokretanje pomoću gotovih skripti

#### Windows (PowerShell):
```powershell
.\run.ps1
```

#### Linux / macOS (Bash):
```bash
chmod +x run.sh
./run.sh
```

Ove skripte automatski očitavaju konfiguraciju iz `.env`, bildaju sve Docker slike, kreiraju mrežu i volumen, te startuju kontejnere sa odgovarajućim parametrima.

---

### Opcija 3: Ručno pokretanje putem Docker CLI komandi

Ovaj korak po korak prikazuje ručno podizanje celog sistema pomoću Docker terminal komandi:

#### 1. Build Docker imidža
```bash
docker build -t fon/wp:1.0 docker/wordpress
docker build -t fon/db:1.0 docker/db
docker build -t fon/pma:1.0 docker/phpmyadmin
```

#### 2. Kreiranje mreže i volumena
```bash
# Kreiranje zajedničke mreže
docker network create fon-net

# Kreiranje perzistentnog volumena za MariaDB
docker volume create fon-db
```

#### 3. Pokretanje MariaDB kontejnera
```bash
# PowerShell primer:
docker run -d --name db --hostname db --network fon-net `
  -p 3306:3306 `
  --env-file .env `
  -e MARIADB_DATABASE=epos `
  -e MARIADB_USER=root `
  -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=yes `
  -v fon-db:/var/lib/mysql `
  --restart unless-stopped fon/db:1.0
```
> *Napomena za Bash (Linux/macOS): Zamenite znak ` na kraju linije kosom crtom `\`.*

#### 4. Pokretanje WordPress kontejnera (sa Bind-Mount-om)
```bash
# PowerShell primer:
docker run -d --name wp --hostname wp --network fon-net `
  -p 8080:80 `
  --env-file .env `
  -e WORDPRESS_DB_HOST=db:3306 `
  -e WORDPRESS_DB_NAME=epos `
  -e WORDPRESS_DB_USER=root `
  -e WORDPRESS_DB_PASSWORD="" `
  -v "${PWD}/site/wp-content:/var/www/html/wp-content" `
  --restart unless-stopped fon/wp:1.0
```

#### 5. Pokretanje phpMyAdmin kontejnera
```bash
docker run -d --name pma --hostname pma --network fon-net `
  -p 8081:80 `
  -e PMA_HOST=db `
  -e PMA_PORT=3306 `
  --restart unless-stopped fon/pma:1.0
```

---

## 💾 Rad sa bazom podataka (Import / Export)

### Automatska inicijalizacija
Prilikom prvog pokretanja baze kroz `docker compose` ili definisani mount u `docker/db/init/`, MariaDB automatski učitava:
- `01-fix-urls.sql` – ažurira WordPress opcije `siteurl` i `home` na `http://localhost:8080`.
- `02-epos.sql` – kreira i popunjava tabele celog sajta.

### Ručni import SQL dump-a:
Ukoliko je potrebno ručno ponovo uvesti dump u bazu:
```bash
# PowerShell:
Get-Content epos.sql | docker exec -i db mariadb -u root epos

# Linux / macOS Bash:
docker exec -i db mariadb -u root epos < epos.sql
```

### Ručni export (Backup) baze:
```bash
# PowerShell:
docker exec db mariadb-dump -u root epos > backup_export.sql

# Linux / macOS Bash:
docker exec db mariadb-dump -u root epos > backup_export.sql
```

---

## 🔍 Provera rada sistema i inspekcija

Komande za verifikaciju i dijagnostiku statusa:

```bash
# Prikaz kreiranih imidža
docker images

# Prikaz statusa pokrenutih kontejnera
docker ps

# Prikaz perzistentnih volumena
docker volume ls

# Prikaz docker mreža
docker network ls

# Detaljna provera mount-a i mrežnih adresa kontejnera
docker inspect wp

# Prikaz logova kontejnera
docker logs wp --tail 50
docker logs db --tail 50

# HTTP test odziva WordPress servisa
curl -I http://localhost:8080
```

---

## 🌟 Ključne karakteristike implementacije

- **Prilagođeni Dockerfile za sve servise:** Svi servisi poseduju namenske `Dockerfile` definicije.
- **Optimizacija Build procesa (`.dockerignore`):** Sprečeno je slanje privremenih datoteka, arhiva i git istorije u build kontekst.
- **Prilagođena PHP konfiguracija (`php.ini`):**
  - `upload_max_filesize = 64M`
  - `post_max_size = 64M`
  - `memory_limit = 256M`
  - `max_execution_time = 120`
- **Healthcheck mehanizmi:**
  - MariaDB vrši proveru kroz `mariadb-admin ping`.
  - WordPress proverava HTTP statusni kod preko `curl`.
- **Sigurno konfigurisanje (`.env`):** Izdvajanje varijabli okruženja iz koda radi fleksibilnosti i portabilnosti.
- **Bind-Mount mehanizam:** Direktorijum `site/wp-content` je montiran direktno sa host mašine, omogućavajući lokalne izmene tema, dodataka i medija u realnom vremenu bez potrebe za ponovnim buildovanjem slike.

---

## 🧹 Zaustavljanje i uklanjanje resursa

```bash
# Zaustavljanje kontejnera
docker stop wp pma db

# Brisanje kontejnera
docker rm wp pma db

# (Opciono) Uklanjanje mreže i volumena
docker network rm fon-net
docker volume rm fon-db
```

---

## 📸 Checklista za dokumentaciju (Screenshot-ovi)

Za potrebe izveštaja i odbrane seminarskog rada, preporučuje se evidentiranje sledećih koraka:
- [ ] Izlaz komandi `docker build` za sve tri komponente (`fon/wp:1.0`, `fon/db:1.0`, `fon/pma:1.0`).
- [ ] Prikaz liste slika: `docker images`.
- [ ] Kreiranje i lista mreža i volumena: `docker network ls` i `docker volume ls`.
- [ ] Pokretanje kontejnera i prikaz aktivnih procesa: `docker ps`.
- [ ] Inspekcija bind-mount-a na kontejneru: `docker inspect wp`.
- [ ] Prikaz rada u veb pretraživaču:
  - Naslovna strana WordPress sajta ([http://localhost:8080](http://localhost:8080)).
  - Admin/login ili shop stranica WordPress-a.
  - phpMyAdmin radna površina ([http://localhost:8081](http://localhost:8081)).
- [ ] Prikaz logova: `docker logs wp` i `docker logs db`.
