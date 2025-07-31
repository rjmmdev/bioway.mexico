#!/bin/bash

echo ""
echo "========================================"
echo "  Desplegando Cloud Functions"
echo "========================================"
echo ""

# Verificar si Firebase CLI está instalado
if ! command -v firebase &> /dev/null
then
    echo "ERROR: Firebase CLI no está instalado."
    echo "Por favor instala Firebase CLI ejecutando: npm install -g firebase-tools"
    echo ""
    exit 1
fi

# Cambiar al directorio de funciones
cd functions

# Verificar si node_modules existe
if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias..."
    npm install
    if [ $? -ne 0 ]; then
        echo "ERROR: Fallo la instalación de dependencias"
        exit 1
    fi
fi

# Volver al directorio raíz
cd ..

# Seleccionar el proyecto
echo ""
echo "Configurando proyecto Firebase..."
firebase use trazabilidad-ecoce

echo ""
echo "Desplegando Cloud Functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "  ✅ Funciones desplegadas exitosamente"
    echo "========================================"
    echo ""
    echo "Puedes ver los logs con: firebase functions:log"
    echo ""
else
    echo ""
    echo "========================================"
    echo "  ❌ Error al desplegar funciones"
    echo "========================================"
    echo ""
    echo "Revisa los errores arriba e intenta nuevamente."
    echo ""
fi