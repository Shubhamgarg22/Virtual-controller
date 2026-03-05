@echo off
echo ====================================================
echo   Installing Virtual Controller Server Dependencies
echo ====================================================
pip install -r requirements.txt
echo.
echo Starting server...
python server.py
pause
