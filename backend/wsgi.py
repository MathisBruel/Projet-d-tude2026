from app import create_app

app = create_app()

if __name__ == '__main__':
    # Use port 5001 to avoid conflicts with services bound to port 5000 on Windows
    app.run(debug=True, host='0.0.0.0', port=5001)
