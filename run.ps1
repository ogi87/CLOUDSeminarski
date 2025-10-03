
# Requires: Docker Desktop running
Set-Location -LiteralPath $PSScriptRoot

# Load env
$envContent = Get-Content .env | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
foreach ($line in $envContent) {
    if ($line -match '^\s*([^=]+)=(.*)$') {
        $key = $matches[1]; $val = $matches[2]
        [Environment]::SetEnvironmentVariable($key, $val)
    }
}

docker build -t fon/wp:1.0 docker/wordpress
docker build -t fon/db:1.0 docker/db
docker build -t fon/pma:1.0 docker/phpmyadmin

docker network create fon-net 2>$null | Out-Null
docker volume create fon-db 2>$null | Out-Null

docker run -d --name db --hostname db --network fon-net `
  -p 3306:3306 `
  --env-file .env `
  -e MARIADB_DATABASE=$Env:WP_DB_NAME `
  -e MARIADB_USER=$Env:WP_DB_USER `
  -e MARIADB_PASSWORD=$Env:WP_DB_PASSWORD `
  -e MARIADB_ROOT_PASSWORD=$Env:WP_DB_ROOT_PASSWORD `
  -v fon-db:/var/lib/mysql `
  --restart unless-stopped fon/db:1.0

docker run -d --name wp --hostname wp --network fon-net `
  -p 8080:80 `
  --env-file .env `
  -e WORDPRESS_DB_HOST=db:3306 `
  -e WORDPRESS_DB_NAME=$Env:WP_DB_NAME `
  -e WORDPRESS_DB_USER=$Env:WP_DB_USER `
  -e WORDPRESS_DB_PASSWORD=$Env:WP_DB_PASSWORD `
  -v ${PWD}/site/wp-content:/var/www/html/wp-content `
  --restart unless-stopped fon/wp:1.0

docker run -d --name pma --hostname pma --network fon-net `
  -p 8081:80 `
  -e PMA_HOST=db `
  -e PMA_PORT=3306 `
  --restart unless-stopped fon/pma:1.0

Write-Host "Pokrenuto. Proveri http://localhost:8080 i http://localhost:8081"
