from app import app

# Vercel uses this file as the Python server entrypoint.
# The Flask app is imported from app.py and served via the @vercel/python runtime.

if __name__ == '__main__':
    app.run()
