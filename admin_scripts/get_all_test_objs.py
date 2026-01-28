import requests
import os
from dotenv import load_dotenv
load_dotenv()

url = "https://localhost:8000/api/sources"

token = f'token {os.environ['API_KEY']}'

headers = {"Authorization": token}

response = requests.get(url, headers=headers)

print(response.json())