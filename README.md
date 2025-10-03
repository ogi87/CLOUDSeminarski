# Seminarski – Dockerizacija WordPress aplikacije (FON, Cloud)

**Tim:**  
- Ime Prezime (Broj Indeksa)  
- Ime Prezime (Broj Indeksa)  
- Ime Prezime (Broj Indeksa)

**Opis:**  
U ovom repozitorijumu se nalazi minimalni ali potpun setup za dockerizaciju postojećeg WordPress sajta: prilagođene Docker slike (Dockerfile za svaki servis), mreža, volumeni, bind‑mount, pokretanje kontejnera isključivo kroz terminal, kao i spisak komandi koje treba screenshot‑ovati za dokumentaciju.

---

## Struktura
```
fon-wp-docker/
├─ .env
├─ run.ps1
├─ run.sh
├─ README.md
├─ site/
│  └─ wp-content/           # OVDE ubacite svoj postojeći wp-content (teme, pluginovi, upload)
└─ docker/
   ├─ wordpress/
   │  ├─ Dockerfile
   │  ├─ .dockerignore
   │  └─ php.ini
   ├─ db/
   │  └─ Dockerfile
   └─ phpmyadmin/
      └─ Dockerfile
```

## 1) Priprema (jednokratno)
- Instalirajte **Docker Desktop** (Windows/Mac) ili Docker Engine (Linux). Omogućite WSL2 na Windowsu.
- Otvorite **terminal** (PowerShell na Windowsu, Bash na Linux/Mac). Sve radimo iz root foldera `fon-wp-docker`.

## 2) Izmena .env (obavezno prilagoditi)
U fajlu `.env` podesite vrednosti (ime baze, korisnik, lozinke). Ove varijable će koristiti i DB i WP kontejneri.

## 3) Build Docker imidža (za svaku sliku imamo Dockerfile)
```bash
docker build -t fon/wp:1.0 docker/wordpress
docker build -t fon/db:1.0 docker/db
docker build -t fon/pma:1.0 docker/phpmyadmin
```

**Screenshot za dokumentaciju:**  
- Output svake `docker build` komande (sa oznakom `Successfully built`/`tagged`).  
- `docker images` (da se vide kreirani imidži).

## 4) Kreiranje mreže i volumena
```bash
# Mreža
docker network create fon-net

# Volumen za bazu (trajnost podataka)
docker volume create fon-db
```

**Bind‑mount (obavezni uslov):**  
Umesto volumena za WordPress kod, koristimo *bind‑mount* na `./site/wp-content` → `/var/www/html/wp-content`.  
Tu ubacite svoj stari `wp-content` (teme, pluginovi, uploads) iz prošlog projekta.

**Screenshot:**  
- `docker network ls`  
- `docker volume ls`

## 5) Start DB kontejnera (MariaDB)
```bash
docker run -d --name db --hostname db --network fon-net \
  -p 3306:3306 \
  --env-file .env \
  -e MARIADB_DATABASE=$Env:WP_DB_NAME \
  -e MARIADB_USER=$Env:WP_DB_USER \
  -e MARIADB_PASSWORD=$Env:WP_DB_PASSWORD \
  -e MARIADB_ROOT_PASSWORD=$Env:WP_DB_ROOT_PASSWORD \
  -v fon-db:/var/lib/mysql \
  --restart unless-stopped fon/db:1.0
```
> Na Bash/Linux-u zamenite `$Env:VAR` sa `$VAR` i uklonite `\` na kraju linija.

**Screenshot:**  
- `docker ps` (da se vidi da `db` radi)  
- `docker logs db --tail 50` (prvih par linija starta).

## 6) Start WordPress kontejnera
```bash
docker run -d --name wp --hostname wp --network fon-net \
  -p 8080:80 \
  --env-file .env \
  -e WORDPRESS_DB_HOST=db:3306 \
  -e WORDPRESS_DB_NAME=$Env:WP_DB_NAME \
  -e WORDPRESS_DB_USER=$Env:WP_DB_USER \
  -e WORDPRESS_DB_PASSWORD=$Env:WP_DB_PASSWORD \
  -v ${PWD}/site/wp-content:/var/www/html/wp-content \
  --restart unless-stopped fon/wp:1.0
