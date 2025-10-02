# Script de verificación para Windows PowerShell
Write-Host "🔍 Verificando código antes de compilar..." -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ No se encontró pubspec.yaml. Ejecuta desde la raíz del proyecto Flutter." -ForegroundColor Red
    exit 1
}

# Ejecutar flutter analyze
Write-Host "📊 Ejecutando flutter analyze..." -ForegroundColor Yellow
$analyzeResult = flutter analyze 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ flutter analyze: Sin errores encontrados" -ForegroundColor Green
} else {
    Write-Host "❌ flutter analyze encontró errores:" -ForegroundColor Red
    Write-Host $analyzeResult
}

# Verificar archivos específicos
Write-Host "`n📄 Verificando archivos específicos..." -ForegroundColor Yellow

$filesToCheck = @(
    "lib/screens/client_invoice_screen.dart",
    "lib/screens/clients_screen.dart",
    "lib/screens/invoice_screen.dart"
)

foreach ($filePath in $filesToCheck) {
    if (Test-Path $filePath) {
        Write-Host "  📄 Verificando: $filePath" -ForegroundColor Blue
        Check-FileContent $filePath
    } else {
        Write-Host "  ⚠️  Archivo no encontrado: $filePath" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 Verificación completada" -ForegroundColor Green

function Check-FileContent {
    param($filePath)
    
    $content = Get-Content $filePath -Raw
    $lines = $content -split "`n"
    
    $hasIssues = $false
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i].Trim()
        
        # Verificar clases anidadas
        if ($line -match "^class\s+\w+.*\{$") {
            $openBraces = 0
            for ($j = 0; $j -lt $i; $j++) {
                $prevLine = $lines[$j]
                $openBraces += ($prevLine.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $openBraces -= ($prevLine.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            }
            
            if ($openBraces -gt 0) {
                Write-Host "    ❌ Línea $($i + 1): Clase anidada: $line" -ForegroundColor Red
                $hasIssues = $true
            }
        }
        
        # Verificar imports faltantes
        if ($line -match "InvoiceItem" -and $content -notmatch "import.*invoice\.dart") {
            Write-Host "    ❌ Línea $($i + 1): InvoiceItem sin import: $line" -ForegroundColor Red
            $hasIssues = $true
        }
        
        if ($line -match "Client" -and $content -notmatch "import.*client\.dart") {
            Write-Host "    ❌ Línea $($i + 1): Client sin import: $line" -ForegroundColor Red
            $hasIssues = $true
        }
        
        if ($line -match "Product" -and $content -notmatch "import.*product\.dart") {
            Write-Host "    ❌ Línea $($i + 1): Product sin import: $line" -ForegroundColor Red
            $hasIssues = $true
        }
    }
    
    if (-not $hasIssues) {
        Write-Host "    ✅ Sin problemas detectados" -ForegroundColor Green
    }
}