```

**Alternativa (ako imate ceo WordPress kod):**  
Umesto samo `wp-content`, možete montirati ceo kod:  
`-v ${PWD}/site:/var/www/html`  
(Vodite računa da će to prebrisati fajlove iz slike; dobro je ako već imate kompletan projekat.)

**Screenshot:**  
- `docker ps` (da se vidi `wp` + port 8080)  
- Browser: `http://localhost:8080` (home stranica/screen).

## 7) Start phpMyAdmin (opciono, ali korisno)
```bash
docker run -d --name pma --hostname pma --network fon-net \
  -p 8081:80 \
  -e PMA_HOST=db \
  -e PMA_PORT=3306 \
  --restart unless-stopped fon/pma:1.0
```

**Screenshot:**  
- `http://localhost:8081` login ekran.

## 8) Konfigurisanje `wp-config.php`
U vašem `site/wp-content/../wp-config.php` (ako montirate ceo `site`), podesite:
```php
define( 'DB_NAME', getenv('WP_DB_NAME') ?: 'wordpress' );
define( 'DB_USER', getenv('WP_DB_USER') ?: 'wpuser' );
define( 'DB_PASSWORD', getenv('WP_DB_PASSWORD') ?: 'wpsecret' );
define( 'DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'db:3306' );
$table_prefix = getenv('WP_TABLE_PREFIX') ?: 'wp_';
```
*Ako montirate samo `wp-content`, onda koristite **installer** u browseru i unesite iste vrednosti kao u `.env`.*

## 9) Import postojeće baze (ako imate .sql dump)
```bash
# Windows PowerShell primer:
type .\backup.sql | docker exec -i db mariadb -u %WP_DB_USER% -p%WP_DB_PASSWORD% %WP_DB_NAME%

# Bash/Linux:
docker exec -i db mariadb -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" "$WP_DB_NAME" < backup.sql
```
**Screenshot:** izvršenje komande i eventualni output.

## 10) Provera i prikaz traženih stavki
```bash
docker images
docker ps
docker volume ls
docker network ls
docker inspect wp | grep -i -E "Mounts|Networks|IPAddress" -n
docker logs wp --tail 50
curl -I http://localhost:8080
```
**Screenshot:** svaki izlaz, plus browser sa pokrenutim sajtem.

## 11) Dodatne opcije (za višu ocenu)
- **.dockerignore** objašnjenje: isključujemo nepotrebne fajlove iz build konteksta → brže i sigurnije build‑ovanje.
- **Dodatne opcije build‑a:** npr. `--build-arg` za prosleđivanje verzija/flagova.
- **Dodatne opcije run‑a:** `--restart unless-stopped`, `--health-cmd`, custom `--hostname`, `--add-host` itd.
- **Bezbednost:** `.env` file van git‑a; ne komitovati lozinke.
- **Backup:** `docker exec db mariadb-dump ... > backup.sql` (napravite skriptu).

## 12) Gašenje i čišćenje
```bash
docker stop wp pma db
docker rm wp pma db
# Ostavite volumene ako želite da sačuvate podatke baze:
# docker volume rm fon-db
# docker network rm fon-net
```

---

## Šta screenshot‑ovati (checklista)
1. `docker build` za sve tri slike + `docker images`
2. `docker network create` + `docker network ls`
3. `docker volume create` + `docker volume ls`
4. `docker run` za DB, WP, (PMA) + `docker ps`
5. `docker inspect wp` (Mounts/Networks) – vidi se bind‑mount i mreža
6. `curl -I http://localhost:8080` i browser sa sajtem
7. (Opcionalno) Import baze: komanda + rezultat
8. `docker logs` izvod za WP/DB

## Autori
- Ime Prezime, br. indeksa …
- Ime Prezime, br. indeksa …
- Ime Prezime, br. indeksa …
